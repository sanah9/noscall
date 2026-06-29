// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_configuration_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCashuWalletConfigurationRecordCollection on Isar {
  IsarCollection<CashuWalletConfigurationRecord>
      get cashuWalletConfigurationRecords => this.collection();
}

const CashuWalletConfigurationRecordSchema = CollectionSchema(
  name: r'CashuWalletConfigurationRecord',
  id: 1783289616838310878,
  properties: {
    r'backupStatus': PropertySchema(
      id: 0,
      name: r'backupStatus',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'ownerPubkey': PropertySchema(
      id: 2,
      name: r'ownerPubkey',
      type: IsarType.string,
    ),
    r'schemaVersion': PropertySchema(
      id: 3,
      name: r'schemaVersion',
      type: IsarType.long,
    ),
    r'seedReference': PropertySchema(
      id: 4,
      name: r'seedReference',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.long,
    )
  },
  estimateSize: _cashuWalletConfigurationRecordEstimateSize,
  serialize: _cashuWalletConfigurationRecordSerialize,
  deserialize: _cashuWalletConfigurationRecordDeserialize,
  deserializeProp: _cashuWalletConfigurationRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerPubkey': IndexSchema(
      id: 4119672793839774934,
      name: r'ownerPubkey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'ownerPubkey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cashuWalletConfigurationRecordGetId,
  getLinks: _cashuWalletConfigurationRecordGetLinks,
  attach: _cashuWalletConfigurationRecordAttach,
  version: '3.1.0+1',
);

int _cashuWalletConfigurationRecordEstimateSize(
  CashuWalletConfigurationRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.backupStatus.length * 3;
  bytesCount += 3 + object.ownerPubkey.length * 3;
  bytesCount += 3 + object.seedReference.length * 3;
  return bytesCount;
}

void _cashuWalletConfigurationRecordSerialize(
  CashuWalletConfigurationRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.backupStatus);
  writer.writeLong(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.ownerPubkey);
  writer.writeLong(offsets[3], object.schemaVersion);
  writer.writeString(offsets[4], object.seedReference);
  writer.writeLong(offsets[5], object.updatedAt);
}

CashuWalletConfigurationRecord _cashuWalletConfigurationRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CashuWalletConfigurationRecord();
  object.backupStatus = reader.readString(offsets[0]);
  object.createdAt = reader.readLong(offsets[1]);
  object.id = id;
  object.ownerPubkey = reader.readString(offsets[2]);
  object.schemaVersion = reader.readLong(offsets[3]);
  object.seedReference = reader.readString(offsets[4]);
  object.updatedAt = reader.readLong(offsets[5]);
  return object;
}

P _cashuWalletConfigurationRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cashuWalletConfigurationRecordGetId(CashuWalletConfigurationRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cashuWalletConfigurationRecordGetLinks(
    CashuWalletConfigurationRecord object) {
  return [];
}

void _cashuWalletConfigurationRecordAttach(
    IsarCollection<dynamic> col, Id id, CashuWalletConfigurationRecord object) {
  object.id = id;
}

extension CashuWalletConfigurationRecordByIndex
    on IsarCollection<CashuWalletConfigurationRecord> {
  Future<CashuWalletConfigurationRecord?> getByOwnerPubkey(String ownerPubkey) {
    return getByIndex(r'ownerPubkey', [ownerPubkey]);
  }

  CashuWalletConfigurationRecord? getByOwnerPubkeySync(String ownerPubkey) {
    return getByIndexSync(r'ownerPubkey', [ownerPubkey]);
  }

  Future<bool> deleteByOwnerPubkey(String ownerPubkey) {
    return deleteByIndex(r'ownerPubkey', [ownerPubkey]);
  }

  bool deleteByOwnerPubkeySync(String ownerPubkey) {
    return deleteByIndexSync(r'ownerPubkey', [ownerPubkey]);
  }

  Future<List<CashuWalletConfigurationRecord?>> getAllByOwnerPubkey(
      List<String> ownerPubkeyValues) {
    final values = ownerPubkeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'ownerPubkey', values);
  }

  List<CashuWalletConfigurationRecord?> getAllByOwnerPubkeySync(
      List<String> ownerPubkeyValues) {
    final values = ownerPubkeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'ownerPubkey', values);
  }

  Future<int> deleteAllByOwnerPubkey(List<String> ownerPubkeyValues) {
    final values = ownerPubkeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'ownerPubkey', values);
  }

  int deleteAllByOwnerPubkeySync(List<String> ownerPubkeyValues) {
    final values = ownerPubkeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'ownerPubkey', values);
  }

  Future<Id> putByOwnerPubkey(CashuWalletConfigurationRecord object) {
    return putByIndex(r'ownerPubkey', object);
  }

  Id putByOwnerPubkeySync(CashuWalletConfigurationRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'ownerPubkey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerPubkey(
      List<CashuWalletConfigurationRecord> objects) {
    return putAllByIndex(r'ownerPubkey', objects);
  }

  List<Id> putAllByOwnerPubkeySync(List<CashuWalletConfigurationRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'ownerPubkey', objects, saveLinks: saveLinks);
  }
}

extension CashuWalletConfigurationRecordQueryWhereSort on QueryBuilder<
    CashuWalletConfigurationRecord, CashuWalletConfigurationRecord, QWhere> {
  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CashuWalletConfigurationRecordQueryWhere on QueryBuilder<
    CashuWalletConfigurationRecord,
    CashuWalletConfigurationRecord,
    QWhereClause> {
  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
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

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
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

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterWhereClause> ownerPubkeyEqualTo(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerPubkey',
        value: [ownerPubkey],
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterWhereClause> ownerPubkeyNotEqualTo(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey',
              lower: [],
              upper: [ownerPubkey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey',
              lower: [ownerPubkey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey',
              lower: [ownerPubkey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey',
              lower: [],
              upper: [ownerPubkey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CashuWalletConfigurationRecordQueryFilter on QueryBuilder<
    CashuWalletConfigurationRecord,
    CashuWalletConfigurationRecord,
    QFilterCondition> {
  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> backupStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backupStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> backupStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'backupStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> backupStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'backupStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> backupStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'backupStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> backupStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'backupStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> backupStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'backupStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
          QAfterFilterCondition>
      backupStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'backupStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
          QAfterFilterCondition>
      backupStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'backupStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> backupStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backupStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> backupStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'backupStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> createdAtGreaterThan(
    int value, {
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

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> createdAtLessThan(
    int value, {
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

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> createdAtBetween(
    int lower,
    int upper, {
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

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
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

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
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

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
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

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerPubkey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
          QAfterFilterCondition>
      ownerPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
          QAfterFilterCondition>
      ownerPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerPubkey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerPubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerPubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> schemaVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> schemaVersionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> schemaVersionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'schemaVersion',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> schemaVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'schemaVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> seedReferenceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seedReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> seedReferenceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'seedReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> seedReferenceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'seedReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> seedReferenceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'seedReference',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> seedReferenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'seedReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> seedReferenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'seedReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
          QAfterFilterCondition>
      seedReferenceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'seedReference',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
          QAfterFilterCondition>
      seedReferenceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'seedReference',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> seedReferenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seedReference',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> seedReferenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'seedReference',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> updatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> updatedAtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> updatedAtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterFilterCondition> updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CashuWalletConfigurationRecordQueryObject on QueryBuilder<
    CashuWalletConfigurationRecord,
    CashuWalletConfigurationRecord,
    QFilterCondition> {}

extension CashuWalletConfigurationRecordQueryLinks on QueryBuilder<
    CashuWalletConfigurationRecord,
    CashuWalletConfigurationRecord,
    QFilterCondition> {}

extension CashuWalletConfigurationRecordQuerySortBy on QueryBuilder<
    CashuWalletConfigurationRecord, CashuWalletConfigurationRecord, QSortBy> {
  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortByBackupStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupStatus', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortByBackupStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupStatus', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortBySeedReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedReference', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortBySeedReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedReference', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CashuWalletConfigurationRecordQuerySortThenBy on QueryBuilder<
    CashuWalletConfigurationRecord,
    CashuWalletConfigurationRecord,
    QSortThenBy> {
  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenByBackupStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupStatus', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenByBackupStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupStatus', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenBySchemaVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'schemaVersion', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenBySeedReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedReference', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenBySeedReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seedReference', Sort.desc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CashuWalletConfigurationRecordQueryWhereDistinct on QueryBuilder<
    CashuWalletConfigurationRecord, CashuWalletConfigurationRecord, QDistinct> {
  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QDistinct> distinctByBackupStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'backupStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QDistinct> distinctByOwnerPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QDistinct> distinctBySchemaVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'schemaVersion');
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QDistinct> distinctBySeedReference({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seedReference',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, CashuWalletConfigurationRecord,
      QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CashuWalletConfigurationRecordQueryProperty on QueryBuilder<
    CashuWalletConfigurationRecord,
    CashuWalletConfigurationRecord,
    QQueryProperty> {
  QueryBuilder<CashuWalletConfigurationRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, String, QQueryOperations>
      backupStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backupStatus');
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, int, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, String, QQueryOperations>
      ownerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerPubkey');
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, int, QQueryOperations>
      schemaVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'schemaVersion');
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, String, QQueryOperations>
      seedReferenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seedReference');
    });
  }

  QueryBuilder<CashuWalletConfigurationRecord, int, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCashuMintConfigurationRecordCollection on Isar {
  IsarCollection<CashuMintConfigurationRecord>
      get cashuMintConfigurationRecords => this.collection();
}

const CashuMintConfigurationRecordSchema = CollectionSchema(
  name: r'CashuMintConfigurationRecord',
  id: 917922194365951873,
  properties: {
    r'description': PropertySchema(
      id: 0,
      name: r'description',
      type: IsarType.string,
    ),
    r'enabled': PropertySchema(
      id: 1,
      name: r'enabled',
      type: IsarType.bool,
    ),
    r'lastError': PropertySchema(
      id: 2,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'lastSyncAt': PropertySchema(
      id: 3,
      name: r'lastSyncAt',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'normalizedUrl': PropertySchema(
      id: 5,
      name: r'normalizedUrl',
      type: IsarType.string,
    ),
    r'ownerPubkey': PropertySchema(
      id: 6,
      name: r'ownerPubkey',
      type: IsarType.string,
    ),
    r'source': PropertySchema(
      id: 7,
      name: r'source',
      type: IsarType.string,
    ),
    r'supportedNutNumbers': PropertySchema(
      id: 8,
      name: r'supportedNutNumbers',
      type: IsarType.longList,
    ),
    r'units': PropertySchema(
      id: 9,
      name: r'units',
      type: IsarType.stringList,
    )
  },
  estimateSize: _cashuMintConfigurationRecordEstimateSize,
  serialize: _cashuMintConfigurationRecordSerialize,
  deserialize: _cashuMintConfigurationRecordDeserialize,
  deserializeProp: _cashuMintConfigurationRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerPubkey_normalizedUrl': IndexSchema(
      id: 4923627344887286795,
      name: r'ownerPubkey_normalizedUrl',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'ownerPubkey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'normalizedUrl',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cashuMintConfigurationRecordGetId,
  getLinks: _cashuMintConfigurationRecordGetLinks,
  attach: _cashuMintConfigurationRecordAttach,
  version: '3.1.0+1',
);

int _cashuMintConfigurationRecordEstimateSize(
  CashuMintConfigurationRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.normalizedUrl.length * 3;
  bytesCount += 3 + object.ownerPubkey.length * 3;
  bytesCount += 3 + object.source.length * 3;
  bytesCount += 3 + object.supportedNutNumbers.length * 8;
  bytesCount += 3 + object.units.length * 3;
  {
    for (var i = 0; i < object.units.length; i++) {
      final value = object.units[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _cashuMintConfigurationRecordSerialize(
  CashuMintConfigurationRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.description);
  writer.writeBool(offsets[1], object.enabled);
  writer.writeString(offsets[2], object.lastError);
  writer.writeLong(offsets[3], object.lastSyncAt);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.normalizedUrl);
  writer.writeString(offsets[6], object.ownerPubkey);
  writer.writeString(offsets[7], object.source);
  writer.writeLongList(offsets[8], object.supportedNutNumbers);
  writer.writeStringList(offsets[9], object.units);
}

CashuMintConfigurationRecord _cashuMintConfigurationRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CashuMintConfigurationRecord();
  object.description = reader.readStringOrNull(offsets[0]);
  object.enabled = reader.readBool(offsets[1]);
  object.id = id;
  object.lastError = reader.readStringOrNull(offsets[2]);
  object.lastSyncAt = reader.readLong(offsets[3]);
  object.name = reader.readStringOrNull(offsets[4]);
  object.normalizedUrl = reader.readString(offsets[5]);
  object.ownerPubkey = reader.readString(offsets[6]);
  object.source = reader.readString(offsets[7]);
  object.supportedNutNumbers = reader.readLongList(offsets[8]) ?? [];
  object.units = reader.readStringList(offsets[9]) ?? [];
  return object;
}

P _cashuMintConfigurationRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLongList(offset) ?? []) as P;
    case 9:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cashuMintConfigurationRecordGetId(CashuMintConfigurationRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cashuMintConfigurationRecordGetLinks(
    CashuMintConfigurationRecord object) {
  return [];
}

void _cashuMintConfigurationRecordAttach(
    IsarCollection<dynamic> col, Id id, CashuMintConfigurationRecord object) {
  object.id = id;
}

extension CashuMintConfigurationRecordByIndex
    on IsarCollection<CashuMintConfigurationRecord> {
  Future<CashuMintConfigurationRecord?> getByOwnerPubkeyNormalizedUrl(
      String ownerPubkey, String normalizedUrl) {
    return getByIndex(
        r'ownerPubkey_normalizedUrl', [ownerPubkey, normalizedUrl]);
  }

  CashuMintConfigurationRecord? getByOwnerPubkeyNormalizedUrlSync(
      String ownerPubkey, String normalizedUrl) {
    return getByIndexSync(
        r'ownerPubkey_normalizedUrl', [ownerPubkey, normalizedUrl]);
  }

  Future<bool> deleteByOwnerPubkeyNormalizedUrl(
      String ownerPubkey, String normalizedUrl) {
    return deleteByIndex(
        r'ownerPubkey_normalizedUrl', [ownerPubkey, normalizedUrl]);
  }

  bool deleteByOwnerPubkeyNormalizedUrlSync(
      String ownerPubkey, String normalizedUrl) {
    return deleteByIndexSync(
        r'ownerPubkey_normalizedUrl', [ownerPubkey, normalizedUrl]);
  }

  Future<List<CashuMintConfigurationRecord?>> getAllByOwnerPubkeyNormalizedUrl(
      List<String> ownerPubkeyValues, List<String> normalizedUrlValues) {
    final len = ownerPubkeyValues.length;
    assert(normalizedUrlValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], normalizedUrlValues[i]]);
    }

    return getAllByIndex(r'ownerPubkey_normalizedUrl', values);
  }

  List<CashuMintConfigurationRecord?> getAllByOwnerPubkeyNormalizedUrlSync(
      List<String> ownerPubkeyValues, List<String> normalizedUrlValues) {
    final len = ownerPubkeyValues.length;
    assert(normalizedUrlValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], normalizedUrlValues[i]]);
    }

    return getAllByIndexSync(r'ownerPubkey_normalizedUrl', values);
  }

  Future<int> deleteAllByOwnerPubkeyNormalizedUrl(
      List<String> ownerPubkeyValues, List<String> normalizedUrlValues) {
    final len = ownerPubkeyValues.length;
    assert(normalizedUrlValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], normalizedUrlValues[i]]);
    }

    return deleteAllByIndex(r'ownerPubkey_normalizedUrl', values);
  }

  int deleteAllByOwnerPubkeyNormalizedUrlSync(
      List<String> ownerPubkeyValues, List<String> normalizedUrlValues) {
    final len = ownerPubkeyValues.length;
    assert(normalizedUrlValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], normalizedUrlValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerPubkey_normalizedUrl', values);
  }

  Future<Id> putByOwnerPubkeyNormalizedUrl(
      CashuMintConfigurationRecord object) {
    return putByIndex(r'ownerPubkey_normalizedUrl', object);
  }

  Id putByOwnerPubkeyNormalizedUrlSync(CashuMintConfigurationRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'ownerPubkey_normalizedUrl', object,
        saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerPubkeyNormalizedUrl(
      List<CashuMintConfigurationRecord> objects) {
    return putAllByIndex(r'ownerPubkey_normalizedUrl', objects);
  }

  List<Id> putAllByOwnerPubkeyNormalizedUrlSync(
      List<CashuMintConfigurationRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'ownerPubkey_normalizedUrl', objects,
        saveLinks: saveLinks);
  }
}

extension CashuMintConfigurationRecordQueryWhereSort on QueryBuilder<
    CashuMintConfigurationRecord, CashuMintConfigurationRecord, QWhere> {
  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CashuMintConfigurationRecordQueryWhere on QueryBuilder<
    CashuMintConfigurationRecord, CashuMintConfigurationRecord, QWhereClause> {
  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
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

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
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

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterWhereClause>
      ownerPubkeyEqualToAnyNormalizedUrl(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerPubkey_normalizedUrl',
        value: [ownerPubkey],
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterWhereClause>
      ownerPubkeyNotEqualToAnyNormalizedUrl(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_normalizedUrl',
              lower: [],
              upper: [ownerPubkey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_normalizedUrl',
              lower: [ownerPubkey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_normalizedUrl',
              lower: [ownerPubkey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_normalizedUrl',
              lower: [],
              upper: [ownerPubkey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterWhereClause>
      ownerPubkeyNormalizedUrlEqualTo(
          String ownerPubkey, String normalizedUrl) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerPubkey_normalizedUrl',
        value: [ownerPubkey, normalizedUrl],
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterWhereClause>
      ownerPubkeyEqualToNormalizedUrlNotEqualTo(
          String ownerPubkey, String normalizedUrl) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_normalizedUrl',
              lower: [ownerPubkey],
              upper: [ownerPubkey, normalizedUrl],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_normalizedUrl',
              lower: [ownerPubkey, normalizedUrl],
              includeLower: false,
              upper: [ownerPubkey],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_normalizedUrl',
              lower: [ownerPubkey, normalizedUrl],
              includeLower: false,
              upper: [ownerPubkey],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_normalizedUrl',
              lower: [ownerPubkey],
              upper: [ownerPubkey, normalizedUrl],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CashuMintConfigurationRecordQueryFilter on QueryBuilder<
    CashuMintConfigurationRecord,
    CashuMintConfigurationRecord,
    QFilterCondition> {
  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> enabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enabled',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
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

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
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

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
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

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastError',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastError',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastError',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastError',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastError',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastSyncAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastSyncAtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastSyncAtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> lastSyncAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> normalizedUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> normalizedUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'normalizedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> normalizedUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'normalizedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> normalizedUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'normalizedUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> normalizedUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'normalizedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> normalizedUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'normalizedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      normalizedUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'normalizedUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      normalizedUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'normalizedUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> normalizedUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizedUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> normalizedUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'normalizedUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerPubkey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      ownerPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      ownerPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerPubkey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerPubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> ownerPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerPubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supportedNutNumbers',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supportedNutNumbers',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supportedNutNumbers',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supportedNutNumbers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNutNumbers',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNutNumbers',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNutNumbers',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNutNumbers',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNutNumbers',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> supportedNutNumbersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNutNumbers',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'units',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'units',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'units',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'units',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'units',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'units',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      unitsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'units',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
          QAfterFilterCondition>
      unitsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'units',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'units',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'units',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'units',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'units',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'units',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'units',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'units',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterFilterCondition> unitsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'units',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension CashuMintConfigurationRecordQueryObject on QueryBuilder<
    CashuMintConfigurationRecord,
    CashuMintConfigurationRecord,
    QFilterCondition> {}

extension CashuMintConfigurationRecordQueryLinks on QueryBuilder<
    CashuMintConfigurationRecord,
    CashuMintConfigurationRecord,
    QFilterCondition> {}

extension CashuMintConfigurationRecordQuerySortBy on QueryBuilder<
    CashuMintConfigurationRecord, CashuMintConfigurationRecord, QSortBy> {
  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByNormalizedUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedUrl', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByNormalizedUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedUrl', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }
}

extension CashuMintConfigurationRecordQuerySortThenBy on QueryBuilder<
    CashuMintConfigurationRecord, CashuMintConfigurationRecord, QSortThenBy> {
  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByNormalizedUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedUrl', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByNormalizedUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'normalizedUrl', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }
}

extension CashuMintConfigurationRecordQueryWhereDistinct on QueryBuilder<
    CashuMintConfigurationRecord, CashuMintConfigurationRecord, QDistinct> {
  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctByLastError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctByNormalizedUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'normalizedUrl',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctByOwnerPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctBySource({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctBySupportedNutNumbers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supportedNutNumbers');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, CashuMintConfigurationRecord,
      QDistinct> distinctByUnits() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'units');
    });
  }
}

extension CashuMintConfigurationRecordQueryProperty on QueryBuilder<
    CashuMintConfigurationRecord,
    CashuMintConfigurationRecord,
    QQueryProperty> {
  QueryBuilder<CashuMintConfigurationRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, bool, QQueryOperations>
      enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, String?, QQueryOperations>
      lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, int, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, String?, QQueryOperations>
      nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, String, QQueryOperations>
      normalizedUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'normalizedUrl');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, String, QQueryOperations>
      ownerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerPubkey');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, String, QQueryOperations>
      sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, List<int>, QQueryOperations>
      supportedNutNumbersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supportedNutNumbers');
    });
  }

  QueryBuilder<CashuMintConfigurationRecord, List<String>, QQueryOperations>
      unitsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'units');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCashuTokenSendOperationRecordCollection on Isar {
  IsarCollection<CashuTokenSendOperationRecord>
      get cashuTokenSendOperationRecords => this.collection();
}

const CashuTokenSendOperationRecordSchema = CollectionSchema(
  name: r'CashuTokenSendOperationRecord',
  id: -9115904375010562033,
  properties: {
    r'amountSats': PropertySchema(
      id: 0,
      name: r'amountSats',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'memo': PropertySchema(
      id: 2,
      name: r'memo',
      type: IsarType.string,
    ),
    r'mintUrl': PropertySchema(
      id: 3,
      name: r'mintUrl',
      type: IsarType.string,
    ),
    r'operationId': PropertySchema(
      id: 4,
      name: r'operationId',
      type: IsarType.string,
    ),
    r'ownerPubkey': PropertySchema(
      id: 5,
      name: r'ownerPubkey',
      type: IsarType.string,
    ),
    r'state': PropertySchema(
      id: 6,
      name: r'state',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.long,
    )
  },
  estimateSize: _cashuTokenSendOperationRecordEstimateSize,
  serialize: _cashuTokenSendOperationRecordSerialize,
  deserialize: _cashuTokenSendOperationRecordDeserialize,
  deserializeProp: _cashuTokenSendOperationRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerPubkey_operationId': IndexSchema(
      id: 8648477427622958036,
      name: r'ownerPubkey_operationId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'ownerPubkey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'operationId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cashuTokenSendOperationRecordGetId,
  getLinks: _cashuTokenSendOperationRecordGetLinks,
  attach: _cashuTokenSendOperationRecordAttach,
  version: '3.1.0+1',
);

int _cashuTokenSendOperationRecordEstimateSize(
  CashuTokenSendOperationRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.memo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mintUrl.length * 3;
  bytesCount += 3 + object.operationId.length * 3;
  bytesCount += 3 + object.ownerPubkey.length * 3;
  bytesCount += 3 + object.state.length * 3;
  return bytesCount;
}

void _cashuTokenSendOperationRecordSerialize(
  CashuTokenSendOperationRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amountSats);
  writer.writeLong(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.memo);
  writer.writeString(offsets[3], object.mintUrl);
  writer.writeString(offsets[4], object.operationId);
  writer.writeString(offsets[5], object.ownerPubkey);
  writer.writeString(offsets[6], object.state);
  writer.writeLong(offsets[7], object.updatedAt);
}

CashuTokenSendOperationRecord _cashuTokenSendOperationRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CashuTokenSendOperationRecord();
  object.amountSats = reader.readLong(offsets[0]);
  object.createdAt = reader.readLong(offsets[1]);
  object.id = id;
  object.memo = reader.readStringOrNull(offsets[2]);
  object.mintUrl = reader.readString(offsets[3]);
  object.operationId = reader.readString(offsets[4]);
  object.ownerPubkey = reader.readString(offsets[5]);
  object.state = reader.readString(offsets[6]);
  object.updatedAt = reader.readLong(offsets[7]);
  return object;
}

P _cashuTokenSendOperationRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cashuTokenSendOperationRecordGetId(CashuTokenSendOperationRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cashuTokenSendOperationRecordGetLinks(
    CashuTokenSendOperationRecord object) {
  return [];
}

void _cashuTokenSendOperationRecordAttach(
    IsarCollection<dynamic> col, Id id, CashuTokenSendOperationRecord object) {
  object.id = id;
}

extension CashuTokenSendOperationRecordByIndex
    on IsarCollection<CashuTokenSendOperationRecord> {
  Future<CashuTokenSendOperationRecord?> getByOwnerPubkeyOperationId(
      String ownerPubkey, String operationId) {
    return getByIndex(r'ownerPubkey_operationId', [ownerPubkey, operationId]);
  }

  CashuTokenSendOperationRecord? getByOwnerPubkeyOperationIdSync(
      String ownerPubkey, String operationId) {
    return getByIndexSync(
        r'ownerPubkey_operationId', [ownerPubkey, operationId]);
  }

  Future<bool> deleteByOwnerPubkeyOperationId(
      String ownerPubkey, String operationId) {
    return deleteByIndex(
        r'ownerPubkey_operationId', [ownerPubkey, operationId]);
  }

  bool deleteByOwnerPubkeyOperationIdSync(
      String ownerPubkey, String operationId) {
    return deleteByIndexSync(
        r'ownerPubkey_operationId', [ownerPubkey, operationId]);
  }

  Future<List<CashuTokenSendOperationRecord?>> getAllByOwnerPubkeyOperationId(
      List<String> ownerPubkeyValues, List<String> operationIdValues) {
    final len = ownerPubkeyValues.length;
    assert(operationIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], operationIdValues[i]]);
    }

    return getAllByIndex(r'ownerPubkey_operationId', values);
  }

  List<CashuTokenSendOperationRecord?> getAllByOwnerPubkeyOperationIdSync(
      List<String> ownerPubkeyValues, List<String> operationIdValues) {
    final len = ownerPubkeyValues.length;
    assert(operationIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], operationIdValues[i]]);
    }

    return getAllByIndexSync(r'ownerPubkey_operationId', values);
  }

  Future<int> deleteAllByOwnerPubkeyOperationId(
      List<String> ownerPubkeyValues, List<String> operationIdValues) {
    final len = ownerPubkeyValues.length;
    assert(operationIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], operationIdValues[i]]);
    }

    return deleteAllByIndex(r'ownerPubkey_operationId', values);
  }

  int deleteAllByOwnerPubkeyOperationIdSync(
      List<String> ownerPubkeyValues, List<String> operationIdValues) {
    final len = ownerPubkeyValues.length;
    assert(operationIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], operationIdValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerPubkey_operationId', values);
  }

  Future<Id> putByOwnerPubkeyOperationId(CashuTokenSendOperationRecord object) {
    return putByIndex(r'ownerPubkey_operationId', object);
  }

  Id putByOwnerPubkeyOperationIdSync(CashuTokenSendOperationRecord object,
      {bool saveLinks = true}) {
    return putByIndexSync(r'ownerPubkey_operationId', object,
        saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerPubkeyOperationId(
      List<CashuTokenSendOperationRecord> objects) {
    return putAllByIndex(r'ownerPubkey_operationId', objects);
  }

  List<Id> putAllByOwnerPubkeyOperationIdSync(
      List<CashuTokenSendOperationRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'ownerPubkey_operationId', objects,
        saveLinks: saveLinks);
  }
}

extension CashuTokenSendOperationRecordQueryWhereSort on QueryBuilder<
    CashuTokenSendOperationRecord, CashuTokenSendOperationRecord, QWhere> {
  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CashuTokenSendOperationRecordQueryWhere on QueryBuilder<
    CashuTokenSendOperationRecord,
    CashuTokenSendOperationRecord,
    QWhereClause> {
  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
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

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
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

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterWhereClause> ownerPubkeyEqualToAnyOperationId(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerPubkey_operationId',
        value: [ownerPubkey],
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterWhereClause>
      ownerPubkeyNotEqualToAnyOperationId(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_operationId',
              lower: [],
              upper: [ownerPubkey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_operationId',
              lower: [ownerPubkey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_operationId',
              lower: [ownerPubkey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_operationId',
              lower: [],
              upper: [ownerPubkey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterWhereClause>
      ownerPubkeyOperationIdEqualTo(String ownerPubkey, String operationId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ownerPubkey_operationId',
        value: [ownerPubkey, operationId],
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterWhereClause>
      ownerPubkeyEqualToOperationIdNotEqualTo(
          String ownerPubkey, String operationId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_operationId',
              lower: [ownerPubkey],
              upper: [ownerPubkey, operationId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_operationId',
              lower: [ownerPubkey, operationId],
              includeLower: false,
              upper: [ownerPubkey],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_operationId',
              lower: [ownerPubkey, operationId],
              includeLower: false,
              upper: [ownerPubkey],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ownerPubkey_operationId',
              lower: [ownerPubkey],
              upper: [ownerPubkey, operationId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CashuTokenSendOperationRecordQueryFilter on QueryBuilder<
    CashuTokenSendOperationRecord,
    CashuTokenSendOperationRecord,
    QFilterCondition> {
  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> amountSatsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountSats',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> amountSatsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountSats',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> amountSatsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountSats',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> amountSatsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountSats',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> createdAtGreaterThan(
    int value, {
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

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> createdAtLessThan(
    int value, {
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

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> createdAtBetween(
    int lower,
    int upper, {
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

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
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

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
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

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
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

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'memo',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'memo',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'memo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'memo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'memo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'memo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'memo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      memoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'memo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      memoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'memo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'memo',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> memoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'memo',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> mintUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mintUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> mintUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mintUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> mintUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mintUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> mintUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mintUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> mintUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mintUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> mintUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mintUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      mintUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mintUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      mintUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mintUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> mintUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mintUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> mintUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mintUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> operationIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'operationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> operationIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'operationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> operationIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'operationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> operationIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'operationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> operationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'operationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> operationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'operationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      operationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'operationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      operationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'operationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> operationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'operationId',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> operationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'operationId',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> ownerPubkeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> ownerPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> ownerPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> ownerPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownerPubkey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> ownerPubkeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> ownerPubkeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      ownerPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownerPubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      ownerPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownerPubkey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> ownerPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownerPubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> ownerPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownerPubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> stateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> stateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> stateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> stateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'state',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> stateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> stateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      stateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
          QAfterFilterCondition>
      stateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'state',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> stateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> stateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> updatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> updatedAtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> updatedAtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterFilterCondition> updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CashuTokenSendOperationRecordQueryObject on QueryBuilder<
    CashuTokenSendOperationRecord,
    CashuTokenSendOperationRecord,
    QFilterCondition> {}

extension CashuTokenSendOperationRecordQueryLinks on QueryBuilder<
    CashuTokenSendOperationRecord,
    CashuTokenSendOperationRecord,
    QFilterCondition> {}

extension CashuTokenSendOperationRecordQuerySortBy on QueryBuilder<
    CashuTokenSendOperationRecord, CashuTokenSendOperationRecord, QSortBy> {
  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByAmountSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountSats', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByAmountSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountSats', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByMemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memo', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByMemoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memo', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByMintUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByMintUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByOperationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationId', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByOperationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationId', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CashuTokenSendOperationRecordQuerySortThenBy on QueryBuilder<
    CashuTokenSendOperationRecord, CashuTokenSendOperationRecord, QSortThenBy> {
  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByAmountSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountSats', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByAmountSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountSats', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByMemo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memo', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByMemoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memo', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByMintUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByMintUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByOperationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationId', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByOperationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'operationId', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CashuTokenSendOperationRecordQueryWhereDistinct on QueryBuilder<
    CashuTokenSendOperationRecord, CashuTokenSendOperationRecord, QDistinct> {
  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QDistinct> distinctByAmountSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountSats');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QDistinct> distinctByMemo({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QDistinct> distinctByMintUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mintUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QDistinct> distinctByOperationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'operationId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QDistinct> distinctByOwnerPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QDistinct> distinctByState({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, CashuTokenSendOperationRecord,
      QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CashuTokenSendOperationRecordQueryProperty on QueryBuilder<
    CashuTokenSendOperationRecord,
    CashuTokenSendOperationRecord,
    QQueryProperty> {
  QueryBuilder<CashuTokenSendOperationRecord, int, QQueryOperations>
      idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, int, QQueryOperations>
      amountSatsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountSats');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, int, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, String?, QQueryOperations>
      memoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memo');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, String, QQueryOperations>
      mintUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mintUrl');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, String, QQueryOperations>
      operationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'operationId');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, String, QQueryOperations>
      ownerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerPubkey');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, String, QQueryOperations>
      stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<CashuTokenSendOperationRecord, int, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
