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

  @override
  String get adminSignIn => 'Admin sign-in';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get mfaEnrollTitle => 'Turn on two-step verification';

  @override
  String get mfaEnrollBody =>
      'Scan the code with an authenticator app (Google Authenticator, Microsoft Authenticator, …), then enter the 6-digit code. Keep the secret key somewhere safe: you need it if you lose your phone.';

  @override
  String get mfaSecret => 'Secret key';

  @override
  String get mfaCodeTitle => 'Verification code';

  @override
  String get mfaCodeBody =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get mfaCode => 'Code';

  @override
  String get verify => 'Verify';

  @override
  String get notAdminTitle => 'This account is not the admin';

  @override
  String get notAdminBody =>
      'The admin center is only available to the admin account.';

  @override
  String noBackendBody(String env) {
    return 'No server is configured for this environment ($env).';
  }

  @override
  String get authFailed => 'Sign-in failed: check the email and password.';

  @override
  String get codeFailed => 'The code is wrong or expired.';

  @override
  String get copied => 'Copied';

  @override
  String get featured => 'Featured';

  @override
  String get recentlyAdded => 'Recently added';

  @override
  String get continueWatching => 'Continue watching';

  @override
  String get allChannels => 'All channels';

  @override
  String get seeAll => 'See all';

  @override
  String get catalogEmpty => 'No channels on this device yet.';

  @override
  String get catalogEmptyHint =>
      'Channels are fetched automatically when you are online.';

  @override
  String get syncing => 'Syncing channels…';

  @override
  String get filterAll => 'All';

  @override
  String get country => 'Country';

  @override
  String get category => 'Category';

  @override
  String channelsCount(int n) {
    return '$n channels';
  }

  @override
  String get searchChannelsHint => 'Search by channel name or number…';

  @override
  String get noMatches => 'No matching channels.';

  @override
  String get favoritesEmpty => 'No favorite channels yet.';

  @override
  String get favoritesEmptyHint => 'Tap ♥ on any channel to add it here.';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String serverOf(int i, int n) {
    return 'Server $i of $n';
  }

  @override
  String get switchingServer => 'Switching to another server…';

  @override
  String get loadingStream => 'Loading…';

  @override
  String get quality => 'Quality';

  @override
  String get auto => 'Auto';

  @override
  String get audioTrack => 'Audio';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get off => 'Off';

  @override
  String get nextChannel => 'Next channel';

  @override
  String get prevChannel => 'Previous channel';

  @override
  String get fullscreen => 'Full screen';

  @override
  String get exitFullscreen => 'Exit full screen';

  @override
  String get retry => 'Retry';

  @override
  String get tryNextServer => 'Try another server';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get errAuthFailed =>
      'The server refused access (the channel may be protected or need a subscription).';

  @override
  String get errUnavailable =>
      'The channel is not available on this server right now.';

  @override
  String get errUnsupported => 'This stream format is not supported.';

  @override
  String get errNetwork =>
      'The server is not responding. Check your connection or try later.';

  @override
  String get errGeneric => 'The channel could not be played.';

  @override
  String allServersFailed(int n) {
    return 'All servers ($n) were tried without success.';
  }

  @override
  String get noServers => 'This channel has no streams.';

  @override
  String get back => 'Back';

  @override
  String channelNumber(int n) {
    return 'Channel $n';
  }
}
