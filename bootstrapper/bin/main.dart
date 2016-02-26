// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:destiny-common/bungie.dart';
import 'package:destiny-common/db.dart';
import 'package:destiny-common/drive_connection.dart';
import 'package:destiny-gplus/gplus.dart';

const OPTION_XBL_MAPPINGS = 'xbl_mappings';
const OPTION_PSN_MAPPINGS = 'psn_mappings';
const OPTION_COMMUNITY_PAGE = 'community_page';
const OPTION_GPLUS_API_KEY = 'gplus_api_key';
const OPTION_DRIVE_ID = 'drive_id';
const OPTION_DRIVE_SECRET = 'drive_secret';
const OPTION_BUNGIE_API_KEY = 'bungie_api_key';
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
    ..addOption(OPTION_XBL_MAPPINGS)
    ..addOption(OPTION_PSN_MAPPINGS)
    ..addOption(OPTION_COMMUNITY_PAGE)
    ..addOption(OPTION_GPLUS_API_KEY)
    ..addOption(OPTION_DRIVE_ID)
    ..addOption(OPTION_DRIVE_SECRET)
    ..addOption(OPTION_BUNGIE_API_KEY)
    ..addFlag(FLAG_HELP, negatable: false);
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
      !params.options.contains(OPTION_XBL_MAPPINGS) ||
      !params.options.contains(OPTION_PSN_MAPPINGS) ||
      !params.options.contains(OPTION_COMMUNITY_PAGE) ||
      !params.options.contains(OPTION_GPLUS_API_KEY) ||
      !params.options.contains(OPTION_DRIVE_ID) ||
      !params.options.contains(OPTION_DRIVE_SECRET) ||
      !params.options.contains(OPTION_BUNGIE_API_KEY)) {
    print(parser.usage);
    return;
  }

  var xblMappings = await _extractMappings(params[OPTION_XBL_MAPPINGS]);
  var psnMappings = await _extractMappings(params[OPTION_PSN_MAPPINGS]);

  var communityFile = params[OPTION_COMMUNITY_PAGE];
  var gplusApiKey = params[OPTION_GPLUS_API_KEY];
  var allUsers = await getGplusUsers(communityFile, gplusApiKey);

  var bungieClient = new BungieClient(params[OPTION_BUNGIE_API_KEY]);

  List<User> users = new List();

  await Future.forEach(allUsers, (user) async {
    String platformId;
    bool onXbox;
    var name = user.displayName;
    if (xblMappings.containsKey(name)) {
      platformId = xblMappings[name];
      onXbox = true;
    } else if (psnMappings.containsKey(name)) {
      platformId = psnMappings[name];
      onXbox = false;
    } else {
      print('No gamertag for ${name}.');
      return;
    }
    var destinyId = await bungieClient.getDestinyId(platformId, onXbox);
    if (destinyId == null) {
      print('Unable to find Destiny id for ${user} [${platformId}].');
      return;
    }
    var bungieId = await bungieClient.getBungieId(destinyId, onXbox);
    if (bungieId == null) {
      print('Unable to find Bungie id for ${user} [${platformId}]');
      return;
    }
    users.add(new User(user.id, platformId, onXbox, bungieId, destinyId));
  });

  var connection =
      new DriveConnection(params[OPTION_DRIVE_ID], params[OPTION_DRIVE_SECRET]);
  await connection.initialize();
  var loader = new DatabaseLoader(connection);
  var db = new Database();
  // Note: not touching the last update time: it will be set the first time the
  // db is actually updated.
  db.users.addAll(users);
  await loader.save(db);
  connection.destroy();

  print(db);
  print('Added ${users.length} users to the database.');
}
