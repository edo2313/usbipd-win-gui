// Return true if USBPcap is installed
import 'dart:io';

bool isUsbpcapPresent() {
  return Process.runSync('usbipd', ['list']).stderr != '';
}

String getVersion() {
  final version = Process.runSync('usbipd', ['--version']).stdout;
  return version.substring(0, version.indexOf('+'));
}
