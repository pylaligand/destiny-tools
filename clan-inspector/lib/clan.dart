// Copyright (c) 2015 P.Y. Laligand

library clan;

import 'dart:async';

import 'package:destiny-common/bungie.dart';

part 'data.dart';

/// Retrieves the roster for the given clan on the given platform.
Future<List<Member>> _getClanRoster(
    String clanId, BungieClient client, bool forXbox) async {
  int pageIndex = 1;
  final List<Member> roster = new List();
  while (true) {
    var data = await client.getClan(clanId, forXbox, pageIndex);
    if (_extractMembers(data, roster, forXbox)) {
      pageIndex++;
    } else {
      break;
    }
  }
  return roster;
}

/// Extracts the users from the given data.
/// Returns |true| if more users are available.
bool _extractMembers(var data, List<Member> roster, bool forXbox) {
  data['Response']['results'].forEach((user) {
    var userData = user['user'];
    var username = userData['displayName'];
    var memberId = userData['membershipId'];
    var consoleKey = forXbox ? 'xboxDisplayName' : 'psnDisplayName';
    var consoleName = userData[consoleKey];
    var approvalDate = DateTime.parse(user['approvalDate']);
    var member = new Member(username, memberId, consoleName, approvalDate);
    roster.add(member);
  });
  var total = data['Response']['totalResults'];
  return roster.length < int.parse(total);
}

/// Gathers some data from the Destiny account of the given user, if applicable.
_addDestinyData(Member member, BungieClient client) async {
  var data = await client.getBungieAccount(member.bungieId);
  var accounts = data['Response']['destinyAccounts'];
  if (accounts.isEmpty) {
    return;
  }
  var account = accounts[0];
  member.destinyId = account['userInfo']['membershipId'];

  var characters = account['characters'];

  // Last played date.
  var playTime = characters.fold(new DateTime(1900), (time, character) {
    var lastPlayTime = DateTime.parse(character['dateLastPlayed']);
    return lastPlayTime.compareTo(time) > 0 ? lastPlayTime : time;
  });
  member.activeTime = playTime;

  // Grimoire.
  member.grimoireScore = account['grimoireScore'];

  /// Characters.
  characters.forEach((character) {
    CharacterClass clazz =
        _classFromType(character['characterClass']['classType']);
    Race race = _raceFromType(character['race']['raceType']);
    int level = character['level'];
    int light = character['powerLevel'];
    member.characters.add(new Character(clazz, race, level, light));
  });
}

/// Creates a character class from its integer representation.
CharacterClass _classFromType(int type) {
  switch (type) {
    case 0:
      return CharacterClass.titan;
    case 1:
      return CharacterClass.hunter;
    case 2:
      return CharacterClass.warlock;
    default:
      throw new ArgumentError.value(type, 'class');
  }
}

/// Creates a race from its integer representation.
Race _raceFromType(int type) {
  switch (type) {
    case 0:
      return Race.human;
    case 1:
      return Race.awoken;
    case 2:
      return Race.exo;
    default:
      throw new ArgumentError.value(type, 'race');
  }
}

/// Adds Destiny-related activity data to the given member.
_addActivityData(Member member, BungieClient client, forXbox) async {
  await _addDestinyData(member, client);
}

Future<List<Member>> getClan(String clanId, String apiKey, bool forXbox) async {
  BungieClient client = new BungieClient(apiKey);
  List<Member> roster = await _getClanRoster(clanId, client, forXbox);
  var tasks = [];
  roster.forEach((member) {
    tasks.add(_addActivityData(member, client, forXbox));
  });
  await Future.wait(tasks);
  return roster;
}
