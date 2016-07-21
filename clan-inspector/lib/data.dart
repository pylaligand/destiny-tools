// Copyright (c) 2015 P.Y. Laligand

part of clan;

/// Represents a clan member.
class Member {
  final String _username;
  final String _bungieId;
  final String _consoleName;
  final List<Character> _characters;

  String _membershipId;
  DateTime _lastActiveDate;
  int _grimoireScore;

  Member(this._username, String memberId, this._consoleName)
      : _characters = new List(),
        _bungieId = memberId,
        _membershipId = '';

  toString() =>
      '${_username} [${_consoleName}] [${_membershipId}] [${_lastActiveDate}]';

  /// Returns the member's Bungie username.
  String get userName => _username;

  /// Returns the username of the member on their gaming platform, or |?| if not
  /// available.
  String get consoleName => _consoleName != null ? _consoleName : '?';

  /// Returns the member's Bungie id.
  String get bungieId => _bungieId;

  /// Returns the member's Destiny id.
  String get destinyId => _membershipId;
  set destinyId(String id) => _membershipId = id;

  /// Returns |true| if the member has a known Destiny id.
  bool get playsDestiny => _membershipId.isNotEmpty;

  /// Returns the last date the member was active in Destiny.
  DateTime get activeTime => _lastActiveDate;
  set activeTime(DateTime time) => _lastActiveDate = time.toLocal();

  /// Returns the user's grimoire score.
  int get grimoireScore => _grimoireScore ?? 0;
  set grimoireScore(int score) => _grimoireScore = score;

  /// Returns the list of characters.
  List<Character> get characters => _characters;
}

/// Character classes.
enum CharacterClass { hunter, titan, warlock, }

/// Character races.
enum Race { awoken, exo, human, }

/// Represents an instance of a character.
class Character {
  final CharacterClass characterClass;
  final Race race;
  final int level;
  final int light;

  Character(this.characterClass, this.race, this.level, this.light);

  toString() => '${characterClass}[${race},${level},${light}]';
}
