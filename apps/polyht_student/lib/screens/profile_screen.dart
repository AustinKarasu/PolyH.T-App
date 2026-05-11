import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Profile header card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.headerGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (user.collegeId != null)
                    Text(user.collegeId!, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (user.branchName != null) _chip(user.branchName!),
                      if (user.semester != null) ...[const SizedBox(width: 8), _chip('Semester ${user.semester}')],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── ID Card section ──
            _SectionHeader(title: 'College ID Card'),
            _InfoCard(children: [
              _InfoRow(label: 'College', value: user.collegeName ?? 'Govt. Polytechnic Kangra'),
              _InfoRow(label: 'College ID', value: user.collegeId ?? '—'),
              _InfoRow(label: 'Roll No', value: user.rollNo ?? '—'),
              _InfoRow(label: 'Board Roll No', value: user.boardRollNo ?? '—'),
            ]),
            const SizedBox(height: 16),

            // ── Academic Info ──
            _SectionHeader(title: 'Academic Information'),
            _InfoCard(children: [
              _InfoRow(label: 'Course', value: user.courseName ?? '—'),
              _InfoRow(label: 'Branch', value: user.branchName ?? '—'),
              _InfoRow(label: 'Semester', value: user.semester?.toString() ?? '—'),
              _InfoRow(label: 'Admission Year', value: user.admissionYear?.toString() ?? '—'),
            ]),
            const SizedBox(height: 16),

            // ── Personal Info ──
            _SectionHeader(title: 'Personal Details'),
            _InfoCard(children: [
              _InfoRow(label: 'Full Name', value: user.fullName),
              _InfoRow(label: 'Date of Birth', value: user.dob ?? '—'),
              _InfoRow(label: 'Guardian', value: user.guardianName ?? '—'),
              _InfoRow(label: 'Phone', value: user.phone ?? '—'),
              _InfoRow(label: 'Address', value: user.address ?? '—'),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.1)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5))),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
