// Copyright (c) 2015 P.Y. Laligand

part of db;

/// Full content of the database file.
class Database {

  /// Timestamp of the last user update.
  DateTime lastUserUpdate;
  /// The list of known users.
  final List<User> users;

  Database() :
      lastUserUpdate = new DateTime.fromMillisecondsSinceEpoch(0),
      users = new List() {}

  /// Bootstraps a database.
  Database.withContent(this.lastUserUpdate, this.users);

  factory Database.fromJson(Map values) {
    var lastUserUpdate =
        new DateTime.fromMillisecondsSinceEpoch(values['lastUserUpdate']);
    var users = new List();
    for (var userData in values['users']) {
      users.add(new User.fromJson(userData));
    }
    return new Database.withContent(lastUserUpdate, users);
  }

  Map toJson() {
    var result = new Map();
    result['lastUserUpdate'] = lastUserUpdate.millisecondsSinceEpoch;
    result['users'] = users.map((user) => user.toJson()).toList();
    return result;
  }

  @override bool operator ==(other) {
    Function usersEq = const DeepCollectionEquality.unordered().equals;
    return other is Database &&
        lastUserUpdate == other.lastUserUpdate &&
        usersEq(users, other.users);
  }

  @override get hashCode {
    int result = 17;
    result = 37 * result + lastUserUpdate.hashCode;
    result = 37 * result + users.fold(0, (hash, user) => hash + user.hashCode);
    return result;
  }

  @override String toString() {
    return new JsonEncoder.withIndent('  ').convert(toJson());
  }
}

/// Represents a user.
class User {

  /// Google+ id.
  final String gplusId;
  /// Platform id (XBL or PSN).
  final String platformId;
  /// Whether the user is on Xbox or Playstation.
  final bool onXbox;
  /// Bungie id.
  final String bungieId;
  /// Destiny id.
  final String destinyId;
  /// True if the user should not be listed.
  final bool ignored;

  User(this.gplusId,
    this.platformId,
    this.onXbox,
    this.bungieId,
    this.destinyId,
    this.ignored);

  factory User.fromJson(Map values) {
    return new User(values['gplusId'],
        values['platformId'],
        values['onXbox'],
        values['bungieId'],
        values['destinyId'],
        values['ignored']);
  }

  Map toJson() {
    var result = new Map();
    result['gplusId'] = gplusId;
    result['platformId'] = platformId;
    result['onXbox'] = onXbox;
    result['bungieId'] = bungieId;
    result['destinyId'] = destinyId;
    result['ignored'] = ignored == 'true';
    return result;
  }

  @override bool operator ==(other) {
    return other is User &&
        gplusId == other.gplusId &&
        platformId == other.platformId &&
        onXbox == other.onXbox &&
        bungieId == other.bungieId &&
        destinyId == other.destinyId &&
        ignored == other.ignored;
  }

  @override int get hashCode {
    int result = 17;
    result = 37 * result + gplusId.hashCode;
    result = 37 * result + platformId.hashCode;
    result = 37 * result + onXbox.hashCode;
    result = 37 * result + bungieId.hashCode;
    result = 37 * result + destinyId.hashCode;
    result = 37 * result + ignored.hashCode;
    return result;
  }

  @override String toString() {
    return new JsonEncoder.withIndent('  ').convert(toJson());
  }
}
