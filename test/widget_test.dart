import 'package:exifapp/app.dart';
import 'package:exifapp/theme.dart';
import 'package:exifapp/ui/widgets/drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders correctly with initial DropZone', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExifForensicsApp());
    await tester.pump();

    // Verify DropZone elements
    expect(find.byType(DropZone), findsOneWidget);
    expect(find.text('Drag & drop your image here'), findsOneWidget);
    expect(find.text('Browse File'), findsOneWidget);

    // Toggle theme to light mode
    final toggle = find.byIcon(Icons.wb_sunny);
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pumpAndSettle();

    // Toggle theme back to dark mode
    final toggleBack = find.byIcon(Icons.nightlight_round);
    expect(toggleBack, findsOneWidget);
    await tester.tap(toggleBack);
    await tester.pump();
    await tester.pumpAndSettle();
  });

  testWidgets('Theme toggle with all themed components does not crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.dark,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(
          body: Column(
            children: [
              const Card(child: Text('Card')),
              const Chip(label: Text('Chip')),
              const TextField(decoration: InputDecoration(hintText: 'Hint')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
              TextButton(onPressed: () {}, child: const Text('Text')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // Switch to light theme
    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.light,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(
          body: Column(
            children: [
              const Card(child: Text('Card')),
              const Chip(label: Text('Chip')),
              const TextField(decoration: InputDecoration(hintText: 'Hint')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
              TextButton(onPressed: () {}, child: const Text('Text')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  });
}
