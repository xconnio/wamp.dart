import "package:wamp/src/realm.dart";
import "package:wamp/src/types.dart";
import "package:wampproto/messages.dart";

class Router {
  final Map<String, Realm> _realms = {};

  void addRealm(String name) {
    _realms[name] = Realm();
  }

  void removeRealm(String name) {
    _realms.remove(name);
  }

  bool hasRealm(String name) {
    return _realms.containsKey(name);
  }

  void attachClient(IBaseSession baseSession) {
    String realm = baseSession.realm();
    if (!_realms.containsKey(realm)) {
      throw Exception("cannot attach client to non-existent realm $realm");
    }

    _realms[realm]?.attachClient(baseSession);
  }

  void detachClient(IBaseSession baseSession) {
    String realm = baseSession.realm();
    if (!_realms.containsKey(realm)) {
      throw Exception("cannot detach client from non-existent realm $realm");
    }

    _realms[realm]?.detachClient(baseSession);
  }

  Future<void> receiveMessage(IBaseSession baseSession, Message msg) async {
    String realm = baseSession.realm();
    if (!_realms.containsKey(realm)) {
      throw Exception("cannot process message for non-existent realm $realm");
    }

    await _realms[realm]?.receiveMessage(baseSession.id(), msg);
  }
}
