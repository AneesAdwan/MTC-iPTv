// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get dcTitle => 'Decide per channel';

  @override
  String get dcOpen => 'Decisions';

  @override
  String get dcHint =>
      'Choose what happens to each channel, edit its name, number or tags if needed, then Apply. Nothing runs before the summary.';

  @override
  String get dcKeep => 'Keep as is';

  @override
  String get dcPublish => 'Keep and publish';

  @override
  String get dcHide => 'Hide';

  @override
  String get dcMerge => 'Merge its streams into…';

  @override
  String dcMergeInto(String name) {
    return 'Merge into: $name';
  }

  @override
  String get dcTrash => 'Recycle bin';

  @override
  String get dcEdit => 'Edit';

  @override
  String get dcDistinct =>
      'The remaining channels are not duplicates (don\'t show them here again)';

  @override
  String get dcSummary => 'Summary';

  @override
  String get dcApply => 'Apply';

  @override
  String get dcNothing => 'No changes chosen.';

  @override
  String get dcDone => 'Decisions applied.';

  @override
  String dcStreams(int ok, int n) {
    return '$ok of $n streams working';
  }

  @override
  String dcLineEdit(String name) {
    return 'Edit details: $name';
  }

  @override
  String dcLinePublish(String name) {
    return 'Publish: $name';
  }

  @override
  String dcLineHide(String name) {
    return 'Hide: $name';
  }

  @override
  String dcLineMerge(String name, String into) {
    return 'Merge $name into $into (its streams become extra servers; it is hidden — undoable)';
  }

  @override
  String dcLineTrash(String name) {
    return 'Recycle bin: $name (restorable for 30 days)';
  }

  @override
  String dcLineDistinct(int n) {
    return 'Mark the rest as not duplicates: $n channel(s)';
  }

  @override
  String get dcMergeChain =>
      'Can\'t merge into a channel that is itself merged, binned or hidden.';

  @override
  String get aTrash => 'Move to bin';

  @override
  String get aRestore => 'Restore';

  @override
  String get aPurge => 'Delete forever';

  @override
  String get trashFilter => 'Recycle bin';

  @override
  String confirmTrash(int n) {
    return 'Move $n channel(s) to the recycle bin? They disappear from the apps now, can be restored for 30 days, then are deleted for good.';
  }

  @override
  String confirmPurge(int n) {
    return 'Delete $n channel(s) and their streams for good? This cannot be undone.';
  }

  @override
  String inTrashSince(String d, int n) {
    return 'In the bin since $d · deleted for good in $n days';
  }

  @override
  String get trashEmpty => 'The recycle bin is empty.';

  @override
  String get trashHint =>
      'Deleted channels stay here for 30 days, then are removed automatically. Restoring brings back their state and number (if still free).';

  @override
  String get selectPage => 'Select shown';

  @override
  String selectAllMatching(int n) {
    return 'Select all results ($n)';
  }

  @override
  String get invertSelection => 'Invert selection';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String selectedOf(int n, int total) {
    return '$n of $total selected';
  }

  @override
  String get plErrHint =>
      'The stream may be temporarily down or blocked in your region. Try later or pick another channel.';

  @override
  String get plLive => 'LIVE';

  @override
  String get plChannels => 'Channel list';

  @override
  String get plSettings => 'Settings';

  @override
  String get plServer => 'Server';

  @override
  String get plOtherServer => 'Another server';

  @override
  String get plCantPlay => 'Can\'t play this channel';

  @override
  String get plStats => 'Stream info';

  @override
  String get plShortcuts => 'Keyboard shortcuts';

  @override
  String get plVolume => 'Volume';

  @override
  String get plSameCategory => 'Same category';

  @override
  String get plSameCountry => 'Same country';

  @override
  String get plResolution => 'Resolution';

  @override
  String get plCodec => 'Codec';

  @override
  String get plDecoder => 'Decoder';

  @override
  String get plBuffer => 'Buffer';

  @override
  String get plKeyPlay => 'Play / pause';

  @override
  String get plKeyChannel => 'Previous / next channel';

  @override
  String get plKeyVolume => 'Volume up / down';

  @override
  String get plKeyDigits => 'Type a channel number';

  @override
  String get plKeyServer => 'Another server';

  @override
  String get plKeyHelp => 'Show shortcuts';

  @override
  String get plNotWorking => 'not working';

  @override
  String get plChannelsHint => '↑ ↓ to move · Enter to play · G to close';

  @override
  String get accountMenu => 'Account';

  @override
  String get signOutConfirm => 'Sign out of the admin account on this device?';

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get numPad => 'Number pad';

  @override
  String get numPadHint => 'Type a channel number';

  @override
  String get numPadGo => 'Go';

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
      'MTC-iPTv does not require an account and does not collect your name, email, IP address, precise location or any advertising ID. Favorites, history, reminders and settings stay on your device.\n\nIf statistics are enabled, the app sends for each playback attempt: the server used (not its link), success or failure and the error type, start time, watch time (rounded) and resolution — with a random device ID, platform, app version, app language and an approximate country. Raw events are kept for 30 days, then only daily totals without device IDs; the device record is deleted 90 days after it was last seen. You can turn statistics off or reset the device ID (which deletes the previous one) in Settings.\n\nProblem reports contain only what you write, plus technical details if you choose to attach them.';

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

  @override
  String get bkUnchecked => 'Not checked';

  @override
  String get bkReady => 'Ready to publish';

  @override
  String get bkDuplicate => 'Duplicates';

  @override
  String get bkOffline => 'Not working';

  @override
  String get bkLogo => 'Broken logo';

  @override
  String get bkIncomplete => 'Incomplete';

  @override
  String get bkUncheckedHint =>
      'Their streams were not checked yet: check the bucket and they sort themselves.';

  @override
  String get bkReadyHint =>
      'Streams work and they are not duplicates. Review, then approve.';

  @override
  String get bkDuplicateHint =>
      'Same channel as one already in the catalog: merge (its streams become extra servers) or mark as not a duplicate.';

  @override
  String get bkOfflineHint =>
      'No working stream. Reject, or keep waiting for a re-check.';

  @override
  String get bkLogoHint => 'The logo does not load. Fix it before publishing.';

  @override
  String get bkIncompleteHint =>
      'Working channels without a country. Edit them before publishing.';

  @override
  String get reviewEmpty => 'Nothing is waiting for review.';

  @override
  String get aApprove => 'Approve & publish';

  @override
  String get aReject => 'Reject (to bin)';

  @override
  String get aMerge => 'Merge into original';

  @override
  String get aNotDuplicate => 'Not a duplicate';

  @override
  String aAllInBucket(int n) {
    return 'All in this bucket ($n)';
  }

  @override
  String originalOf(String name) {
    return 'Original: $name';
  }

  @override
  String streamsWorking(int ok, int n) {
    return '$ok/$n working';
  }

  @override
  String confirmReject(int n) {
    return 'Reject $n channel(s) and move them to the recycle bin? Restorable for 30 days.';
  }

  @override
  String doneCount(int n) {
    return 'Done: $n.';
  }

  @override
  String get numOrderBy => 'Order by';

  @override
  String get nkArab => 'Arab countries first';

  @override
  String get nkCountry => 'Country';

  @override
  String get nkCategory => 'Category';

  @override
  String get nkLanguage => 'Language';

  @override
  String get nkFeatured => 'Featured first';

  @override
  String get nkQuality => 'Quality';

  @override
  String get nkOnline => 'Working streams';

  @override
  String get nkName => 'Name';

  @override
  String get nkCurrent => 'Current number';

  @override
  String get nkNewest => 'Newest';

  @override
  String get nkSortOrder => 'Display order';

  @override
  String get numStart => 'First number';

  @override
  String get numBlock => 'Block per group (0 = continuous)';

  @override
  String get numPublishedFirst => 'Published channels first';

  @override
  String get numPreview => 'Preview';

  @override
  String get numApply => 'Apply';

  @override
  String numSummary(int changed, int total, int max) {
    return '$changed of $total channels change number · last number $max';
  }

  @override
  String numConfirm(int n) {
    return 'Renumber $n channels? Viewers will see the new numbers after their next sync.';
  }

  @override
  String numApplied(int n) {
    return 'Renumbered $n channels.';
  }

  @override
  String get numHint =>
      'Choose the order, preview, then apply. The whole change happens at once on the server, and every channel\'s old number stays in its history.';

  @override
  String get tabCategories => 'Categories';

  @override
  String get tabCountries => 'Countries';

  @override
  String get tabLanguages => 'Languages';

  @override
  String get fSlug => 'Id';

  @override
  String get fIcon => 'Icon';

  @override
  String get fHue => 'Colour (0–360)';

  @override
  String get fSort => 'Order';

  @override
  String get fVisible => 'Visible';

  @override
  String get fFlag => 'Flag';

  @override
  String get fContinent => 'Continent';

  @override
  String get fArab => 'Arab country';

  @override
  String usedBy(int n) {
    return '$n channels';
  }

  @override
  String cannotDeleteUsed(int n) {
    return 'Used by $n channels — move them first.';
  }

  @override
  String get addItem => 'Add';

  @override
  String get hostFilter => 'Host…';

  @override
  String get allProtocols => 'All protocols';

  @override
  String get fCredentials => 'With credentials';

  @override
  String get hostsTitle => 'Hosts';

  @override
  String get jobsRunning => 'Running now';

  @override
  String get jobsHistory => 'Recent runs';

  @override
  String get jobsScheduled => 'Scheduled tasks';

  @override
  String get noRuns => 'No runs recorded yet.';

  @override
  String taskEvery(int m) {
    return 'every $m min';
  }

  @override
  String taskLast(String t) {
    return 'last run $t';
  }

  @override
  String get tkHealthPublished => 'Check published streams';

  @override
  String get tkHealthAll => 'Check all streams';

  @override
  String get tkPlaybackSample => 'Playback sample';

  @override
  String get tkLogos => 'Check logos';

  @override
  String get tkEpg => 'Programme guide sync';

  @override
  String get tkSources => 'Refresh sources';

  @override
  String get tkBackup => 'Backup';

  @override
  String get schedulerNote =>
      'The scheduler that runs these automatically arrives with phase 6 (ADM-H2). Manual checks are recorded here.';

  @override
  String get hlHero => 'Now showing (hero)';

  @override
  String get hlHeroHint =>
      'One or more channels shown large at the top of Home; several rotate every 8 seconds.';

  @override
  String get hlRows => 'Home rows';

  @override
  String get hlAddRow => 'Add row';

  @override
  String get hlPublishHint => 'Saved changes reach viewers at their next sync.';

  @override
  String get hlReset => 'Reset to default';

  @override
  String get rtFeatured => 'Featured';

  @override
  String get rtHistory => 'Continue watching (per viewer)';

  @override
  String get rtFavorites => 'Favorites (per viewer)';

  @override
  String get rtRecent => 'Recently added';

  @override
  String get rtCategoriesAuto => 'Category rows (automatic)';

  @override
  String get rtCategory => 'One category';

  @override
  String get rtCountry => 'One country';

  @override
  String get rtManual => 'Hand-picked channels';

  @override
  String get rtAll => 'All channels';

  @override
  String get fTitleAr => 'Title (Arabic, optional)';

  @override
  String get fTitleEn => 'Title (English, optional)';

  @override
  String get fCount => 'Channels in row';

  @override
  String get fFrom => 'Show from';

  @override
  String get fTo => 'Show until';

  @override
  String get addChannels => 'Add channels';

  @override
  String get pickChannel => 'Pick a channel';

  @override
  String netChannels(int n) {
    return '$n channels';
  }

  @override
  String get netRename => 'Rename';

  @override
  String get netNewName => 'New name (empty = remove the network)';

  @override
  String get logoLibraryLater =>
      'The logo library (upload to storage, WebP sizes) arrives with the storage setup in phase 6.';

  @override
  String dupGroups(int n) {
    return '$n groups of duplicates';
  }

  @override
  String get noDuplicates => 'No duplicates found.';

  @override
  String get aCompare => 'Compare';

  @override
  String get aHideOthers => 'Hide the others';

  @override
  String get aMergeHere => 'Merge into this one';

  @override
  String mergeTitle(String name) {
    return 'Merge into: $name';
  }

  @override
  String mergePreview(int s, int c) {
    return '$s streams move to it · $c channels are hidden (not deleted)';
  }

  @override
  String get mergeFieldsHint => 'Fields that differ: choose the value to keep.';

  @override
  String get mergeUndoHint =>
      'Merged channels stay hidden with a link to this one, and the merge can be undone from its page.';

  @override
  String get mergedHere => 'Merged into this channel';

  @override
  String get aUnmerge => 'Undo merge';

  @override
  String get compareHint =>
      'Pick 2–4 channels from Duplicates or Channels to compare them here.';

  @override
  String get playSideBySide => 'Play side by side';

  @override
  String get diffOnly => 'Differences only';

  @override
  String get compareMoreLater =>
      'Comparing sources and snapshots arrives with import (phase 5).';

  @override
  String get lgBroken => 'Broken';

  @override
  String get lgMissing => 'No logo';

  @override
  String get lgUnchecked => 'Not checked';

  @override
  String get lgOk => 'Working';

  @override
  String get checkLogos => 'Check logos';

  @override
  String logoChecking(int done, int total) {
    return 'Checking logos $done/$total…';
  }

  @override
  String get logoMoreLater =>
      'Logo suggestions from iptv-org and copying logos to storage arrive with phases 5 and 6.';

  @override
  String get setLogo => 'Set logo';

  @override
  String get imFile => 'File';

  @override
  String get imUrl => 'Link';

  @override
  String get imPaste => 'Paste';

  @override
  String get imXtream => 'Xtream account';

  @override
  String get imChooseFiles => 'Choose a file…';

  @override
  String get imPasteHint => 'Paste M3U, CSV, JSON or links (one per line)…';

  @override
  String get imAnalyze => 'Analyze';

  @override
  String get imXServer => 'Server (http://host:port)';

  @override
  String get imXUser => 'Username';

  @override
  String get imXPass => 'Password';

  @override
  String get imXtreamNote =>
      'The account is used once for this import and is not saved.';

  @override
  String get imAnalyzing => 'Analyzing…';

  @override
  String imFormat(String f, String e) {
    return 'Format $f · encoding $e';
  }

  @override
  String imIssues(int n) {
    return 'Lines that could not be read ($n)';
  }

  @override
  String get kNew => 'New channels';

  @override
  String get kUpdate => 'Add to existing';

  @override
  String get kExisting => 'Already in catalog';

  @override
  String get kInFile => 'Duplicate in file';

  @override
  String get kFailed => 'Not supported';

  @override
  String imCommit(int n) {
    return 'Import selected ($n)';
  }

  @override
  String get imCommitHint =>
      'Nothing is written until you import. New channels go to Pending review; existing channels only get the new streams (your edits stay as they are).';

  @override
  String get imDone => 'Import finished';

  @override
  String imResult(int channels, int streams, int disabled) {
    return '$channels channels and $streams streams added · $disabled streams disabled';
  }

  @override
  String get imGoReview => 'Open pending review';

  @override
  String get imNew => 'New import';

  @override
  String imVanished(int n) {
    return '$n streams of this source are no longer in it';
  }

  @override
  String get imDisableVanished => 'Disable them (not delete)';

  @override
  String get imPossibleDup => 'possible duplicate';

  @override
  String get imAll => 'All';

  @override
  String get imNone => 'None';

  @override
  String get srcAdd => 'Add source';

  @override
  String get srcName => 'Name';

  @override
  String get srcUrl => 'Playlist link (https)';

  @override
  String get srcRefresh => 'Fetch & review';

  @override
  String srcLast(String t) {
    return 'Last import $t';
  }

  @override
  String srcCounts(int c, int s) {
    return '$c channels · $s streams';
  }

  @override
  String get srcRemove => 'Remove source';

  @override
  String get srcRemoveConfirm =>
      'Remove this source? Its streams and channels stay in the catalog.';

  @override
  String get srcActive => 'Active';

  @override
  String get srcScheduleLater =>
      'Automatic refresh on a schedule arrives with the scheduler (phase 6). For now: Fetch & review.';

  @override
  String get srcEmpty => 'No sources yet.';

  @override
  String get exFormat => 'Format';

  @override
  String get exWorkingOnly => 'Working streams only';

  @override
  String get exBestOnly => 'Best stream only';

  @override
  String get exSkipCreds => 'Leave out links with credentials';

  @override
  String get exExport => 'Export…';

  @override
  String exDone(int n) {
    return 'Exported $n channels.';
  }

  @override
  String exChannels(int n) {
    return '$n channels match';
  }

  @override
  String get needsMigration =>
      'This needs a server migration that is not applied yet.';

  @override
  String get resetInstallId => 'Reset device ID';

  @override
  String get resetInstallIdHint =>
      'Creates a new random ID and deletes the previous one and its statistics from the server.';

  @override
  String get resetInstallIdDone => 'A new device ID was created';

  @override
  String get reset => 'Reset';

  @override
  String get kpiSuccess24h => 'Playback success (24h)';

  @override
  String kpiSampleLow(int n) {
    return 'Sample too small ($n attempts)';
  }

  @override
  String kpiAttempts(int n) {
    return '$n attempts';
  }

  @override
  String get kpiDevices7 => 'Active devices (7 days)';

  @override
  String get tkTelemetryRollup => 'Playback statistics rollup';

  @override
  String get tkAlerts => 'Alerts check';

  @override
  String get alEpgFailed => 'Guide update failed';

  @override
  String get alEpgStale => 'Guide not updated for 48 hours';

  @override
  String get alSourceFailed => 'Source failing';

  @override
  String get alImportFailed => 'Import failed';

  @override
  String get alSuccessDrop => 'Playback success dropped';

  @override
  String get alBackupFailed => 'Backup failed';

  @override
  String get alBackupStale => 'No backup for 48 hours';

  @override
  String get alRepeatedReports => 'Repeated reports';

  @override
  String get alConnectorStopped => 'Connector stopped automatically';

  @override
  String get alTaskFailed => 'Scheduled task failed';

  @override
  String alSuccessDetail(String rate, String prev, String attempts) {
    return 'Yesterday $rate (previous week $prev) from $attempts attempts';
  }

  @override
  String alReportsDetail(String name, String count) {
    return '$name: $count open reports in 24 hours';
  }

  @override
  String get alAlreadyOpen =>
      'An open alert for the same condition already exists.';

  @override
  String get alOpen => 'Open';

  @override
  String get alNew => 'New';

  @override
  String get alSeen => 'Seen';

  @override
  String get alResolved => 'Resolved';

  @override
  String get alAll => 'All';

  @override
  String get alScanNow => 'Check now';

  @override
  String get alMarkAllSeen => 'Mark all seen';

  @override
  String get alHint =>
      'The scheduler checks the conditions every hour. A problem stays one alert whose count grows, and is resolved only by you.';

  @override
  String get alNone => 'No alerts.';

  @override
  String alTimes(int n) {
    return '$n times';
  }

  @override
  String alFirst(String t) {
    return 'First $t';
  }

  @override
  String alLast(String t) {
    return 'Last $t';
  }

  @override
  String get alOpenItem => 'Open';

  @override
  String get alReopen => 'Reopen';

  @override
  String anDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get anAttempts => 'Attempts';

  @override
  String get anSuccesses => 'Succeeded';

  @override
  String get anRate => 'Success rate';

  @override
  String get anViews => 'Views (≥ 30s)';

  @override
  String get anHours => 'Watch hours';

  @override
  String get anTtff50 => 'Start time (median)';

  @override
  String get anTtff90 => 'Start time (P90)';

  @override
  String get anExport => 'Export CSV (opens in Excel)';

  @override
  String get anNoData => 'No data yet.';

  @override
  String get anHint =>
      'From real playback only (not checks). Rates show only with enough samples; start time across days is approximate.';

  @override
  String anDevices30(int n) {
    return '$n in 30 days';
  }

  @override
  String get anTopChannels => 'Most watched';

  @override
  String get anChannel => 'Channel';

  @override
  String get anWorstChannels => 'Lowest success';

  @override
  String anMinSample(int n) {
    return 'Channels with at least $n attempts.';
  }

  @override
  String get anByHost => 'By server (host)';

  @override
  String get anHost => 'Host';

  @override
  String get anByPlatform => 'By platform';

  @override
  String get anPlatform => 'Platform';

  @override
  String get anByCountry => 'By country';

  @override
  String get anCountry => 'Country';

  @override
  String get anByDay => 'By day';

  @override
  String get anDay => 'Day';

  @override
  String get anDevices => 'Devices and versions';

  @override
  String get anGroup => 'Group';

  @override
  String get anValue => 'Value';

  @override
  String get anCount => 'Count';

  @override
  String get anVersion => 'Version';

  @override
  String get anLanguage => 'Language';

  @override
  String anDevicesLine(int a7, int a30) {
    return 'Active: $a7 in 7 days, $a30 in 30 days';
  }

  @override
  String anReportsLine(int total, int open) {
    return '$total reports in the period, $open still open';
  }

  @override
  String get anReason => 'Reason';

  @override
  String get anActivity => 'Task activity (import, checks, guide, backups…)';

  @override
  String get anTask => 'Task';

  @override
  String get anOk => 'Succeeded';

  @override
  String get anFailed => 'Failed';

  @override
  String get copy => 'Copy';

  @override
  String get pictureInPicture => 'Picture-in-picture';

  @override
  String get favSyncTitle => 'Favorites sync';

  @override
  String get favSyncCreate => 'Sync favorites across your devices';

  @override
  String get favSyncCreateHint =>
      'No account needed: you get an 8-character code to enter on your other device.';

  @override
  String get favSyncCreateBtn => 'Create code';

  @override
  String get favSyncJoin => 'Link with a code from another device';

  @override
  String get favSyncJoinShort => 'Enter the code or the edit key.';

  @override
  String get favSyncJoinHint =>
      'The code alone brings the other device\'s favorites and adds them to yours. The edit key (code, then -, then the secret) makes both devices share one list they both edit.';

  @override
  String get favSyncLink => 'Link';

  @override
  String get favSyncBadCode => 'Invalid code';

  @override
  String get favSyncLinked => 'Linked and favorites fetched.';

  @override
  String get favSyncNotFound => 'No favorites with this code.';

  @override
  String get favSyncFailed => 'Sync failed. Try again later.';

  @override
  String get favSyncCode => 'Code';

  @override
  String get favSyncOwnerHint =>
      'Every change uploads automatically. Give the code to another device to fetch the list, or the edit key to edit it too.';

  @override
  String get favSyncFollowerHint =>
      'This device fetches the list on every start and adds it to its favorites, without editing it.';

  @override
  String get favSyncCopyKey => 'Copy edit key';

  @override
  String get favSyncUnlink => 'Unlink';

  @override
  String get favSyncUnlinkHint =>
      'Your favorites on this device stay as they are.';

  @override
  String get favSyncDeleteRemote =>
      'Also delete the shared list from the server';

  @override
  String get anEmpty =>
      'No playback statistics yet. They appear once users watch with the new version and the day is rolled up.';

  @override
  String get epgAddSource => 'Add source';

  @override
  String get epgSyncNow => 'Sync now';

  @override
  String epgSyncing(int done, int total, String name) {
    return 'Syncing $done/$total: $name';
  }

  @override
  String epgSummary(int c, int p) {
    return '$c channels · $p programmes';
  }

  @override
  String epgEvery(int h) {
    return 'every $h h';
  }

  @override
  String get epgGithubNote =>
      'The iptv-org grabber still runs on GitHub (it needs Node). These XMLTV sources run from this program; each one fills the channels the previous ones missed.';

  @override
  String get epgSourceUrl => 'XMLTV link (.xml or .xml.gz)';

  @override
  String get epgPriority => 'Order (smaller first)';

  @override
  String get epgIntervalHours => 'Every (hours)';

  @override
  String mapMissing(int n) {
    return '$n published channels have no programmes in the next 24 hours';
  }

  @override
  String get mapLoad => 'Load suggestions from the sources';

  @override
  String get mapLink => 'Link';

  @override
  String mapLinkAll(int n) {
    return 'Link all exact matches ($n)';
  }

  @override
  String get mapNone => 'No suggestion';

  @override
  String get mapHint =>
      'Linking sets the channel\'s EPG id (by id, not by name). Programmes arrive at the next sync.';

  @override
  String e3Issues(int g, int o) {
    return '$g gaps · $o overlaps';
  }

  @override
  String get e3Offset => 'Offset (minutes)';

  @override
  String get e3OffsetHint =>
      'Applied to programmes written from the next sync by this program.';

  @override
  String e3Gap(int m) {
    return 'Gap of $m min';
  }

  @override
  String e3Overlap(int m) {
    return 'Overlap of $m min';
  }

  @override
  String get rkGroupCategory => 'group-title → category';

  @override
  String get rkNameCountry => 'Name → country';

  @override
  String get rkNameLanguage => 'Name → language';

  @override
  String get rkNameCleanup => 'Clean the name';

  @override
  String get rkIdMap => 'tvg-id → our channel';

  @override
  String get rPattern => 'Contains';

  @override
  String get rTarget => 'Result';

  @override
  String get rRegex => 'Regular expression';

  @override
  String get rNote => 'Note';

  @override
  String get rulesHint =>
      'Rules apply to every import before matching. A rule only fills what is unknown; it never overwrites your edits.';

  @override
  String get xtSave =>
      'Save this account (the password is encrypted in Supabase Vault)';

  @override
  String get xtSaved => 'Saved accounts';

  @override
  String get xtFetch => 'Fetch & review';

  @override
  String get ioLoad => 'Load iptv-org data';

  @override
  String get ioSearch => 'Search iptv-org channels…';

  @override
  String get ioInCatalog => 'In catalog';

  @override
  String get ioNotInCatalog => 'Not in catalog';

  @override
  String ioStreams(int n) {
    return '$n streams';
  }

  @override
  String ioReview(int n) {
    return 'Review selected in import ($n)';
  }

  @override
  String get ioLicense =>
      'Data from iptv-org (public domain). A link listed there is not proof of the right to redistribute it; new channels always go to review.';

  @override
  String get acEmail => 'Email';

  @override
  String get acMfa => 'Two-step verification';

  @override
  String get acAddFactor => 'Add a backup authenticator';

  @override
  String get acAddFactorHint =>
      'Recommended: a second authenticator (another phone or a password manager). If you lose one, the other still works.';

  @override
  String get acChangePassword => 'Change password';

  @override
  String get acNewPassword => 'New password (at least 10 characters)';

  @override
  String get acSignOutAll => 'Sign out of all devices';

  @override
  String get acSignOutAllConfirm =>
      'Sign out everywhere, including this device?';

  @override
  String get acRecovery =>
      'Lost every authenticator? Follow docs/runbooks/admin-recovery.md to restore access from the Supabase dashboard.';

  @override
  String get shEnabled => 'Run scheduled tasks on this device';

  @override
  String get shTray =>
      'Keep running in the notification area when the window is closed';

  @override
  String get shStartup => 'Start with Windows (hidden)';

  @override
  String get shRunNow => 'Run now';

  @override
  String get shAnyTime => 'any time';

  @override
  String get shAllowed => 'Allowed hours';

  @override
  String shNext(String t) {
    return 'next $t';
  }

  @override
  String shMissed(String list) {
    return 'Missed while this computer was off: $list';
  }

  @override
  String shRunning(String task) {
    return 'Running: $task';
  }

  @override
  String get shInterval => 'Every (minutes)';

  @override
  String get shNote =>
      'Heavy checks wait while you are watching a channel. Only one device runs each task (server lock). Missed tasks run when the program opens.';

  @override
  String get auSearch => 'Row id…';

  @override
  String get auAllTables => 'All tables';

  @override
  String get auAllActions => 'All actions';

  @override
  String get auExport => 'Export CSV';

  @override
  String get bkFolder => 'Backup folder';

  @override
  String get bkChooseFolder => 'Choose folder…';

  @override
  String get bkPassphrase => 'Passphrase (at least 8 characters)';

  @override
  String get bkPassphraseHint =>
      'It is never sent to the server. If you lose it, the backups cannot be opened — keep it in a password manager. Tip: choose a folder synced to OneDrive or Google Drive.';

  @override
  String get bkNow => 'Back up now';

  @override
  String bkDone(String name) {
    return 'Backup saved: $name';
  }

  @override
  String get bkList => 'Backups in the folder';

  @override
  String get bkOpen => 'Open & preview';

  @override
  String get bkRestoreTables => 'Restore selected tables';

  @override
  String get bkRestoreChannel => 'Restore one channel';

  @override
  String bkCounts(int b, int c) {
    return 'backup $b · now $c';
  }

  @override
  String bkRestored(String s) {
    return 'Restored: $s';
  }

  @override
  String get bkNotConfigured => 'Choose a folder and a passphrase first.';

  @override
  String get bkRestoreNote =>
      'Restore only adds or updates rows; it never deletes newer data. A full replacement is tested on a separate copy, never on the live catalog.';

  @override
  String get bkChannelId => 'Channel id';

  @override
  String get mtStatus => 'System status';

  @override
  String mtDbLatency(int ms) {
    return 'Database response: $ms ms';
  }

  @override
  String get mtEpgStale => 'The guide has not synced for more than 48 hours';

  @override
  String get mtBackupStale => 'No backup in the last 48 hours';

  @override
  String get mtCleanup => 'Clean-up';

  @override
  String get mtDanger => 'Danger zone';

  @override
  String get mtDangerHint =>
      'Each action first takes a mandatory backup, then asks you to type the confirmation word.';

  @override
  String mtTypeWord(String w) {
    return 'Type $w to confirm';
  }

  @override
  String get mtRefreshCounts => 'Recount sources';

  @override
  String get mtClearReports => 'Delete resolved reports';

  @override
  String get mtClearBrokenLogos => 'Remove broken logos';

  @override
  String get mtDeleteOffline => 'Delete unavailable streams';

  @override
  String get mtDeleteHidden => 'Delete hidden channels';

  @override
  String get mtDeletePending => 'Delete channels pending review';

  @override
  String get g1Identity => 'App';

  @override
  String get g1AppNameAr => 'App name (Arabic)';

  @override
  String get g1AppNameEn => 'App name (English)';

  @override
  String get g1AboutAr => 'About text (Arabic)';

  @override
  String get g1AboutEn => 'About text (English)';

  @override
  String get g1CreditsAr => 'Credits (Arabic)';

  @override
  String get g1CreditsEn => 'Credits (English)';

  @override
  String get g1CompanyAr => 'Company name (Arabic)';

  @override
  String get g1CompanyEn => 'Company name (English)';

  @override
  String get g1Website => 'Website';

  @override
  String get g1Email => 'Email';

  @override
  String get g1Legal => 'Legal pages';

  @override
  String get g1PrivacyAr => 'Privacy policy (Arabic)';

  @override
  String get g1PrivacyEn => 'Privacy policy (English)';

  @override
  String get g1PrivacyHint =>
      'Empty = the built-in policy that matches what the app actually collects (spec §20).';

  @override
  String get g1TermsAr => 'Terms of use (Arabic)';

  @override
  String get g1TermsEn => 'Terms of use (English)';

  @override
  String get g3Defaults => 'Defaults for new devices';

  @override
  String get g3DefaultLang => 'Default language';

  @override
  String get g3DefaultTheme => 'Default theme';

  @override
  String get g3ParentalCats =>
      'Categories locked by default (parental control)';

  @override
  String get g3Catalog => 'Catalog';

  @override
  String get g3RecentDays => '\"Recently added\" covers (days)';

  @override
  String get g3AttentionDays =>
      '\"Needs your attention\" after (days of continuous failure)';

  @override
  String get g3AttentionHint =>
      'Only raises an alert for you. Nothing is hidden or deleted automatically (D-14).';

  @override
  String get g3EpgTz => 'Guide reference time zone';

  @override
  String get g4Player => 'Player';

  @override
  String get g4ConnectTimeout => 'Network timeout (seconds)';

  @override
  String get g4FirstFrame =>
      'Wait for the first picture (seconds) before switching server';

  @override
  String get g4Stall => 'Freeze before switching server (seconds)';

  @override
  String get g4Retries => 'Extra rounds over all servers';

  @override
  String get g4Buffer => 'Buffer (seconds)';

  @override
  String get g4UserAgent => 'Default User-Agent (empty = player default)';

  @override
  String get g4Hwdec => 'Hardware decoding';

  @override
  String get g4Probe => 'Stream checks (spec §12.3)';

  @override
  String get g4ProbeConnect => 'Connect timeout (seconds)';

  @override
  String get g4ProbePlaylist => 'Playlist timeout (seconds)';

  @override
  String get g4ProbeFrame => 'First frame timeout (seconds)';

  @override
  String get g4PerHost => 'Parallel checks per host';

  @override
  String get g4Total => 'Parallel checks in total';

  @override
  String get g4Ports => 'Allowed ports for fetching (comma separated)';

  @override
  String get g5Maintenance => 'Maintenance';

  @override
  String get g5MaintOn => 'Maintenance mode';

  @override
  String get g5MaintHint =>
      'Viewers see the message instead of the app; the admin can still sign in.';

  @override
  String get g5MsgAr => 'Message (Arabic)';

  @override
  String get g5MsgEn => 'Message (English)';

  @override
  String get g5Features => 'Features';

  @override
  String get g5FMini => 'Mini player';

  @override
  String get g5Refresh => 'Check for catalog updates every (minutes)';

  @override
  String get g5Telemetry => 'Collect anonymous playback statistics';

  @override
  String get g5KillSwitch => 'Hide a channel immediately on every device';

  @override
  String get g5KillHint =>
      'The channel disappears from every device at its next sync, without changing the catalog. Remove it here to bring it back.';

  @override
  String get g2Handle => 'Username or link';

  @override
  String get g2OwnDeveloper => 'Developer';

  @override
  String get g2Footer => 'Footer';

  @override
  String get g2Splash => 'Start screen';

  @override
  String get g2Support => 'Support channels';

  @override
  String get followUs => 'Follow us';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get contactSupport => 'Contact support directly';

  @override
  String get g2SupportHint => 'Shown in \"Report a problem\".';

  @override
  String get g6MinSupported => 'Minimum supported version';

  @override
  String get g6MinHint => 'Older versions are forced to update.';

  @override
  String get g6Recommended => 'Recommended version';

  @override
  String get g6RecHint => 'Older versions see an update reminder.';

  @override
  String get g6Url => 'Download page';

  @override
  String get g6NotesAr => 'Release notes (Arabic)';

  @override
  String get g6NotesEn => 'Release notes (English)';

  @override
  String get g6Github => 'Latest on GitHub';

  @override
  String get f2Kind => 'Type';

  @override
  String get f2Info => 'Information';

  @override
  String get f2Warning => 'Warning';

  @override
  String get f2Style => 'Shown as';

  @override
  String get f2Banner => 'Banner';

  @override
  String get f2Dialog => 'Welcome window';

  @override
  String get f2BodyAr => 'Text (Arabic)';

  @override
  String get f2BodyEn => 'Text (English)';

  @override
  String get f2MinVersion => 'From version';

  @override
  String get f2MaxVersion => 'Up to version';

  @override
  String get f2Dismissible => 'Viewers can close it';

  @override
  String get f2Empty => 'Nothing yet.';

  @override
  String get f1Compose => 'New notification';

  @override
  String get f1Link => 'Open inside the app (optional)';

  @override
  String get f1Image => 'Image link (optional)';

  @override
  String get f1SendAt => 'Schedule (optional, YYYY-MM-DD HH:MM)';

  @override
  String get f1SendAtHint =>
      'Empty = now. Scheduled notifications reach the inbox at that time on every platform.';

  @override
  String get f1Push => 'Also send a push to Android now';

  @override
  String get f1PushHint =>
      'Through the existing send-push function (Firebase). Windows and macOS receive it in the inbox.';

  @override
  String get f1Sent => 'Notification published';

  @override
  String get f1History => 'Sent';

  @override
  String get f1CheckFcm => 'Check push setup';

  @override
  String get maintenanceTitle => 'Under maintenance';

  @override
  String get updateRequired => 'Please update to continue';

  @override
  String get updateRecommended => 'A newer version is available';

  @override
  String get updateNow => 'Update now';

  @override
  String get later => 'Later';
}
