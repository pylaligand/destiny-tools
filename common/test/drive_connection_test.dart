// Copyright (c) 2015 P.Y. Laligand

library db_test;

import 'package:destiny_common/drive_connection.dart';
import 'package:test/test.dart';

main() {
  test('uninitialized destroy', () {
    var connection = new DriveConnection('foo', 'bar');
    expect(() => connection.destroy(), throwsStateError);
  });
}
