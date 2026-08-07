import 'package:flutter_test/flutter_test.dart';
import 'package:audiobook_app/state/settings_provider.dart';
import 'package:audiobook_app/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(AudiobookApp(settings: SettingsProvider(baseUrl: 'http://example.com')));
    await tester.pump();
    expect(find.text('аудиокниги'), findsOneWidget);
  });
}
