import 'package:web/web.dart' as web;

bool getSystemIsDarkMode() {
  try {
    return web.window.matchMedia('(prefers-color-scheme: dark)').matches;
  } catch (_) {
    return false;
  }
}

void syncWebTheme(String themeStr) {
  try {
    web.document.documentElement?.setAttribute('data-theme', themeStr);
  } catch (_) {}
}
