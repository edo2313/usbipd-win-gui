import 'dart:convert';
import 'dart:io';

late bool isUsbpcapPresent;
late String version;
late WslDistribution selectedDistribution;

class WslDistribution {
  final String name;
  final String status;
  final bool isDefault;
  WslDistribution(this.name, this.status, this.isDefault);
  @override
  String toString() {
    return '$name - $status - $isDefault';
  }
}

List<WslDistribution> getWslDistributions() {
  List<WslDistribution> wslDistributions = <WslDistribution>[];
  String? output = Process.runSync('wsl', ['-l', '-v']).stdout;

  if (output != null) {
    // TODO: check if there is another way
    output = jsonDecode(jsonEncode(output).replaceAll('\\u0000', '')) as String;
    
    List<String> splitOutput = output.split('\r\n');

    String headers = splitOutput.removeAt(0);
    int nameIndex = headers.indexOf("NAME");
    int statusIndex = headers.indexOf("STATE");
    int versionIndex = headers.indexOf("VERSION");

    for (String line in splitOutput) {
      if (line.isEmpty) {
        continue;
      }
      String name = line.substring(nameIndex, statusIndex).trim();
      String status = line.substring(statusIndex, versionIndex).trim();
      bool isDefault = line.contains('*');
      wslDistributions.add(WslDistribution(name, status, isDefault));
    }
  }
  return wslDistributions;
}
