import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';

import '../globals.dart' as globals;

class Devices extends StatefulWidget {
  const Devices({Key? key, this.controller}) : super(key: key);

  final ScrollController? controller;

  @override
  State<Devices> createState() => _DevicesState();
}

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
List<TreeViewItem> selectedDevices = <TreeViewItem>[];

class _DevicesState extends State<Devices> {
  bool isRefreshing = false;
  String? processingId;
  String? selectedDevice;
  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(height: 10.0);
    List<Checkbox> deviceCheckboxes = devices
        .map((e) => Checkbox(
            content: Text('${e.name}  |  ${e.status}'),
            onChanged: processingId == e.id ? null : (value) => toggleItem(e, value),
            checked: e.status != 'Not shared'))
        .toList();
    return ScaffoldPage.scrollable(
      header: PageHeader(
          title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Devices'),
          FilledButton(
              onPressed: () => {refreshDevices()},
              child:
                  isRefreshing ? const ProgressRing() : const Text('Refresh'))
        ],
      )),
      scrollController: widget.controller,
      children: [
        SizedBox(
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 380,
                  maxWidth: 350,
                ),
                child: deviceCheckboxes.isNotEmpty
                    ? Column(
                        children: [
                          Expanded(
                            child: ListView(
                              children: deviceCheckboxes,
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Text('No devices found'),
                      ),
              ),
              processingId != null ? const ProgressRing() : const Text('not working...'),
            ],
          ),
        ),
        spacer,
      ],
    );
  }

  void toggleItem(Device device, bool? value) {
    setState(() {
      processingId = device.id;
    });
    (value == true ? attachDevice(device) : detachDevice(device))
        .then((value) => setState(() {
              processingId = null;
            }));
  }

  Future<void> attachDevice(Device device) async {
    if (globals.isUsbpcapPresent) {
      await Process.run('usbipd', ['bind', '--force', '--busid', device.id]);
    }
    await Process.run('usbipd', ['wsl', 'attach', '--busid', device.id]);
    devices = getDevices();
    debugPrint('attached $device.id');
  }

  Future<void> detachDevice(Device device) async {
    await Process.run('usbipd', ['wsl', 'detach', '--busid', device.id]);
    if (globals.isUsbpcapPresent) {
      await Process.run('usbipd', ['unbind', '--busid', device.id]);
    }
    devices = getDevices();
    debugPrint('detached $device.id');
  }

  Future<void> refreshDevices() async {
    setState(() {
      isRefreshing = true;
    });
    devices = getDevices();
    setState(() {
      isRefreshing = false;
    });
  }
}

List<Device> getDevices() {
  List<Device> devices = <Device>[];
  String? output = Process.runSync('usbipd', ['state']).stdout;
  if (output != null) {
    Map<String, dynamic> json = jsonDecode(output);
    json['Devices']?.forEach((e) {
      if (e['BusId'] != null) {
        devices.add(Device(
            e['BusId'],
            e['Description'],
            e['PersistedGuid'] == null
                ? 'Not shared'
                : (e['ClientWslInstance'] == null ? 'Shared' : 'Attached')));
      }
    });
  }

  return devices;
}
