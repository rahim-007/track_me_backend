// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'app_settings_model.dart';

extension GetAppSettingsModelCollection on Isar {
  IsarCollection<AppSettingsModel> get appSettingsModels => this.collection();
}

const AppSettingsModelSchema = CollectionSchema(
  name: r'AppSettingsModel',
  id: 5555555555555555555,
  properties: {
    r'goalRemindersEnabled': PropertySchema(id: 0, name: r'goalRemindersEnabled', type: IsarType.bool),
    r'habitRemindersEnabled': PropertySchema(id: 1, name: r'habitRemindersEnabled', type: IsarType.bool),
    r'language': PropertySchema(id: 2, name: r'language', type: IsarType.string),
    r'notificationsEnabled': PropertySchema(id: 3, name: r'notificationsEnabled', type: IsarType.bool),
    r'themeMode': PropertySchema(id: 4, name: r'themeMode', type: IsarType.string),
    r'weeklyReportEnabled': PropertySchema(id: 5, name: r'weeklyReportEnabled', type: IsarType.bool),
  },
  estimateSize: _appSettingsModelEstimateSize,
  serialize: _appSettingsModelSerialize,
  deserialize: _appSettingsModelDeserialize,
  deserializeProp: _appSettingsModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appSettingsModelGetId,
  getLinks: _appSettingsModelGetLinks,
  attach: _appSettingsModelAttach,
  version: '3.1.0+1',
);

int _appSettingsModelEstimateSize(AppSettingsModel object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.language.length * 3;
  bytesCount += 3 + object.themeMode.length * 3;
  return bytesCount;
}

void _appSettingsModelSerialize(AppSettingsModel object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeBool(offsets[0], object.goalRemindersEnabled);
  writer.writeBool(offsets[1], object.habitRemindersEnabled);
  writer.writeString(offsets[2], object.language);
  writer.writeBool(offsets[3], object.notificationsEnabled);
  writer.writeString(offsets[4], object.themeMode);
  writer.writeBool(offsets[5], object.weeklyReportEnabled);
}

AppSettingsModel _appSettingsModelDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = AppSettingsModel();
  object.goalRemindersEnabled = reader.readBool(offsets[0]);
  object.habitRemindersEnabled = reader.readBool(offsets[1]);
  object.id = id;
  object.language = reader.readString(offsets[2]);
  object.notificationsEnabled = reader.readBool(offsets[3]);
  object.themeMode = reader.readString(offsets[4]);
  object.weeklyReportEnabled = reader.readBool(offsets[5]);
  return object;
}

P _appSettingsModelDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0: return (reader.readBool(offset)) as P;
    case 1: return (reader.readBool(offset)) as P;
    case 2: return (reader.readString(offset)) as P;
    case 3: return (reader.readBool(offset)) as P;
    case 4: return (reader.readString(offset)) as P;
    case 5: return (reader.readBool(offset)) as P;
    default: throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appSettingsModelGetId(AppSettingsModel object) => object.id;
List<IsarLinkBase<dynamic>> _appSettingsModelGetLinks(AppSettingsModel object) => [];
void _appSettingsModelAttach(IsarCollection<dynamic> col, Id id, AppSettingsModel object) { object.id = id; }
