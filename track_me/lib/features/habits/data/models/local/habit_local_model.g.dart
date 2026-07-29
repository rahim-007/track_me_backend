// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'habit_local_model.dart';

extension GetHabitLocalModelCollection on Isar {
  IsarCollection<HabitLocalModel> get habitLocalModels => this.collection();
}

const HabitLocalModelSchema = CollectionSchema(
  name: r'HabitLocalModel',
  id: 123456789,
  properties: {
    r'category': PropertySchema(id: 0, name: r'category', type: IsarType.string),
    r'color': PropertySchema(id: 1, name: r'color', type: IsarType.string),
    r'createdAt': PropertySchema(id: 2, name: r'createdAt', type: IsarType.dateTime),
    r'emoji': PropertySchema(id: 3, name: r'emoji', type: IsarType.string),
    r'habitId': PropertySchema(id: 4, name: r'habitId', type: IsarType.string),
    r'isSynced': PropertySchema(id: 5, name: r'isSynced', type: IsarType.bool),
    r'name': PropertySchema(id: 6, name: r'name', type: IsarType.string),
    r'reminderTime': PropertySchema(id: 7, name: r'reminderTime', type: IsarType.string),
    r'updatedAt': PropertySchema(id: 8, name: r'updatedAt', type: IsarType.dateTime),
  },
  estimateSize: _habitLocalModelEstimateSize,
  serialize: _habitLocalModelSerialize,
  deserialize: _habitLocalModelDeserialize,
  deserializeProp: _habitLocalModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'habitId': IndexSchema(
      id: 987654321,
      name: r'habitId',
      unique: true,
      replace: false,
      properties: [IndexPropertySchema(name: r'habitId', type: IndexType.hash, caseSensitive: true)],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _habitLocalModelGetId,
  getLinks: _habitLocalModelGetLinks,
  attach: _habitLocalModelAttach,
  version: '3.1.0+1',
);

int _habitLocalModelEstimateSize(HabitLocalModel object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + (object.color?.length ?? 0) * 3;
  bytesCount += 3 + (object.emoji?.length ?? 0) * 3;
  bytesCount += 3 + object.habitId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + (object.reminderTime?.length ?? 0) * 3;
  return bytesCount;
}

void _habitLocalModelSerialize(HabitLocalModel object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.color);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.emoji);
  writer.writeString(offsets[4], object.habitId);
  writer.writeBool(offsets[5], object.isSynced);
  writer.writeString(offsets[6], object.name);
  writer.writeString(offsets[7], object.reminderTime);
  writer.writeDateTime(offsets[8], object.updatedAt);
}

HabitLocalModel _habitLocalModelDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = HabitLocalModel();
  object.category = reader.readString(offsets[0]);
  object.color = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.emoji = reader.readStringOrNull(offsets[3]);
  object.habitId = reader.readString(offsets[4]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[5]);
  object.name = reader.readString(offsets[6]);
  object.reminderTime = reader.readStringOrNull(offsets[7]);
  object.updatedAt = reader.readDateTime(offsets[8]);
  return object;
}

P _habitLocalModelDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0: return (reader.readString(offset)) as P;
    case 1: return (reader.readStringOrNull(offset)) as P;
    case 2: return (reader.readDateTime(offset)) as P;
    case 3: return (reader.readStringOrNull(offset)) as P;
    case 4: return (reader.readString(offset)) as P;
    case 5: return (reader.readBool(offset)) as P;
    case 6: return (reader.readString(offset)) as P;
    case 7: return (reader.readStringOrNull(offset)) as P;
    case 8: return (reader.readDateTime(offset)) as P;
    default: throw IsarError('Unknown property with id $propertyId');
  }
}

Id _habitLocalModelGetId(HabitLocalModel object) => object.id;
List<IsarLinkBase<dynamic>> _habitLocalModelGetLinks(HabitLocalModel object) => [];
void _habitLocalModelAttach(IsarCollection<dynamic> col, Id id, HabitLocalModel object) { object.id = id; }
