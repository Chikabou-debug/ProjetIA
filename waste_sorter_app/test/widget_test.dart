import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_sorter_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'base_url': 'http://127.0.0.1:1'});
  });

  testWidgets('affiche la page scanner au demarrage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EcoTriApp());
    await tester.pump();

    expect(find.text('EcoTri AI'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Statistiques'), findsOneWidget);
    expect(find.text('Scannez vos déchets'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsWidgets);
    expect(find.text('Choisir depuis la galerie'), findsOneWidget);
  });

  testWidgets('ouvre la page historique', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoTriApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pump();

    expect(find.byType(HistoryPage), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('ouvre la page statistiques', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoTriApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pump();

    expect(find.byType(StatsPage), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('ouvre la configuration API', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoTriApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Configuration API'), findsOneWidget);
    expect(find.text('URL du serveur'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
  });
}
