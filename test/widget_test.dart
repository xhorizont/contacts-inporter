// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:contacts_inporter/main.dart';

void main() {
  testWidgets('Import and about screens are rendered', (tester) async {
    await tester.pumpWidget(const ContactsImporterApp());

    expect(find.text('Uvozi kontakte'), findsOneWidget);
    expect(find.text('URL do CSV datoteke'), findsOneWidget);
    expect(find.text('Posodobi'), findsOneWidget);

    await tester.tap(find.text('O aplikaciji'));
    await tester.pumpAndSettle();

    expect(find.text('O aplikaciji'), findsWidgets);
    expect(find.textContaining('Lorem ipsum'), findsOneWidget);
  });
}
