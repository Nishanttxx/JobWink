import 'theme_web_stub.dart'
    if (dart.library.js_interop) 'theme_web_impl.dart';

bool getBrowserIsDarkMode() => getSystemIsDarkMode();
void setBrowserThemeAttribute(String themeStr) => syncWebTheme(themeStr);
