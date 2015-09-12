// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

import 'data.dart';

const OPTION_PLATFORM = 'platform';
const VALUE_XBL = 'xbl';
const VALUE_PSN = 'psn';
const OPTION_CLAN_ID = 'clan_id';
const FLAG_HELP = 'help';

/// Retrieves the roster for the given clan on the given platform.
Future<List<Member>> _getClanRoster(int clanId, bool isXbox) async {
  final platform = isXbox ? 1 : 2;
  int pageIndex = 1;
  final List<Member> roster = new List();
  while (true) {
    var url = 'http://www.bungie.net/Platform/Group/${clanId}/Members/?lc=en&fmt=true&currentPage=${pageIndex}&platformType=${platform}';
    var data = await _doGet(url);
    if (_extractMembers(data, roster, isXbox)) {
      pageIndex++;
    } else {
      break;
    }
  }
  return roster;
}

/// Extracts the users from the given data.
/// Returns |true| if more users are available.
bool _extractMembers(var data, List<Member> roster, bool isXbox) {
  data['Response']['results'].forEach((user) {
    var userData = user['user'];
    var username = userData['displayName'];
    var memberId = userData['membershipId'];
    var consoleKey = isXbox ? 'xboxDisplayName' : 'psnDisplayName';
    var consoleName = userData[consoleKey];
    var approvalDate = DateTime.parse(user['approvalDate']);
    var member = new Member(username, memberId, consoleName, approvalDate);
    roster.add(member);
  });
  var total = data['Response']['totalResults'];
  return roster.length < int.parse(total);
}

/// Gathers some data from the Destiny account of the given user, if applicable.
_addDestinyData(Member member) async {
  var url = 'http://www.bungie.net/Platform/User/GetBungieAccount/${member.bungieId}/254/';
  var data = await _doGet(url);
  var accounts = data['Response']['destinyAccounts'];
  if (accounts.isEmpty) {
    return;
  }
  var account = accounts[0];
  var id = account['userInfo']['membershipId'];
  member.destinyId = int.parse(id);

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
    case 0: return CharacterClass.titan;
    case 1: return CharacterClass.hunter;
    case 2: return CharacterClass.warlock;
    default: throw new ArgumentError.value(type, 'class');
  }
}

/// Creates a race from its integer representation.
Race _raceFromType(int type) {
  switch (type) {
    case 0: return Race.human;
    case 1: return Race.awoken;
    case 2: return Race.exo;
    default: throw new ArgumentError.value(type, 'race');
  }
}

/// Adds Destiny-related activity data to the given member.
_addActivityData(Member member, isXbox) async {
  await _addDestinyData(member);
}

/// Executes an HTTP GET query and returns the response's body as parsed JSON.
_doGet(String url) async {
  return JSON.decode((await http.get(url)).body);
}

/// Prints a string representing the given time.
_stringify(DateTime time) {
  return new StringBuffer()
      ..write(time.month)
      ..write('/')
      ..write(time.day)
      ..write('/')
      ..write(time.year)
      ..toString();
}

main(List<String> args) async {
  final parser = new ArgParser()
      ..addOption(OPTION_PLATFORM, allowed: [VALUE_XBL, VALUE_PSN], abbr: 'p')
      ..addOption(OPTION_CLAN_ID, abbr: 'c')
      ..addFlag(FLAG_HELP, negatable: false, abbr: 'h');
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
      !params.options.contains(OPTION_PLATFORM)) {
    print(parser.usage);
    return;
  }

  final isXbox = params[OPTION_PLATFORM] == VALUE_XBL;
  final clanId = int.parse(params[OPTION_CLAN_ID]);

  print('Fetching the list...');
  List<Member> roster = await _getClanRoster(clanId, isXbox);
  var tasks = [];
  roster.forEach((member) => tasks.add(_addActivityData(member, isXbox)));
  await Future.wait(tasks);
  // Sort the roster.
  // 1- no Destiny info, sorted by approval date.
  // 2- Destiny info, sorted by last played date.
  roster.sort((a, b) {
      if (a.playsDestiny) {
        if (b.playsDestiny) {
          return a.activeTime.compareTo(b.activeTime);
        } else {
          return 1;
        }
      } else {
          if (b.playsDestiny) {
            return -1;
          } else {
            return a.approvalTime.compareTo(b.approvalTime);
          }
      }
  });

  // Print the results in a table format.
  final headers = 'Bungie username\t${isXbox ? 'XBL' : 'PSN'} username\tApproval day\tLast active day\tGrimoire';
  print(headers);
  roster.forEach((member) {
    var activeDay = member.activeTime != null
        ? _stringify(member.activeTime)
        : '?';
    var approvalDay = _stringify(member.approvalTime);
    print('${member.userName}\t${member.consoleName}\t${approvalDay}\t${activeDay}\t${member.grimoireScore}\t${member.characters.length}');
  });
  print(headers);
  print('Found ${roster.length} users.');
  print('All done!');
}
