// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'goal_local_model.dart';

extension GetGoalLocalModelCollection on Isar {
  IsarCollection<GoalLocalModel> get goalLocalModels => this.collection();
}

const GoalLocalModelSchema = CollectionSchema(
  name: r'GoalLocalModel',
  id: 987654321,
  properties: {
    r'category': PropertySchema(id: 0, name: r'category', type: IsarType.string),
    r'createdAt': PropertySchema(id: 1, name: r'createdAt', type: IsarType.dateTime),
    r'goalId': PropertySchema(id: 2, name: r'goalId', type: IsarType.string),
    r'isSynced': PropertySchema(id: 3, name: r'isSynced', type: IsarType.bool),
    r'name': PropertySchema(id: 4, name: r'name', type: IsarType.string),
    r'priority': PropertySchema(id: 5, name: r'priority', type: IsarType.string),
    r'progress': PropertySchema(id: 6, name: r'progress', type: IsarType.double),
    r'status': PropertySchema(id: 7, name: r'status', type: IsarType.string),
    r'targetDate': PropertySchema(id: 8, name: r'targetDate', type: IsarType.dateTime),
  },
  estimateSize: _goalLocalModelEstimateSize,
  serialize: _goalLocalModelSerialize,
  deserialize: _goalLocalModelDeserialize,
  deserializeProp: _goalLocalModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'goalId': IndexSchema(
      id: 123456789,
      name: r'goalId',
      unique: true,
      replace: false,
      properties: [IndexPropertySchema(name: r'goalId', type: IndexType.hash, caseSensitive: true)],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _goalLocalModelGetId,
  getLinks: _goalLocalModelGetLinks,
  attach: _goalLocalModelAttach,
  version: '3.1.0+1',
);

int _goalLocalModelEstimateSize(GoalLocalModel object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.category.length * 3;
  bytesCount += 3 + object.goalId.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.priority.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _goalLocalModelSerialize(GoalLocalModel object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeString(offsets[0], object.category);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.goalId);
  writer.writeBool(offsets[3], object.isSynced);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.priority);
  writer.writeDouble(offsets[6], object.progress);
  writer.writeString(offsets[7], object.status);
  writer.writeDateTime(offsets[8], object.targetDate);
}

GoalLocalModel _goalLocalModelDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = GoalLocalModel();
  object.category = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.goalId = reader.readString(offsets[2]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[3]);
  object.name = reader.readString(offsets[4]);
  object.priority = reader.readString(offsets[5]);
  object.progress = reader.readDouble(offsets[6]);
  object.status = reader.readString(offsets[7]);
  object.targetDate = reader.readDateTime(offsets[8]);
  return object;
}

P _goalLocalModelDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0: return (reader.readString(offset)) as P;
    case 1: return (reader.readDateTime(offset)) as P;
    case 2: return (reader.readString(offset)) as P;
    case 3: return (reader.readBool(offset)) as P;
    case 4: return (reader.readString(offset)) as P;
    case 5: return (reader.readString(offset)) as P;
    case 6: return (reader.readDouble(offset)) as P;
    case 7: return (reader.readString(offset)) as P;
    case 8: return (reader.readDateTime(offset)) as P;
    default: throw IsarError('Unknown property with id $propertyId');
  }
}

Id _goalLocalModelGetId(GoalLocalModel object) => object.id;
List<IsarLinkBase<dynamic>> _goalLocalModelGetLinks(GoalLocalModel object) => [];
void _goalLocalModelAttach(IsarCollection<dynamic> col, Id id, GoalLocalModel object) { object.id = id; }
