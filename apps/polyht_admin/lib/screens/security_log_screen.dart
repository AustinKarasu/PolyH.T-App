import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
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
          flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.lock_outline_rounded), text: 'Locked'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Event Logs'),
            ],
          ),
        ),
        body: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async => setState(() => _data = _load()),
          child: FutureBuilder<_SecurityData>(
            future: _data,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow reopen?'),
        content: Text('Allow ${attempt.studentName} to reopen "${attempt.testTitle}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.allowAttempt(attempt.id);
    setState(() => _data = _load());
  }
}

// ── Locked attempts list ──────────────────────────────────────────
class _LockedList extends StatelessWidget {
  const _LockedList({required this.attempts, required this.onAllow});

  final List<LockedAttempt> attempts;
  final ValueChanged<LockedAttempt> onAllow;

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.success.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text('No locked attempts', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'All students have normal access.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.4)),
        ),
      ]);
    }
    final format = DateFormat('dd MMM, hh:mm a');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: attempts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final attempt = attempts[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.error.withValues(alpha: 0.15)),
            boxShadow: AppTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_off_rounded, size: 22, color: AppTheme.error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(attempt.studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(
                          '${attempt.collegeId ?? 'N/A'} • ${attempt.branchName}',
                          style: TextStyle(fontSize: 12, color: AppTheme.ink.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attempt.testTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.error.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${attempt.blockedReason ?? 'Locked'} • ${format.format(attempt.blockedAt)}',
                            style: TextStyle(fontSize: 11, color: AppTheme.ink.withValues(alpha: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onAllow(attempt),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: const Text('Allow Reopen'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Event log list ────────────────────────────────────────────────
class _EventList extends StatelessWidget {
  const _EventList({required this.events});

  final List<ExamEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Icon(Icons.history_rounded, size: 64, color: AppTheme.primaryLight.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text('No exam events', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      ]);
    }
    final format = DateFormat('dd MMM, hh:mm:ss a');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final event = events[index];
        final isCritical = event.severity == 'critical';
        final isWarning = event.severity == 'warning';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isCritical
                  ? AppTheme.error.withValues(alpha: 0.2)
                  : isWarning
                      ? AppTheme.accent.withValues(alpha: 0.2)
                      : AppTheme.primaryLight.withValues(alpha: 0.1),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isCritical ? AppTheme.error : isWarning ? AppTheme.accent : AppTheme.primary)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCritical ? Icons.error_outline : isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
                size: 20,
                color: isCritical ? AppTheme.error : isWarning ? AppTheme.accent : AppTheme.primary,
              ),
            ),
            title: Text(
              '${event.eventType} • ${event.studentName}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${event.branchName} • ${event.testTitle}\n${event.message ?? ''}',
              style: TextStyle(fontSize: 11, color: AppTheme.ink.withValues(alpha: 0.5)),
            ),
            trailing: Text(
              format.format(event.createdAt),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 10, color: AppTheme.ink.withValues(alpha: 0.4)),
            ),
            isThreeLine: true,
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
