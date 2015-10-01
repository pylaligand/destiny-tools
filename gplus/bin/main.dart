// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'package:gdestiny-gplus/gplus.dart';

const OPTION_COMMUNITY_PAGE = 'community_page';
const OPTION_API_KEY = 'api_key';
const OPTION_MAX_USERS = 'max_users';
const OPTION_OUTPUT_FILE = 'output';
const FLAG_HELP = 'help';

main(List<String> args) async {
  final parser = new ArgParser()
      ..addOption(OPTION_COMMUNITY_PAGE, abbr: 'c')
      ..addOption(OPTION_API_KEY, abbr: 'a')
      ..addOption(OPTION_MAX_USERS, abbr: 'm', defaultsTo: '0')
      ..addOption(OPTION_OUTPUT_FILE, abbr: 'o')
      ..addFlag(FLAG_HELP, negatable: false, abbr: 'h');
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
      !params.options.contains(OPTION_COMMUNITY_PAGE) ||
      !params.options.contains(OPTION_API_KEY)) {
    print(parser.usage);
    return;
  }

  var communityFile = params[OPTION_COMMUNITY_PAGE];
  var apiKey = params[OPTION_API_KEY];
  var maxCount = int.parse(params[OPTION_MAX_USERS], onError: (s) => 0);
  var users = await getGplusUsers(communityFile, apiKey, maxCount);

  var output = stdout;
  if (params.options.contains(OPTION_OUTPUT_FILE)) {
    output = new File(params[OPTION_OUTPUT_FILE]).openWrite();
  }
  users.forEach((user) {
    output.writeln(user);
  });
  output.writeln('${users.length} members.');
  output.close();
}
