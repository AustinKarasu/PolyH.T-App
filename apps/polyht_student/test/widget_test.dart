import 'package:flutter_test/flutter_test.dart';
import 'package:polyht_student/main.dart';

void main() {
  test('student app type is available', () {
    expect(const PolyHtStudentApp(), isA<PolyHtStudentApp>());
  });
}
