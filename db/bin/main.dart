// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';

import 'package:args/args.dart';
import 'package:destiny-db/db.dart';

const OPTION_CLIENT_ID = 'client_id';
const OPTION_CLIENT_SECRET = 'client_secret';
const FLAG_HELP = 'help';

main(List<String> args) async {
  final parser = new ArgParser()
      ..addOption(OPTION_CLIENT_ID, abbr: 'i')
      ..addOption(OPTION_CLIENT_SECRET, abbr: 's')
      ..addFlag(FLAG_HELP, negatable: false, abbr: 'h');
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
      !params.options.contains(OPTION_CLIENT_ID) ||
      !params.options.contains(OPTION_CLIENT_SECRET)) {
    print(parser.usage);
    return;
  }

  var config = new Config(
      params[OPTION_CLIENT_ID], params[OPTION_CLIENT_SECRET]);
  var loader = new DatabaseLoader(config);
  await loader.initialize();
  var database = await loader.load();
  print(database);
  loader.destroy();
}
