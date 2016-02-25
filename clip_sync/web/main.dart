// Copyright (c) 2016 P.Y. Laligand

import 'dart:html';

import 'package:chrome/chrome_ext.dart' as chrome;

main() {
  querySelector('#status').text = 'This is an extension';
  chrome.browserAction
      .setBadgeText(new chrome.BrowserActionSetBadgeTextParams(text: '31'));
}
