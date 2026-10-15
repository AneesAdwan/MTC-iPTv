// قاعدة الكتالوج المحلية (ADR-06، §22): نسخة من القنوات والروابط المنشورة على الجهاز،
// فيفتح التطبيق فورًا ويعمل التصفّح والبحث دون اتصال. تُملأ بالمزامنة التفاضلية (catalog_sync).
// بعد أي تعديل هنا:  dart run build_runner build
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'catalog_db.g.dart';

@DataClassName('ChannelRow')
class Channels extends Table {
  TextColumn get id => text()();
  TextColumn get uid => text()();
  IntColumn get number => integer().nullable()();
  TextColumn get nameAr => text().nullable()();
  TextColumn get nameEn => text().nullable()();
  TextColumn get altNames => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get network => text().nullable()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get categories => text().withDefault(const Constant('[]'))(); // JSON
  TextColumn get language => text().nullable()();
  TextColumn get quality => text().nullable()();
  BoolColumn get featured => boolean().withDefault(const Constant(false))();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  TextColumn get epgId => text().nullable()();
  IntColumn get epgOffset => integer().withDefault(const Constant(0))();
  TextColumn get family => text().nullable()();
  BoolColumn get parental => boolean().withDefault(const Constant(false))();
  DateTimeColumn get publishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StreamRow')
class Streams extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get url => text()();
  TextColumn get label => text().nullable()();
  TextColumn get quality => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get userAgent => text().nullable()();
  TextColumn get referrer => text().nullable()();
  TextColumn get headers => text().withDefault(const Constant('{}'))(); // JSON
  TextColumn get protocol => text().nullable()();
  TextColumn get health => text().withDefault(const Constant('inconclusive'))();
  IntColumn get score => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// قيم مفتاح/قيمة: آخر رقم مزامنة (catalog_rev) ووقتها.
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Channels, Streams, SyncState])
class CatalogDb extends _$CatalogDb {
  CatalogDb([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'mtc_catalog'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX IF NOT EXISTS streams_channel_idx ON streams (channel_id, priority)');
          await customStatement('CREATE INDEX IF NOT EXISTS channels_number_idx ON channels (number)');
        },
      );

  Future<int> catalogRev() async {
    final row = await (select(syncState)..where((s) => s.key.equals('catalog_rev'))).getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }

  Future<void> setSyncValue(String key, String value) =>
      into(syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: value));
}
