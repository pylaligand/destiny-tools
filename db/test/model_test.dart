// Copyright (c) 2015 P.Y. Laligand

library model_test;

import 'package:destiny-db/db.dart';
import 'package:test/test.dart';

main() {
  var user = new User('gid', 'pid', true, 'bid', 'did');
  var sameUser = new User('gid', 'pid', true, 'bid', 'did');
  var differentUser = new User('gid', 'pid', true, 'other_bid', 'did');

  var timestamp = new DateTime.now();
  var users = [user, differentUser];
  var db = new Database.withContent(timestamp, users);
  var sameDb = new Database.withContent(timestamp, users);
  var differentDb = new Database.withContent(timestamp, [user]);

  test('user equality', () {
    expect(sameUser, equals(user));
    expect(sameUser.hashCode, equals(user.hashCode));
  });

  test('user inequality', () {
    expect(differentUser, isNot(equals(user)));
  });

  test('user serialization', () {
    var json = user.toJson();
    var otherUser = new User.fromJson(json);
    expect(otherUser, equals(user));
  });

  test('database equality', () {
    expect(sameDb, equals(db));
    expect(sameDb.hashCode, equals(db.hashCode));
  });

  test('database inequality', () {
    expect(differentDb, isNot(equals(db)));
  });

  test('database serialization', () {
    var json = db.toJson();
    var otherDb = new Database.fromJson(json);
    expect(otherDb, equals(db));
  });
}
