import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

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
      body: PDFView(
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onRender: (pages) => setState(() => _totalPages = pages ?? 0),
        onPageChanged: (page, _) => setState(() => _currentPage = page ?? 0),
      ),
    );
  }
}
