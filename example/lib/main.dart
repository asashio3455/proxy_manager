import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:proxy_manager/proxy_manager.dart';

final proxyManager = ProxyManager();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _proxyManagerPlugin = ProxyManager();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _proxyManagerPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Proxy Manager Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _proxyManagerPlugin.setAsSystemProxy(
                    ProxyTypes.http, 
                    '127.0.0.1', 
                    8080
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proxy set successfully'))
                  );
                },
                child: const Text('Set HTTP Proxy (127.0.0.1:8080)'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _proxyManagerPlugin.setProxyBypassLocal(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bypass local addresses enabled'))
                  );
                },
                child: const Text('Enable Bypass Local'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _proxyManagerPlugin.setProxyBypassLocal(false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bypass local addresses disabled'))
                  );
                },
                child: const Text('Disable Bypass Local'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _proxyManagerPlugin.cleanSystemProxy();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proxy cleaned successfully'))
                  );
                },
                child: const Text('Clean System Proxy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
