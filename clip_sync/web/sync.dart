// Copyright (c) 2016 P.Y. Laligand

import 'package:chrome/chrome_ext.dart' as chrome;

main() {
  chrome.runtime.onInstalled.listen((_) {
    print('Extension was installed, booyah!');
  });
}
