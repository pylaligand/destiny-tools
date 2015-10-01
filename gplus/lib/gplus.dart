// Copyright (c) 2015 P.Y. Laligand

library gplus;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

// API calls are limited to 20 per second, but in practice we need to issue even
// less parallel queries.
const _GPLUS_REQUESTS_PER_SECOND = 5;

/// Extracts the G+ ids in the given page.
Future<List<String>> _extractIds(String data) async {
  RegExp expression = new RegExp(r'data-id="(\d+)"');
  return expression.allMatches(data).map((match) => match.group(1)).toList();
}

/// Represents a Google+ user.
class GplusUser {

  final String id;
  final String displayName;
  final Uri picture;

  GplusUser(this.id, this.displayName, this.picture);

  toString() => '${displayName}';
}

/// Fetches some information about the user with the given id.
Future<GplusUser> _getUser(String id, String apiKey) async {
  var url = 'https://www.googleapis.com/plus/v1/people/${id}?key=${apiKey}';
  var response = await http.get(url);
  var json = JSON.decode(response.body);
  var name = json['displayName'];
  var photoUri = json['image'] != null ? Uri.parse(json['image']['url']) : null;
  return new GplusUser(id, name, photoUri);
}

/// Parses the given community member page and returns the list of users it
/// contains with extra information.
Future<List<GplusUser>> getGplusUsers(
    String communityFile, String apiKey, [int maxCount = 0]) async {
  // Extract the ids from the downloaded page.
  var file = new File(communityFile);
  var data = await file.readAsString();
  var ids = await _extractIds(data);

  // Get some information from each user.
  List<GplusUser> users = new List();
  while (ids.isNotEmpty) {
    stdout.write('.');
    var tasks = [];
    var n = min(ids.length, _GPLUS_REQUESTS_PER_SECOND);
    ids.sublist(0, n).forEach((id) {
      tasks.add(_getUser(id, apiKey));
    });
    users.addAll(await Future.wait(tasks));
    // Verify if enough users were found.
    if (maxCount > 0 && users.length >= maxCount) {
      break;
    }
    ids = ids.sublist(n);
    // Artificially limit our request rate.
    sleep(new Duration(seconds: 1));
  }
  stdout.writeln();

  return users;
}
