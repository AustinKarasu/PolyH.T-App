import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/test_paper.dart';
import '../providers/auth_provider.dart';
import '../services/test_service.dart';
import '../widgets/update_button.dart';
import 'admin_accounts_screen.dart';
import 'security_log_screen.dart';
import 'upload_test_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = TestService();
  late Future<List<TestPaper>> _tests;

  @override
  void initState() {
    super.initState();
    _tests = _service.fetchTests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PolyH.T Admin'),
        actions: [
          const UpdateButton(),
          IconButton(
            tooltip: 'Admins',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminAccountsScreen())),
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
          IconButton(
            tooltip: 'Exam logs',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecurityLogScreen())),
            icon: const Icon(Icons.shield_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: context.read<AuthProvider>().logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUpload,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload PDF'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _tests = _service.fetchTests()),
        child: FutureBuilder<List<TestPaper>>(
          future: _tests,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final tests = snapshot.data ?? [];
            if (tests.isEmpty) {
              return const Center(child: Text('No scheduled tests yet.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _TestCard(
                test: tests[index],
                onChanged: () => setState(() => _tests = _service.fetchTests()),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openUpload() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UploadTestScreen()));
    setState(() => _tests = _service.fetchTests());
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test, required this.onChanged});

  final TestPaper test;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd MMM, hh:mm a');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                child: Text(test.branchName.substring(0, 1)),
              ),
              title: Text(test.title),
              subtitle: Text('${test.branchName} | ${format.format(test.scheduledStart)} | ${test.timeLimitMinutes} min'),
              trailing: Chip(label: Text(test.isActive ? 'Active' : 'Hidden')),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _replacePdf(context),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Re-upload'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _delete(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _replacePdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    final path = result?.files.single.path;
    if (path == null) return;
    await TestService().replacePdf(testId: test.id, pdfPath: path);
    onChanged();
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PDF test?'),
        content: Text(test.title),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    await TestService().deleteTest(test.id);
    onChanged();
  }
}
