// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';

import 'package:args/args.dart';
import 'package:bungie_client/bungie_client.dart';

const OPTION_PLATFORM = 'platform';
const VALUE_XBL = 'xbl';
const VALUE_PSN = 'psn';
const OPTION_CLAN_ID = 'clan_id';
const OPTION_API_KEY = 'api_key';
const FLAG_HELP = 'help';

/// Describes a member of the clan and their account data.
class Player {
  final ClanMember membership;
  final Profile data;

  const Player(this.membership, this.data);
}

/// Fetches clan members and their data.
Future<List<Player>> _getClan(
    String clanId, String apiKey, bool forXbox) async {
  BungieClient client = new BungieClient(apiKey);
  final roster = await client.getClanRoster(clanId, forXbox);
  return Future.wait(roster.map((member) async {
    final profile = await client.getPlayerProfile(member.id);
    return new Player(member, profile);
  }));
}

/// Prints a string representing the given time.
String _stringify(DateTime time) {
  final buffer = new StringBuffer()
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
  final params = parser.parse(args);
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
  final roster = await _getClan(clanId, apiKey, forXbox);

  // Sort the roster.
  roster.sort((a, b) => a.data.lastPlayedCharacter.lastPlayed
      .compareTo(b.data.lastPlayedCharacter.lastPlayed));

  // Print the results in a table format.
  final headers = 'Username\t\tLast active\tGrimoire\tCharacters';
  print(headers);
  roster.forEach((member) {
    final activeTime = member.data.lastPlayedCharacter.lastPlayed;
    final activeDay =
        (activeTime != null ? _stringify(activeTime) : '?').padRight(10);
    final gamertag = member.membership.gamertag.padRight(20);
    final grimoire = member.data.grimoire;
    final characterCount = member.data.characterCount;
    print('$gamertag\t$activeDay\t$grimoire\t\t$characterCount');
  });
  print(headers);
  print('Found ${roster.length} users.');
  print('All done!');
}
