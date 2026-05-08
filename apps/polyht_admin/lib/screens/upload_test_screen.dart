import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../services/test_service.dart';

class UploadTestScreen extends StatefulWidget {
  const UploadTestScreen({super.key});

  @override
  State<UploadTestScreen> createState() => _UploadTestScreenState();
}

class _UploadTestScreenState extends State<UploadTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '60');
  final _service = TestService();

  List<Branch> _branches = [];
  Branch? _selectedBranch;
  DateTime? _start;
  DateTime? _end;
  String? _pdfPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Test PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Test title'),
                validator: (value) => value == null || value.trim().length < 3 ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Branch>(
                initialValue: _selectedBranch,
                decoration: const InputDecoration(labelText: 'Branch'),
                items: _branches.map((branch) {
                  return DropdownMenuItem(value: branch, child: Text(branch.name));
                }).toList(),
                onChanged: (branch) => setState(() => _selectedBranch = branch),
                validator: (value) => value == null ? 'Choose branch' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Time limit in minutes'),
                validator: (value) {
                  final minutes = int.tryParse(value ?? '');
                  return minutes == null || minutes <= 0 ? 'Enter valid minutes' : null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickSchedule,
                icon: const Icon(Icons.schedule),
                label: Text(_start == null ? 'Choose date and time' : '${_start!.toLocal()}'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_pdfPath == null ? 'Choose PDF' : _pdfPath!.split(RegExp(r'[\\/]')).last),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator() : const Text('Schedule test'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadBranches() async {
    final branches = await _service.fetchBranches();
    setState(() {
      _branches = branches;
      _selectedBranch = branches.isEmpty ? null : branches.first;
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() => _pdfPath = result.files.single.path);
    }
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final minutes = int.tryParse(_timeLimitController.text) ?? 60;
    setState(() {
      _start = start;
      _end = start.add(Duration(minutes: minutes));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _pdfPath == null || _start == null || _end == null) return;
    setState(() => _saving = true);
    try {
      await _service.uploadTest(
        title: _titleController.text.trim(),
        branchId: _selectedBranch!.id,
        scheduledStart: _start!,
        scheduledEnd: _end!,
        timeLimitMinutes: int.parse(_timeLimitController.text),
        pdfPath: _pdfPath!,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
