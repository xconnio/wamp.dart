import "dart:async";
import "dart:io";

import "package:wampproto/auth.dart";
import "package:wampproto/joiner.dart";
import "package:wampproto/serializers.dart";

import "package:xconn/src/helpers.dart";
import "package:xconn/src/types.dart";

class WAMPSessionJoiner {
  WAMPSessionJoiner({IClientAuthenticator? authenticator, Serializer? serializer}) {
    _serializer = serializer ?? JSONSerializer();
    _authenticator = authenticator;
  }

  IClientAuthenticator? _authenticator;
  late Serializer _serializer;

  Future<BaseSession> join(String uri, String realm) async {
    // ignore: close_sinks
    var ws = await WebSocket.connect(uri, protocols: [getSubProtocol(_serializer)]);

    final joiner = Joiner(realm, _serializer, _authenticator);
    ws.add(joiner.sendHello());

    var welcomeCompleter = Completer<BaseSession>();

    late StreamSubscription<dynamic> wsStreamSubscription;
    final sessionStreamController = StreamController.broadcast();

    wsStreamSubscription = ws.listen((event) {
      dynamic toSend = joiner.receive(event);
      if (toSend == null) {
        wsStreamSubscription.onData(null);

        BaseSession baseSession = BaseSession(ws, wsStreamSubscription, joiner.getSessionDetails(), _serializer);
        welcomeCompleter.complete(baseSession);
      } else {
        ws.add(toSend);
      }
    });
    wsStreamSubscription.onDone(() {
      sessionStreamController.stream.isEmpty.then(
        (isEmpty) => {
          if (!isEmpty) {sessionStreamController.close()},
        },
      );
      wsStreamSubscription.cancel();
    });

    return welcomeCompleter.future;
  }
}
