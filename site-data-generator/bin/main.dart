// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:destiny-common/drive_connection.dart';
import 'package:destiny-common/form.dart';
import 'package:destiny-common/form_data.dart' as data;

import 'package:destiny-site-data-generator/user.dart';

const OPTION_DRIVE_ID = 'drive_id';
const OPTION_DRIVE_SECRET = 'drive_secret';
const OPTION_OUTPUT_FILE = 'output_file';
const OPTION_USER_FORM = 'user_form';
const FLAG_HELP = 'help';

// Sorts a user list.
// Currently uses platform ids.
_sortUserList(List<User> users) {
  users.sort((a, b) {
    var comparable = (User user) => user.member.gamertag.toLowerCase();
    return comparable(a).compareTo(comparable(b));
  });
  return users;
}

main(List<String> args) async {
  final parser = new ArgParser()
    ..addOption(OPTION_DRIVE_ID)
    ..addOption(OPTION_DRIVE_SECRET)
    ..addOption(OPTION_OUTPUT_FILE)
    ..addOption(OPTION_USER_FORM)
    ..addFlag(FLAG_HELP, negatable: false);
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
      !params.options.contains(OPTION_DRIVE_ID) ||
      !params.options.contains(OPTION_DRIVE_SECRET) ||
      !params.options.contains(OPTION_USER_FORM) ||
      !params.options.contains(OPTION_OUTPUT_FILE)) {
    print(parser.usage);
    return;
  }

  var connection =
      new DriveConnection(params[OPTION_DRIVE_ID], params[OPTION_DRIVE_SECRET]);
  await connection.initialize();
  final members =
      await new FormLoader(connection, params[OPTION_USER_FORM]).load();

  final users = members.map((member) => new User(member));
  var xblUsers = _sortUserList(users
      .where((user) => user.member.platform == data.Platform.Xbox)
      .toList());
  var psnUsers = _sortUserList(users
      .where((user) => user.member.platform == data.Platform.Playstation)
      .toList());
  var model = {'xblUsers': xblUsers, 'psnUsers': psnUsers};

  var content = new JsonEncoder.withIndent('  ').convert(model);
  await new File(params[OPTION_OUTPUT_FILE]).writeAsString(content);

  connection.destroy();
}
