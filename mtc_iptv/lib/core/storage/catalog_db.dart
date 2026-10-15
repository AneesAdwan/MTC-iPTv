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

  /// مفتاح بحث مطبّع (matchKey للاسمين والأسماء البديلة + الرقم) يُحسب عند المزامنة (§20).
  TextColumn get search => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// الدول/الفئات/اللغات المرئية (بيانات مرجعية صغيرة، تُجلب كاملة عند كل مزامنة).
@DataClassName('CountryRow')
class Countries extends Table {
  TextColumn get code => text()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get flag => text().nullable()(); // emoji
  TextColumn get continent => text().nullable()();
  BoolColumn get isArab => boolean().withDefault(const Constant(false))();
  IntColumn get sort => integer().withDefault(const Constant(100))();
  @override
  Set<Column> get primaryKey => {code};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get slug => text()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get icon => text().withDefault(const Constant('tv'))();
  IntColumn get hue => integer().withDefault(const Constant(220))();
  IntColumn get sort => integer().withDefault(const Constant(100))();
  @override
  Set<Column> get primaryKey => {slug};
}

@DataClassName('LanguageRow')
class Languages extends Table {
  TextColumn get code => text()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  @override
  Set<Column> get primaryKey => {code};
}

/// المفضلة محليًا (§8.3): ترتيب يدوي.
class Favorites extends Table {
  TextColumn get channelId => text()();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {channelId};
}

/// آخر المشاهدات (§8.3).
class History extends Table {
  TextColumn get channelId => text()();
  DateTimeColumn get watchedAt => dateTime()();
  IntColumn get seconds => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {channelId};
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

/// دليل البرامج محليًا (V-07): نافذة من الأمس حتى ما يتوفر، تُستبدل كاملة عند كل مزامنة.
@DataClassName('ProgrammeRow')
class Programmes extends Table {
  TextColumn get channelUid => text()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  @override
  Set<Column> get primaryKey => {channelUid, startAt};
}

/// «ذكّرني» (§8.5): إشعار قبل 5 دقائق من بداية البرنامج.
@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get channelId => text()();
  DateTimeColumn get startAt => dateTime()();
  TextColumn get title => text()();
  BoolColumn get fired => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {channelId, startAt};
}

/// صندوق الوارد (V-09): التذكيرات المنطلقة الآن، وإعلانات الإدارة لاحقًا (ADM-F1/F2).
@DataClassName('InboxRow')
class Inbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()(); // reminder | announcement
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get channelId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  BoolColumn get read => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Channels, Streams, SyncState, Countries, Categories, Languages, Favorites, History, Programmes, Reminders, Inbox])
class CatalogDb extends _$CatalogDb {
  CatalogDb([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'mtc_catalog'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _indexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(channels, channels.search);
            for (final TableInfo t in [countries, categories, languages, favorites, history]) {
              await m.createTable(t);
            }
            // مفتاح البحث الجديد يُملأ من المزامنة التالية: نصفّر رقم المزامنة لإعادة جلب الكل
            await (delete(syncState)..where((s) => s.key.equals('catalog_rev'))).go();
            await _indexes();
          }
          if (from < 3) {
            for (final TableInfo t in [programmes, reminders, inbox]) {
              await m.createTable(t);
            }
            await _indexes();
          }
        },
      );

  Future<void> _indexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS streams_channel_idx ON streams (channel_id, priority)');
    await customStatement('CREATE INDEX IF NOT EXISTS channels_number_idx ON channels (number)');
    await customStatement('CREATE INDEX IF NOT EXISTS channels_country_idx ON channels (country)');
    await customStatement('CREATE INDEX IF NOT EXISTS channels_category_idx ON channels (category)');
    await customStatement('CREATE INDEX IF NOT EXISTS programmes_time_idx ON programmes (start_at, end_at)');
  }

  Future<int> catalogRev() async {
    final row = await (select(syncState)..where((s) => s.key.equals('catalog_rev'))).getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }

  Future<void> setSyncValue(String key, String value) =>
      into(syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: key, value: value));
}
