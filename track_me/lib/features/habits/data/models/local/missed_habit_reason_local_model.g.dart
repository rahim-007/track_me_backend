// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missed_habit_reason_local_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMissedHabitReasonLocalModelCollection on Isar {
  IsarCollection<MissedHabitReasonLocalModel>
      get missedHabitReasonLocalModels => this.collection();
}

const MissedHabitReasonLocalModelSchema = CollectionSchema(
  name: r'MissedHabitReasonLocalModel',
  id: 3883439466895680949,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'habitEmoji': PropertySchema(
      id: 1,
      name: r'habitEmoji',
      type: IsarType.string,
    ),
    r'habitId': PropertySchema(
      id: 2,
      name: r'habitId',
      type: IsarType.string,
    ),
    r'habitName': PropertySchema(
      id: 3,
      name: r'habitName',
      type: IsarType.string,
    ),
    r'isSynced': PropertySchema(
      id: 4,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'missedDate': PropertySchema(
      id: 5,
      name: r'missedDate',
      type: IsarType.string,
    ),
    r'reason': PropertySchema(
      id: 6,
      name: r'reason',
      type: IsarType.string,
    ),
    r'userId': PropertySchema(
      id: 7,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _missedHabitReasonLocalModelEstimateSize,
  serialize: _missedHabitReasonLocalModelSerialize,
  deserialize: _missedHabitReasonLocalModelDeserialize,
  deserializeProp: _missedHabitReasonLocalModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'missedDate': IndexSchema(
      id: 8955166464275099061,
      name: r'missedDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'missedDate',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _missedHabitReasonLocalModelGetId,
  getLinks: _missedHabitReasonLocalModelGetLinks,
  attach: _missedHabitReasonLocalModelAttach,
  version: '3.1.0+1',
);

int _missedHabitReasonLocalModelEstimateSize(
  MissedHabitReasonLocalModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.habitEmoji;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.habitId.length * 3;
  bytesCount += 3 + object.habitName.length * 3;
  bytesCount += 3 + object.missedDate.length * 3;
  bytesCount += 3 + object.reason.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _missedHabitReasonLocalModelSerialize(
  MissedHabitReasonLocalModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.habitEmoji);
  writer.writeString(offsets[2], object.habitId);
  writer.writeString(offsets[3], object.habitName);
  writer.writeBool(offsets[4], object.isSynced);
  writer.writeString(offsets[5], object.missedDate);
  writer.writeString(offsets[6], object.reason);
  writer.writeString(offsets[7], object.userId);
}

MissedHabitReasonLocalModel _missedHabitReasonLocalModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MissedHabitReasonLocalModel();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.habitEmoji = reader.readStringOrNull(offsets[1]);
  object.habitId = reader.readString(offsets[2]);
  object.habitName = reader.readString(offsets[3]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[4]);
  object.missedDate = reader.readString(offsets[5]);
  object.reason = reader.readString(offsets[6]);
  object.userId = reader.readString(offsets[7]);
  return object;
}

P _missedHabitReasonLocalModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _missedHabitReasonLocalModelGetId(MissedHabitReasonLocalModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _missedHabitReasonLocalModelGetLinks(
    MissedHabitReasonLocalModel object) {
  return [];
}

void _missedHabitReasonLocalModelAttach(
    IsarCollection<dynamic> col, Id id, MissedHabitReasonLocalModel object) {
  object.id = id;
}

extension MissedHabitReasonLocalModelQueryWhereSort on QueryBuilder<
    MissedHabitReasonLocalModel, MissedHabitReasonLocalModel, QWhere> {
  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MissedHabitReasonLocalModelQueryWhere on QueryBuilder<
    MissedHabitReasonLocalModel, MissedHabitReasonLocalModel, QWhereClause> {
  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterWhereClause> missedDateEqualTo(String missedDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'missedDate',
        value: [missedDate],
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterWhereClause> missedDateNotEqualTo(String missedDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'missedDate',
              lower: [],
              upper: [missedDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'missedDate',
              lower: [missedDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'missedDate',
              lower: [missedDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'missedDate',
              lower: [],
              upper: [missedDate],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MissedHabitReasonLocalModelQueryFilter on QueryBuilder<
    MissedHabitReasonLocalModel,
    MissedHabitReasonLocalModel,
    QFilterCondition> {
  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'habitEmoji',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'habitEmoji',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'habitEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'habitEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'habitEmoji',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'habitEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'habitEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      habitEmojiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'habitEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      habitEmojiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'habitEmoji',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitEmojiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'habitEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'habitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'habitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'habitId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'habitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'habitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      habitIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'habitId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      habitIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'habitId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitId',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'habitId',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'habitName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      habitNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'habitName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      habitNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'habitName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'habitName',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> habitNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'habitName',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> missedDateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'missedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> missedDateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'missedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> missedDateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'missedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> missedDateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'missedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> missedDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'missedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> missedDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'missedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      missedDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'missedDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      missedDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'missedDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> missedDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'missedDate',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> missedDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'missedDate',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> reasonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> reasonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> reasonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> reasonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> reasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> reasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      reasonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'reason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      reasonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'reason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> reasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reason',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> reasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'reason',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
          QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension MissedHabitReasonLocalModelQueryObject on QueryBuilder<
    MissedHabitReasonLocalModel,
    MissedHabitReasonLocalModel,
    QFilterCondition> {}

extension MissedHabitReasonLocalModelQueryLinks on QueryBuilder<
    MissedHabitReasonLocalModel,
    MissedHabitReasonLocalModel,
    QFilterCondition> {}

extension MissedHabitReasonLocalModelQuerySortBy on QueryBuilder<
    MissedHabitReasonLocalModel, MissedHabitReasonLocalModel, QSortBy> {
  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByHabitEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitEmoji', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByHabitEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitEmoji', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByHabitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByHabitIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByHabitName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitName', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByHabitNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitName', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByMissedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missedDate', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByMissedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missedDate', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension MissedHabitReasonLocalModelQuerySortThenBy on QueryBuilder<
    MissedHabitReasonLocalModel, MissedHabitReasonLocalModel, QSortThenBy> {
  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByHabitEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitEmoji', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByHabitEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitEmoji', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByHabitId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByHabitIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitId', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByHabitName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitName', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByHabitNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'habitName', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByMissedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missedDate', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByMissedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'missedDate', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension MissedHabitReasonLocalModelQueryWhereDistinct on QueryBuilder<
    MissedHabitReasonLocalModel, MissedHabitReasonLocalModel, QDistinct> {
  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QDistinct> distinctByHabitEmoji({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitEmoji', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QDistinct> distinctByHabitId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QDistinct> distinctByHabitName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'habitName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QDistinct> distinctByMissedDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'missedDate', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QDistinct> distinctByReason({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reason', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, MissedHabitReasonLocalModel,
      QDistinct> distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension MissedHabitReasonLocalModelQueryProperty on QueryBuilder<
    MissedHabitReasonLocalModel, MissedHabitReasonLocalModel, QQueryProperty> {
  QueryBuilder<MissedHabitReasonLocalModel, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, String?, QQueryOperations>
      habitEmojiProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'habitEmoji');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, String, QQueryOperations>
      habitIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'habitId');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, String, QQueryOperations>
      habitNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'habitName');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, bool, QQueryOperations>
      isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, String, QQueryOperations>
      missedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'missedDate');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, String, QQueryOperations>
      reasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reason');
    });
  }

  QueryBuilder<MissedHabitReasonLocalModel, String, QQueryOperations>
      userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
