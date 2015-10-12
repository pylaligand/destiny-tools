// Copyright (c) 2015 P.Y. Laligand

library bungie;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Wrapper around the Bungie API.
///
/// Methods return JSON objects.
class BungieClient {

  final String _apiKey;

  BungieClient(this._apiKey);

  getBungieAccount(String id) async {
    final url = 'http://www.bungie.net/Platform/User/GetBungieAccount/${id}/254/';
    return _getJson(url);
  }

  getDestinyAccount(String id, bool onXbox) async {
    final type = onXbox ? '1' : '2';
    final url = 'http://www.bungie.net/Platform/User/GetBungieAccount/${id}/${type}/';
  }

  // TODO(pylaligand): take care of the pagination here.
  getClan(String id, bool onXbox, int pageIndex) async {
    final type = onXbox ? '1' : '2';
    final url = 'http://www.bungie.net/Platform/Group/${id}/Members/?lc=en&fmt=true&currentPage=${pageIndex}&platformType=${type}';
    return _getJson(url);
  }

  Future<String> getDestinyId(String platformId, bool onXbox) async {
    final type = onXbox ? 'TigerXbox' : 'TigerPsn';
    final url = 'http://www.bungie.net/Platform/Destiny/SearchDestinyPlayer/${type}/${platformId}';
    var data = await _getJson(url);
    List results = data['Response'];
    if (results.isEmpty || results.length > 1) {
      return null;
    }
    return results[0]['membershipId'];
  }

  Future<String> getBungieId(String destinyId, bool onXbox) async {
    final type = onXbox ? '1' : '2';
    final url = 'http://www.bungie.net/Platform/User/GetBungieAccount/${destinyId}/${type}/';
    var data = await _getJson(url);
    Map user = data['Response']['bungieNetUser'];
    return user != null ? user['membershipId'] : null;
  }

  _getJson(String url) async {
    var body = await http.read(url, headers: {'X-API-Key': this._apiKey});
    return JSON.decode(body);
  }
}
