// Page id (app/nav.dart) → widget.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'channels_pages.dart';
import 'decisions_pages.dart';
import 'epg_pages.dart';
import 'experience_pages.dart';
import 'home_pages.dart';
import 'sources_pages.dart';
import 'system_pages.dart';

Widget buildPage(String id, GoRouterState state) => switch (id) {
  'home.overview' => const OverviewPage(),
  'home.jobs' => const JobsPage(),
  'home.alerts' => const AlertsPage(),
  'channels.list' => const ChannelsListPage(),
  'channels.new' => const NewChannelPage(),
  'channels.trash' => const TrashPage(),
  'channels.numbering' => const NumberingPage(),
  'channels.networks' => const NetworksPage(),
  'channels.detail' => ChannelDetailPage(channelId: state.pathParameters['id'] ?? ''),
  'decisions.inbox' => const DecisionsPage(),
  'decisions.compare' => const ComparePage(),
  'sources.hub' => const SourcesHubPage(),
  'sources.import' => const ImportPage(),
  'sources.connectors' => const ConnectorsPage(),
  'sources.monitoring' => const MonitoringPage(),
  'sources.enrichment' => const EnrichmentPage(),
  'sources.rules' => const RulesPage(),
  'sources.export' => const ExportPage(),
  'sources.licensing' => const LicensingPage(),
  'epg.sources' => const EpgSourcesPage(),
  'epg.mapping' => const EpgMappingPage(),
  'epg.preview' => const EpgPreviewPage(),
  'experience.home' => const ViewerHomePage(),
  'experience.taxonomy' => const TaxonomyPage(),
  'experience.notifications' => const NotificationsPage(),
  'experience.announcements' => const AnnouncementsPage(),
  'experience.branding' => const BrandingPage(),
  'experience.player' => const PlayerSettingsPage(),
  'experience.features' => const FeaturesPage(),
  'experience.releases' => const ReleasesPage(),
  'system.account' => const AccountPage(),
  'system.schedules' => const SchedulesPage(),
  'system.audit' => const AuditPage(),
  'system.backup' => const BackupPage(),
  'system.diagnostics' => const DiagnosticsPage(),
  'system.analytics' => const AnalyticsPage(),
  _ => Center(child: Text('Unknown page: $id')),
};
