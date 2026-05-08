import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/exam_event.dart';
import '../models/locked_attempt.dart';
import '../services/test_service.dart';

class SecurityLogScreen extends StatefulWidget {
  const SecurityLogScreen({super.key});

  @override
  State<SecurityLogScreen> createState() => _SecurityLogScreenState();
}

class _SecurityLogScreenState extends State<SecurityLogScreen> {
  final _service = TestService();
  late Future<_SecurityData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exam Security'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Locked'),
              Tab(text: 'Logs'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() => _data = _load()),
          child: FutureBuilder<_SecurityData>(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data ?? _SecurityData.empty();
              return TabBarView(
                children: [
                  _LockedList(attempts: data.locked, onAllow: _allow),
                  _EventList(events: data.events),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<_SecurityData> _load() async {
    final locked = await _service.fetchLockedAttempts();
    final events = await _service.fetchEvents();
    return _SecurityData(locked: locked, events: events);
  }

  Future<void> _allow(LockedAttempt attempt) async {
    await _service.allowAttempt(attempt.id);
    setState(() => _data = _load());
  }
}

class _LockedList extends StatelessWidget {
  const _LockedList({required this.attempts, required this.onAllow});

  final List<LockedAttempt> attempts;
  final ValueChanged<LockedAttempt> onAllow;

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return ListView(children: const [SizedBox(height: 220), Center(child: Text('No locked attempts.'))]);
    }
    final format = DateFormat('dd MMM, hh:mm a');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: attempts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final attempt = attempts[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attempt.studentName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('${attempt.collegeId ?? ''} | ${attempt.branchName} | ${attempt.testTitle}'),
                const SizedBox(height: 4),
                Text('${attempt.blockedReason ?? 'locked'} | ${format.format(attempt.blockedAt)}'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => onAllow(attempt),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Allow reopen'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events});

  final List<ExamEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return ListView(children: const [SizedBox(height: 220), Center(child: Text('No exam events.'))]);
    }
    final format = DateFormat('dd MMM, hh:mm:ss a');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          child: ListTile(
            leading: Icon(
              event.severity == 'critical' ? Icons.error_outline : Icons.info_outline,
              color: event.severity == 'critical' ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
            ),
            title: Text('${event.eventType} | ${event.studentName}'),
            subtitle: Text('${event.branchName} | ${event.testTitle}\n${event.message ?? ''}'),
            trailing: Text(format.format(event.createdAt), textAlign: TextAlign.end),
          ),
        );
      },
    );
  }
}

class _SecurityData {
  _SecurityData({required this.locked, required this.events});

  final List<LockedAttempt> locked;
  final List<ExamEvent> events;

  factory _SecurityData.empty() => _SecurityData(locked: [], events: []);
}
