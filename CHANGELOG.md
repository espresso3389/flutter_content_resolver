## 0.3.3

- Merge PR #6: Disable build-id link option to allow reproducible builds

## 0.3.2

- Android build environment updates

## 0.3.1

- Update build.gradle to support recent Flutter

## 0.3.0

- BREAKING CHANGE: ContentResolver.resolveContent now returns Content object rather than Uint8List.
- Update example code to handle ACTION_SEND also.

## 0.2.0

- Fixes and updates.

## 0.1.0

- Add `ContentResolver.writeContent` (#1)

## 0.0.2

- To deal with problematic URIs like Slack's content URI (content://com.Slack.fileprovider/...; that contains capitalized letter on its host name), we should not use Dart's Uri class.

## 0.0.1

- Initial release.
