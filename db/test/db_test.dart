// Copyright (c) 2015 P.Y. Laligand

library db_test;

import 'package:destiny-db/db.dart';
import 'package:test/test.dart';

main() {
  var config = new Config('foo', 'bar');
  var database = new Database();

  test('uninitialized load', () {
    var loader = new DatabaseLoader(config);
    expect(loader.load(), throwsStateError);
  });

  test('uninitialized save', () {
    var loader = new DatabaseLoader(config);
    expect(loader.save(database), throwsStateError);
  });

  test('uninitialized destroy', () {
    var loader = new DatabaseLoader(config);
    expect(() => loader.destroy(), throwsStateError);
  });
}
