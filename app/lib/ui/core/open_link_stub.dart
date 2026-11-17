import 'dart:io';

void openLink(String url) {
  if (Platform.isWindows) {
    Process.run('cmd', ['/c', 'start', '', url]);
    return;
  }
  if (Platform.isMacOS) {
    Process.run('open', [url]);
    return;
  }
  Process.run('xdg-open', [url]);
}
