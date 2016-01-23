// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';

import 'package:args/args.dart';
import 'package:destiny-clan/clan.dart';

const OPTION_PLATFORM = 'platform';
const VALUE_XBL = 'xbl';
const VALUE_PSN = 'psn';
const OPTION_CLAN_ID = 'clan_id';
const OPTION_API_KEY = 'api_key';
const FLAG_HELP = 'help';

/// Prints a string representing the given time.
String _stringify(DateTime time) {
  var buffer = new StringBuffer()
      ..write(time.month)
      ..write('/')
      ..write(time.day)
      ..write('/')
      ..write(time.year);
  return buffer.toString();
}

main(List<String> args) async {
  final parser = new ArgParser()
      ..addOption(OPTION_PLATFORM, allowed: [VALUE_XBL, VALUE_PSN], abbr: 'p')
      ..addOption(OPTION_CLAN_ID, abbr: 'c')
      ..addOption(OPTION_API_KEY, abbr: 'a')
      ..addFlag(FLAG_HELP, negatable: false, abbr: 'h');
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
      !params.options.contains(OPTION_PLATFORM) ||
      !params.options.contains(OPTION_API_KEY)) {
    print(parser.usage);
    return;
  }

  final forXbox = params[OPTION_PLATFORM] == VALUE_XBL;
  final clanId = params[OPTION_CLAN_ID];
  final apiKey = params[OPTION_API_KEY];

  print('Fetching the list...');
  var roster = await getClan(clanId, apiKey, forXbox);

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
  final headers = 'Bungie username\t\t${forXbox ? 'XBL' : 'PSN'} username\t\tApproval\tLast active\tGrimoire\tCharacters';
  print(headers);
  roster.forEach((member) {
    var activeDay = member.activeTime != null
        ? _stringify(member.activeTime)
        : '?';
    var approvalDay = _stringify(member.approvalTime);
    print('${member.userName.padRight(20)}\t${member.consoleName.padRight(20)}\t${approvalDay}\t${activeDay.padRight(10)}\t${member.grimoireScore}\t\t${member.characters.length}');
  });
  print(headers);
  print('Found ${roster.length} users.');
  print('All done!');
}
