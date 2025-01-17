// (c) 2020-2021 Dian Iliev (Tuntorius)
// This code is licensed under MIT license (see LICENSE.md for details)

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:mighty_plug_manager/bluetooth/devices/NuxMighty8BT.dart';
import 'package:mighty_plug_manager/platform/simpleSharedPrefs.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:undo/undo.dart';

import 'bleMidiHandler.dart';

import 'devices/NuxConstants.dart';
import 'devices/NuxDevice.dart';
import 'devices/NuxMighty2040BT.dart';
import 'devices/NuxMightyLite.dart';
import 'devices/NuxMightyPlugAir.dart';
import 'devices/effects/Processor.dart';

enum DeviceConnectionState { connectedStart, presetsLoaded, configReceived }

class NuxDiagnosticData {
  String device = "";
  bool connected = false;
  String lastNuxPreset = "";

  Map<String, dynamic> toMap(bool includeJsonPreset) {
    var data = Map<String, dynamic>();
    data['device'] = device;
    data['connected'] = connected;
    data['lastNuxPreset'] = lastNuxPreset;

    if (includeJsonPreset)
      data['jsonPreset'] = NuxDeviceControl().device.presetToJson();

    return data;
  }
}

class NuxDeviceControl extends ChangeNotifier {
  static final NuxDeviceControl _nuxDeviceControl = NuxDeviceControl._();

  final BLEMidiHandler _midiHandler = BLEMidiHandler();

  NuxDiagnosticData diagData = NuxDiagnosticData();

  //holds current device
  late NuxDevice _device;
  StreamSubscription<List<int>>? rxSubscription;
  Timer? batteryTimer;

  double _masterVolume = 100;

  var changes = new ChangeStack();

  bool developer = false;
  Function(List<int>)? onDataReceiveDebug;

  double get masterVolume => _masterVolume;
  set masterVolume(double vol) {
    _masterVolume = vol;
    if (isConnected) {
      device.sendAmpLevel();
    }
  }

  //connect status control
  final StreamController<DeviceConnectionState> connectStatus =
      StreamController();
  final StreamController<int> batteryPercentage = StreamController<int>();

  bool get isConnected => _midiHandler.connectedDevice != null;

  //list of all different nux devices
  List<NuxDevice> _deviceInstances = <NuxDevice>[];

  List<NuxDevice> get deviceList => _deviceInstances;

  List<String> deviceBLEName() {
    var names = <String>[];
    for (int i = 0; i < _deviceInstances.length; i++)
      names.addAll(_deviceInstances[i].productBLENames);
    return names;
  }

  List<String> get deviceNameList {
    var names = <String>[];
    for (int i = 0; i < _deviceInstances.length; i++)
      names.add(_deviceInstances[i].productNameShort);
    return names;
  }

  int get deviceIndex {
    for (int i = 0; i < _deviceInstances.length; i++)
      if (_device == _deviceInstances[i]) return i;
    return 0;
  }

  set deviceIndex(int index) {
    clearUndoStack();
    _device = _deviceInstances[index];

    updateDiagnosticsData();
    SharedPrefs().setValue(SettingsKeys.device, _device.productStringId);
    SharedPrefs().setValue(SettingsKeys.deviceVersion, _device.productVersion);
    notifyListeners();
  }

  List<String> get deviceVersionsList {
    var names = <String>[];
    for (int i = 0; i < device.getAvailableVersions(); i++)
      names.add(device.getProductNameVersion(i));
    return names;
  }

  int get deviceFirmwareVersion => device.productVersion;

  set deviceFirmwareVersion(int ver) {
    clearUndoStack();
    device.setFirmwareVersionByIndex(ver);
    SharedPrefs().setValue(SettingsKeys.deviceVersion, ver);
  }

  NuxDevice deviceFromBLEId(String id) {
    for (int i = 0; i < _deviceInstances.length; i++)
      if (_deviceInstances[i].productBLENames.contains(id))
        return _deviceInstances[i];

    //return plug/air by default
    return _deviceInstances[0];
  }

  String getDeviceNameFromId(String id) {
    for (int i = 0; i < _deviceInstances.length; i++) {
      if (_deviceInstances[i].productStringId == id)
        return _deviceInstances[i].productNameShort;
    }
    return "Unknown";
  }

  NuxDevice? getDeviceFromId(String id) {
    for (int i = 0; i < _deviceInstances.length; i++) {
      if (_deviceInstances[i].productStringId == id) return _deviceInstances[i];
    }
    return null;
  }

  clearUndoStack() {
    changes.clearHistory();
    notifyListeners();
  }

  undoStackChanged() {
    notifyListeners();
  }

  forceNotifyListeners() {
    notifyListeners();
  }

  factory NuxDeviceControl() {
    return _nuxDeviceControl;
  }

  NuxDeviceControl._() {
    masterVolume = SharedPrefs().getValue(SettingsKeys.masterVolume, 100.0);

    _midiHandler.setAmpDeviceIdProvider(deviceBLEName);
    _midiHandler.status.listen(_statusListener);

    //create all supported devices
    _deviceInstances.add(NuxMightyPlug(this));
    _deviceInstances.add(NuxMighty8BT(this));
    _deviceInstances.add(NuxMighty2040BT(this));
    _deviceInstances.add(NuxMightyLite(this));

    //make it read from config
    String _dev = SharedPrefs()
        .getValue(SettingsKeys.device, _deviceInstances[0].productStringId);
    _device = getDeviceFromId(_dev) ?? _deviceInstances[0];
    int ver = SharedPrefs().getValue(
        SettingsKeys.deviceVersion, _device.getAvailableVersions() - 1);
    _device.setFirmwareVersionByIndex(ver);

    updateDiagnosticsData(connected: false);

    for (int i = 0; i < _deviceInstances.length; i++) {
      var dev = _deviceInstances[i];
      _deviceInstances[i]
          .presetChangedNotifier
          .addListener(presetChangedListener);
      _deviceInstances[i]
          .parameterChanged
          .stream
          .listen(parameterChangedListener);
      _deviceInstances[i].effectChanged.stream.listen(effectChangedListener);
      _deviceInstances[i].effectSwitched.stream.listen(effectSwitchedListener);
    }
  }

  void _statusListener(statusValue) {
    switch (statusValue) {
      case midiSetupStatus.deviceFound:
        // check if this is valid nux device
        print("Devices found " + _midiHandler.nuxDevices.toString());
        _midiHandler.nuxDevices.forEach((dev) {
          if (dev.device.type != BluetoothDeviceType.classic) {
            //don't autoconnect on manual scan
            if (!_midiHandler.manualScan) {
              _midiHandler.connectToDevice(dev.device);
            }
          }
        });
        break;
      case midiSetupStatus.deviceConnected:
        clearUndoStack();

        //find which device connected
        if (isConnected) {
          print("${_midiHandler.connectedDevice!.name} connected");
          _device = deviceFromBLEId(_midiHandler.connectedDevice!.name);

          updateDiagnosticsData(connected: true);
          SharedPrefs().setValue(SettingsKeys.device, _device.productStringId);
          //can't set version yet, firmware is unknown
          notifyListeners();
          _onConnect();
        }
        break;
      case midiSetupStatus.deviceDisconnected:
        clearUndoStack();
        updateDiagnosticsData(connected: false);
        notifyListeners();
        _onDisconnect();
        break;
      default:
        break;
    }
  }

  void _onConnect() {
    print("Device connected");
    device.onConnect();
    connectStatus.add(DeviceConnectionState.connectedStart);
    rxSubscription = _midiHandler.registerDataListener(_onDataReceive);

    //manually call on presets ready if device doesn't support them
    if (!device.presetSaveSupport) onPresetsReady();
  }

  void _onDisconnect() {
    batteryTimer?.cancel();
    rxSubscription?.cancel();
    device.onDisconnect();
    print("Device disconnected");
  }

  void _onDataReceive(List<int> data) {
    if (developer) onDataReceiveDebug?.call(data);

    if (data.length > 2) {
      //check for firmware message
      if (data[2] == MidiMessageValues.sysExStart &&
          data[3] == 0 &&
          data[8] == 16 &&
          data.length == 12) {
        //firmware version is in the 9th bit
        device.setFirmwareVersion(data[9]);
        //save device version since we know it already
        SharedPrefs()
            .setValue(SettingsKeys.deviceVersion, _device.productVersion);
        requestPresetDelayed();
      } else
        _device.onDataReceived(data.sublist(2));
    } else if (!_device.nuxPresetsReceived && _device.presetSaveSupport) {
      //ask the presets now
      requestFirmwareVersion();
    }
  }

  void _onBatteryTimer(Timer? t) {
    if (!device.batterySupport) return;
    var data = createSysExMessage(DeviceMessageID.devSysCtrlMsgID,
        [SysCtrlState.syscmd_dsprun_battery, 0, 0, 0, 0]);
    _midiHandler.sendData(data);
  }

  void requestFirmwareVersion() async {
    await Future.delayed(Duration(seconds: 1));
    var data = createFirmwareMessage();

    _midiHandler.sendData(data);
  }

  //for some reason we should not ask for presets immediately
  void requestPresetDelayed() async {
    await Future.delayed(Duration(milliseconds: 400));
    requestPreset(0);
  }

  void requestPreset(int index) {
    var data = createSysExMessage(DeviceMessageID.devReqPresetMsgID, index);

    _midiHandler.sendData(data);
  }

  void onPresetsReady() async {
    if (device.batterySupport) {
      batteryTimer = Timer.periodic(Duration(seconds: 15), _onBatteryTimer);
      if (device.presetSaveSupport) _onBatteryTimer(null);
    }
    print("Presets received");

    connectStatus.add(DeviceConnectionState.presetsLoaded);

    if (!device.presetSaveSupport) {
      await Future.delayed(Duration(milliseconds: 1500));
      _onBatteryTimer(null);
      device.selectedChannelNormalized = 0;
      changeDevicePreset(0);
      sendFullPresetSettings();
      deviceConnectionReady();
      return;
    }

    if (!device.advancedSettingsSupport) return;

    await Future.delayed(Duration(milliseconds: 200));
    //request other nux stuff

    //eco mode and other
    var data = createSysExMessage(DeviceMessageID.devReqManuMsgID, [0]);
    _midiHandler.sendData(data);

    await Future.delayed(Duration(milliseconds: 200));
    //usb settings. Send them 3 times as the module does not respond everytime.
    // This is what their software is doing)
    data = createSysExMessage(DeviceMessageID.devSysCtrlMsgID,
        [SysCtrlState.syscmd_usbaudio, 0, 0, 0, 0]);
    _midiHandler.sendData(data);
  }

  void deviceConnectionReady() {
    device.sendAmpLevel();
    connectStatus.add(DeviceConnectionState.configReceived);
  }

  void onBatteryPercentage(int val) {
    batteryPercentage.add(val);
  }

  void setEcoMode(bool enable) {
    var data = createSysExMessage(DeviceMessageID.devSysCtrlMsgID,
        [SysCtrlState.syscmd_eco_pro, enable ? 1 : 0, 0, 0, 0]);
    _midiHandler.sendData(data);
  }

  void setBtEq(int eq) {
    var data = createSysExMessage(
        DeviceMessageID.devSysCtrlMsgID, [SysCtrlState.syscmd_bt, 1, eq, 0, 0]);
    _midiHandler.sendData(data);
  }

  void setUsbAudioMode(int mode) {
    var data = createCCMessage(MidiCCValues.bCC_VolumePedalMin, mode);
    _midiHandler.sendData(data);
  }

  void setUsbInputVolume(int vol) {
    var data = createCCMessage(
        MidiCCValues.bCC_VolumePedal, percentageTo7Bit(vol.toDouble()));
    _midiHandler.sendData(data);
  }

  void setUsbOutputVolume(int vol) {
    var data = createCCMessage(
        MidiCCValues.bCC_VolumePrePost, percentageTo7Bit(vol.toDouble()));
    _midiHandler.sendData(data);
  }

  //preset editing listeners
  void parameterChangedListener(Parameter param) {
    if (!isConnected) return;
    sendParameter(param, false);
  }

  void presetChangedListener() {
    clearUndoStack();
    if (!isConnected) return;
    changeDevicePreset(device.presetChangedNotifier.value);
  }

  void changeDevicePreset(int preset) {
    clearUndoStack();
    if (!isConnected) return;

    var data = createCCMessage(device.channelChangeCC, preset);
    _midiHandler.sendData(data);
  }

  void effectSwitchedListener(int slot) {
    if (!isConnected) return;
    var preset = device.getPreset(device.selectedChannel);
    var swIndex = preset
        .getEffectsForSlot(slot)[preset.getSelectedEffectForSlot(slot)]
        .midiCCEnableValue;

    //in midi boolean is 00 and 7f for false and true
    int enabled = preset.slotEnabled(slot) ? 0x7f : 0x00;
    var data = createCCMessage(swIndex, enabled);
    _midiHandler.sendData(data);
  }

  void effectChangedListener(int slot) {
    sendFullEffectSettings(slot, true);
  }

  void sendFullPresetSettings() {
    if (!isConnected) return;
    for (var i = 0; i < device.processorList.length; i++)
      sendFullEffectSettings(i, false);
  }

  void sendFullEffectSettings(int slot, bool force) {
    if (!isConnected) return;
    var preset = device.getPreset(device.selectedChannel);
    var effect;
    int index;
    effect =
        preset.getEffectsForSlot(slot)[preset.getSelectedEffectForSlot(slot)];
    index = effect.nuxIndex;

    //check if preset switchable
    bool switchable = preset.slotSwitchable(slot);
    bool enabled = preset.slotEnabled(slot);

    //send parameters only if the effect is on OR is not switchable off
    bool send = !switchable || (switchable && enabled) || force;
    send = true; //still buggy, fix it first

    //send effect type
    if (slot != 0 && send && effect.midiCCSelectionValue >= 0) {
      var data = createCCMessage(effect.midiCCSelectionValue, index);
      _midiHandler.sendData(data);
    }

    //send parameters
    if (send) {
      for (int i = 0; i < effect.parameters.length; i++) {
        sendParameter(effect.parameters[i], false);
      }
    }

    //send switched
    if (switchable) {
      int enabledVal = enabled ? 0x7f : 0x00;
      var data = createCCMessage(effect.midiCCEnableValue, enabledVal);
      _midiHandler.sendData(data);
    }
  }

  void resetToChannelDefaults() {
    int channel = device.selectedChannel;
    changeDevicePreset(channel);
    sendFullPresetSettings();
  }

  List<int> sendParameter(Parameter param, bool returnOnly) {
    int outVal;
    double value = param.value;

    //implement master volume
    if (param.masterVolume) value *= (masterVolume * 0.01);

    if (param.valueType == ValueType.db)
      outVal = dbTo7Bit(value);
    else
      outVal = percentageTo7Bit(value);
    var data = createCCMessage(param.midiCC, outVal);
    if (!returnOnly) _midiHandler.sendData(data);
    return data;
  }

  void saveNuxPreset() {
    if (!isConnected) return;
    var data = createCCMessage(MidiCCValues.bCC_CtrlCmd, 0x7e);
    _midiHandler.sendData(data);
    requestPreset(device.selectedChannel);
  }

  void resetNuxPresets() {
    if (!isConnected) return;
    var data = createCCMessage(MidiCCValues.bCC_CtrlCmd, 0x7f);
    _midiHandler.sendData(data);

    //show loading popup
    if (device.presetSaveSupport) {
      connectStatus.add(DeviceConnectionState.connectedStart);
      requestPresetDelayed();
    }
  }

  void sendDrumsEnabled(bool enabled) {
    if (!isConnected) return;
    var data =
        createCCMessage(MidiCCValues.bCC_drumOnOff_No, enabled ? 0x7f : 0);
    _midiHandler.sendData(data);
  }

  void sendDrumsStyle(int style) {
    if (!isConnected) return;
    var data = createCCMessage(MidiCCValues.bCC_drumType_No, style);
    _midiHandler.sendData(data);
  }

  void sendDrumsLevel(double volume) {
    if (!isConnected) return;
    int val = percentageTo7Bit(volume);
    var data = createCCMessage(MidiCCValues.bCC_drumLevel_No, val);
    _midiHandler.sendData(data);
  }

  void sendDrumsTempo(double tempo) {
    if (!isConnected) return;

    int tempoNux = (((tempo - 40) / 200) * 16384).floor();
    //these must be sent as 2 7bit values
    int tempoL = tempoNux & 0x7f;
    int tempoH = (tempoNux >> 7);

    //no idea what the first 2 messages are for
    var data = createCCMessage(MidiCCValues.bCC_drumTempo1, 0x06);
    _midiHandler.sendData(data);
    data = createCCMessage(MidiCCValues.bCC_drumTempo2, 0x26);
    _midiHandler.sendData(data);
    data = createCCMessage(MidiCCValues.bCC_drumTempoH, tempoH);
    _midiHandler.sendData(data);
    data = createCCMessage(MidiCCValues.bCC_drumTempoL, tempoL);
    _midiHandler.sendData(data);
  }

  double sevenBitToPercentage(int val) {
    return (val / 127) * 100;
  }

  double sevenBitToDb(int val) {
    return (val / 127) * 12 - 6;
  }

  int percentageTo7Bit(double val) {
    return (val / 100 * 127).floor();
  }

  int dbTo7Bit(double db) {
    return ((db + 6) / 12 * 127).floor();
  }

  List<int> createCCMessage(int controlNumber, int value) {
    var msg = List<int>.filled(5, 0);
    msg[0] = 0x80;
    msg[1] = 0x80;
    msg[2] = MidiMessageValues.controlChange;
    msg[3] = controlNumber;
    msg[4] = value;
    return msg;
  }

  List<int> createSysExMessage(int deviceMessageId, var data,
      {int sysExMsgId = CherubSysExMessageID.cSysExDeviceSpecMsgID}) {
    List<int> msg = [];

    //create header
    msg.addAll([
      0x80,
      0x80,
      MidiMessageValues.sysExStart,
      0,
      device.vendorID & 255,
      device.vendorID >> 8 & 255,
      device.productVID & 255,
      device.productVID >> 8 & 255,
      (7 & sysExMsgId) << 4,
      deviceMessageId
    ]);

    //add payload
    if (data is int)
      msg.add(data);
    else
      msg.addAll(data);

    //add termination symbol
    msg.add(0x80);
    msg.add(MidiMessageValues.sysExEnd);

    return msg;
  }

  List<int> createFirmwareMessage() {
    List<int> msg = [];

    //create header
    msg.addAll([
      0x80,
      0x80,
      MidiMessageValues.sysExStart,
      0,
      device.vendorID & 255,
      device.vendorID >> 8 & 255,
      device.productVID & 255,
      device.productVID >> 8 & 255,
      0
    ]);

    //add termination symbol
    msg.add(0x80);
    msg.add(MidiMessageValues.sysExEnd);

    return msg;
  }

  void updateDiagnosticsData(
      {bool? connected, String? nuxPreset, bool includeJsonPreset = false}) {
    if (nuxPreset != null) diagData.lastNuxPreset = nuxPreset;

    diagData.device = "${_device.productName} ${_device.productVersion}";
    if (connected != null) diagData.connected = connected;

    Sentry.configureScope((scope) {
      scope.setTag(
          "nuxDevice", "${_device.productName} ${_device.productVersion}");
      scope.setContexts('NUX', diagData.toMap(includeJsonPreset));
    });
  }

  NuxDevice get device => _device;
}
