// Copyright (c) 2015 P.Y. Laligand

import 'dart:async';

import 'package:csv/csv.dart';
import 'package:googleapis/drive/v2.dart' as drive;
import 'package:http/http.dart' as http;

import 'drive_connection.dart';

class FormLoader {

  static final _NUM_REGEX = new RegExp(r'^\d+$');
  static final _CUSTOM_REGEX = new RegExp(r'^\+\w+$');

  final DriveConnection _connection;
  final String _formId;

  /// Constructor.
  ///
  /// [connection] - connection to Google Drive.
  /// [formId] - id of the form results to read.
  FormLoader(this._connection, this._formId);

  /// Loads the content of the form.
  Future<List> load() async {
    drive.File file = await _connection.api.files.get(_formId);
    var content = await _connection.client.read(file.exportLinks['text/csv']);
    var codec = new CsvCodec(parseNumbers: false);
    var list = codec.decoder.convert(content);
    // Remove the headers.
    list.removeAt(0);
    list.retainWhere(_validate);
    return list;
  }

  /// Returns |true| if the given entry contains valid data.
  bool _validate(List<String> user) {
    // Platform.
    const platforms = const ['Xbox', 'Playstation'];
    var platform = user[1];
    if (!platforms.contains(platform)) {
      print('Invalid platform: ${platform}');
      return false;
    }
    // G+ id.
    var gplusId = user[3];
    if (_NUM_REGEX.firstMatch(gplusId) == null &&
        _CUSTOM_REGEX.firstMatch(gplusId) == null) {
      print('Invalid G+ id: ' + gplusId);
      return false;
    }
    // Bungie id.
    var bungieId = user[4];
    if (_NUM_REGEX.firstMatch(bungieId) == null) {
      print('Invalid Bungie id: ' + bungieId);
      return false;
    }
    return true;
  }
}
