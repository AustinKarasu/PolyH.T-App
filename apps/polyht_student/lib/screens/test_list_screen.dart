import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/student_test.dart';
import '../providers/auth_provider.dart';
import '../services/test_service.dart';
import '../widgets/update_button.dart';
import 'exam_screen.dart';

class TestListScreen extends StatefulWidget {
  const TestListScreen({super.key});

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  final _service = TestService();
  late Future<List<StudentTest>> _tests;

  @override
  void initState() {
    super.initState();
    _tests = _service.fetchTests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PolyH.T Tests'),
        actions: [
          const UpdateButton(),
          IconButton(
            tooltip: 'Sign out',
            onPressed: context.read<AuthProvider>().logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _tests = _service.fetchTests()),
        child: FutureBuilder<List<StudentTest>>(
          future: _tests,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final tests = snapshot.data ?? [];
            if (tests.isEmpty) {
              return const Center(child: Text('No tests assigned.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _StudentTestCard(test: tests[index]),
            );
          },
        ),
      ),
    );
  }
}

class _StudentTestCard extends StatelessWidget {
  const _StudentTestCard({required this.test});

  final StudentTest test;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd MMM, hh:mm a');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(test.title, style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(test.status.toUpperCase())),
              ],
            ),
            const SizedBox(height: 8),
            Text('${format.format(test.scheduledStart)} - ${format.format(test.scheduledEnd)}'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: test.isLive && !test.isLocked
                  ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExamScreen(test: test)))
                  : null,
              icon: Icon(test.isLocked ? Icons.lock : Icons.lock_open),
              label: Text(test.isLocked ? 'Locked by admin' : 'Start test'),
            ),
            if (test.isLocked && test.blockedReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Reason: ${test.blockedReason}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
