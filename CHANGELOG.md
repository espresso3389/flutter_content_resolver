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
