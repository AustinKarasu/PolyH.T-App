import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../models/student_test.dart';
import '../services/exam_security_service.dart';
import '../services/test_service.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.test});

  final StudentTest test;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
  final _testService = TestService();
  final _securityService = ExamSecurityService();
  String? _pdfPath;
  bool _loading = true;
  bool _hasFocusWarning = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterExam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _securityService.exitExamMode();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      setState(() => _hasFocusWarning = true);
      unawaited(_logEvent('app_inactive'));
    }
    if (state == AppLifecycleState.paused) {
      setState(() => _hasFocusWarning = true);
      unawaited(_logEvent('app_backgrounded'));
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_logEvent('app_resumed'));
    }
    if (state == AppLifecycleState.detached) {
      unawaited(_logEvent('app_detached'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_logEvent('back_blocked'));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.test.title),
          actions: [
            TextButton(
              onPressed: _complete,
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
        body: Column(
          children: [
            if (_hasFocusWarning)
              MaterialBanner(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                content: Text(_locked
                    ? 'This paper is locked. Contact the admin to reopen it.'
                    : 'App switching was detected. Your attempt may be reviewed.'),
                actions: [
                  TextButton(onPressed: () => setState(() => _hasFocusWarning = false), child: const Text('Dismiss')),
                ],
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _locked
                      ? const Center(child: Text('Paper locked. Admin permission is required to reopen.'))
                      : _pdfPath == null
                      ? const Center(child: Text('Unable to open PDF.'))
                      : PDFView(
                          filePath: _pdfPath!,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enterExam() async {
    try {
      await _securityService.enterExamMode();
      await _testService.startAttempt(widget.test.id);
      final path = await _testService.downloadPdf(widget.test.id);
      await _testService.recordEvent(widget.test.id, 'pdf_opened');
      if (mounted) {
        setState(() {
          _pdfPath = path;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locked = true;
          _hasFocusWarning = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _complete() async {
    if (_locked) return;
    await _testService.completeAttempt(widget.test.id);
    await _securityService.exitExamMode();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _logEvent(String eventType) async {
    try {
      final locked = await _testService.recordEvent(widget.test.id, eventType);
      if (locked && mounted) {
        await _deleteLocalPdf();
        setState(() {
          _locked = true;
          _hasFocusWarning = true;
          _pdfPath = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _deleteLocalPdf() async {
    final path = _pdfPath;
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
