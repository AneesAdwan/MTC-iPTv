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

  @override
  String get nowLabel => 'Now';

  @override
  String get nextLabel => 'Next';

  @override
  String get jumpToNow => 'Now';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get guideEmpty => 'No programme guide yet.';

  @override
  String get guideEmptyHint =>
      'The guide is fetched automatically when you are online.';

  @override
  String get remindMe => 'Remind me';

  @override
  String get cancelReminder => 'Cancel reminder';

  @override
  String get reminderSet => 'You will be reminded 5 minutes before it starts.';

  @override
  String get reminderRemoved => 'Reminder cancelled.';

  @override
  String reminderFired(String title) {
    return '$title starts soon';
  }

  @override
  String get watchNow => 'Watch';

  @override
  String get inboxEmpty => 'No notifications.';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get clearAll => 'Clear all';

  @override
  String get kindReminder => 'Reminder';

  @override
  String get sectionGeneral => 'General';

  @override
  String get sectionPlayer => 'Player';

  @override
  String get sectionParental => 'Parental control';

  @override
  String get sectionStorage => 'Storage & sync';

  @override
  String get sectionPrivacy => 'Privacy';

  @override
  String get showNumbers => 'Show channel numbers';

  @override
  String get maxQuality => 'Highest automatic quality';

  @override
  String get qualityNoLimit => 'No limit (up to 1080p)';

  @override
  String get parentalHint =>
      'A 4-digit PIN locks the categories you choose and channels marked for adults.';

  @override
  String get setPin => 'Set a PIN';

  @override
  String get removePin => 'Turn off';

  @override
  String get enterPin => 'Enter the PIN';

  @override
  String get newPin => 'New 4-digit PIN';

  @override
  String get pinWrong => 'Wrong PIN';

  @override
  String get lockedCategories => 'Locked categories';

  @override
  String get channelLocked => 'This channel is locked by parental control.';

  @override
  String get unlock => 'Unlock';

  @override
  String lastSync(String t) {
    return 'Last sync: $t';
  }

  @override
  String get never => 'never';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncDone => 'Sync complete.';

  @override
  String get clearHistory => 'Clear watch history';

  @override
  String get historyCleared => 'Watch history cleared.';

  @override
  String get telemetry => 'Send anonymous playback statistics';

  @override
  String get telemetryHint =>
      'Helps improve the channels. Never includes links, accounts or personal data.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get checkUpdates => 'Check for updates';

  @override
  String get upToDate => 'You have the latest version.';

  @override
  String updateAvailable(String v) {
    return 'Version $v is available.';
  }

  @override
  String get download => 'Download';

  @override
  String get updateCheckFailed => 'Could not check for updates.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyText =>
      'MTC-iPTv does not require an account and does not collect personal data. Favorites, history, reminders and settings stay on your device. If enabled, anonymous playback statistics (success or failure, start time, error type) are sent without links or identifiers to help improve the channels. Problem reports contain only what you write, plus technical details if you choose to attach them.';

  @override
  String get reportTitle => 'Report a problem';

  @override
  String get reportChannelHint =>
      'Open a channel, then press the flag button in the player to report a problem with it.';

  @override
  String get reasonNotWorking => 'Not working';

  @override
  String get reasonWrongInfo => 'Wrong information';

  @override
  String get reasonBadQuality => 'Poor quality';

  @override
  String get reasonOther => 'Other';

  @override
  String get noteHint => 'Details (optional)';

  @override
  String get attachDiag =>
      'Attach technical details (app version, system, error type — no links)';

  @override
  String get send => 'Send';

  @override
  String get reportSent => 'Thank you! Your report was sent.';

  @override
  String get reportFailed =>
      'Sending failed. Check your connection and try again.';

  @override
  String noChannelNumber(int n) {
    return 'No channel with number $n';
  }

  @override
  String get openPlayer => 'Open player';

  @override
  String get closePlayer => 'Close player';

  @override
  String get psPublished => 'Published';

  @override
  String get psPending => 'Pending review';

  @override
  String get psHidden => 'Hidden';

  @override
  String get psDraft => 'Draft';

  @override
  String get psRejected => 'Rejected';

  @override
  String get hsPlayable => 'Playable';

  @override
  String get hsReachable => 'Reachable';

  @override
  String get hsDegraded => 'Degraded';

  @override
  String get hsAuthFailed => 'Auth refused';

  @override
  String get hsUnsupported => 'Unsupported';

  @override
  String get hsNetworkError => 'Network error';

  @override
  String get hsUnavailable => 'Unavailable';

  @override
  String get hsGeoRestricted => 'Possibly restricted';

  @override
  String get hsInconclusive => 'Inconclusive';

  @override
  String get hsDisabled => 'Disabled';

  @override
  String get kpiChannels => 'Channels';

  @override
  String get kpiStreams => 'Streams';

  @override
  String get kpiWorking => 'Working';

  @override
  String get kpiFailing => 'Failing';

  @override
  String get kpiUncertain => 'Not proven';

  @override
  String get kpiOpenReports => 'Open reports';

  @override
  String get kpiEpgCoverage => 'Guide coverage';

  @override
  String kpiEpgHint(int n, int total) {
    return '$n of $total published have programmes in the next 24h';
  }

  @override
  String get streamHealth => 'Stream health';

  @override
  String get recentChanges => 'Recent changes';

  @override
  String get noChanges => 'No changes recorded yet.';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get qaReviewPending => 'Review pending';

  @override
  String get qaCheckFailing => 'Check failing streams';

  @override
  String get qaReports => 'Viewer reports';

  @override
  String get refresh => 'Refresh';

  @override
  String get addChannel => 'Add channel';

  @override
  String get searchAdminHint => 'Name, number, uid or network…';

  @override
  String get allStates => 'All states';

  @override
  String get allCountries => 'All countries';

  @override
  String get allCategories => 'All categories';

  @override
  String get fFeatured => 'Featured';

  @override
  String get fNoLogo => 'No logo';

  @override
  String get fManual => 'Manual';

  @override
  String get colNumber => '#';

  @override
  String get colName => 'Name';

  @override
  String get colCountry => 'Country';

  @override
  String get colCategory => 'Category';

  @override
  String get colStreams => 'Streams';

  @override
  String get colState => 'State';

  @override
  String get colUpdated => 'Updated';

  @override
  String pageOf(int from, int to, int total) {
    return '$from–$to of $total';
  }

  @override
  String selected(int n) {
    return '$n selected';
  }

  @override
  String get aPublish => 'Publish';

  @override
  String get aHide => 'Hide';

  @override
  String get aFeature => 'Feature';

  @override
  String get aUnfeature => 'Unfeature';

  @override
  String get aSetCategory => 'Set category';

  @override
  String get aSetCountry => 'Set country';

  @override
  String get aCheckStreams => 'Check streams';

  @override
  String get aDelete => 'Delete';

  @override
  String get aDisable => 'Disable';

  @override
  String get aEnable => 'Enable';

  @override
  String get aTry => 'Try now';

  @override
  String get aCheck => 'Check';

  @override
  String get aEdit => 'Edit';

  @override
  String get aResolve => 'Resolve';

  @override
  String get aOpenChannel => 'Open channel';

  @override
  String get aHideChannel => 'Hide channel';

  @override
  String confirmDelete(int n) {
    return 'Delete $n item(s) permanently? This cannot be undone from here (the change log keeps a copy).';
  }

  @override
  String get saved => 'Saved.';

  @override
  String saveFailed(String e) {
    return 'Saving failed: $e';
  }

  @override
  String get tabInfo => 'Info';

  @override
  String get tabStreams => 'Streams';

  @override
  String get tabGuide => 'Guide';

  @override
  String get tabHistory => 'History';

  @override
  String get fNameAr => 'Arabic name';

  @override
  String get fNameEn => 'English name';

  @override
  String get fAltNames => 'Alternative names (comma separated)';

  @override
  String get fNumber => 'Number';

  @override
  String get fNetwork => 'Network';

  @override
  String get fLogoUrl => 'Logo URL';

  @override
  String get fLanguage => 'Language code';

  @override
  String get fQuality => 'Quality';

  @override
  String get fDescription => 'Description';

  @override
  String get fWebsite => 'Website';

  @override
  String get fEpgId => 'EPG id (empty = uid)';

  @override
  String get fEpgOffset => 'EPG offset (minutes)';

  @override
  String get fParental => 'Adults only (parental lock)';

  @override
  String get fPublishState => 'Publish state';

  @override
  String get addStream => 'Add stream';

  @override
  String get fUrl => 'Stream URL';

  @override
  String get fLabel => 'Server name (optional)';

  @override
  String get fUserAgent => 'User-Agent (optional)';

  @override
  String get fReferrer => 'Referer (optional)';

  @override
  String get dragToReorder =>
      'Drag to set the order: the player tries the top server first.';

  @override
  String get noStreamsAdmin => 'No streams for this channel.';

  @override
  String lastChecked(String t) {
    return 'Checked $t';
  }

  @override
  String get neverChecked => 'Not checked yet';

  @override
  String checkRunning(int done, int total) {
    return 'Checking $done of $total…';
  }

  @override
  String checkDone(int done) {
    return 'Check finished: $done streams.';
  }

  @override
  String get checkOffline =>
      'Check stopped: no internet on this computer, nothing was recorded.';

  @override
  String get stop => 'Stop';

  @override
  String get playCheck => 'Playback check (mpv)';

  @override
  String get playCheckHint =>
      'Layer 1 proves the server answers; layer 2 proves a real video frame arrives.';

  @override
  String get noStreamsInState => 'No streams in this state.';

  @override
  String get noOpenReports => 'No open reports.';

  @override
  String reportsCount(int n) {
    return '$n reports';
  }

  @override
  String get epgPreviewHint =>
      'Programmes stored on this device for this channel.';

  @override
  String get noEpgForChannel => 'No programmes for this channel.';

  @override
  String notAvailableYet(int p) {
    return 'Arrives with phase $p.';
  }

  @override
  String reasonLabel(String r) {
    return 'Reason: $r';
  }
}
