// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'user_local_model.dart';

extension GetUserLocalModelCollection on Isar {
  IsarCollection<UserLocalModel> get userLocalModels => this.collection();
}

const UserLocalModelSchema = CollectionSchema(
  name: r'UserLocalModel',
  id: -4890124739293001234,
  properties: {
    r'avatarUrl': PropertySchema(id: 0, name: r'avatarUrl', type: IsarType.string),
    r'email': PropertySchema(id: 1, name: r'email', type: IsarType.string),
    r'lastSyncedAt': PropertySchema(id: 2, name: r'lastSyncedAt', type: IsarType.dateTime),
    r'name': PropertySchema(id: 3, name: r'name', type: IsarType.string),
    r'userId': PropertySchema(id: 4, name: r'userId', type: IsarType.string),
  },
  estimateSize: _userLocalModelEstimateSize,
  serialize: _userLocalModelSerialize,
  deserialize: _userLocalModelDeserialize,
  deserializeProp: _userLocalModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'userId': IndexSchema(
      id: -6989234512340001,
      name: r'userId',
      unique: true,
      replace: false,
      properties: [IndexPropertySchema(name: r'userId', type: IndexType.hash, caseSensitive: true)],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _userLocalModelGetId,
  getLinks: _userLocalModelGetLinks,
  attach: _userLocalModelAttach,
  version: '3.1.0+1',
);

int _userLocalModelEstimateSize(UserLocalModel object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  bytesCount += 3 + (object.avatarUrl?.length ?? 0) * 3;
  bytesCount += 3 + object.email.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _userLocalModelSerialize(UserLocalModel object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeString(offsets[0], object.avatarUrl);
  writer.writeString(offsets[1], object.email);
  writer.writeDateTime(offsets[2], object.lastSyncedAt);
  writer.writeString(offsets[3], object.name);
  writer.writeString(offsets[4], object.userId);
}

UserLocalModel _userLocalModelDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = UserLocalModel();
  object.avatarUrl = reader.readStringOrNull(offsets[0]);
  object.email = reader.readString(offsets[1]);
  object.id = id;
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[2]);
  object.name = reader.readString(offsets[3]);
  object.userId = reader.readString(offsets[4]);
  return object;
}

P _userLocalModelDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0: return (reader.readStringOrNull(offset)) as P;
    case 1: return (reader.readString(offset)) as P;
    case 2: return (reader.readDateTimeOrNull(offset)) as P;
    case 3: return (reader.readString(offset)) as P;
    case 4: return (reader.readString(offset)) as P;
    default: throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userLocalModelGetId(UserLocalModel object) => object.id;
List<IsarLinkBase<dynamic>> _userLocalModelGetLinks(UserLocalModel object) => [];
void _userLocalModelAttach(IsarCollection<dynamic> col, Id id, UserLocalModel object) { object.id = id; }
