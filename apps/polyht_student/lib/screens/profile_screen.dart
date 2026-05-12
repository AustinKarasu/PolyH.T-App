import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_rounded),
            onPressed: _saving ? null : () => _editProfile(context),
          ),
        ],
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
                  InkWell(
                    onTap: _saving ? null : () => _pickPhoto(context),
                    customBorder: const CircleBorder(),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: user.photoUrl == null ? null : NetworkImage(_photoUrl(user.photoUrl!)),
                          child: user.photoUrl == null
                              ? Text(
                                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
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

  String _photoUrl(String value) {
    if (value.startsWith('http')) return value;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
    return '$base$value';
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().uploadProfilePhoto(path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editProfile(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');
    final guardianController = TextEditingController(text: user.guardianName ?? '');
    final addressController = TextEditingController(text: user.address ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 44, height: 4, decoration: BoxDecoration(color: AppTheme.primaryLight.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 16),
            Text('Edit Personal Details', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextField(controller: guardianController, decoration: const InputDecoration(labelText: 'Guardian name')),
            const SizedBox(height: 12),
            TextField(controller: addressController, maxLines: 3, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        guardianName: guardianController.text.trim(),
        address: addressController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      emailController.dispose();
      phoneController.dispose();
      guardianController.dispose();
      addressController.dispose();
      if (mounted) setState(() => _saving = false);
    }
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
