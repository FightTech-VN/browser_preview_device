import 'package:device_preview/device_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:webview_windows/webview_windows.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const ExampleBrowser(),
    );
  }
}

class ExampleBrowser extends StatefulWidget {
  const ExampleBrowser({Key? key}) : super(key: key);

  @override
  State<ExampleBrowser> createState() => _ExampleBrowser();
}

class _ExampleBrowser extends State<ExampleBrowser> {
  final _controller = WebviewController();
  final _textController = TextEditingController();
  bool _isWebviewSuspended = false;

  bool _visible = true;
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    // Optionally initialize the webview environment using
    // a custom user data directory
    // and/or a custom browser executable directory
    // and/or custom chromium command line flags
    //await WebviewController.initializeEnvironment(
    //    additionalArguments: '--show-fps-counter');

    try {
      await _controller.initialize();
      _controller.url.listen((url) {
        _textController.text = url;
      });

      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl('http://localhost:4200/');

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code: ${e.code}'),
                  Text('Message: ${e.message}'),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          );
        },
      );
    }
  }

  Widget compositeView() {
    if (!_controller.value.isInitialized) {
      return const Text(
        'Not Initialized',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Stack(
        children: [
          Expanded(
            child: Stack(
              children: [
                Webview(
                  _controller,
                  permissionRequested: _onPermissionRequested,
                ),
                StreamBuilder<LoadingState>(
                    stream: _controller.loadingState,
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data == LoadingState.loading) {
                        return const LinearProgressIndicator();
                      } else {
                        return const SizedBox();
                      }
                    }),
              ],
            ),
          ),
          Visibility(
            visible: _visible,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Card(
                  elevation: 0,
                  child: Row(
                    children: [
                      FloatingActionButton(
                        tooltip: _isWebviewSuspended
                            ? 'Resume webview'
                            : 'Suspend webview',
                        onPressed: () async {
                          if (_isWebviewSuspended) {
                            await _controller.resume();
                          } else {
                            await _controller.suspend();
                          }
                          setState(() {
                            _isWebviewSuspended = !_isWebviewSuspended;
                          });
                        },
                        child: Icon(_isWebviewSuspended
                            ? Icons.play_arrow
                            : Icons.pause),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        splashRadius: 20,
                        onPressed: () {
                          _controller.reload();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.developer_mode),
                        tooltip: 'Open DevTools',
                        splashRadius: 20,
                        onPressed: () {
                          _controller.openDevTools();
                        },
                      ),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'URL',
                            contentPadding: EdgeInsets.all(10.0),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          controller: _textController,
                          onSubmitted: (val) {
                            _controller.loadUrl(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: compositeView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _visible = !_visible;
          });
        },
        child: const Icon(CupertinoIcons.share),
      ),
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }
}
