import 'dart:async';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Resolves `content:xxxx` style URI using [ContentResolver](https://developer.android.com/reference/android/content/ContentResolver).
class ContentResolver {
  ContentResolver._(this.address, this.length, this.mimeType, this.fileName);

  /// Address of buffer that contains the content
  final int address;

  /// Byte size of the content
  final int length;

  /// Mimetype of the content
  final String? mimeType;

  /// File name of the content
  final String? fileName;

  static final _channel = const MethodChannel('content_resolver')
    ..setMethodCallHandler(_onMethodCall);

  ///  Get the content of the specified `content:xxxx` style URI.
  static Future<Content> resolveContent(String uri) async {
    final cr = await resolve(uri);
    try {
      return Content(
        data: Uint8List.fromList(cr.buffer),
        mimeType: cr.mimeType,
        fileName: cr.fileName,
      );
    } finally {
      cr.dispose();
    }
  }

  /// For advanced use only; obtaining [ContentResolver] that manages content buffer.
  /// the instance must be released by calling [dispose] method.
  static Future<ContentResolver> resolve(String uri) async {
    try {
      final result = await _channel.invokeMethod('getContent', uri);
      return ContentResolver._(
          result['address'] as int,
          result['length'] as int,
          result['mimeType'] as String?,
          result['fileName'] as String?);
    } on Exception {
      throw Exception('Handling URI "$uri" failed.');
    }
  }

  /// Save the content of the specified `content:xxxx` style URI to a file.
  static Future<ContentMetadata> resolveContentToFile(
    String uri,
    String filePath,
  ) async {
    try {
      final result = await _channel.invokeMethod('saveContentToFile', {
        "uri": uri,
        "filePath": filePath,
      });
      return ContentMetadata(
        mimeType: result['mimeType'] as String?,
        fileName: result['fileName'] as String?,
      );
    } on Exception {
      throw Exception('Handling URI "$uri" failed.');
    }
  }

  static Future<ContentMetadata> resolveContentMetadata(String uri) async {
    try {
      final result = await _channel.invokeMethod('getContentMetadata', uri);
      return ContentMetadata(
        mimeType: result['mimeType'] as String?,
        fileName: result['fileName'] as String?,
      );
    } on Exception {
      throw Exception('Handling URI "$uri" failed.');
    }
  }

  static int _streamId = 0;

  static Stream<Uint8List> resolveContentToStream(String uri,
      {int bufferSize = 64 * 1024}) {
    try {
      final id = ++_streamId;
      final controller = StreamController<Uint8List>();
      _streamMap[id] = controller;

      _channel.invokeMethod('streamContent', {
        "id": id,
        "uri": uri,
        "bufferSize": bufferSize,
      });
      return controller.stream;
    } on Exception {
      throw Exception('Handling URI "$uri" failed.');
    }
  }

  /// Directly writes a content as a [Uint8List]
  static Future<void> writeContent(String uri, Uint8List bytes,
      {String mode = "wt"}) async {
    try {
      await _channel.invokeMethod(
          'writeContent', {"uri": uri, "bytes": bytes, "mode": mode});
    } on Exception {
      throw Exception('Handling URI "$uri" failed.');
    }
  }

  /// Dispose the associated native buffer.
  Future<void> dispose() async {
    await _channel.invokeMethod('releaseBuffer', address);
  }

  /// Buffer that contains the content.
  Uint8List get buffer =>
      Pointer<Uint8>.fromAddress(address).asTypedList(length);

  static final _streamMap = <int, StreamController<Uint8List>>{};

  static Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'data':
        final id = call.arguments['id'] as int;
        final data = call.arguments['data'] as Uint8List;
        final controller = _streamMap[id];
        controller?.add(data);
        break;
      case 'close':
        final id = call.arguments['id'] as int;
        final controller = _streamMap.remove(id);
        controller?.close();
        break;
      case 'error':
        final id = call.arguments['id'] as int;
        final controller = _streamMap.remove(id);
        controller?.addError(Exception(call.arguments['message'] as String));
        controller?.close();
        break;
    }
  }
}

@immutable
class ContentMetadata {
  const ContentMetadata({this.mimeType, this.fileName});

  /// Mimetype of the content
  final String? mimeType;

  /// File name of the content
  final String? fileName;
}

///
@immutable
class Content extends ContentMetadata {
  /// Byte data of the content
  final Uint8List data;

  const Content({
    required this.data,
    required super.mimeType,
    required super.fileName,
  });
}
