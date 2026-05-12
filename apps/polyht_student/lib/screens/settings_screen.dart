import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final enabled = auth.user?.twoFactorEnabled == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: AppTheme.cardShadow),
            child: Row(children: [
              const Icon(Icons.verified_user_outlined, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(enabled ? 'Two-factor authentication is enabled' : 'Two-factor authentication is off')),
              FilledButton(onPressed: () => enabled ? _disable(context) : _enable(context), child: Text(enabled ? 'Disable' : 'Enable')),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _enable(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final setup = await auth.setupTwoFactor();
    if (!context.mounted) return;
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable 2FA'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Scan the QR code with your authenticator app, then enter the generated code.'),
            const SizedBox(height: 12),
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(data: setup['otpauthUrl'] as String, size: 190),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(setup['secret'] as String),
            const SizedBox(height: 12),
            TextField(controller: code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Authenticator code')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Enable')),
        ],
      ),
    );
    if (ok == true) await auth.enableTwoFactor(code.text.trim());
    code.dispose();
  }

  Future<void> _disable(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable 2FA'),
        content: TextField(controller: code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Authenticator code')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Disable')),
        ],
      ),
    );
    if (ok == true) await auth.disableTwoFactor(code.text.trim());
    code.dispose();
  }
}
