// ignore_for_file: constant_identifier_names

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../globals.dart' as globals;

class Settings extends StatelessWidget {
  const Settings({Key? key, this.controller}) : super(key: key);

  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final appTheme = context.watch<AppTheme>();
    const spacer = SizedBox(height: 10.0);
    const biggerSpacer = SizedBox(height: 40.0);
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Settings')),
      scrollController: controller,
      children: [
        Text('usbipd info', style: FluentTheme.of(context).typography.subtitle),
        spacer,
        Text(globals.version),
        spacer,
        Text(globals.isUsbpcapPresent
            ? 'USBPcap is installed'
            : 'USBPcap is not installed'),
        spacer,
        Text('WSL', style: FluentTheme.of(context).typography.subtitle),
        spacer,
        Text(globals.selectedDistribution.name),
        biggerSpacer,
        Text('Theme', style: FluentTheme.of(context).typography.subtitle),
        spacer,
        ...List.generate(ThemeMode.values.length, (index) {
          final mode = ThemeMode.values[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RadioButton(
              checked: appTheme.mode == mode,
              onChanged: (value) {
                if (value) {
                  appTheme.mode = mode;
                }
              },
              content: Text('$mode'.replaceAll('ThemeMode.', '')),
            ),
          );
        }),
        biggerSpacer,
      ],
    );
  }
}
