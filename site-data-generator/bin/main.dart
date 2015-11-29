// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:destiny-common/db.dart';
import 'package:destiny-common/drive_connection.dart';

const OPTION_DRIVE_ID = 'drive_id';
const OPTION_DRIVE_SECRET = 'drive_secret';
const OPTION_OUTPUT_FILE = 'output_file';
const FLAG_HELP = 'help';

// Sorts a user list.
// Currently uses platform ids.
_sortUserList(List<User> users) {
  users.sort((a, b) {
    var comparable = (User user) => user.platformId.toLowerCase();
    return comparable(a).compareTo(comparable(b));
  });
  return users;
}

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

  var connection = new DriveConnection(
      params[OPTION_DRIVE_ID], params[OPTION_DRIVE_SECRET]);
  await connection.initialize();
  var loader = new DatabaseLoader(connection);
  Database db = await loader.load();

  var xblUsers = _sortUserList(
      db.users.where((user) => user.onXbox && !user.ignored).toList());
  var psnUsers = _sortUserList(
      db.users.where((user) => !user.onXbox && !user.ignored).toList());
  var model = {
    'xblUsers': xblUsers,
    'psnUsers': psnUsers,
  };
  var data = new JsonEncoder.withIndent('  ').convert(model);
  await new File(params[OPTION_OUTPUT_FILE]).writeAsString(data);

  connection.destroy();
}
