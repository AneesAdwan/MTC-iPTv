import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repositories.dart';
import 'repositories_impl.dart';
import 'rpc/admin_rpc.dart';
import 'sample/sample_data.dart';

/// Overridden in main(): SupabaseAdminRpc once the Phase 2 functions exist, StubAdminRpc until then.
final adminRpcProvider = Provider<AdminRpc>((ref) => StubAdminRpc());

final sampleDataProvider = Provider<SampleData>((ref) => SampleData.instance);

final dashboardRepoProvider = Provider<DashboardRepository>((ref) => DashboardRepositoryImpl(ref.watch(adminRpcProvider), ref.watch(sampleDataProvider)));
final channelsRepoProvider = Provider<ChannelsRepository>((ref) => ChannelsRepositoryImpl(ref.watch(adminRpcProvider), ref.watch(sampleDataProvider)));
final decisionsRepoProvider = Provider<DecisionsRepository>((ref) => DecisionsRepositoryImpl(ref.watch(adminRpcProvider), ref.watch(sampleDataProvider)));
final sourcesRepoProvider = Provider<SourcesRepository>((ref) => SourcesRepositoryImpl(ref.watch(adminRpcProvider), ref.watch(sampleDataProvider)));
final epgRepoProvider = Provider<EpgRepository>((ref) => EpgRepositoryImpl(ref.watch(adminRpcProvider), ref.watch(sampleDataProvider)));
final experienceRepoProvider = Provider<ExperienceRepository>((ref) => ExperienceRepositoryImpl(ref.watch(adminRpcProvider), ref.watch(sampleDataProvider)));
final systemRepoProvider = Provider<SystemRepository>((ref) => SystemRepositoryImpl(ref.watch(adminRpcProvider), ref.watch(sampleDataProvider)));
