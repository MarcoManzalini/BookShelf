import 'package:bookshelf/features/scanner/presentation/cubit/isbn_scan_cubit.dart';
import 'package:bookshelf/features/scanner/presentation/widgets/scan_result_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/pump_app.dart';

class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  _FakeUrlLauncher({required this.result});

  final bool result;
  final opened = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return result;
  }
}

void main() {
  const isbn = '9788806219352';
  late UrlLauncherPlatform realLauncher;
  String? copied;

  setUp(() {
    realLauncher = UrlLauncherPlatform.instance;
    copied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
  });

  tearDown(() {
    UrlLauncherPlatform.instance = realLauncher;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pumpPanel(WidgetTester tester, IsbnScanState state) {
    return tester.pumpApp(
      Scaffold(body: ScanResultPanel(state: state, onRescan: () {})),
    );
  }

  testWidgets('copies the ISBN and opens the Open Library form',
      (tester) async {
    final launcher = _FakeUrlLauncher(result: true);
    UrlLauncherPlatform.instance = launcher;
    await pumpPanel(
      tester,
      const IsbnScanState(status: ScanStatus.notFound, isbn: isbn),
    );
    await tester.tap(find.text('Aggiungilo a Open Library'));
    await tester.pumpAndSettle();

    expect(copied, isbn);
    expect(launcher.opened, ['https://openlibrary.org/books/add']);
    expect(
      find.text('ISBN copiato: incollalo nel modulo di Open Library.'),
      findsOneWidget,
    );
  });

  testWidgets('tells the reader when the browser cannot open', (tester) async {
    UrlLauncherPlatform.instance = _FakeUrlLauncher(result: false);

    await pumpPanel(
      tester,
      const IsbnScanState(status: ScanStatus.notFound, isbn: isbn),
    );
    await tester.tap(find.text('Aggiungilo a Open Library'));
    await tester.pumpAndSettle();

    expect(find.text('Impossibile aprire il link.'), findsOneWidget);
  });

  testWidgets('does not offer Open Library while scanning', (tester) async {
    await pumpPanel(tester, const IsbnScanState(status: ScanStatus.scanning));

    expect(find.text('Aggiungilo a Open Library'), findsNothing);
  });
}
