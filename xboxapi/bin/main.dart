// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:xboxapi/client.dart';

const OPTION_API_KEY = 'api_key';
const OPTION_GAMERTAG = 'gamertag';
const OPTION_DESTINATION_FOLDER = 'destination';
const FLAG_HELP = 'help';

/// Downloads some content and saves it to a local file.
///
/// Returns [true] if the file was properly saved.
Future<bool> save(String downloadUrl, String filePath) async {
  final response = await new HttpClient()
      .getUrl(Uri.parse(downloadUrl))
      .then((HttpClientRequest request) => request.close());
  bool success = true;
  await response
      .pipe(new File(filePath).openWrite()
      .catchError(() => success = false));
  return success;
}

main(List<String> args) async {
  final parser = new ArgParser()
    ..addOption(OPTION_API_KEY, abbr: 'k')
    ..addOption(OPTION_GAMERTAG, abbr: 'g')
    ..addOption(OPTION_DESTINATION_FOLDER, abbr: 'd')
    ..addFlag(FLAG_HELP, negatable: false, abbr: 'h');
  final params = parser.parse(args);
  if (params[FLAG_HELP] ||
      !params.options.contains(OPTION_API_KEY) ||
      !params.options.contains(OPTION_GAMERTAG) ||
      !params.options.contains(OPTION_DESTINATION_FOLDER)) {
    print(parser.usage);
    return;
  }

  final apiKey = params[OPTION_API_KEY];
  final gamertag = params[OPTION_GAMERTAG];
  final destination = params[OPTION_DESTINATION_FOLDER];

  final client = new XboxApiClient(apiKey);
  print('Looking for gamertag ${gamertag}');
  final xuid = await client.getXuid(gamertag);
  print('XUID is ${xuid}');
  final videos = await client.getVideos(xuid);
  print('Found ${videos.length} videos.');

  final download = (video) async {
    final success =
        await save(video.url, path.join(destination, '${video.id}.mp4'));
    stdout.write('.');
    return success;
  };
  final status = await Future.wait(videos.map((video) => download(video)));
  stdout.writeln();
  final completed = status.fold(true, (result, value) => result && value);
  if (!completed) {
    print('Some files were not correctly downloaded!');
  }
}
