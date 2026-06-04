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
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Appuyez pour capturer un déchet'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsWidgets);
    expect(find.text('Galerie'), findsOneWidget);
  });

  testWidgets('ouvre la page historique', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoTriApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.history));
    await tester.pump();

    expect(find.byType(HistoryPage), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('ouvre la page statistiques', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoTriApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pump();

    expect(find.byType(StatsPage), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('ouvre la configuration API', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoTriApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Configuration API'), findsOneWidget);
    expect(find.text('URL du serveur Flask'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
  });
}
