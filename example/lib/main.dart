import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:content_resolver/content_resolver.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _contentSubject = PublishSubject<Content>();
  late final AppLinks _appLinks;
  late final StreamSubscription<String> _appLinksSub;

  @override
  void initState() {
    super.initState();
    // This example illustrates how to deal with the content intent with ContentResolver.
    _appLinks = AppLinks();
    _appLinksSub = _appLinks.allStringLinkStream.listen((uri) async {
      _contentSubject.add(await ContentResolver.resolveContent(uri));
    });
  }

  @override
  void dispose() {
    _appLinksSub.cancel();
    _contentSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ContentResolver example app'),
        ),
        body: StreamBuilder<Content>(
            stream: _contentSubject.stream,
            builder: (context, snapshot) {
              return Center(
                child: snapshot.hasData
                    ? Image.memory(snapshot.data!.data)
                    : Text('Nothing received.'),
              );
            }),
      ),
    );
  }
}
