// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MTC-iPTv';

  @override
  String get company => 'Middle East Technology Center Group — MTC-Group';

  @override
  String get developedBy => 'Developed by: Anees Adwan';

  @override
  String version(String v) {
    return 'Version $v';
  }

  @override
  String get groupViewer => 'Watch';

  @override
  String get groupAdmin => 'Admin';

  @override
  String get groupA => 'Overview';

  @override
  String get groupB => 'Catalog';

  @override
  String get groupC => 'Import & Transform';

  @override
  String get groupD => 'Quality';

  @override
  String get groupE => 'Program Guide';

  @override
  String get groupF => 'Communication';

  @override
  String get groupG => 'Settings';

  @override
  String get groupH => 'Security & System';

  @override
  String get groupI => 'Reports';

  @override
  String get sV01 => 'Splash';

  @override
  String get sV02 => 'Home';

  @override
  String get sV03 => 'Channels';

  @override
  String get sV04 => 'Countries';

  @override
  String get sV05 => 'Search';

  @override
  String get sV06 => 'Watch';

  @override
  String get sV07 => 'TV Guide';

  @override
  String get sV08 => 'Favorites';

  @override
  String get sV09 => 'Notifications';

  @override
  String get sV10 => 'Settings';

  @override
  String get sV11 => 'About';

  @override
  String get sV12 => 'Report a problem';

  @override
  String get sA1 => 'Dashboard';

  @override
  String get sA2 => 'Jobs & Queues';

  @override
  String get sA3 => 'Alerts';

  @override
  String get sB1 => 'Channels';

  @override
  String get sB2 => 'Channel details';

  @override
  String get sB3 => 'Streams & Servers';

  @override
  String get sB4 => 'Home layout';

  @override
  String get sB5 => 'Taxonomy';

  @override
  String get sB6 => 'Networks & Logos';

  @override
  String get sB7 => 'Numbering';

  @override
  String get sC1 => 'Import wizard';

  @override
  String get sC2 => 'Import review';

  @override
  String get sC3 => 'Sources';

  @override
  String get sC4 => 'External references';

  @override
  String get sC5 => 'Export';

  @override
  String get sC6 => 'Transform rules';

  @override
  String get sD1 => 'Pending review';

  @override
  String get sD2 => 'Duplicates & Merge';

  @override
  String get sD3 => 'Compare';

  @override
  String get sD4 => 'Stream health';

  @override
  String get sD5 => 'Logos';

  @override
  String get sD6 => 'Viewer reports';

  @override
  String get sE1 => 'EPG sources';

  @override
  String get sE2 => 'Channel mapping';

  @override
  String get sE3 => 'Schedule preview';

  @override
  String get sF1 => 'Notifications';

  @override
  String get sF2 => 'Announcements';

  @override
  String get sG1 => 'Brand';

  @override
  String get sG2 => 'Social media';

  @override
  String get sG3 => 'General settings';

  @override
  String get sG4 => 'Player & Network';

  @override
  String get sG5 => 'Features & Maintenance';

  @override
  String get sG6 => 'Releases & Updates';

  @override
  String get sH1 => 'Account & Security';

  @override
  String get sH2 => 'Scheduled tasks';

  @override
  String get sH3 => 'Audit log';

  @override
  String get sH4 => 'Backups';

  @override
  String get sH5 => 'Maintenance & Diagnostics';

  @override
  String get sI1 => 'Analytics';

  @override
  String get searchHint => 'Search everything…';

  @override
  String get searchShortcut => 'Ctrl+K';

  @override
  String get paletteHint => 'Type a screen or command…';

  @override
  String get noResults => 'No results';

  @override
  String get collapse => 'Collapse sidebar';

  @override
  String get expand => 'Expand sidebar';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdle => 'No running jobs';

  @override
  String get minimize => 'Minimize';

  @override
  String get maximize => 'Maximize';

  @override
  String get restore => 'Restore';

  @override
  String get close => 'Close';

  @override
  String get placeholderTitle => 'Under construction';

  @override
  String placeholderBody(String id, String phase) {
    return 'This screen ($id) is built in phase $phase of the plan.';
  }

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get cmdToggleLanguage => 'Toggle language';

  @override
  String get cmdToggleTheme => 'Toggle theme';

  @override
  String get cmdToggleSidebar => 'Collapse/expand sidebar';
}
