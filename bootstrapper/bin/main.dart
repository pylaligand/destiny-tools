// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

import 'package:destiny-gplus/gplus.dart';

const OPTION_MAPPINGS = 'mappings';
const OPTION_COMMUNITY_PAGE = 'community_page';
const OPTION_API_KEY = 'api_key';
const FLAG_HELP = 'help';

/// Reads the |real name| <--> |platform id| mappings from the given file.
Future<Map<String, String>> _extractMappings(String fileName) async {
  var file = new File(fileName);
  var data = await file.readAsLines();
  var regex = new RegExp(r'^(.+)\ \((.+)\)\s*$');
  var result = {};
  data.forEach((line) {
    var match = regex.firstMatch(line);
    result[match.group(2)] = match.group(1);
  });
  return result;
}

main(List<String> args) async {
  final parser = new ArgParser()
      ..addOption(OPTION_MAPPINGS, abbr: 'm')
      ..addOption(OPTION_COMMUNITY_PAGE, abbr: 'c')
      ..addOption(OPTION_API_KEY, abbr: 'a')
      ..addFlag(FLAG_HELP, negatable: false, abbr: 'h');
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
        !params.options.contains(OPTION_MAPPINGS) ||
        !params.options.contains(OPTION_COMMUNITY_PAGE)) {
    print(parser.usage);
    return;
  }

  var mappings = await _extractMappings(params[OPTION_MAPPINGS]);

  var communityFile = params[OPTION_COMMUNITY_PAGE];
  var apiKey = params[OPTION_API_KEY];
  var allUsers = await getGplusUsers(communityFile, apiKey);

  var knownUsers = allUsers.where((user) {
    return mappings.containsKey(user.displayName);
  }).toList()..sort((x, y) {
    return x.displayName.compareTo(y.displayName);
  });
  print('Users whose platform id is known:');
  knownUsers.forEach((user) => print(' - ${user}'));
  print('${knownUsers.length} users.');

  var notFound = mappings.keys.where((name) {
    var found = allUsers.firstWhere((gUser) {
      return gUser.displayName == name;
    }, orElse: () => null);
    return found == null;
  });
  print('Mapped users not recognized in community:');
  notFound.forEach((user) => print(' - ${user}'));
  print('${notFound.length} users.');
}
