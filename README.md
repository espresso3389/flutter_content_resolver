# content_resolver

The plugin is to resolve Android's content URI that is often used by [Content providers](https://developer.android.com/guide/topics/providers/content-providers).

# Install

Add this to your package's pubspec.yaml file and execute flutter pub get:

```
dependencies:
    content_resolver: ^0.0.2
```

# Usage

The following fragment is a use case with [app_links](https://pub.dev/packages/app_links) to receive `content:...` URI content:

```dart
_appLinks = AppLinks(onAppLink: (uri) async {
  // If the data is some image, you can pass the data directly to Image.data or something.
  final Uint8List data = await ContentResolver.resolveContent(uri);
  ...
});
```
