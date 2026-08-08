import 'package:flutter_test/flutter_test.dart';
import 'package:audiobook_app/api/ak_api.dart';
import 'package:audiobook_app/services/audio_handler.dart';
import 'package:audiobook_app/services/download_service.dart';
import 'package:audiobook_app/state/settings_provider.dart';
import 'package:audiobook_app/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(AudiobookApp(
      settings: SettingsProvider(baseUrl: 'http://example.com'),
      api: AkApi(baseUrl: 'http://example.com'),
      downloads: DownloadService(AkApi(baseUrl: 'http://example.com')),
      handler: AkAudioHandler(),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('аудиокниги'), findsOneWidget);
  });
}
