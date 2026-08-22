// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_local_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBudgetLocalModelCollection on Isar {
  IsarCollection<BudgetLocalModel> get budgetLocalModels => this.collection();
}

const BudgetLocalModelSchema = CollectionSchema(
  name: r'BudgetLocalModel',
  id: -4211117892613485833,
  properties: {
    r'budgetId': PropertySchema(
      id: 0,
      name: r'budgetId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dailyGoal': PropertySchema(
      id: 2,
      name: r'dailyGoal',
      type: IsarType.double,
    ),
    r'daysInMonth': PropertySchema(
      id: 3,
      name: r'daysInMonth',
      type: IsarType.long,
    ),
    r'isSynced': PropertySchema(
      id: 4,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'month': PropertySchema(
      id: 5,
      name: r'month',
      type: IsarType.long,
    ),
    r'monthlyIncome': PropertySchema(
      id: 6,
      name: r'monthlyIncome',
      type: IsarType.double,
    ),
    r'savingsTarget': PropertySchema(
      id: 7,
      name: r'savingsTarget',
      type: IsarType.double,
    ),
    r'spendableBudget': PropertySchema(
      id: 8,
      name: r'spendableBudget',
      type: IsarType.double,
    ),
    r'year': PropertySchema(
      id: 9,
      name: r'year',
      type: IsarType.long,
    )
  },
  estimateSize: _budgetLocalModelEstimateSize,
  serialize: _budgetLocalModelSerialize,
  deserialize: _budgetLocalModelDeserialize,
  deserializeProp: _budgetLocalModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'budgetId': IndexSchema(
      id: 1954233043883219522,
      name: r'budgetId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'budgetId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _budgetLocalModelGetId,
  getLinks: _budgetLocalModelGetLinks,
  attach: _budgetLocalModelAttach,
  version: '3.1.0+1',
);

int _budgetLocalModelEstimateSize(
  BudgetLocalModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.budgetId.length * 3;
  return bytesCount;
}

void _budgetLocalModelSerialize(
  BudgetLocalModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.budgetId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDouble(offsets[2], object.dailyGoal);
  writer.writeLong(offsets[3], object.daysInMonth);
  writer.writeBool(offsets[4], object.isSynced);
  writer.writeLong(offsets[5], object.month);
  writer.writeDouble(offsets[6], object.monthlyIncome);
  writer.writeDouble(offsets[7], object.savingsTarget);
  writer.writeDouble(offsets[8], object.spendableBudget);
  writer.writeLong(offsets[9], object.year);
}

BudgetLocalModel _budgetLocalModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BudgetLocalModel();
  object.budgetId = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.dailyGoal = reader.readDouble(offsets[2]);
  object.daysInMonth = reader.readLong(offsets[3]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[4]);
  object.month = reader.readLong(offsets[5]);
  object.monthlyIncome = reader.readDouble(offsets[6]);
  object.savingsTarget = reader.readDouble(offsets[7]);
  object.spendableBudget = reader.readDouble(offsets[8]);
  object.year = reader.readLong(offsets[9]);
  return object;
}

P _budgetLocalModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _budgetLocalModelGetId(BudgetLocalModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _budgetLocalModelGetLinks(BudgetLocalModel object) {
  return [];
}

void _budgetLocalModelAttach(
    IsarCollection<dynamic> col, Id id, BudgetLocalModel object) {
  object.id = id;
}

extension BudgetLocalModelByIndex on IsarCollection<BudgetLocalModel> {
  Future<BudgetLocalModel?> getByBudgetId(String budgetId) {
    return getByIndex(r'budgetId', [budgetId]);
  }

  BudgetLocalModel? getByBudgetIdSync(String budgetId) {
    return getByIndexSync(r'budgetId', [budgetId]);
  }

  Future<bool> deleteByBudgetId(String budgetId) {
    return deleteByIndex(r'budgetId', [budgetId]);
  }

  bool deleteByBudgetIdSync(String budgetId) {
    return deleteByIndexSync(r'budgetId', [budgetId]);
  }

  Future<List<BudgetLocalModel?>> getAllByBudgetId(
      List<String> budgetIdValues) {
    final values = budgetIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'budgetId', values);
  }

  List<BudgetLocalModel?> getAllByBudgetIdSync(List<String> budgetIdValues) {
    final values = budgetIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'budgetId', values);
  }

  Future<int> deleteAllByBudgetId(List<String> budgetIdValues) {
    final values = budgetIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'budgetId', values);
  }

  int deleteAllByBudgetIdSync(List<String> budgetIdValues) {
    final values = budgetIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'budgetId', values);
  }

  Future<Id> putByBudgetId(BudgetLocalModel object) {
    return putByIndex(r'budgetId', object);
  }

  Id putByBudgetIdSync(BudgetLocalModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'budgetId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBudgetId(List<BudgetLocalModel> objects) {
    return putAllByIndex(r'budgetId', objects);
  }

  List<Id> putAllByBudgetIdSync(List<BudgetLocalModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'budgetId', objects, saveLinks: saveLinks);
  }
}

extension BudgetLocalModelQueryWhereSort
    on QueryBuilder<BudgetLocalModel, BudgetLocalModel, QWhere> {
  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BudgetLocalModelQueryWhere
    on QueryBuilder<BudgetLocalModel, BudgetLocalModel, QWhereClause> {
  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterWhereClause> idBetween(
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

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterWhereClause>
      budgetIdEqualTo(String budgetId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'budgetId',
        value: [budgetId],
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterWhereClause>
      budgetIdNotEqualTo(String budgetId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'budgetId',
              lower: [],
              upper: [budgetId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'budgetId',
              lower: [budgetId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'budgetId',
              lower: [budgetId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'budgetId',
              lower: [],
              upper: [budgetId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension BudgetLocalModelQueryFilter
    on QueryBuilder<BudgetLocalModel, BudgetLocalModel, QFilterCondition> {
  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'budgetId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'budgetId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'budgetId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'budgetId',
        value: '',
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      budgetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'budgetId',
        value: '',
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      createdAtGreaterThan(
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

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      createdAtLessThan(
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

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      createdAtBetween(
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

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      dailyGoalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyGoal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      dailyGoalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyGoal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      dailyGoalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyGoal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      dailyGoalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyGoal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      daysInMonthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysInMonth',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      daysInMonthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysInMonth',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      daysInMonthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysInMonth',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      daysInMonthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysInMonth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      monthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'month',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      monthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'month',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      monthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'month',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      monthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'month',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      monthlyIncomeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyIncome',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      monthlyIncomeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlyIncome',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      monthlyIncomeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlyIncome',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      monthlyIncomeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlyIncome',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      savingsTargetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'savingsTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      savingsTargetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'savingsTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      savingsTargetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'savingsTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      savingsTargetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'savingsTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      spendableBudgetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spendableBudget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      spendableBudgetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spendableBudget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      spendableBudgetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spendableBudget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      spendableBudgetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spendableBudget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      yearEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'year',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      yearGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'year',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      yearLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'year',
        value: value,
      ));
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterFilterCondition>
      yearBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'year',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension BudgetLocalModelQueryObject
    on QueryBuilder<BudgetLocalModel, BudgetLocalModel, QFilterCondition> {}

extension BudgetLocalModelQueryLinks
    on QueryBuilder<BudgetLocalModel, BudgetLocalModel, QFilterCondition> {}

extension BudgetLocalModelQuerySortBy
    on QueryBuilder<BudgetLocalModel, BudgetLocalModel, QSortBy> {
  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByBudgetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetId', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByBudgetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetId', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByDailyGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoal', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByDailyGoalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoal', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByDaysInMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysInMonth', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByDaysInMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysInMonth', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy> sortByMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'month', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'month', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByMonthlyIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortBySavingsTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsTarget', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortBySavingsTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsTarget', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortBySpendableBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spendableBudget', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortBySpendableBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spendableBudget', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy> sortByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      sortByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.desc);
    });
  }
}

extension BudgetLocalModelQuerySortThenBy
    on QueryBuilder<BudgetLocalModel, BudgetLocalModel, QSortThenBy> {
  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByBudgetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetId', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByBudgetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetId', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByDailyGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoal', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByDailyGoalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyGoal', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByDaysInMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysInMonth', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByDaysInMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysInMonth', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy> thenByMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'month', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'month', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByMonthlyIncomeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'monthlyIncome', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenBySavingsTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsTarget', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenBySavingsTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savingsTarget', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenBySpendableBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spendableBudget', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenBySpendableBudgetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spendableBudget', Sort.desc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy> thenByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.asc);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QAfterSortBy>
      thenByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.desc);
    });
  }
}

extension BudgetLocalModelQueryWhereDistinct
    on QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct> {
  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct>
      distinctByBudgetId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'budgetId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct>
      distinctByDailyGoal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyGoal');
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct>
      distinctByDaysInMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysInMonth');
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct>
      distinctByMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'month');
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct>
      distinctByMonthlyIncome() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'monthlyIncome');
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct>
      distinctBySavingsTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savingsTarget');
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct>
      distinctBySpendableBudget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spendableBudget');
    });
  }

  QueryBuilder<BudgetLocalModel, BudgetLocalModel, QDistinct> distinctByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'year');
    });
  }
}

extension BudgetLocalModelQueryProperty
    on QueryBuilder<BudgetLocalModel, BudgetLocalModel, QQueryProperty> {
  QueryBuilder<BudgetLocalModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BudgetLocalModel, String, QQueryOperations> budgetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'budgetId');
    });
  }

  QueryBuilder<BudgetLocalModel, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<BudgetLocalModel, double, QQueryOperations> dailyGoalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyGoal');
    });
  }

  QueryBuilder<BudgetLocalModel, int, QQueryOperations> daysInMonthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysInMonth');
    });
  }

  QueryBuilder<BudgetLocalModel, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<BudgetLocalModel, int, QQueryOperations> monthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'month');
    });
  }

  QueryBuilder<BudgetLocalModel, double, QQueryOperations>
      monthlyIncomeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'monthlyIncome');
    });
  }

  QueryBuilder<BudgetLocalModel, double, QQueryOperations>
      savingsTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savingsTarget');
    });
  }

  QueryBuilder<BudgetLocalModel, double, QQueryOperations>
      spendableBudgetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spendableBudget');
    });
  }

  QueryBuilder<BudgetLocalModel, int, QQueryOperations> yearProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'year');
    });
  }
}
