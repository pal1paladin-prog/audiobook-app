import 'package:flutter/material.dart';
import '../theme/ak_theme.dart';

final GlobalKey<ScaffoldMessengerState> appMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showToast(String message, {bool error = false}) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? AkTheme.danger : null,
    duration: const Duration(seconds: 4),
  ));
}
