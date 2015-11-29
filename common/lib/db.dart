// Copyright (c) 2015 P.Y. Laligand

library db;

import 'dart:async';
import 'dart:convert';

import 'package:collection/equality.dart';
import 'package:googleapis/drive/v2.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import 'drive_connection.dart';

part 'model.dart';

/// Used to load a database from Google Drive.
class DatabaseLoader {

  final DriveConnection _connection;
  final String folderName;
  final String fileName;

  /// Constructor.
  ///
  /// [connection] - Google Drive connection.
  /// [folderName] - Name of the (existing) Drive folder where the database is
  /// stored.
  /// [fileName] - Name of the database file.
  DatabaseLoader(this._connection, {
      this.folderName: '',
      this.fileName: 'destinydb.txt'});

  /// Loads the database from Drive.
  Future<Database> load() async {
    drive.File file = await _getDatabaseFile();
    var content = await _connection.client.read(file.downloadUrl);
    Database db = _databaseFromContent(content);
    return db;
  }

  /// Saves the database to Drive.
  save(Database db) async {
    drive.File file = await _getDatabaseFile();
    var content = _mediaFromDatabase(db);
    await _connection.api.files.update(
        file, file.id, uploadMedia: content, newRevision: true);
  }

  /// Returns the database file, creating it if necessary.
  Future<drive.File> _getDatabaseFile() async {
    // Locate the destination folder.
    String folderId;
    if (folderName.isEmpty) {
      folderId = (await _connection.api.about.get()).rootFolderId;
    } else {
      var query = '''title = "${folderName}" and
          mimeType = "application/vnd.google-apps.folder" and
          trashed = false''';
      var folderList =
          await _connection.api.files.list(q: query, maxResults: 1);
      if (folderList.items.isEmpty) {
        throw new StateError('Could not find folder "${folderName}"');
      }
      folderId = folderList[0].fileId;
    }

    // Find the file in the folder.
    var query = '''title = "${fileName}" and
        trashed = false''';
    var fileList =
        await _connection.api.children.list(folderId, q: query, maxResults: 1);
    if (fileList.items.isNotEmpty) {
      var fileId = fileList.items[0].id;
      return _connection.api.files.get(fileId);
    }

    // Create the file if it does not exist.
    print('Creating new database file "${fileName}".');
    drive.File newFile = new drive.File();
    newFile.title = fileName;
    newFile.description = 'Destiny database';
    newFile.mimeType = 'text/plain';
    newFile.parents = [new drive.ParentReference()..id = folderId];
    // Add some default -empty- content.
    var content = _mediaFromDatabase(new Database());
    return _connection.api.files.insert(newFile, uploadMedia: content);
  }

  /// Converts a Database object into a byte stream.
  drive.Media _mediaFromDatabase(Database db) {
    var jsonEncoder = new JsonEncoder.withIndent('  ');
    var json = jsonEncoder.convert(db.toJson());
    var bytes = UTF8.encoder.convert(json);
    var stream = new Stream.fromIterable([bytes]);
    return new drive.Media(stream, bytes.length);
  }

  /// Converts the content of a db file into the corresponding Database object.
  Database _databaseFromContent(String content) {
    var json = JSON.decode(content);
    return new Database.fromJson(json);
  }
}
