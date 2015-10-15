// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:destiny-common/db.dart';

const OPTION_DRIVE_ID = 'drive_id';
const OPTION_DRIVE_SECRET = 'drive_secret';
const OPTION_OUTPUT_FILE = 'output_file';
const FLAG_HELP = 'help';

main(List<String> args) async {
  final parser = new ArgParser()
      ..addOption(OPTION_DRIVE_ID)
      ..addOption(OPTION_DRIVE_SECRET)
      ..addOption(OPTION_OUTPUT_FILE)
      ..addFlag(FLAG_HELP, negatable: false);
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
        !params.options.contains(OPTION_DRIVE_ID) ||
        !params.options.contains(OPTION_DRIVE_SECRET) ||
        !params.options.contains(OPTION_OUTPUT_FILE)) {
    print(parser.usage);
    return;
  }

  var config = new Config(
      params[OPTION_DRIVE_ID], params[OPTION_DRIVE_SECRET]);
  var loader = new DatabaseLoader(config);
  await loader.initialize();
  Database db = await loader.load();

  var xboxUsers = db.users.where((user) => user.onXbox).toList();
  var data = new JsonEncoder.withIndent('  ').convert(xboxUsers);
  await new File(params[OPTION_OUTPUT_FILE]).writeAsString(data);

  loader.destroy();
}
