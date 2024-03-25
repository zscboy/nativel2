import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'nativel2.dart' as nativel2;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<nativel2.JSONRsp> signAsyncResult;

  @override
  void initState() {
    super.initState();
    signAsyncResult = nativel2.L2APIs().sign("abc");
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                FutureBuilder<String>(
                  future: signAsyncResult,
                  builder: (BuildContext context, AsyncSnapshot<String> value) {
                    final displayValue =
                        (value.hasData) ? value.data : 'loading';
                    return Text(
                      'await sign("abc") = $displayValue',
                      style: textStyle,
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                spacerSmall,
                const DaemonCtrl(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DaemonCtrl extends StatefulWidget {
  const DaemonCtrl({super.key});

  @override
  State<DaemonCtrl> createState() => _DaemonCtrlState();
}

class _DaemonCtrlState extends State<DaemonCtrl> {
  bool isDaemonRunning = false;
  int daemonCounter = 0;
  bool isClickHandling = false;
  String _title = "Start";
  late Timer timer;
  bool isQuerying = false;

  void handleClick() async {
    if (isClickHandling) {
      return;
    }

    isClickHandling = true;
    String result;

    if (isDaemonRunning) {
      result = await nativel2.L2APIs().stopDaemon();
    } else {
      final Map<String, dynamic> args = {
        "logPath": "/var/aabb/l2.log",
        "configPath": "/var/aabb/l2.toml",
      };

      final String argsString = jsonEncode(args);
      result = await nativel2.L2APIs().startDaemon(argsString);
    }

    debugPrint('start/stop call: $result');
    isClickHandling = false;
    final Map<String, dynamic> jsonResult = jsonDecode(result);

    if (jsonResult["Code"] == 0) {
      isDaemonRunning = !isDaemonRunning;
      setState(() {
        _title = isDaemonRunning ? "Stop" : "Start";
      });
    }
  }

  void queryDaemonState() async {
    if (isQuerying) {
      return;
    }

    if (!isDaemonRunning) {
      return;
    }

    isQuerying = true;
    String result;

    result = await nativel2.L2APIs().daemonState();

    debugPrint('state call: $result');

    isQuerying = false;
    final Map<String, dynamic> jsonResult = jsonDecode(result);

    if (jsonResult["Code"] == 0) {
      if (jsonResult["Counter"] != daemonCounter) {
        daemonCounter = jsonResult["Counter"];

        setState(() {
          final String prefix = isDaemonRunning ? "Stop" : "Start";
          _title = "$prefix(counter:$daemonCounter)";
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      queryDaemonState();
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build call with button title: $_title');
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            if (isClickHandling) {
              return;
            }
            handleClick();
          },
          child: Text(
            _title,
          ),
        )
      ],
    );
  }
}
