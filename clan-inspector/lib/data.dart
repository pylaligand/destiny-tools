// Copyright (c) 2015 P.Y. Laligand

part of clan;

/// Represents a clan member.
class Member {

  final String _username;
  final int _bungieId;
  final String _consoleName;
  final DateTime _approvalDate;
  final List<Character> _characters;

  int _membershipId;
  DateTime _lastActiveDate;
  int _grimoireScore;

  Member(this._username, String memberId, this._consoleName, DateTime approvalDate) :
      _characters = new List(),
      _bungieId = int.parse(memberId),
      _approvalDate = approvalDate.toLocal(),
      _membershipId = -1;

  toString() => '${_username}\t[${_consoleName}]\t[${_membershipId}]\t[${_approvalDate}]\t[${_lastActiveDate}]';

  /// Returns the member's Bungie username.
  String get userName => _username;
  /// Returns the username of the member on their gaming platform, or |?| if not
  /// available.
  String get consoleName => _consoleName != null ? _consoleName : '?';
  /// Returns the date when the member was added to the clan.
  DateTime get approvalTime => _approvalDate;
  /// Returns the member's Bungie id.
  num get bungieId => _bungieId;
  /// Returns the member's Destiny id.
  num get destinyId => _membershipId;
      set destinyId(num id) => _membershipId = id;
  /// Returns |true| if the member has a known Destiny id.
  bool get playsDestiny => _membershipId > 0;
  /// Returns the last date the member was active in Destiny.
  DateTime get activeTime => _lastActiveDate;
           set activeTime(DateTime time) => _lastActiveDate = time.toLocal();
  /// Returns the user's grimoire score.
  int get grimoireScore => _grimoireScore;
      set grimoireScore(int score) => _grimoireScore = score;
  /// Returns the list of characters.
  List<Character> get characters => _characters;
}

/// Character classes.
enum CharacterClass {
  hunter,
  titan,
  warlock,
}

/// Character races.
enum Race {
  awoken,
  exo,
  human,
}

/// Represents an instance of a character.
class Character {

  final CharacterClass characterClass;
  final Race race;
  final int level;
  final int light;

  Character(this.characterClass, this.race, this.level, this.light);

  toString() => '${characterClass}[${race},${level},${light}]';
}
