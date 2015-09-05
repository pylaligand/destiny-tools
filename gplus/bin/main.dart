// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

// API calls are limited to 20 per second, but in practice we need to issue even
// less parallel queries.
const GPLUS_REQUESTS_PER_SECOND = 5;

const OPTION_COMMUNITY_PAGE = 'community_page';
const OPTION_API_KEY = 'api_key';
const OPTION_MAX_USERS = 'max_users';
const FLAG_HELP = 'help';

/// Extracts the G+ ids in the give page.
Future<List<String>> _extractIds(String data) async {
  RegExp expression = new RegExp(r'data-id="(\d+)"');
  return expression.allMatches(data).map((match) => match.group(1)).toList();
}

/// Represents a Google+ user.
class _User {

  final String _id;
  final String _displayName;
  final Uri _picture;

  _User(this._id, this._displayName, this._picture);

  String get id => _id;
  String get displayName => _displayName;
  Uri get pictureUri => _picture;

  toString() => '${_displayName} [${_picture}]';
}

/// Fetches some information about the user with the given id.
Future<_User> _getUser(String id, String apiKey) async {
  var url = 'https://www.googleapis.com/plus/v1/people/${id}?key=${apiKey}';
  var response = await http.get(url);
  var json = JSON.decode(response.body);
  var name = json['displayName'];
  var photoUri = json['image']['url'];
  return new _User(id, name, Uri.parse(photoUri));
}

main(List<String> args) async {
  final parser = new ArgParser()
      ..addOption(OPTION_COMMUNITY_PAGE, abbr: 'c')
      ..addOption(OPTION_API_KEY, abbr: 'a')
      ..addOption(OPTION_MAX_USERS, abbr: 'm', defaultsTo: '0')
      ..addFlag(FLAG_HELP, negatable: false, abbr: 'h');
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
      !params.options.contains(OPTION_COMMUNITY_PAGE) ||
      !params.options.contains(OPTION_API_KEY)) {
    print(parser.usage);
    return;
  }

  // Extract the ids from the downloaded page.
  var file = new File(params[OPTION_COMMUNITY_PAGE]);
  var data = await file.readAsString();
  var ids = await _extractIds(data);

  final userCount = int.parse(params[OPTION_MAX_USERS], onError: (s) => 0);

  // Get some information from each user.
  List<_User> users = new List();
  while (ids.isNotEmpty) {
    stdout.write('.');
    var tasks = [];
    var n = min(ids.length, GPLUS_REQUESTS_PER_SECOND);
    ids.sublist(0, n).forEach((id) {
      tasks.add(_getUser(id, params[OPTION_API_KEY]));
    });
    users.addAll(await Future.wait(tasks));
    // Verify if enough users were found.
    if (userCount > 0 && users.length >= userCount) {
      break;
    }
    ids = ids.sublist(n);
    // Artificially limit our request rate.
    sleep(new Duration(seconds: 1));
  }
  stdout.writeln();

  users.forEach((user) {
    print(user);
  });
}
