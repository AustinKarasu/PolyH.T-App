import 'package:flutter_test/flutter_test.dart';
import 'package:polyht_admin/main.dart';

void main() {
  test('admin app type is available', () {
    expect(const PolyHtAdminApp(), isA<PolyHtAdminApp>());
  });
}
