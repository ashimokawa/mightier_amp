// (c) 2020-2021 Dian Iliev (Tuntorius)
// This code is licensed under MIT license (see LICENSE.md for details)

class AppConstants {
  static const patcherUrl =
      "https://github.com/tuntorius/nux-ir-patcher#nux-ir-patcher";
}

class EProductNo {
  static const CHERUB_VID = 8721;
  static const TAPECORE_PID = 0;
  static const STAGEMAN_PID = 16;
  static const CERBERUS_PID = 32;
  static const MIGHTYBT_PID = 48;
  static const MIGHTYLITE_PID = 64;
  static const TAP5_PID = 102;
}

class CherubSysExMessageID {
  static const cSysExRollCallMsgID = 0;
  static const cSysExDeviceSpecMsgID = 7;
}

class SysCtrlState {
  static const syscmd_null = 0;
  static const syscmd_save = 48;
  static const syscmd_resetall = 50;
  static const syscmd_refresh_preset = 51;
  static const syscmd_bt = 64;
  static const syscmd_eco_pro = 65;
  static const syscmd_dsprun_battery = 66;
  static const syscmd_usbaudio = 67;
}

class DeviceMessageID {
  static const devReqMIDIParaMsgID = 0;
  static const devGetMIDIParaMsgID = 1;
  static const devSetMIDIParaMsgID = 2;
  static const devReqCurCCMsgID = 3;
  static const devReqCurNRPNMsgID = 4;
  static const devSysCtrlMsgID = 5;
  static const devReqPresetMsgID = 6; //request preset
  static const devGetPresetMsgID = 7;
  static const devSetPresetMsgID = 8;
  static const devReqCurLoopMsgID = 9;
  static const devProjectMsgID = 16;
  static const devReqManuMsgID = 22;
  static const devGetManuMsgID = 23;
  static const devSetManuMsgID = 24;
  static const devSetPresetNameMsgID = 32;
  static const devNullDataID = 80;
  static const devParaDataID = 81;
  static const devCabDataSetID = 88;
  static const devCabDataGetID = 89;
  static const devCrcNameGetId = 92;
  static const devCablevelGetId = 94;
  static const devCabLCGetId = 96;
  static const devCabHCGetId = 98;
  static const devOpenTapLedMsgID = 10;
  static const padReqCurCCMsgID = 19;
  static const devHadrWareTestID = 100;
  static const devDfuEnterID = 102;
  static const devSysStateID = 103;
  static const devDfuDataSetID = 104;
  static const devDfuDataGetID = 105;
}

class PresetDataIndexPlugAir {
  static const effectTypesIndex = [
    0, //not used but there must be a value here
    efxtype,
    amptype,
    cabtype,
    modfxtype,
    delaytype,
    reverbtype
  ];

  static const effectEnabledIndex = [
    ngenable,
    efxenable,
    ampenable,
    cabenable,
    modfxenable,
    delayenable,
    reverbenable
  ];

  static const ngenable = 0;
  static const ngthresold = 1;
  static const ngsustain = 2;
  static const efxenable = 3;
  static const efxtype = 4;
  static const efxvar1 = 5;
  static const efxvar2 = 6;
  static const efxvar3 = 7;
  static const ampenable = 8;
  static const amptype = 9;
  static const ampgain = 10;
  static const amplevel = 11;
  static const ampbass = 12;
  static const ampmiddle = 13;
  static const amptreble = 14;
  static const amptone = 15;
  static const cabenable = 16;
  static const cabtype = 17;
  static const cabgain = 18;
  static const modfxenable = 19;
  static const modfxtype = 20;
  static const modfxrate = 21;
  static const modfxvar1rate = 21;
  static const modfxdepth = 22;
  static const modfxvar2depth = 22;
  static const modfxmix = 23;
  static const modfxvar3mix = 23;
  static const delayenable = 24;
  static const delaytype = 25;
  static const delaytime = 26;
  static const delayvar1time = 26;
  static const delayfeedback = 27;
  static const delayvar2feedback = 27;
  static const delaymix = 28;
  static const delayvar3mix = 28;
  static const reverbenable = 29;
  static const reverbtype = 30;
  static const reverbdecay = 31;
  static const reverbvar1decay = 31;
  static const reverbdamp = 32;
  static const reverbvar2damp = 32;
  static const reverbmix = 33;
  static const reverbvar3mix = 33;
}

class PresetDataIndex8BT {
  //use PresetDataIndexLite for most of the constants

}

class PresetDataIndexLite {
  static const effectTypesIndex = [
    0, //not used but there must be a value here
    drivetype,
    modfxtype,
    efxtype,
  ];

  static const effectEnabledIndex = [ngenable, modfxenable, efxenable];

  static const ngenable = 0;
  static const ngthresold = 1;
  static const ngsustain = 2;

  static const drivetype = 3;
  static const drivesubtype1 = 4;
  static const drivesubtype2 = 5;
  static const drivesubtype3 = 6;
  static const drivegain = 7;
  static const drivelevel = 8;
  static const drivebass = 9;
  static const drivemid = 10;
  static const drivetreble = 11;
  static const drivetone = 12;

  static const modfxenable = 13;
  static const modfxtype = 14;
  static const modfxrate = 15;
  static const modfxdepth = 16;
  static const modfxmix = 17;

  static const efxenable = 18;
  static const efxtype = 19;
  static const reverbtype = 20;
  static const reverbdecay = 21;
  static const reverbmix = 22;

  static const delaytype = 23;
  static const delaytime = 24;
  static const delayfeedback = 25;
  static const delaymix = 26;

  static const tap_time_flag = 27;
  static const tap_time_bpm_h = 28;
  static const tap_time_bpm_l = 29;
  static const tap_time_value_h = 30;
  static const tap_time_value_l = 31;
  static const reverbenable = 32;
  static const delayenable = 33;
  static const miclevel = 34;
  static const micambsend = 35;
}

class MidiMessageValues {
  static const controlChange = 0xb0;
  static const sysExStart = 0xf0;
  static const sysExEnd = 0xf7;
}

class MidiCCValues {
  static const bCC_NotUsed = -1; //for LITE amp
  static const bCC_OverDriveEnable = 111;
  static const bCC_OverDriveDrive = 13;
  static const bCC_OverDriveTone = 14;
  static const bCC_OverDriveLevel = 15;
  static const bCC_OverDriveMode = 16;
  static const bCC_DistEnable = 84;
  static const bCC_DistGain = 21;
  static const bCC_DistTone = 17;
  static const bCC_DistLevel = 10;
  static const bCC_DistMode = 12;
  static const bCC_BoostEnable = 76;
  static const bCC_BypassEnable = 9;
  static const bCC_Routing = 11;
  static const bCC_VolumePedal = 7;
  static const bCC_VolumePrePost = 47;
  static const bCC_VolumePedalMin = 46;
  static const bCC_TempoMSB = 89;
  static const bCC_TempoLSB = 90;
  static const bCC_Tap = 64;
  static const bCC_GateEnable = 22;
  static const bCC_GateThresold = 23;
  static const bCC_GateDecay = 24;
  static const bCC_CabMode = 71;
  static const bCC_CabMicsel = 70;
  static const bCC_CabEnable = 101;
  static const bCC_AmpModeSetup = 75;
  static const bCC_AmpMode = 78;
  static const bCC_AmpDrive = 79;
  static const bCC_AmpPresence = 80;
  static const bCC_AmpMaster = 81;
  static const bCC_AmpEnable = 102;
  static const bCC_AmpBass = 103;
  static const bCC_AmpMid = 104;
  static const bCC_AmpHigh = 105;
  static const bCC_ModfxMode = 58;
  static const bCC_ModfxRate = 51;
  static const bCC_ModfxDepth = 52;
  static const bCC_ChorusMode = 61;
  static const bCC_ChorusRate = 53;
  static const bCC_ChorusDepth = 54;
  static const bCC_ChorusLevel = 55;
  static const bCC_ModfxEnable = 56;
  static const bCC_ChorusEnable = 57;
  static const bCC_DelayMode = 88;
  static const bCC_DelayTime = 30;
  static const bCC_DelayRepeat = 31;
  static const bCC_ReverbMode = 37;
  static const bCC_DelayLevel = 85;
  static const bCC_ReverbDecay = 86;
  static const bCC_ReverbLevel = 87;
  static const bCC_ReverbRouting = 34;
  static const bCC_DelayEnable = 28;
  static const bCC_ReverbEnable = 36;
  static const bCC_CtrlType = 49;
  static const bCC_drumOnOff_No = 122;
  static const bCC_drumType_No = 123;
  static const bCC_drumLevel_No = 125;
  static const bCC_drumTempo1 = 0x62;
  static const bCC_drumTempo2 = 0x63;
  static const bCC_drumTempoH = 0x06;
  static const bCC_drumTempoL = 0x26;
  static const bCC_LoopLevel = 121;
  static const bCC_LoopCtrl = 124;
  static const bCC_DrumLed = 126;
  static const bCC_CtrlCmd = 127;
  static const bcc_mChrOnOff = 112;
  static const bcc_gChrOnOff = 57;
  static const bcc_mRevOnOff = 113;
  static const bcc_gRevOnOff = 36;
  static const bcc_gChrRate = 51;
  static const bcc_gChrDepth = 52;
  static const bcc_mChrRate = 53;
  static const bcc_mChrDepth = 54;
  static const bcc_gRevDecay = 91;
  static const bcc_gRevDamp = 92;
  static const bcc_mRevDecay = 93;
  static const bcc_mRevDamp = 94;
  static const bcc_gChrType = 60;
  static const bcc_mChrType = 63;
  static const bcc_gRevType = 37;
  static const bcc_mRevType = 39;
}
