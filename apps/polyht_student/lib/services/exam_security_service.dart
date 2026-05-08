import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ExamSecurityService {
  static const _channel = MethodChannel('polyht/exam_security');

  Future<void> enterExamMode() async {
    await WakelockPlus.enable();
    await _channel.invokeMethod('enterExamMode').catchError((_) {});
  }

  Future<void> exitExamMode() async {
    await WakelockPlus.disable();
    await _channel.invokeMethod('exitExamMode').catchError((_) {});
  }
}
