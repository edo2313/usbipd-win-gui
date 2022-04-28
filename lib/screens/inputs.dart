import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../theme.dart';

class Inputs extends StatelessWidget {
  const Inputs({Key? key, this.controller}) : super(key: key);

  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final appTheme = context.watch<AppTheme>();
    const spacer = SizedBox(height: 10.0);
    const biggerSpacer = SizedBox(height: 40.0);
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Inputs')),
      scrollController: controller,
      children: [
        Text(usbipdVersion.stdout
            .substring(0, usbipdVersion.stdout.indexOf('+'))),
        spacer,
        biggerSpacer,
      ],
    );
  }
}
