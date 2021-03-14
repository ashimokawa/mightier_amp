// (c) 2020-2021 Dian Iliev (Tuntorius)
// This code is licensed under MIT license (see LICENSE.md for details)

import 'package:mighty_plug_manager/UI/popups/alertDialogs.dart';
import 'package:mighty_plug_manager/UI/popups/changeCategory.dart';
import 'package:mighty_plug_manager/bluetooth/NuxDeviceControl.dart';
import 'package:tinycolor/tinycolor.dart';
import '../../../platform/fileSaver.dart';

import '../../../bluetooth/devices/presets/Preset.dart';
import '../../mightierIcons.dart';
import '../dynamic_treeview.dart';
import 'package:flutter/material.dart';
import '../../../bluetooth/devices/presets/presetsStorage.dart';

class PresetList extends StatefulWidget {
  final void Function(dynamic) onTap;
  final bool simplified;
  PresetList({this.onTap, this.simplified = false});
  @override
  _PresetListState createState() => _PresetListState();
}

class _PresetListState extends State<PresetList> {
  var presetsMenu = <PopupMenuEntry>[
    PopupMenuItem(
      value: 1,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.save_alt,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Export"),
        ],
      ),
    ),
    PopupMenuItem(
      value: 2,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.open_in_browser,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Import"),
        ],
      ),
    )
  ];
  //menu for category
  var popupMenu = <PopupMenuEntry>[
    PopupMenuItem(
      value: 0,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.delete,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Delete"),
        ],
      ),
    ),
    PopupMenuItem(
      value: 1,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.drive_file_rename_outline,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Rename"),
        ],
      ),
    ),
    PopupMenuItem(
      value: 2,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.save_alt,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Export Category"),
        ],
      ),
    )
  ];

  //menu for preset
  var popupSubmenu = <PopupMenuEntry>[
    PopupMenuItem(
      value: 0,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.delete,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Delete"),
        ],
      ),
    ),
    PopupMenuItem(
      value: 2,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.alt_route,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Change Channel"),
        ],
      ),
    ),
    PopupMenuItem(
      value: 5,
      child: Row(
        children: <Widget>[
          Icon(
            MightierIcons.tag,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Change Category"),
        ],
      ),
    ),
    PopupMenuItem(
      value: 1,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.drive_file_rename_outline,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Rename"),
        ],
      ),
    ),
    PopupMenuItem(
      value: 3,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.copy,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Duplicate"),
        ],
      ),
    ),
    PopupMenuItem(
      value: 4,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.save_alt,
            color: Colors.grey[400],
          ),
          SizedBox(width: 5),
          Text("Export Preset"),
        ],
      ),
    ),
  ];

  void mainMenuActions(action) async {
    switch (action) {
      case 1: //export category
        String data = PresetsStorage().presetsToJson();

        if (data != null)
          saveFile("application/octet-stream", "presets.nuxpreset", data);
        break;
      case 2: //import
        var content = await openFile("application/octet-stream");
        if (content != null)
          PresetsStorage().presetsFromJson(content).then((value) {
            setState(() {});
          });
        break;
    }
  }

  void menuActions(action, item) async {
    {
      if (item is String) {
        //category
        switch (action) {
          case 0:
            AlertDialogs.showConfirmDialog(context,
                title: "Confirm",
                description: "Are you sure you want to delete category $item?",
                cancelButton: "Cancel",
                confirmButton: "Delete",
                confirmColor: Colors.red, onConfirm: (delete) {
              if (delete) {
                PresetsStorage()
                    .deleteCategory(item)
                    .then((value) => setState(() {}));
              }
            });
            break;
          case 1:
            AlertDialogs.showInputDialog(context,
                title: "Rename",
                description: "Enter category name:",
                cancelButton: "Cancel",
                confirmButton: "Rename",
                value: item,
                validation: (String newName) {
                  return !PresetsStorage().getCategories().contains(newName);
                },
                validationErrorMessage: "Name already taken!",
                confirmColor: Colors.blue,
                onConfirm: (newName) {
                  PresetsStorage()
                      .renameCategory(item, newName)
                      .then((value) => setState(() {}));
                });
            break;
          case 2: //export category
            String data = PresetsStorage().presetsToJson(item);

            if (data != null)
              saveFile("application/octet-stream", "$item.nuxpreset", data);
        }
      } else {
        //preset
        switch (action) {
          case 0:
            AlertDialogs.showConfirmDialog(context,
                title: "Confirm",
                description: "Are you sure you want to delete ${item["name"]}?",
                cancelButton: "Cancel",
                confirmButton: "Delete",
                confirmColor: Colors.red, onConfirm: (delete) {
              if (delete) {
                if (item is Map) {
                  PresetsStorage()
                      .deletePreset(item["category"], item["name"])
                      .then((value) => setState(() {}));
                }
              }
            });
            break;
          case 1:
            AlertDialogs.showInputDialog(context,
                title: "Rename",
                description: "Enter preset name:",
                cancelButton: "Cancel",
                confirmButton: "Rename",
                value: item["name"],
                validationErrorMessage: "Name already taken!",
                validation: (newName) {
                  return PresetsStorage()
                          .findPreset(newName, item["category"]) ==
                      null;
                },
                confirmColor: Colors.blue,
                onConfirm: (newName) {
                  PresetsStorage()
                      .renamePreset(item["category"], item["name"], newName)
                      .then((value) => setState(() {}));
                });
            break;
          case 2:
            var channelList = <String>[];
            int nuxChannel = item["channel"];
            var d = NuxDeviceControl().device;
            for (int i = 0; i < d.channelsCount; i++)
              channelList.add(d.channelName(i));
            var dialog = AlertDialogs.showOptionDialog(context,
                confirmButton: "Change",
                cancelButton: "Cancel",
                title: "Select Channel",
                options: channelList,
                value: nuxChannel, onConfirm: (changed, newValue) {
              if (changed) {
                setState(() {
                  PresetsStorage()
                      .changeChannel(item["category"], item["name"], newValue);
                });
              }
            });
            showDialog(
              context: context,
              builder: (BuildContext context) => dialog,
            );
            break;
          case 3: //duplicate
            PresetsStorage()
                .duplicatePreset(item["category"], item["name"])
                .then((value) {
              setState(() {});
            });
            break;
          case 4: //export
            String data =
                PresetsStorage().presetToJson(item["category"], item["name"]);

            if (data != null)
              saveFile("application/octet-stream", "${item["name"]}.nuxpreset",
                  data);
            break;
          case 5: //change category
            //TODO:
            var categoryDialog = ChangeCategoryDialog(
                category: item["category"],
                name: item["name"],
                onCategoryChange: (newCategory) {
                  setState(() {
                    PresetsStorage().changePresetCategory(
                        item["category"], item["name"], newCategory);
                  });
                });
            showDialog(
              context: context,
              builder: (BuildContext context) =>
                  categoryDialog.buildDialog(context),
            );
            break;
        }
      }
    }
  }

  void showContextMenu(_position, dynamic item, List<PopupMenuEntry> _menu) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    //open menu
    var rect = RelativeRect.fromRect(
        _position & const Size(40, 40), // smaller rect, the touch area
        Offset.zero & overlay.size);
    showMenu(
      position: rect,
      items: _menu,
      context: context,
    ).then((value) {
      menuActions(value, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!widget.simplified)
          ListTile(
            contentPadding: EdgeInsets.only(left: 16, right: 12),
            title: Text("Presets"),
            trailing: PopupMenuButton(
              child: Icon(Icons.more_vert, color: Colors.grey),
              itemBuilder: (context) {
                return presetsMenu;
              },
              onSelected: (pos) {
                mainMenuActions(pos);
              },
            ),
          ),
        Expanded(
          child: _buildList(context),
        )
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    if (PresetsStorage().getCategories().length == 0)
      return Center(child: Text("Empty"));
    Offset _position;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        _position = details.globalPosition;
      },
      child: DynamicTreeView(
        simplified: widget.simplified,
        onCategoryTap: (val) {
          //print(val);
        },
        onCategoryLongPress: (val) {
          showContextMenu(_position, val, popupMenu);
        },
        itemBuilder: (context) {
          return popupMenu;
        },
        onSelected: (pos, item) {
          menuActions(pos, item);
        },
        categories: PresetsStorage().getCategories(),
        items: PresetsStorage().presetsData,
        childBuilder: (item) {
          var device = NuxDeviceControl().device;
          //check if enabled and desaturate color if needed
          bool enabled = item["product_id"] == device.productStringId;
          Color color = Preset.channelColors[item["channel"]];
          if (!enabled) color = TinyColor(color).desaturate(90).color;
          bool selected = item["category"] == device.presetCategory &&
              item["name"] == device.presetName;
          return ListTile(
            enabled: enabled,
            selectedTileColor: Colors.grey[800],
            selected: selected && !widget.simplified,
            onTap: () {
              widget.onTap(item);
              setState(() {});
            },
            onLongPress: () {
              if (!widget.simplified)
                showContextMenu(_position, item, popupSubmenu);
            },
            minLeadingWidth: 0,
            leading: Container(
              height: double.infinity, //strange hack to center icon vertically
              child: Icon(
                NuxDeviceControl()
                    .getDeviceFromId(item["product_id"])
                    .productIcon,
                size: 30,
                color: color,
              ),
            ),
            title: Text(item["name"],
                style: TextStyle(color: enabled ? Colors.white : Colors.grey)),
            subtitle: Text(
              //NuxDeviceControl().getDeviceNameFromId(item["product_id"]),
              NuxDeviceControl().device.channelName(item["channel"]),
              //Channel.values[item["channel"]].toString().split('.')[1],
              style: TextStyle(color: color),
            ),
            trailing: widget.simplified
                ? null
                : PopupMenuButton(
                    child: Icon(Icons.more_vert, color: Colors.grey),
                    itemBuilder: (context) {
                      return popupSubmenu;
                    },
                    onSelected: (pos) {
                      menuActions(pos, item);
                    },
                  ),
          );
        },
        config: Config(
            parentTextStyle: TextStyle(color: Colors.white),
            parentPaddingEdgeInsets: EdgeInsets.only(left: 16, right: 8),
            childrenPaddingEdgeInsets: EdgeInsets.only(left: 0, right: 4),
            arrowIcon: Icon(Icons.keyboard_arrow_down, color: Colors.white)),
      ),
    );
  }
}
