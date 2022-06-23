import 'dart:typed_data';

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
  final _imageDataSubject = PublishSubject<Uint8List>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    // This example illustrates how to deal with the content intent with ContentResolver.
    _appLinks = AppLinks(onAppLink: (uri) async {
      // NOTE: AppLinks uses Uri class but it may break certain content URIs like Slack's one;
      // Slack's content URI is currently content://com.Slack.fileprovider/... form and the most problematic issue
      // with the URI is capitalized `S` inside the host name; Dart's Uri class will make the host name lower-case
      // and the resulting URI can not be resolved with Content Resolver any longer :(
      // Possible, but dirty workaround might be replacing these host names on your code.
      final uriStr = uri.toString().replaceFirst(
          'content://com.slack.fileprovider/',
          'content://com.Slack.fileprovider/');

      _imageDataSubject.add(await ContentResolver.resolveContent(uriStr));
    });
  }

  @override
  void dispose() {
    _imageDataSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ContentResolver example app'),
        ),
        body: StreamBuilder<Uint8List>(
            stream: _imageDataSubject.stream,
            builder: (context, snapshot) {
              return Center(
                child: snapshot.hasData
                    ? Image.memory(snapshot.data!)
                    : Text('Nothing received.'),
              );
            }),
      ),
    );
  }
}
