import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';

class Devices extends StatefulWidget {
  const Devices({Key? key, this.controller}) : super(key: key);

  final ScrollController? controller;

  @override
  State<Devices> createState() => _DevicesState();
}

bool usbpcap = isUsbpcapPresent();

class Device {
  String id;
  String name;
  String status;
  Device(this.id, this.name, this.status);
  @override
  String toString() {
    return '$id - $name - $status';
  }
}

List<Device> devices = getDevices();
Iterable<TreeViewItem> selectedDevices = <TreeViewItem>[];

class _DevicesState extends State<Devices> {
  String? selectedDevice;
  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(height: 10.0);
    List<TreeViewItem> treeViewItemsMultipleSelection = devices
        .map((e) => TreeViewItem(
            content: Text(e.name + '  |  ' + e.status),
            value: e.id,
            selected: e.status != 'Not shared'))
        .toList();
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Devices')),
      scrollController: widget.controller,
      children: [
        SizedBox(
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 380,
              maxHeight: 380,
              maxWidth: 350,
            ),
            child: TreeView(
              selectionMode: TreeViewSelectionMode.multiple,
              shrinkWrap: false,
              items: treeViewItemsMultipleSelection,
              onItemInvoked: (item) async => toggleItem(item.value),
              onSelectionChanged: (newItems) async =>
                  selectedDevices = newItems,
            ),
          ),
        ),
        spacer,
      ],
    );
  }

  void toggleItem(String item) {
    // TODO: Maybe optimize with one call only
    if (List.generate(selectedDevices.length,
            (i) => selectedDevices.elementAt(i).value).contains(item) &&
        devices.where((e) => e.id == item).first.status == 'Not shared') {
      debugPrint(devices.where((e) => e.id == item).first.status);
      attachDevice(item);
    } else if (!List.generate(selectedDevices.length,
            (i) => selectedDevices.elementAt(i).value).contains(item) &&
        devices.where((e) => e.id == item).first.status != 'Not shared') {
      detachDevice(item);
    }

    //Update the widget
    setState(() {});
  }

  bool attachDevice(String id) {
    if (usbpcap) {
      Process.runSync('usbipd', ['bind', '--force', '--busid', id]);
    }
    Process.runSync('usbipd', ['wsl', 'attach', '--busid', id]);
    devices = getDevices();
    debugPrint('attached $id');
    return true;
  }

  bool detachDevice(String id) {
    Process.runSync('usbipd', ['wsl', 'detach', '--busid', id]);
    if (usbpcap) {
      Process.runSync('usbipd', ['unbind', '--busid', id]);
    }
    devices = getDevices();
    debugPrint('detached $id');
    return true;
  }
}

List<Device> getDevices() {
  List<Device> devices = [];

  String? match = RegExp(r"(Connected.*\r*\n*.*STATE\r\n)((.+\r\n)+)")
      .firstMatch(Process.runSync('usbipd', ['list']).stdout)
      ?.group(2);
  if (match != null) {
    match.split('\r\n').forEach((e) {
      RegExpMatch? device = RegExp(
              r"(?<id>[0-9]+-[0-9]+)\s*(?<name>(?:\S+\s)+)\s*(?<status>(?:\S+\s?)+)")
          .firstMatch(e);
      if (device != null) {
        devices.add(Device(device.namedGroup('id')!, device.namedGroup('name')!,
            device.namedGroup('status')!));
      }
    });
  }
  return devices;
}

// Return true if USBPcap is installed
bool isUsbpcapPresent() {
  return Process.runSync('usbipd', ['list']).stderr != '';
}
