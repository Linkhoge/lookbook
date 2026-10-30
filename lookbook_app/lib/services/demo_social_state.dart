/*
 * Shared demo interactions.
 * No Firestore writes or real user notifications.
 */

import 'package:flutter/foundation.dart';

class DemoSocialState extends ChangeNotifier {
  DemoSocialState._();

  static final instance = DemoSocialState._();

  bool liked = false;
  bool requestPending = false;
  bool blocked = false;
  bool postsHidden = false;

  void like() {
    if (blocked || liked) return;
    liked = true;
    notifyListeners();
  }

  void toggleLike() {
    if (blocked) return;
    liked = !liked;
    notifyListeners();
  }

  void toggleRequest() {
    if (blocked) return;
    requestPending = !requestPending;
    notifyListeners();
  }

  void toggleBlock() {
    blocked = !blocked;

    if (blocked) {
      requestPending = false;
    }

    notifyListeners();
  }

  void hidePosts() {
    postsHidden = true;
    notifyListeners();
  }

  void showPosts() {
    postsHidden = false;
    notifyListeners();
  }

  void reset() {
    liked = false;
    requestPending = false;
    blocked = false;
    postsHidden = false;
    notifyListeners();
  }
}