// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

const OPTION_PLATFORM = 'platform';
const VALUE_XBL = 'xbl';
const VALUE_PSN = 'psn';
const OPTION_CLAN_ID = 'clan_id';
const FLAG_HELP = 'help';

/// Retrieves the roster for the given clan on the given platform.
Future<List<_Member>> _getClanRoster(int clanId, bool isXbox) async {
  final platform = isXbox ? 1 : 2;
  int pageIndex = 1;
  final List<_Member> roster = new List();
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
bool _extractMembers(var data, List<_Member> roster, bool isXbox) {
  data['Response']['results'].forEach((user) {
    var userData = user['user'];
    var username = userData['displayName'];
    var memberId = userData['membershipId'];
    var consoleKey = isXbox ? 'xboxDisplayName' : 'psnDisplayName';
    var consoleName = userData[consoleKey];
    var approvalDate = DateTime.parse(user['approvalDate']);
    var member = new _Member(username, memberId, consoleName, approvalDate);
    roster.add(member);
  });
  var total = data['Response']['totalResults'];
  return roster.length < int.parse(total);
}

/// Adds a Destiny-specific id to the given user.
_addMembershipId(_Member member) async {
  var url = 'http://www.bungie.net/Platform/User/GetBungieAccount/${member.bungieId}/254/';
  var data = await _doGet(url);
  var hasAccount = data['Response']['destinyAccounts'].length > 0;
  if (hasAccount) {
    var id = data['Response']['destinyAccounts'][0]['userInfo']['membershipId'];
    member.destinyId = int.parse(id);
  }
}

/// Adds some Destiny data to the given member.
_addDestinyData(_Member member, isXbox) async {
  // Note: specifiying the platform type does not seem to matter, a result is
  // always returned for a valid membership id.
  var type = isXbox ? 'TigerXbox' : 'TigerPSN';
  var url = 'http://www.bungie.net/Platform/Destiny/${type}/Account/${member.destinyId}/';
  var data = (await _doGet(url))['Response']['data'];

  // Last played date.
  var characters = data['characters'];
  var playTime = characters.fold(new DateTime(1900), (time, character) {
    var lastPlayTime = DateTime.parse(character['characterBase']['dateLastPlayed']);
    return lastPlayTime.compareTo(time) > 0 ? lastPlayTime : time;
  });
  member.activeTime = playTime;

  member.grimoireScore = data['grimoireScore'];
}

/// Adds Destiny-related activity data to the given member.
_addActivityData(_Member member, isXbox) async {
  await _addMembershipId(member);
  if (member.playsDestiny) {
    await _addDestinyData(member, isXbox);
  }
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

/// Represents a clan member.
class _Member {

  final String _username;
  final int _bungieId;
  final String _consoleName;
  final DateTime _approvalDate;

  int _membershipId;
  DateTime _lastActiveDate;
  int _grimoireScore;

  _Member(this._username, String memberId, this._consoleName, DateTime approvalDate) :
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
  List<_Member> roster = await _getClanRoster(clanId, isXbox);
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
    var activeDay = member.activeTime != null ? _stringify(member.activeTime) : '?';
    var approvalDay = _stringify(member.approvalTime);
    print('${member.userName}\t${member.consoleName}\t${approvalDay}\t${activeDay}\t${member.grimoireScore}');
  });
  print(headers);
  print('Found ${roster.length} users.');
  print('All done!');
}
