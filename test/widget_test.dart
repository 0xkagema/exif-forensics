import 'package:exifapp/main.dart';
import 'package:exifapp/ui/components/drop_zone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders correctly with initial DropZone', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExifForensicsApp());
    await tester.pump();

    // Verify app title in header
    expect(find.text('EXIF Forensics'), findsOneWidget);
    expect(find.text('OSINT'), findsOneWidget);

    // Verify DropZone elements
    expect(find.byType(DropZone), findsOneWidget);
    expect(find.text('Drag & drop your image here'), findsOneWidget);
    expect(find.text('Browse File'), findsOneWidget);
  });
}
