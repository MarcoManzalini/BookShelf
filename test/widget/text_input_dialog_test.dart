import 'package:bookshelf/core/widgets/text_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('returns the typed value and closes cleanly', (tester) async {
    String? result;
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showTextInputDialog<String>(
            context,
            title: 'Nome',
            initialText: 'Marco',
            parse: (text) => text.trim(),
            validator: (text) => text.trim().isEmpty ? 'Obbligatorio' : null,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Salva'));
    await tester.pump();
    expect(find.text('Obbligatorio'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), ' Anna ');
    await tester.tap(find.text('Salva'));
    // The closing animation runs with the field still on screen: this is
    // where a controller disposed too early used to break.
    await tester.pumpAndSettle();
    expect(result, 'Anna');
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
