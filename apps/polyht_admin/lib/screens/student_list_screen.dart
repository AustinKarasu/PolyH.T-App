import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/app_user.dart';
import '../services/student_service.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _service = StudentService();
  final _searchController = TextEditingController();
  late Future<List<AppUser>> _students;

  @override
  void initState() {
    super.initState();
    _students = _service.fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() => _students = _service.fetchStudents(search: _searchController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Directory'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or roll no…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _search(); }),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),

          // ── Student list ──
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _students,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading students', style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.5))));
                }
                final students = snapshot.data ?? [];
                if (students.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('No students found', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ]),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _StudentTile(
                    student: students[index],
                    onTap: () => _showDetail(context, students[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, AppUser student) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _StudentDetailScreen(student: student)));
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});
  final AppUser student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.1)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(gradient: AppTheme.headerGradient, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(
                  '${student.collegeId ?? '—'}  •  ${student.branchName ?? '—'}  •  Sem ${student.semester ?? '—'}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                ),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.ink.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _StudentDetailScreen extends StatelessWidget {
  const _StudentDetailScreen({required this.student});
  final AppUser student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Header card ──
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppTheme.headerGradient, borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2)),
                  child: Center(child: Text(student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
                const SizedBox(height: 10),
                Text(student.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                if (student.collegeId != null) Text(student.collegeId!, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
              ]),
            ),
            const SizedBox(height: 20),

            _Section(title: 'College ID Card', rows: [
              _Row('College', student.collegeName ?? 'Govt. Polytechnic Kangra'),
              _Row('College ID', student.collegeId ?? '—'),
              _Row('Roll No', student.rollNo ?? '—'),
              _Row('Board Roll No', student.boardRollNo ?? '—'),
            ]),
            const SizedBox(height: 16),

            _Section(title: 'Academic Information', rows: [
              _Row('Course', student.courseName ?? '—'),
              _Row('Branch', student.branchName ?? '—'),
              _Row('Semester', student.semester?.toString() ?? '—'),
              _Row('Admission Year', student.admissionYear?.toString() ?? '—'),
            ]),
            const SizedBox(height: 16),

            _Section(title: 'Personal Details', rows: [
              _Row('Full Name', student.fullName),
              _Row('Date of Birth', student.dob ?? '—'),
              _Row('Guardian', student.guardianName ?? '—'),
              _Row('Phone', student.phone ?? '—'),
              _Row('Email', student.email ?? '—'),
              _Row('Address', student.address ?? '—'),
            ]),
            const SizedBox(height: 16),

            _Section(title: 'Account Status', rows: [
              _Row('Status', student.isActive == true ? 'Active' : 'Inactive'),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});
  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
      ),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.1)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(children: rows),
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
