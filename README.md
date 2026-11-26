# content_resolver

The plugin is to resolve Android's content URI that is often used by [Content providers](https://developer.android.com/guide/topics/providers/content-providers).

## Install

Add this to your package's pubspec.yaml file and execute flutter pub get:

```yaml
dependencies:
  content_resolver: ^0.4.0
```

Version 0.4.0 requires Flutter 3.44 and Dart 3.12. The bundled example uses Flutter 3.50 and AGP 9 with built-in Kotlin.
On Flutter 3.44 with AGP 9, keep built-in Kotlin disabled in the host app. Use 0.3.6 if you cannot upgrade the Flutter SDK.

## Usage

### Resolving content

The following fragment is a use case with [app_links](https://pub.dev/packages/app_links) to receive `content:...` URI content:

```dart
_appLinks = AppLinks(onAppLink: (uri) async {
  // If the data is some image, you can pass the data directly to Image.data or something.
  final Content content = await ContentResolver.resolveContent(uri);
  ...
});
```

### Writing content

The following fragment illustrates how to write data to `content:...` URI:

```dart
  final data = Uint8List.fromList(utf8.encode('Hello World'));
  await ContentResolver.writeContent(uri.toString(), data);
  ...
```

Please note that if the URI is not writable, the code throws certain exception.
