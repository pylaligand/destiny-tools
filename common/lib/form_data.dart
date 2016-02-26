// Copyright (c) 2016 P.Y. Laligand

/// Gaming platforms.
enum Platform { Xbox, Playstation }

/// Some canonical timezones.
enum Timezone { Pacific, Mountain, Central, Eastern, London, Paris, Other }

/// A registered member.
class Member {
  /// Gaming platform of choice.
  final Platform platform;

  /// Identifier on the paltform.
  final String gamertag;

  /// Google Plus identifier.
  final String gplusId;

  /// Bungie identifier.
  final String bungieId;

  /// Playing timezone.
  final Timezone timezone;

  Member(
      this.platform, this.gamertag, this.gplusId, this.bungieId, this.timezone);

  Member.fromRawData(String platform, this.gamertag, this.gplusId,
      this.bungieId, String timezone)
      : platform = _toPlatform(platform),
        timezone = _toTimezone(timezone);

  static Platform _toPlatform(String rawPlatform) {
    switch (rawPlatform) {
      case 'Xbox':
        return Platform.Xbox;
      case 'Playstation':
        return Platform.Playstation;
      default:
        throw 'Unknown platform $rawPlatform';
    }
  }

  static Timezone _toTimezone(String rawTimezone) {
    switch (rawTimezone) {
      case 'Pacific':
        return Timezone.Pacific;
      case 'Mountain':
        return Timezone.Mountain;
      case 'Central':
        return Timezone.Central;
      case 'Eastern':
        return Timezone.Eastern;
      case 'London':
        return Timezone.London;
      case 'Paris':
        return Timezone.Paris;
      case 'Other':
        return Timezone.Other;
      default:
        throw 'Unknown timezone $rawTimezone';
    }
  }

  @override
  String toString() {
    final platformCode = platform == Platform.Xbox ? 'XBL' : 'PSN';
    return '${gamertag}[${platformCode}]';
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Member) {
      return false;
    }
    return platform == other.platform && gamertag == other.gamertag;
  }

  @override
  int get hashCode {
    int result = 17;
    result += 37 * platform.hashCode;
    result += 37 * gamertag.hashCode;
    return result;
  }
}
