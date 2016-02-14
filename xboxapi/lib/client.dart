// Copyright (c) 2016 P.Y. Laligand

library xboxapi;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const BASE_URL = 'https://xboxapi.com/v2';

/// Wrapper around the xboxapi.com API.
///
/// Methods return JSON objects.
class XboxApiClient {
  final String _apiKey;

  XboxApiClient(this._apiKey);

  Future<String> getXuid(String gamertag) async {
    final url = '$BASE_URL/xuid/$gamertag';
    return _getJson(url);
  }

  Future<List<GameClip>> getVideos(String xuid) async {
    final url = '$BASE_URL/$xuid/game-clips';
    final data = await _getJson(url);
    return data.map((clip) {
      final id = clip['gameClipId'];
      final content = clip['gameClipUris'][0];
      final clipUrl = content['uri'];
      return new GameClip(id, clipUrl);
    });
  }

  dynamic _getJson(String url) async {
    var body = await http.read(url, headers: {'X-AUTH': this._apiKey});
    return JSON.decode(body);
  }
}

/// Describes a game clip on Xbox Live.
class GameClip {
  final String id;
  final String url;

  GameClip(this.id, this.url);

  @override String toString() {
    return '${this.id}[${this.url}]';
  }
}
