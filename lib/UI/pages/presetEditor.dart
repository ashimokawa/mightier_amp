// (c) 2020-2021 Dian Iliev (Tuntorius)
// This code is licensed under MIT license (see LICENSE.md for details)

import 'package:flutter/material.dart';
import 'package:mighty_plug_manager/UI/popups/alertDialogs.dart';
import 'package:mighty_plug_manager/bluetooth/NuxDeviceControl.dart';
import '../popups/savePreset.dart';
import '../widgets/presets/channelSelector.dart';
import '../../bluetooth/devices/NuxDevice.dart';

class PresetEditor extends StatefulWidget {
  PresetEditor();
  @override
  _PresetEditorState createState() => _PresetEditorState();
}

class _PresetEditorState extends State<PresetEditor> {
  late NuxDevice device;

  @override
  void initState() {
    super.initState();
    device = NuxDeviceControl().device;
    device.addListener(onDeviceDataChanged);
    NuxDeviceControl().addListener(onDeviceChanged);
  }

  @override
  void dispose() {
    super.dispose();
    device.removeListener(onDeviceDataChanged);
    NuxDeviceControl().removeListener(onDeviceChanged);
  }

  void onDeviceChanged() {
    device.removeListener(onDeviceDataChanged);
    device = NuxDeviceControl().device;
    device.addListener(onDeviceDataChanged);
    setState(() {});
  }

  void onDeviceDataChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool uploadPresetEnabled =
        device.deviceControl.isConnected && device.presetSaveSupport;

    List<bool> _groupSelection = List<bool>.filled(device.groupsCount, false);
    _groupSelection[device.selectedGroup] = true;
    return ListView(
      children: [
        Column(children: [
          ListTile(
            title: Text("Preset Editor"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  child: Icon(Icons.save_alt),
                  onPressed: !uploadPresetEnabled
                      ? null
                      : () {
                          //TODO: move to method
                          if (device.deviceControl.isConnected) {
                            AlertDialogs.showConfirmDialog(context,
                                title: "Save preset to device",
                                cancelButton: "Cancel",
                                confirmButton: "Save",
                                confirmColor: Colors.red,
                                description: "Are you sure?", onConfirm: (val) {
                              if (val) device.saveNuxPreset();
                            });
                          }
                        },
                ),
                const SizedBox(
                  width: 2,
                ),
                ElevatedButton(
                  child: Icon(Icons.playlist_add),
                  onPressed: () {
                    var saveDialog = SavePresetDialog(
                        device: device, confirmColor: Colors.blue);
                    showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          saveDialog.buildDialog(device, context),
                    );
                  },
                )
              ],
            ),
          ),
          if (_groupSelection.length > 1)
            ToggleButtons(
              fillColor: Colors.blue,
              children: [
                for (int i = 0; i < device.groupsCount; i++)
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(device.groupsName[i])),
              ],
              isSelected: _groupSelection,
              onPressed: (int index) {
                setState(() {
                  device.selectedGroup = index;
                });
              },
            ),
        ]),
        ChannelSelector(device: device)
      ],
    );
  }
}
