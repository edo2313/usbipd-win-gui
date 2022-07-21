import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:version/version.dart';

import '../utilities.dart';

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
            content: Text('${e.name}  |  ${e.status}'),
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
            child: treeViewItemsMultipleSelection.isNotEmpty
                ? TreeView(
                    selectionMode: TreeViewSelectionMode.multiple,
                    shrinkWrap: false,
                    items: treeViewItemsMultipleSelection,
                    onItemInvoked: (item) async => toggleItem(item.value),
                    onSelectionChanged: (newItems) async =>
                        selectedDevices = newItems,
                  )
                : const Center(
                    child: Text('No devices found'),
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
  if (Version.parse(getVersion()) > Version.parse('2.2.0')) {
    return newGetDevices();
  } else {
    return oldGetDevices();
  }
}

List<Device> newGetDevices() {
  List<Device> devices = <Device>[];
  String? output = Process.runSync('usbipd', ['state']).stdout;
  if (output != null) {
    Map<String, dynamic> json = jsonDecode(output);
    json['Devices']?.forEach((e) {
      if (e['PersistedGuid'] == null || e['ClientWslInstance'] != null) {
        devices.add(Device(e['BusId'], e['Description'],
            e['ClientWslInstance'] == null ? 'Not shared' : 'Shared'));
      }
    });
  }

  return devices;
}

List<Device> oldGetDevices() {
  List<Device> devices = <Device>[];

  String? output = Process.runSync('usbipd', ['list']).stdout;
  if (output != null) {
    List<String> splitOutput = output.split('\r\n');
    if (splitOutput.removeAt(0) != 'Connected:') {
      return [];
    }
    String headers = splitOutput.removeAt(0);
    int busidIndex = headers.indexOf("BUSID");
    int vidpidIndex = headers.indexOf("VID:PID");
    int nameIndex = headers.indexOf("DEVICE");
    int statusIndex = headers.indexOf("STATE");

    for (String line in splitOutput) {
      if (line.isEmpty) {
        break;
      }
      String busid = line.substring(busidIndex, vidpidIndex).trim();
      // String vidpid = line.substring(vidpidIndex, nameIndex).trim();
      String name = line.substring(nameIndex, statusIndex).trim();
      String status = line.substring(statusIndex).trim();
      devices.add(Device(busid, name, status));
    }
  }
  return devices;
}
