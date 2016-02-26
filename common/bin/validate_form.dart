// Copyright (c) 2015 P.Y. Laligand

import 'package:args/args.dart';
import 'package:destiny-common/drive_connection.dart';
import 'package:destiny-common/form.dart';

const OPTION_CLIENT_ID = 'client_id';
const OPTION_CLIENT_SECRET = 'client_secret';
const OPTION_FORM_ID = 'form_id';
const FLAG_HELP = 'help';

/// Validates the data in the given member form.
main(List<String> args) async {
  final parser = new ArgParser()
    ..addOption(OPTION_CLIENT_ID, abbr: 'i')
    ..addOption(OPTION_CLIENT_SECRET, abbr: 's')
    ..addOption(OPTION_FORM_ID, abbr: 'f')
    ..addFlag(FLAG_HELP, negatable: false, abbr: 'h');
  var params = parser.parse(args);
  if (params[FLAG_HELP] ||
      !params.options.contains(OPTION_CLIENT_ID) ||
      !params.options.contains(OPTION_CLIENT_SECRET) ||
      !params.options.contains(OPTION_FORM_ID)) {
    print(parser.usage);
    return;
  }

  var connection = new DriveConnection(
      params[OPTION_CLIENT_ID], params[OPTION_CLIENT_SECRET]);
  await connection.initialize();
  var loader = new FormLoader(connection, params[OPTION_FORM_ID]);
  var list = await loader.load();
  connection.destroy();

  print('Done, found ${list.length} entries.');
}
