// Copyright (c) 2016 P.Y. Laligand

import 'dart:math';

import 'package:chrome/chrome_ext.dart' as chrome;

const ALARM_NAME = 'xbl2drive';
const ALARM_PERIOD_MIN = 60;
const BADGE_THRESHOLD = 10;

/// Returns the number of unsynced videos.
int _getUnsyncedVideoCount() {
  return new Random().nextInt(30);
}

/// Executes a sync.
void _performSync() {
  print('Syncing!');
  int count = _getUnsyncedVideoCount();
  chrome.browserAction.setBadgeText(new chrome.BrowserActionSetBadgeTextParams(
      text: count > BADGE_THRESHOLD ? count.toString() : ''));
  chrome.storage.local.set({'lastCount': count});
}

main() {
  print('Extension was installed, booyah!');
  chrome.alarms.onAlarm.listen((chrome.Alarm alarm) {
    if (alarm.name == ALARM_NAME) {
      _performSync();
    }
  });
  chrome.alarms.create(
      new chrome.AlarmCreateInfo(periodInMinutes: ALARM_PERIOD_MIN),
      ALARM_NAME);
}
