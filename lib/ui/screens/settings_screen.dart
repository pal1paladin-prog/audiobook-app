import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config.dart';
import '../../state/settings_provider.dart';
import '../../theme/ak_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _url;
  late TextEditingController _user;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _url = TextEditingController(text: s.baseUrl);
    _user = TextEditingController(text: s.user);
  }

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Section('Сервер'),
          TextField(
            controller: _url,
            style: const TextStyle(color: AkTheme.text),
            decoration: const InputDecoration(
              labelText: 'Адрес сервера',
              hintText: 'http://100.x.x.x/audio-kniga или https://example.ts.net/audio-kniga',
            ),
            onChanged: (v) => s.setBaseUrl(v.trim()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _user,
            style: const TextStyle(color: AkTheme.text),
            decoration: const InputDecoration(labelText: 'Имя пользователя'),
            onChanged: (v) => s.setUser(v.trim().isEmpty ? 'default' : v.trim()),
          ),
          const SizedBox(height: 16),
          _tailscaleHint(),
          const SizedBox(height: 24),
          const _Section('Тема'),
          Wrap(
            spacing: 8,
            children: [
              _themeChip(s, 'dark', 'Тёмная'),
              _themeChip(s, 'light', 'Светлая'),
              _themeChip(s, 'system', 'Системная'),
            ],
          ),
          const SizedBox(height: 24),
          const _Section('О приложении'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AkTheme.bg3,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AkTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AkTheme.accent2, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(kAppName, style: TextStyle(color: AkTheme.text, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('Версия $kAppVersion', style: TextStyle(color: AkTheme.dim, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Кэширование + фоновый плеер + Tailscale',
              style: TextStyle(color: AkTheme.dim, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _themeChip(SettingsProvider s, String value, String label) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: s.theme == value ? Colors.black : AkTheme.text)),
      selected: s.theme == value,
      selectedColor: AkTheme.accent2,
      backgroundColor: AkTheme.bg3,
      onSelected: (_) => s.setTheme(value),
    );
  }

  Widget _tailscaleHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AkTheme.bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AkTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.vpn_lock, color: AkTheme.accent2, size: 18),
            SizedBox(width: 8),
            Text('Tailscale', style: TextStyle(color: AkTheme.accent, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Для доступа к серверу через Tailscale:\n'
            '1. Установите Tailscale на телефон и подключите к вашей сети\n'
            '2. Узнайте Tailscale-IP сервера (в приложении Tailscale или на mynet)\n'
            '3. Введите адрес вида http://100.x.x.x/audio-kniga',
            style: TextStyle(color: AkTheme.dim, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(color: AkTheme.accent2, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
