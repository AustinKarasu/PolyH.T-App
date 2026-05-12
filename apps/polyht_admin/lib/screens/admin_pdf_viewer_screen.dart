import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';

import '../config/app_theme.dart';

class AdminPdfViewerScreen extends StatefulWidget {
  const AdminPdfViewerScreen({super.key, required this.title, required this.filePath});

  final String title;
  final String filePath;

  @override
  State<AdminPdfViewerScreen> createState() => _AdminPdfViewerScreenState();
}

class _AdminPdfViewerScreenState extends State<AdminPdfViewerScreen> {
  int _currentPage = 0;
  int _totalPages = 0;
  String? _error;

  @override
  void dispose() {
    unawaited(File(widget.filePath).delete().catchError((_) => File(widget.filePath)));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_totalPages > 0)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.72)),
              ),
          ],
        ),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
      ),
      body: _error == null
          ? PDFView(
              filePath: widget.filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) => setState(() => _totalPages = pages ?? 0),
              onPageChanged: (page, _) => setState(() => _currentPage = page ?? 0),
              onError: (error) => setState(() => _error = error.toString()),
              onPageError: (page, error) => setState(() => _error = 'Page ${(page ?? 0) + 1}: $error'),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 56, color: AppTheme.error),
                    const SizedBox(height: 12),
                    const Text('Unable to open PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => OpenFilex.open(widget.filePath, type: 'application/pdf'),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open with PDF app'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
