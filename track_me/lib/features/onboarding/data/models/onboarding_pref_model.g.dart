// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_pref_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOnboardingPrefModelCollection on Isar {
  IsarCollection<OnboardingPrefModel> get onboardingPrefModels =>
      this.collection();
}

const OnboardingPrefModelSchema = CollectionSchema(
  name: r'OnboardingPrefModel',
  id: -3458513862895416757,
  properties: {
    r'completedAt': PropertySchema(
      id: 0,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'isCompleted': PropertySchema(
      id: 1,
      name: r'isCompleted',
      type: IsarType.bool,
    )
  },
  estimateSize: _onboardingPrefModelEstimateSize,
  serialize: _onboardingPrefModelSerialize,
  deserialize: _onboardingPrefModelDeserialize,
  deserializeProp: _onboardingPrefModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _onboardingPrefModelGetId,
  getLinks: _onboardingPrefModelGetLinks,
  attach: _onboardingPrefModelAttach,
  version: '3.1.0+1',
);

int _onboardingPrefModelEstimateSize(
  OnboardingPrefModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _onboardingPrefModelSerialize(
  OnboardingPrefModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.completedAt);
  writer.writeBool(offsets[1], object.isCompleted);
}

OnboardingPrefModel _onboardingPrefModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OnboardingPrefModel();
  object.completedAt = reader.readDateTimeOrNull(offsets[0]);
  object.id = id;
  object.isCompleted = reader.readBool(offsets[1]);
  return object;
}

P _onboardingPrefModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _onboardingPrefModelGetId(OnboardingPrefModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _onboardingPrefModelGetLinks(OnboardingPrefModel object) {
  return [];
}

void _onboardingPrefModelAttach(
    IsarCollection<dynamic> col, Id id, OnboardingPrefModel object) {
  object.id = id;
}

extension OnboardingPrefModelQueryWhereSort
    on QueryBuilder<OnboardingPrefModel, OnboardingPrefModel, QWhere> {
  QueryBuilder<OnboardingPrefModel, OnboardingPrefModel, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}
