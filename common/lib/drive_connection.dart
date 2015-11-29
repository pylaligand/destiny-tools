// Copyright (c) 2015 P.Y. Laligand

import 'package:googleapis/drive/v2.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

/// A connection to the Google Drive service.
class DriveConnection {

  /// Client id.
  final String _id;
  /// Client secret.
  final String _secret;

  http.Client _client;
  drive.DriveApi _api;

  /// Constructor.
  ///
  /// See https://developers.google.com/identity/protocols/OAuth2 for details on
  /// OAuth2 authentication parameters.
  ///
  /// [id] - client id.
  /// [secret] - client secret.
  DriveConnection(this._id, this._secret);

  bool get isLoaded => _client != null;
  http.Client get client => _client;
  drive.DriveApi get api => _api;

  /// Initializes the connection to Google services.
  initialize() async {
    _verifyLoaded(false);
    var id = new auth.ClientId(_id, _secret);
    _client = await auth.clientViaUserConsent(
        id, [drive.DriveApi.DriveScope], _authPrompt);
    _api = new drive.DriveApi(_client);
  }

  /// Disposes of the connection.
  destroy() {
    _verifyLoaded(true);
    _client.close();
    _client = null;
    _api = null;
  }

  /// Displays a prompt inviting the user to use a browser for authentication
  /// purposes.
  _authPrompt(String url) {
    print('To authenticate, please visit:');
    print(url);
  }

  /// Verifies the expected initialization state of the connection.
  _verifyLoaded(bool loaded) {
    if (loaded) {
      if (_client == null) {
        throw new StateError('Loader not initialized.');
      }
    } else {
      if (_client != null) {
        throw new StateError('Loader already initialized.');
      }
    }
  }
}
