import 'package:flutter/material.dart';

import '../services/update_service.dart';

class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  final _service = UpdateService();
  AppUpdate? _mandatoryUpdate;
  bool _installing = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final update = await _service.checkForUpdate();
      if (mounted) {
        setState(() {
          _mandatoryUpdate = update?.mandatory == true ? update : null;
        });
      }
    } catch (_) {
      // Update checks should never block opening the app.
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = _mandatoryUpdate;
    if (update == null) return widget.child;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.system_update_alt_rounded, size: 64),
                const SizedBox(height: 16),
                Text('Update Required',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  update.releaseNotes.isEmpty
                      ? 'A newer secure build is required to continue.'
                      : update.releaseNotes,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _installing ? null : () => _install(update),
                  icon: _installing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(update.usesPlayStore
                          ? Icons.shop_rounded
                          : Icons.download_rounded),
                  label: Text(_installing
                      ? 'Downloading...'
                      : update.usesPlayStore
                          ? 'Update on Play Store'
                          : 'Download ${update.latestVersion}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _install(AppUpdate update) async {
    setState(() => _installing = true);
    try {
      await _service.openUpdate(update);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err.toString())));
      }
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }
}
