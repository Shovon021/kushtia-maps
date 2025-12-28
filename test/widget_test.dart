import 'package:flutter_test/flutter_test.dart';
import 'package:kushtia_maps/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Just verify it builds without crashing
    expect(find.text('Kushtia Maps'), findsOneWidget); // Checks AppBar title
  });
}
