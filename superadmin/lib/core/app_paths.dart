// Where SuperAdmin keeps its local files.
//
// Decision: the folder is chosen HERE, not derived from the exe's ProductName. The interim SuperAdmin
// (built from mtc_iptv/) has the same ProductName "MTC-iPTv SuperAdmin" + CompanyName "MTC-Group", so
// path_provider would give both programs %APPDATA%\MTC-Group\MTC-iPTv SuperAdmin and they would share
// files. The new program uses %APPDATA%\MTC-Group\mtc_superadmin2 (matches InternalName in Runner.rc)
// and does not use path_provider / shared_preferences at all.
//
// Only harmless per-device preferences live here (language, theme, saved table views). The login
// session is kept in memory only: every launch asks for password + TOTP (plan §9.1).
import 'dart:io';

abstract final class AppPaths {
  static const folderName = 'mtc_superadmin2';

  static Directory supportDir() {
    final appData = Platform.environment['APPDATA'];
    final base = (appData != null && appData.isNotEmpty) ? appData : Directory.systemTemp.path;
    return Directory('$base${Platform.pathSeparator}MTC-Group${Platform.pathSeparator}$folderName');
  }
}
