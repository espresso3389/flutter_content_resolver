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

  static const MethodChannel _channel = const MethodChannel('content_resolver');

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
}

///
@immutable
class Content {
  /// Byte data of the content
  final Uint8List data;

  /// Mimetype of the content
  final String? mimeType;

  /// File name of the content
  final String? fileName;

  const Content({
    required this.data,
    required this.mimeType,
    required this.fileName,
  });
}
