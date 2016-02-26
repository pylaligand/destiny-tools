// Copyright (c) 2016 P.Y. Laligand

import 'package:destiny-common/form_data.dart';

/// Aggregated data about a user.
class User {
  /// The user's membership.
  final Member member;

  User(this.member);

  Map toJson() {
    final result = new Map();
    result['gplusId'] = member.gplusId;
    result['platformId'] = member.gamertag;
    result['onXbox'] = member.platform == Platform.Xbox;
    result['bungieId'] = member.bungieId;
    return result;
  }
}
