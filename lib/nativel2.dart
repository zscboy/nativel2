import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'nativel2_bindings_generated.dart';
import 'package:ffi/ffi.dart';

typedef JSONRsp = String;

const String methodStartDaemon = "startDaemon";
const String methodStopDaemon = "stopDaemon";
const String methodSign = "sign";
const String methodDaemonState = "daemonState";
const String methodDaemonVersion = "daemonVersion";

class JSONCallRsp {
  JSONCallRsp(this.requestID, this.rsp);
  final int requestID;
  final JSONRsp rsp;
}

class JSONCallContext {
  JSONCallContext(this.requestID, this.method, this.args);

  final int requestID;
  final String method;
  final String? args;
}

class JSONCallExecutor {
  JSONCallExecutor(this._context);

  final JSONCallContext _context;

  JSONCallRsp doNativeCall() {
    Pointer<Char> ptrChar;
    final Nativel2Bindings bindings = L2APIs()._bindings;
    switch (_context.method) {
      case methodStartDaemon:
        var argsPtr = _context.args!.toNativeUtf8().cast<Char>();
        var pchar = bindings.startDaemon(argsPtr);
        malloc.free(argsPtr);
        ptrChar = pchar;
        break;
      case methodSign:
        var argsPtr = _context.args!.toNativeUtf8().cast<Char>();
        var pchar = bindings.sign(argsPtr);
        malloc.free(argsPtr);
        ptrChar = pchar;
        break;
      case methodStopDaemon:
        var pchar = bindings.stopDaemon();
        ptrChar = pchar;
        break;
      case methodDaemonState:
        var pchar = bindings.daemonState();
        ptrChar = pchar;
        break;
      case methodDaemonVersion:
        var pchar = bindings.daemonVersion();
        ptrChar = pchar;
        break;
      default:
        ptrChar = "{\"code\":-1000}".toNativeUtf8().cast<Char>();
    }

    String strResult = ptrChar.cast<Utf8>().toDartString();
    malloc.free(ptrChar);

    return JSONCallRsp(_context.requestID, strResult);
  }
}

class L2APIs {
  // singleton pattern
  static final L2APIs _instance = L2APIs._internal();

  static const String _libName = 'nativel2';

  final DynamicLibrary _dylib = () {
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('$_libName.framework/$_libName');
    }
    if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('lib$_libName.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('$_libName.dll');
    }
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }();

  late Nativel2Bindings _bindings;
  int _nextJSONCallRequestId = 0;
  final Map<int, Completer<JSONRsp>> _jsonCallRequests =
      <int, Completer<JSONRsp>>{};
  late Future<SendPort> _helperIsolateSendPortFuture;

  L2APIs._internal() {
    _bindings = Nativel2Bindings(_dylib);
    _helperIsolateSendPortFuture = _isolateNew();
  }

  factory L2APIs() {
    return _instance;
  }

  Future<SendPort> _isolateNew() async {
    // The helper isolate is going to send us back a SendPort, which we want to
    // wait for.
    final Completer<SendPort> completer = Completer<SendPort>();

    // Receive port on the main isolate to receive messages from the helper.
    // We receive two types of messages:
    // 1. A port to send messages on.
    // 2. Responses to requests we sent.
    final ReceivePort receivePort = ReceivePort()
      ..listen((dynamic data) {
        if (data is SendPort) {
          // The helper isolate sent us the port on which we can sent it requests.
          completer.complete(data);
          return;
        }
        if (data is JSONCallRsp) {
          // The helper isolate sent us a response to a request we sent.
          final Completer<JSONRsp> completer2 =
              _jsonCallRequests[data.requestID]!;
          _jsonCallRequests.remove(data.requestID);

          completer2.complete(data.rsp);
          return;
        }
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      });

    // Start the helper isolate.
    await Isolate.spawn((SendPort sendPort) async {
      final ReceivePort helperReceivePort = ReceivePort()
        ..listen((dynamic data) {
          // On the helper isolate listen to requests and respond to them.
          if (data is JSONCallContext) {
            final JSONCallExecutor exe = JSONCallExecutor(data);
            final JSONCallRsp result = exe.doNativeCall();
            sendPort.send(result);
            return;
          }
          throw UnsupportedError(
              'Unsupported message type: ${data.runtimeType}');
        });

      // Send the port to the main isolate on which we can receive requests.
      sendPort.send(helperReceivePort.sendPort);
    }, receivePort.sendPort);

    // Wait until the helper isolate has sent us back the SendPort on which we
    // can start sending requests.
    return completer.future;
  }

  Future<JSONRsp> _jsonCall(String method, String? args) async {
    var helperIsolateSendPort = await _helperIsolateSendPortFuture;
    final int requestId = _nextJSONCallRequestId++;
    final JSONCallContext request = JSONCallContext(requestId, method, args);

    final Completer<JSONRsp> completer = Completer<JSONRsp>();
    _jsonCallRequests[requestId] = completer;
    helperIsolateSendPort.send(request);

    return completer.future;
  }

  Future<JSONRsp> startDaemon(String jsonArgs) async {
    return _jsonCall(methodStartDaemon, jsonArgs);
  }

  Future<JSONRsp> stopDaemon() async {
    return _jsonCall(methodStopDaemon, null);
  }

  Future<JSONRsp> daemonState() async {
    return _jsonCall(methodDaemonState, null);
  }

  Future<JSONRsp> daemonVersion() async {
    return _jsonCall(methodDaemonVersion, null);
  }

  Future<JSONRsp> sign(String jsonArgs) async {
    return _jsonCall(methodSign, jsonArgs);
  }
}
