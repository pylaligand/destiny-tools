// Copyright (c) 2015 P.Y. Laligand

library db;

import 'dart:async';
import 'dart:convert';

import 'package:collection/equality.dart';
import 'package:googleapis/drive/v2.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

part 'model.dart';

/// Configuration data necessary for OAuth 2.0 authentication.
/// See https://developers.google.com/identity/protocols/OAuth2.
class Config {
  /// Client id.
  final String id;
  /// Client secret.
  final String secret;

  Config(this.id, this.secret);
}

/// Used to load a database from Google Drive.
class DatabaseLoader {

  final Config config;
  final String folderName;
  final String fileName;

  drive.DriveApi api;
  http.Client client;

  /// Constructor.
  ///
  /// [config] - oAuth configuration parameters.
  /// [folderName] - Name of the (existing) Drive folder where the database is
  /// stored.
  /// [fileName] - Name of the database file.
  DatabaseLoader(this.config, {
      this.folderName: '',
      this.fileName: 'destinydb.txt'});

  /// Initializes the connection to Google Drive.
  /// Must be called before any load/save operations.
  initialize() async {
    _verifyLoaded(false);
    var id = new auth.ClientId(config.id, config.secret);
    var scopes = [drive.DriveApi.DriveScope];
    client = await auth.clientViaUserConsent(id, scopes, _authPrompt);
    api = new drive.DriveApi(client);
    return null;
  }

  /// Disposes of the loader.
  /// Load/save operations are unavailable once this method has been called.
  destroy() {
    _verifyLoaded(true);
    client.close();
    api = null;
    client = null;
  }

  /// Loads the database from Drive.
  Future<Database> load() async {
    _verifyLoaded(true);
    drive.File file = await _getDatabaseFile();
    var content = await client.read(file.downloadUrl);
    Database db = _databaseFromContent(content);
    return db;
  }

  /// Saves the database to Drive.
  save(Database db) async {
    _verifyLoaded(true);
    drive.File file = await _getDatabaseFile();
    var content = _mediaFromDatabase(db);
    await api.files.update(
        file, file.id, uploadMedia: content, newRevision: true);
  }

  /// Verifies the expected initialization state of the loader.
  _verifyLoaded(bool loaded) {
    if (loaded) {
      if (client == null) {
        throw new StateError('Loader not initialized.');
      }
    } else {
      if (client != null) {
        throw new StateError('Loader already initialized.');
      }
    }
  }

  /// Displays a prompt inviting the user to use a browser for authentication
  /// purposes.
  _authPrompt(String url) {
    print('To authenticate, please visit:');
    print(url);
  }

  /// Returns the database file, creating it if necessary.
  Future<drive.File> _getDatabaseFile() async {
    // Locate the destination folder.
    String folderId;
    if (folderName.isEmpty) {
      folderId = (await api.about.get()).rootFolderId;
    } else {
      var query = '''title = "${folderName}" and
          mimeType = "application/vnd.google-apps.folder" and
          trashed = false''';
      var folderList = await api.files.list(q: query, maxResults: 1);
      if (folderList.items.isEmpty) {
        throw new StateError('Could not find folder "${folderName}"');
      }
      folderId = folderList[0].fileId;
    }

    // Find the file in the folder.
    var query = '''title = "${fileName}" and
        trashed = false''';
    var fileList = await api.children.list(folderId, q: query, maxResults: 1);
    if (fileList.items.isNotEmpty) {
      var fileId = fileList.items[0].id;
      return api.files.get(fileId);
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
    return api.files.insert(newFile, uploadMedia: content);
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
