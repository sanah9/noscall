// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_payment_isar.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCallPaymentPolicyRecordCollection on Isar {
  IsarCollection<CallPaymentPolicyRecord> get callPaymentPolicyRecords =>
      this.collection();
}

const CallPaymentPolicyRecordSchema = CollectionSchema(
  name: r'CallPaymentPolicyRecord',
  id: -3183534336283167350,
  properties: {
    r'acceptedMintUrls': PropertySchema(
      id: 0,
      name: r'acceptedMintUrls',
      type: IsarType.stringList,
    ),
    r'audioPriceSatsPerMinute': PropertySchema(
      id: 1,
      name: r'audioPriceSatsPerMinute',
      type: IsarType.long,
    ),
    r'billingPeriodSeconds': PropertySchema(
      id: 2,
      name: r'billingPeriodSeconds',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'enabled': PropertySchema(id: 4, name: r'enabled', type: IsarType.bool),
    r'freePolicy': PropertySchema(
      id: 5,
      name: r'freePolicy',
      type: IsarType.string,
    ),
    r'freePubkeys': PropertySchema(
      id: 6,
      name: r'freePubkeys',
      type: IsarType.stringList,
    ),
    r'gracePeriodSeconds': PropertySchema(
      id: 7,
      name: r'gracePeriodSeconds',
      type: IsarType.long,
    ),
    r'ownerPubkey': PropertySchema(
      id: 8,
      name: r'ownerPubkey',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.long,
    ),
    r'videoPriceSatsPerMinute': PropertySchema(
      id: 10,
      name: r'videoPriceSatsPerMinute',
      type: IsarType.long,
    ),
  },
  estimateSize: _callPaymentPolicyRecordEstimateSize,
  serialize: _callPaymentPolicyRecordSerialize,
  deserialize: _callPaymentPolicyRecordDeserialize,
  deserializeProp: _callPaymentPolicyRecordDeserializeProp,
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
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _callPaymentPolicyRecordGetId,
  getLinks: _callPaymentPolicyRecordGetLinks,
  attach: _callPaymentPolicyRecordAttach,
  version: '3.1.0+1',
);

int _callPaymentPolicyRecordEstimateSize(
  CallPaymentPolicyRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.acceptedMintUrls.length * 3;
  {
    for (var i = 0; i < object.acceptedMintUrls.length; i++) {
      final value = object.acceptedMintUrls[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.freePolicy.length * 3;
  bytesCount += 3 + object.freePubkeys.length * 3;
  {
    for (var i = 0; i < object.freePubkeys.length; i++) {
      final value = object.freePubkeys[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.ownerPubkey.length * 3;
  return bytesCount;
}

void _callPaymentPolicyRecordSerialize(
  CallPaymentPolicyRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.acceptedMintUrls);
  writer.writeLong(offsets[1], object.audioPriceSatsPerMinute);
  writer.writeLong(offsets[2], object.billingPeriodSeconds);
  writer.writeLong(offsets[3], object.createdAt);
  writer.writeBool(offsets[4], object.enabled);
  writer.writeString(offsets[5], object.freePolicy);
  writer.writeStringList(offsets[6], object.freePubkeys);
  writer.writeLong(offsets[7], object.gracePeriodSeconds);
  writer.writeString(offsets[8], object.ownerPubkey);
  writer.writeLong(offsets[9], object.updatedAt);
  writer.writeLong(offsets[10], object.videoPriceSatsPerMinute);
}

CallPaymentPolicyRecord _callPaymentPolicyRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CallPaymentPolicyRecord();
  object.acceptedMintUrls = reader.readStringList(offsets[0]) ?? [];
  object.audioPriceSatsPerMinute = reader.readLong(offsets[1]);
  object.billingPeriodSeconds = reader.readLong(offsets[2]);
  object.createdAt = reader.readLong(offsets[3]);
  object.enabled = reader.readBool(offsets[4]);
  object.freePolicy = reader.readString(offsets[5]);
  object.freePubkeys = reader.readStringList(offsets[6]) ?? [];
  object.gracePeriodSeconds = reader.readLong(offsets[7]);
  object.id = id;
  object.ownerPubkey = reader.readString(offsets[8]);
  object.updatedAt = reader.readLong(offsets[9]);
  object.videoPriceSatsPerMinute = reader.readLong(offsets[10]);
  return object;
}

P _callPaymentPolicyRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringList(offset) ?? []) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _callPaymentPolicyRecordGetId(CallPaymentPolicyRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _callPaymentPolicyRecordGetLinks(
  CallPaymentPolicyRecord object,
) {
  return [];
}

void _callPaymentPolicyRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  CallPaymentPolicyRecord object,
) {
  object.id = id;
}

extension CallPaymentPolicyRecordByIndex
    on IsarCollection<CallPaymentPolicyRecord> {
  Future<CallPaymentPolicyRecord?> getByOwnerPubkey(String ownerPubkey) {
    return getByIndex(r'ownerPubkey', [ownerPubkey]);
  }

  CallPaymentPolicyRecord? getByOwnerPubkeySync(String ownerPubkey) {
    return getByIndexSync(r'ownerPubkey', [ownerPubkey]);
  }

  Future<bool> deleteByOwnerPubkey(String ownerPubkey) {
    return deleteByIndex(r'ownerPubkey', [ownerPubkey]);
  }

  bool deleteByOwnerPubkeySync(String ownerPubkey) {
    return deleteByIndexSync(r'ownerPubkey', [ownerPubkey]);
  }

  Future<List<CallPaymentPolicyRecord?>> getAllByOwnerPubkey(
    List<String> ownerPubkeyValues,
  ) {
    final values = ownerPubkeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'ownerPubkey', values);
  }

  List<CallPaymentPolicyRecord?> getAllByOwnerPubkeySync(
    List<String> ownerPubkeyValues,
  ) {
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

  Future<Id> putByOwnerPubkey(CallPaymentPolicyRecord object) {
    return putByIndex(r'ownerPubkey', object);
  }

  Id putByOwnerPubkeySync(
    CallPaymentPolicyRecord object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'ownerPubkey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerPubkey(List<CallPaymentPolicyRecord> objects) {
    return putAllByIndex(r'ownerPubkey', objects);
  }

  List<Id> putAllByOwnerPubkeySync(
    List<CallPaymentPolicyRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'ownerPubkey', objects, saveLinks: saveLinks);
  }
}

extension CallPaymentPolicyRecordQueryWhereSort
    on QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QWhere> {
  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CallPaymentPolicyRecordQueryWhere
    on
        QueryBuilder<
          CallPaymentPolicyRecord,
          CallPaymentPolicyRecord,
          QWhereClause
        > {
  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterWhereClause
  >
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterWhereClause
  >
  ownerPubkeyEqualTo(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerPubkey',
          value: [ownerPubkey],
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterWhereClause
  >
  ownerPubkeyNotEqualTo(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey',
                lower: [],
                upper: [ownerPubkey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey',
                lower: [ownerPubkey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey',
                lower: [ownerPubkey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey',
                lower: [],
                upper: [ownerPubkey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension CallPaymentPolicyRecordQueryFilter
    on
        QueryBuilder<
          CallPaymentPolicyRecord,
          CallPaymentPolicyRecord,
          QFilterCondition
        > {
  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'acceptedMintUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'acceptedMintUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'acceptedMintUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'acceptedMintUrls',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'acceptedMintUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'acceptedMintUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'acceptedMintUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'acceptedMintUrls',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'acceptedMintUrls', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'acceptedMintUrls', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'acceptedMintUrls', length, true, length, true);
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'acceptedMintUrls', 0, true, 0, true);
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'acceptedMintUrls', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'acceptedMintUrls', 0, true, length, include);
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'acceptedMintUrls',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  acceptedMintUrlsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'acceptedMintUrls',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  audioPriceSatsPerMinuteEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'audioPriceSatsPerMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  audioPriceSatsPerMinuteGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'audioPriceSatsPerMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  audioPriceSatsPerMinuteLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'audioPriceSatsPerMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  audioPriceSatsPerMinuteBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'audioPriceSatsPerMinute',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  billingPeriodSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'billingPeriodSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  billingPeriodSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'billingPeriodSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  billingPeriodSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'billingPeriodSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  billingPeriodSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'billingPeriodSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  createdAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  createdAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  createdAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  enabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'enabled', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'freePolicy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'freePolicy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'freePolicy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'freePolicy',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'freePolicy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'freePolicy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'freePolicy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'freePolicy',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'freePolicy', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePolicyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'freePolicy', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'freePubkeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'freePubkeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'freePubkeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'freePubkeys',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'freePubkeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'freePubkeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'freePubkeys',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'freePubkeys',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'freePubkeys', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'freePubkeys', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'freePubkeys', length, true, length, true);
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'freePubkeys', 0, true, 0, true);
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'freePubkeys', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'freePubkeys', 0, true, length, include);
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'freePubkeys', length, include, 999999, true);
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  freePubkeysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'freePubkeys',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  gracePeriodSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'gracePeriodSeconds', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  gracePeriodSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'gracePeriodSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  gracePeriodSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'gracePeriodSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  gracePeriodSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'gracePeriodSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerPubkey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ownerPubkey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerPubkey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  ownerPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerPubkey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  updatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  updatedAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  videoPriceSatsPerMinuteEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'videoPriceSatsPerMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  videoPriceSatsPerMinuteGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'videoPriceSatsPerMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  videoPriceSatsPerMinuteLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'videoPriceSatsPerMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentPolicyRecord,
    CallPaymentPolicyRecord,
    QAfterFilterCondition
  >
  videoPriceSatsPerMinuteBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'videoPriceSatsPerMinute',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CallPaymentPolicyRecordQueryObject
    on
        QueryBuilder<
          CallPaymentPolicyRecord,
          CallPaymentPolicyRecord,
          QFilterCondition
        > {}

extension CallPaymentPolicyRecordQueryLinks
    on
        QueryBuilder<
          CallPaymentPolicyRecord,
          CallPaymentPolicyRecord,
          QFilterCondition
        > {}

extension CallPaymentPolicyRecordQuerySortBy
    on QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QSortBy> {
  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByAudioPriceSatsPerMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioPriceSatsPerMinute', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByAudioPriceSatsPerMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioPriceSatsPerMinute', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByBillingPeriodSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingPeriodSeconds', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByBillingPeriodSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingPeriodSeconds', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByFreePolicy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freePolicy', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByFreePolicyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freePolicy', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByGracePeriodSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gracePeriodSeconds', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByGracePeriodSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gracePeriodSeconds', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByVideoPriceSatsPerMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPriceSatsPerMinute', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  sortByVideoPriceSatsPerMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPriceSatsPerMinute', Sort.desc);
    });
  }
}

extension CallPaymentPolicyRecordQuerySortThenBy
    on
        QueryBuilder<
          CallPaymentPolicyRecord,
          CallPaymentPolicyRecord,
          QSortThenBy
        > {
  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByAudioPriceSatsPerMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioPriceSatsPerMinute', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByAudioPriceSatsPerMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioPriceSatsPerMinute', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByBillingPeriodSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingPeriodSeconds', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByBillingPeriodSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingPeriodSeconds', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByFreePolicy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freePolicy', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByFreePolicyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'freePolicy', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByGracePeriodSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gracePeriodSeconds', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByGracePeriodSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gracePeriodSeconds', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByVideoPriceSatsPerMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPriceSatsPerMinute', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QAfterSortBy>
  thenByVideoPriceSatsPerMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPriceSatsPerMinute', Sort.desc);
    });
  }
}

extension CallPaymentPolicyRecordQueryWhereDistinct
    on
        QueryBuilder<
          CallPaymentPolicyRecord,
          CallPaymentPolicyRecord,
          QDistinct
        > {
  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByAcceptedMintUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'acceptedMintUrls');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByAudioPriceSatsPerMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioPriceSatsPerMinute');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByBillingPeriodSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'billingPeriodSeconds');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByFreePolicy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'freePolicy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByFreePubkeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'freePubkeys');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByGracePeriodSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gracePeriodSeconds');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByOwnerPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, CallPaymentPolicyRecord, QDistinct>
  distinctByVideoPriceSatsPerMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'videoPriceSatsPerMinute');
    });
  }
}

extension CallPaymentPolicyRecordQueryProperty
    on
        QueryBuilder<
          CallPaymentPolicyRecord,
          CallPaymentPolicyRecord,
          QQueryProperty
        > {
  QueryBuilder<CallPaymentPolicyRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, List<String>, QQueryOperations>
  acceptedMintUrlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'acceptedMintUrls');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, int, QQueryOperations>
  audioPriceSatsPerMinuteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioPriceSatsPerMinute');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, int, QQueryOperations>
  billingPeriodSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'billingPeriodSeconds');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, int, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, bool, QQueryOperations>
  enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, String, QQueryOperations>
  freePolicyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'freePolicy');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, List<String>, QQueryOperations>
  freePubkeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'freePubkeys');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, int, QQueryOperations>
  gracePeriodSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gracePeriodSeconds');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, String, QQueryOperations>
  ownerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerPubkey');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, int, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<CallPaymentPolicyRecord, int, QQueryOperations>
  videoPriceSatsPerMinuteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'videoPriceSatsPerMinute');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCallPaymentSessionRecordCollection on Isar {
  IsarCollection<CallPaymentSessionRecord> get callPaymentSessionRecords =>
      this.collection();
}

const CallPaymentSessionRecordSchema = CollectionSchema(
  name: r'CallPaymentSessionRecord',
  id: -5539424445271575547,
  properties: {
    r'billingPeriodSeconds': PropertySchema(
      id: 0,
      name: r'billingPeriodSeconds',
      type: IsarType.long,
    ),
    r'callId': PropertySchema(id: 1, name: r'callId', type: IsarType.string),
    r'callType': PropertySchema(
      id: 2,
      name: r'callType',
      type: IsarType.string,
    ),
    r'chargedSats': PropertySchema(
      id: 3,
      name: r'chargedSats',
      type: IsarType.long,
    ),
    r'connectedAt': PropertySchema(
      id: 4,
      name: r'connectedAt',
      type: IsarType.long,
    ),
    r'connectedDurationSeconds': PropertySchema(
      id: 5,
      name: r'connectedDurationSeconds',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 6,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'direction': PropertySchema(
      id: 7,
      name: r'direction',
      type: IsarType.string,
    ),
    r'endedAt': PropertySchema(id: 8, name: r'endedAt', type: IsarType.long),
    r'maxSpendSats': PropertySchema(
      id: 9,
      name: r'maxSpendSats',
      type: IsarType.long,
    ),
    r'mintUrl': PropertySchema(id: 10, name: r'mintUrl', type: IsarType.string),
    r'ownerPubkey': PropertySchema(
      id: 11,
      name: r'ownerPubkey',
      type: IsarType.string,
    ),
    r'peerPubkey': PropertySchema(
      id: 12,
      name: r'peerPubkey',
      type: IsarType.string,
    ),
    r'priceSatsPerMinute': PropertySchema(
      id: 13,
      name: r'priceSatsPerMinute',
      type: IsarType.long,
    ),
    r'refundedSats': PropertySchema(
      id: 14,
      name: r'refundedSats',
      type: IsarType.long,
    ),
    r'role': PropertySchema(id: 15, name: r'role', type: IsarType.string),
    r'status': PropertySchema(id: 16, name: r'status', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 17,
      name: r'updatedAt',
      type: IsarType.long,
    ),
  },
  estimateSize: _callPaymentSessionRecordEstimateSize,
  serialize: _callPaymentSessionRecordSerialize,
  deserialize: _callPaymentSessionRecordDeserialize,
  deserializeProp: _callPaymentSessionRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerPubkey_callId': IndexSchema(
      id: -412053139585855362,
      name: r'ownerPubkey_callId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'ownerPubkey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'callId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _callPaymentSessionRecordGetId,
  getLinks: _callPaymentSessionRecordGetLinks,
  attach: _callPaymentSessionRecordAttach,
  version: '3.1.0+1',
);

int _callPaymentSessionRecordEstimateSize(
  CallPaymentSessionRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.callId.length * 3;
  bytesCount += 3 + object.callType.length * 3;
  bytesCount += 3 + object.direction.length * 3;
  bytesCount += 3 + object.mintUrl.length * 3;
  bytesCount += 3 + object.ownerPubkey.length * 3;
  bytesCount += 3 + object.peerPubkey.length * 3;
  bytesCount += 3 + object.role.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _callPaymentSessionRecordSerialize(
  CallPaymentSessionRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.billingPeriodSeconds);
  writer.writeString(offsets[1], object.callId);
  writer.writeString(offsets[2], object.callType);
  writer.writeLong(offsets[3], object.chargedSats);
  writer.writeLong(offsets[4], object.connectedAt);
  writer.writeLong(offsets[5], object.connectedDurationSeconds);
  writer.writeLong(offsets[6], object.createdAt);
  writer.writeString(offsets[7], object.direction);
  writer.writeLong(offsets[8], object.endedAt);
  writer.writeLong(offsets[9], object.maxSpendSats);
  writer.writeString(offsets[10], object.mintUrl);
  writer.writeString(offsets[11], object.ownerPubkey);
  writer.writeString(offsets[12], object.peerPubkey);
  writer.writeLong(offsets[13], object.priceSatsPerMinute);
  writer.writeLong(offsets[14], object.refundedSats);
  writer.writeString(offsets[15], object.role);
  writer.writeString(offsets[16], object.status);
  writer.writeLong(offsets[17], object.updatedAt);
}

CallPaymentSessionRecord _callPaymentSessionRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CallPaymentSessionRecord();
  object.billingPeriodSeconds = reader.readLong(offsets[0]);
  object.callId = reader.readString(offsets[1]);
  object.callType = reader.readString(offsets[2]);
  object.chargedSats = reader.readLong(offsets[3]);
  object.connectedAt = reader.readLongOrNull(offsets[4]);
  object.connectedDurationSeconds = reader.readLong(offsets[5]);
  object.createdAt = reader.readLong(offsets[6]);
  object.direction = reader.readString(offsets[7]);
  object.endedAt = reader.readLongOrNull(offsets[8]);
  object.id = id;
  object.maxSpendSats = reader.readLong(offsets[9]);
  object.mintUrl = reader.readString(offsets[10]);
  object.ownerPubkey = reader.readString(offsets[11]);
  object.peerPubkey = reader.readString(offsets[12]);
  object.priceSatsPerMinute = reader.readLong(offsets[13]);
  object.refundedSats = reader.readLong(offsets[14]);
  object.role = reader.readString(offsets[15]);
  object.status = reader.readString(offsets[16]);
  object.updatedAt = reader.readLong(offsets[17]);
  return object;
}

P _callPaymentSessionRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _callPaymentSessionRecordGetId(CallPaymentSessionRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _callPaymentSessionRecordGetLinks(
  CallPaymentSessionRecord object,
) {
  return [];
}

void _callPaymentSessionRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  CallPaymentSessionRecord object,
) {
  object.id = id;
}

extension CallPaymentSessionRecordByIndex
    on IsarCollection<CallPaymentSessionRecord> {
  Future<CallPaymentSessionRecord?> getByOwnerPubkeyCallId(
    String ownerPubkey,
    String callId,
  ) {
    return getByIndex(r'ownerPubkey_callId', [ownerPubkey, callId]);
  }

  CallPaymentSessionRecord? getByOwnerPubkeyCallIdSync(
    String ownerPubkey,
    String callId,
  ) {
    return getByIndexSync(r'ownerPubkey_callId', [ownerPubkey, callId]);
  }

  Future<bool> deleteByOwnerPubkeyCallId(String ownerPubkey, String callId) {
    return deleteByIndex(r'ownerPubkey_callId', [ownerPubkey, callId]);
  }

  bool deleteByOwnerPubkeyCallIdSync(String ownerPubkey, String callId) {
    return deleteByIndexSync(r'ownerPubkey_callId', [ownerPubkey, callId]);
  }

  Future<List<CallPaymentSessionRecord?>> getAllByOwnerPubkeyCallId(
    List<String> ownerPubkeyValues,
    List<String> callIdValues,
  ) {
    final len = ownerPubkeyValues.length;
    assert(
      callIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], callIdValues[i]]);
    }

    return getAllByIndex(r'ownerPubkey_callId', values);
  }

  List<CallPaymentSessionRecord?> getAllByOwnerPubkeyCallIdSync(
    List<String> ownerPubkeyValues,
    List<String> callIdValues,
  ) {
    final len = ownerPubkeyValues.length;
    assert(
      callIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], callIdValues[i]]);
    }

    return getAllByIndexSync(r'ownerPubkey_callId', values);
  }

  Future<int> deleteAllByOwnerPubkeyCallId(
    List<String> ownerPubkeyValues,
    List<String> callIdValues,
  ) {
    final len = ownerPubkeyValues.length;
    assert(
      callIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], callIdValues[i]]);
    }

    return deleteAllByIndex(r'ownerPubkey_callId', values);
  }

  int deleteAllByOwnerPubkeyCallIdSync(
    List<String> ownerPubkeyValues,
    List<String> callIdValues,
  ) {
    final len = ownerPubkeyValues.length;
    assert(
      callIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], callIdValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerPubkey_callId', values);
  }

  Future<Id> putByOwnerPubkeyCallId(CallPaymentSessionRecord object) {
    return putByIndex(r'ownerPubkey_callId', object);
  }

  Id putByOwnerPubkeyCallIdSync(
    CallPaymentSessionRecord object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'ownerPubkey_callId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOwnerPubkeyCallId(
    List<CallPaymentSessionRecord> objects,
  ) {
    return putAllByIndex(r'ownerPubkey_callId', objects);
  }

  List<Id> putAllByOwnerPubkeyCallIdSync(
    List<CallPaymentSessionRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'ownerPubkey_callId',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension CallPaymentSessionRecordQueryWhereSort
    on
        QueryBuilder<
          CallPaymentSessionRecord,
          CallPaymentSessionRecord,
          QWhere
        > {
  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CallPaymentSessionRecordQueryWhere
    on
        QueryBuilder<
          CallPaymentSessionRecord,
          CallPaymentSessionRecord,
          QWhereClause
        > {
  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterWhereClause
  >
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterWhereClause
  >
  ownerPubkeyEqualToAnyCallId(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerPubkey_callId',
          value: [ownerPubkey],
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterWhereClause
  >
  ownerPubkeyNotEqualToAnyCallId(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_callId',
                lower: [],
                upper: [ownerPubkey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_callId',
                lower: [ownerPubkey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_callId',
                lower: [ownerPubkey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_callId',
                lower: [],
                upper: [ownerPubkey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterWhereClause
  >
  ownerPubkeyCallIdEqualTo(String ownerPubkey, String callId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerPubkey_callId',
          value: [ownerPubkey, callId],
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterWhereClause
  >
  ownerPubkeyEqualToCallIdNotEqualTo(String ownerPubkey, String callId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_callId',
                lower: [ownerPubkey],
                upper: [ownerPubkey, callId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_callId',
                lower: [ownerPubkey, callId],
                includeLower: false,
                upper: [ownerPubkey],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_callId',
                lower: [ownerPubkey, callId],
                includeLower: false,
                upper: [ownerPubkey],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_callId',
                lower: [ownerPubkey],
                upper: [ownerPubkey, callId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension CallPaymentSessionRecordQueryFilter
    on
        QueryBuilder<
          CallPaymentSessionRecord,
          CallPaymentSessionRecord,
          QFilterCondition
        > {
  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  billingPeriodSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'billingPeriodSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  billingPeriodSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'billingPeriodSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  billingPeriodSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'billingPeriodSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  billingPeriodSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'billingPeriodSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'callId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'callId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'callId', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'callId', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'callType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'callType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'callType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'callType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'callType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'callType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'callType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'callType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'callType', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  callTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'callType', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  chargedSatsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'chargedSats', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  chargedSatsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'chargedSats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  chargedSatsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'chargedSats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  chargedSatsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'chargedSats',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'connectedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'connectedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedAtEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'connectedAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedAtGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'connectedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedAtLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'connectedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'connectedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedDurationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'connectedDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedDurationSecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'connectedDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedDurationSecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'connectedDurationSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  connectedDurationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'connectedDurationSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  createdAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  createdAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  createdAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'direction',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'direction',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'direction', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  directionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'direction', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  endedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'endedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  endedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'endedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  endedAtEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endedAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  endedAtGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  endedAtLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  endedAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  maxSpendSatsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'maxSpendSats', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  maxSpendSatsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'maxSpendSats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  maxSpendSatsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'maxSpendSats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  maxSpendSatsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'maxSpendSats',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mintUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mintUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mintUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  mintUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mintUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerPubkey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ownerPubkey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerPubkey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  ownerPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerPubkey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'peerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'peerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'peerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'peerPubkey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'peerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'peerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'peerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'peerPubkey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'peerPubkey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  peerPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'peerPubkey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  priceSatsPerMinuteEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'priceSatsPerMinute', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  priceSatsPerMinuteGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'priceSatsPerMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  priceSatsPerMinuteLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'priceSatsPerMinute',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  priceSatsPerMinuteBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'priceSatsPerMinute',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  refundedSatsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'refundedSats', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  refundedSatsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'refundedSats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  refundedSatsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'refundedSats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  refundedSatsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'refundedSats',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'role',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'role',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'role',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'role', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'role', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  updatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  updatedAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentSessionRecord,
    CallPaymentSessionRecord,
    QAfterFilterCondition
  >
  updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension CallPaymentSessionRecordQueryObject
    on
        QueryBuilder<
          CallPaymentSessionRecord,
          CallPaymentSessionRecord,
          QFilterCondition
        > {}

extension CallPaymentSessionRecordQueryLinks
    on
        QueryBuilder<
          CallPaymentSessionRecord,
          CallPaymentSessionRecord,
          QFilterCondition
        > {}

extension CallPaymentSessionRecordQuerySortBy
    on
        QueryBuilder<
          CallPaymentSessionRecord,
          CallPaymentSessionRecord,
          QSortBy
        > {
  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByBillingPeriodSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingPeriodSeconds', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByBillingPeriodSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingPeriodSeconds', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByCallId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByCallIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByCallType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callType', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByCallTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callType', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByChargedSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chargedSats', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByChargedSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chargedSats', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByConnectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectedAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByConnectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectedAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByConnectedDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectedDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByConnectedDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectedDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByMaxSpendSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxSpendSats', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByMaxSpendSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxSpendSats', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByMintUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByMintUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByPeerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByPeerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByPriceSatsPerMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceSatsPerMinute', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByPriceSatsPerMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceSatsPerMinute', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByRefundedSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refundedSats', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByRefundedSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refundedSats', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CallPaymentSessionRecordQuerySortThenBy
    on
        QueryBuilder<
          CallPaymentSessionRecord,
          CallPaymentSessionRecord,
          QSortThenBy
        > {
  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByBillingPeriodSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingPeriodSeconds', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByBillingPeriodSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'billingPeriodSeconds', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByCallId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByCallIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByCallType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callType', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByCallTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callType', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByChargedSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chargedSats', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByChargedSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chargedSats', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByConnectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectedAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByConnectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectedAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByConnectedDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectedDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByConnectedDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'connectedDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByEndedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endedAt', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByMaxSpendSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxSpendSats', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByMaxSpendSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxSpendSats', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByMintUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByMintUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByPeerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerPubkey', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByPeerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peerPubkey', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByPriceSatsPerMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceSatsPerMinute', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByPriceSatsPerMinuteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceSatsPerMinute', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByRefundedSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refundedSats', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByRefundedSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refundedSats', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CallPaymentSessionRecordQueryWhereDistinct
    on
        QueryBuilder<
          CallPaymentSessionRecord,
          CallPaymentSessionRecord,
          QDistinct
        > {
  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByBillingPeriodSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'billingPeriodSeconds');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByCallId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'callId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByCallType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'callType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByChargedSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chargedSats');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByConnectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'connectedAt');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByConnectedDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'connectedDurationSeconds');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByDirection({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'direction', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByEndedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endedAt');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByMaxSpendSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxSpendSats');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByMintUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mintUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByOwnerPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByPeerPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peerPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByPriceSatsPerMinute() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priceSatsPerMinute');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByRefundedSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'refundedSats');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByRole({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'role', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CallPaymentSessionRecord, CallPaymentSessionRecord, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CallPaymentSessionRecordQueryProperty
    on
        QueryBuilder<
          CallPaymentSessionRecord,
          CallPaymentSessionRecord,
          QQueryProperty
        > {
  QueryBuilder<CallPaymentSessionRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int, QQueryOperations>
  billingPeriodSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'billingPeriodSeconds');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, String, QQueryOperations>
  callIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'callId');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, String, QQueryOperations>
  callTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'callType');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int, QQueryOperations>
  chargedSatsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chargedSats');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int?, QQueryOperations>
  connectedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'connectedAt');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int, QQueryOperations>
  connectedDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'connectedDurationSeconds');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, String, QQueryOperations>
  directionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'direction');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int?, QQueryOperations>
  endedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endedAt');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int, QQueryOperations>
  maxSpendSatsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxSpendSats');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, String, QQueryOperations>
  mintUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mintUrl');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, String, QQueryOperations>
  ownerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerPubkey');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, String, QQueryOperations>
  peerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peerPubkey');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int, QQueryOperations>
  priceSatsPerMinuteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priceSatsPerMinute');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int, QQueryOperations>
  refundedSatsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'refundedSats');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, String, QQueryOperations>
  roleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'role');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, String, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CallPaymentSessionRecord, int, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCallPaymentInstallmentRecordCollection on Isar {
  IsarCollection<CallPaymentInstallmentRecord>
  get callPaymentInstallmentRecords => this.collection();
}

const CallPaymentInstallmentRecordSchema = CollectionSchema(
  name: r'CallPaymentInstallmentRecord',
  id: 5876685507469488391,
  properties: {
    r'amountSats': PropertySchema(
      id: 0,
      name: r'amountSats',
      type: IsarType.long,
    ),
    r'callId': PropertySchema(id: 1, name: r'callId', type: IsarType.string),
    r'claimedAt': PropertySchema(
      id: 2,
      name: r'claimedAt',
      type: IsarType.long,
    ),
    r'coversFromSecond': PropertySchema(
      id: 3,
      name: r'coversFromSecond',
      type: IsarType.long,
    ),
    r'coversToSecond': PropertySchema(
      id: 4,
      name: r'coversToSecond',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 5,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'direction': PropertySchema(
      id: 6,
      name: r'direction',
      type: IsarType.string,
    ),
    r'errorCode': PropertySchema(
      id: 7,
      name: r'errorCode',
      type: IsarType.string,
    ),
    r'idempotencyKey': PropertySchema(
      id: 8,
      name: r'idempotencyKey',
      type: IsarType.string,
    ),
    r'mintUrl': PropertySchema(id: 9, name: r'mintUrl', type: IsarType.string),
    r'ownerPubkey': PropertySchema(
      id: 10,
      name: r'ownerPubkey',
      type: IsarType.string,
    ),
    r'ownerPubkeyForWalletOperation': PropertySchema(
      id: 11,
      name: r'ownerPubkeyForWalletOperation',
      type: IsarType.string,
    ),
    r'paymentSessionId': PropertySchema(
      id: 12,
      name: r'paymentSessionId',
      type: IsarType.string,
    ),
    r'purpose': PropertySchema(id: 13, name: r'purpose', type: IsarType.string),
    r'reclaimedAt': PropertySchema(
      id: 14,
      name: r'reclaimedAt',
      type: IsarType.long,
    ),
    r'refundedAt': PropertySchema(
      id: 15,
      name: r'refundedAt',
      type: IsarType.long,
    ),
    r'sentAt': PropertySchema(id: 16, name: r'sentAt', type: IsarType.long),
    r'sequence': PropertySchema(id: 17, name: r'sequence', type: IsarType.long),
    r'status': PropertySchema(id: 18, name: r'status', type: IsarType.string),
    r'tokenHash': PropertySchema(
      id: 19,
      name: r'tokenHash',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 20,
      name: r'updatedAt',
      type: IsarType.long,
    ),
    r'walletOperationId': PropertySchema(
      id: 21,
      name: r'walletOperationId',
      type: IsarType.string,
    ),
  },
  estimateSize: _callPaymentInstallmentRecordEstimateSize,
  serialize: _callPaymentInstallmentRecordSerialize,
  deserialize: _callPaymentInstallmentRecordDeserialize,
  deserializeProp: _callPaymentInstallmentRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'ownerPubkey_idempotencyKey': IndexSchema(
      id: 4535835806683746358,
      name: r'ownerPubkey_idempotencyKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'ownerPubkey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'idempotencyKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'ownerPubkeyForWalletOperation_walletOperationId': IndexSchema(
      id: -6740700298371095311,
      name: r'ownerPubkeyForWalletOperation_walletOperationId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ownerPubkeyForWalletOperation',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'walletOperationId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _callPaymentInstallmentRecordGetId,
  getLinks: _callPaymentInstallmentRecordGetLinks,
  attach: _callPaymentInstallmentRecordAttach,
  version: '3.1.0+1',
);

int _callPaymentInstallmentRecordEstimateSize(
  CallPaymentInstallmentRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.callId.length * 3;
  bytesCount += 3 + object.direction.length * 3;
  {
    final value = object.errorCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.idempotencyKey.length * 3;
  bytesCount += 3 + object.mintUrl.length * 3;
  bytesCount += 3 + object.ownerPubkey.length * 3;
  bytesCount += 3 + object.ownerPubkeyForWalletOperation.length * 3;
  bytesCount += 3 + object.paymentSessionId.length * 3;
  bytesCount += 3 + object.purpose.length * 3;
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.tokenHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.walletOperationId.length * 3;
  return bytesCount;
}

void _callPaymentInstallmentRecordSerialize(
  CallPaymentInstallmentRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amountSats);
  writer.writeString(offsets[1], object.callId);
  writer.writeLong(offsets[2], object.claimedAt);
  writer.writeLong(offsets[3], object.coversFromSecond);
  writer.writeLong(offsets[4], object.coversToSecond);
  writer.writeLong(offsets[5], object.createdAt);
  writer.writeString(offsets[6], object.direction);
  writer.writeString(offsets[7], object.errorCode);
  writer.writeString(offsets[8], object.idempotencyKey);
  writer.writeString(offsets[9], object.mintUrl);
  writer.writeString(offsets[10], object.ownerPubkey);
  writer.writeString(offsets[11], object.ownerPubkeyForWalletOperation);
  writer.writeString(offsets[12], object.paymentSessionId);
  writer.writeString(offsets[13], object.purpose);
  writer.writeLong(offsets[14], object.reclaimedAt);
  writer.writeLong(offsets[15], object.refundedAt);
  writer.writeLong(offsets[16], object.sentAt);
  writer.writeLong(offsets[17], object.sequence);
  writer.writeString(offsets[18], object.status);
  writer.writeString(offsets[19], object.tokenHash);
  writer.writeLong(offsets[20], object.updatedAt);
  writer.writeString(offsets[21], object.walletOperationId);
}

CallPaymentInstallmentRecord _callPaymentInstallmentRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CallPaymentInstallmentRecord();
  object.amountSats = reader.readLong(offsets[0]);
  object.callId = reader.readString(offsets[1]);
  object.claimedAt = reader.readLongOrNull(offsets[2]);
  object.coversFromSecond = reader.readLong(offsets[3]);
  object.coversToSecond = reader.readLong(offsets[4]);
  object.createdAt = reader.readLong(offsets[5]);
  object.direction = reader.readString(offsets[6]);
  object.errorCode = reader.readStringOrNull(offsets[7]);
  object.id = id;
  object.idempotencyKey = reader.readString(offsets[8]);
  object.mintUrl = reader.readString(offsets[9]);
  object.ownerPubkey = reader.readString(offsets[10]);
  object.ownerPubkeyForWalletOperation = reader.readString(offsets[11]);
  object.paymentSessionId = reader.readString(offsets[12]);
  object.purpose = reader.readString(offsets[13]);
  object.reclaimedAt = reader.readLongOrNull(offsets[14]);
  object.refundedAt = reader.readLongOrNull(offsets[15]);
  object.sentAt = reader.readLongOrNull(offsets[16]);
  object.sequence = reader.readLong(offsets[17]);
  object.status = reader.readString(offsets[18]);
  object.tokenHash = reader.readStringOrNull(offsets[19]);
  object.updatedAt = reader.readLong(offsets[20]);
  object.walletOperationId = reader.readString(offsets[21]);
  return object;
}

P _callPaymentInstallmentRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readLongOrNull(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readLong(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _callPaymentInstallmentRecordGetId(CallPaymentInstallmentRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _callPaymentInstallmentRecordGetLinks(
  CallPaymentInstallmentRecord object,
) {
  return [];
}

void _callPaymentInstallmentRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  CallPaymentInstallmentRecord object,
) {
  object.id = id;
}

extension CallPaymentInstallmentRecordByIndex
    on IsarCollection<CallPaymentInstallmentRecord> {
  Future<CallPaymentInstallmentRecord?> getByOwnerPubkeyIdempotencyKey(
    String ownerPubkey,
    String idempotencyKey,
  ) {
    return getByIndex(r'ownerPubkey_idempotencyKey', [
      ownerPubkey,
      idempotencyKey,
    ]);
  }

  CallPaymentInstallmentRecord? getByOwnerPubkeyIdempotencyKeySync(
    String ownerPubkey,
    String idempotencyKey,
  ) {
    return getByIndexSync(r'ownerPubkey_idempotencyKey', [
      ownerPubkey,
      idempotencyKey,
    ]);
  }

  Future<bool> deleteByOwnerPubkeyIdempotencyKey(
    String ownerPubkey,
    String idempotencyKey,
  ) {
    return deleteByIndex(r'ownerPubkey_idempotencyKey', [
      ownerPubkey,
      idempotencyKey,
    ]);
  }

  bool deleteByOwnerPubkeyIdempotencyKeySync(
    String ownerPubkey,
    String idempotencyKey,
  ) {
    return deleteByIndexSync(r'ownerPubkey_idempotencyKey', [
      ownerPubkey,
      idempotencyKey,
    ]);
  }

  Future<List<CallPaymentInstallmentRecord?>> getAllByOwnerPubkeyIdempotencyKey(
    List<String> ownerPubkeyValues,
    List<String> idempotencyKeyValues,
  ) {
    final len = ownerPubkeyValues.length;
    assert(
      idempotencyKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], idempotencyKeyValues[i]]);
    }

    return getAllByIndex(r'ownerPubkey_idempotencyKey', values);
  }

  List<CallPaymentInstallmentRecord?> getAllByOwnerPubkeyIdempotencyKeySync(
    List<String> ownerPubkeyValues,
    List<String> idempotencyKeyValues,
  ) {
    final len = ownerPubkeyValues.length;
    assert(
      idempotencyKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], idempotencyKeyValues[i]]);
    }

    return getAllByIndexSync(r'ownerPubkey_idempotencyKey', values);
  }

  Future<int> deleteAllByOwnerPubkeyIdempotencyKey(
    List<String> ownerPubkeyValues,
    List<String> idempotencyKeyValues,
  ) {
    final len = ownerPubkeyValues.length;
    assert(
      idempotencyKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], idempotencyKeyValues[i]]);
    }

    return deleteAllByIndex(r'ownerPubkey_idempotencyKey', values);
  }

  int deleteAllByOwnerPubkeyIdempotencyKeySync(
    List<String> ownerPubkeyValues,
    List<String> idempotencyKeyValues,
  ) {
    final len = ownerPubkeyValues.length;
    assert(
      idempotencyKeyValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([ownerPubkeyValues[i], idempotencyKeyValues[i]]);
    }

    return deleteAllByIndexSync(r'ownerPubkey_idempotencyKey', values);
  }

  Future<Id> putByOwnerPubkeyIdempotencyKey(
    CallPaymentInstallmentRecord object,
  ) {
    return putByIndex(r'ownerPubkey_idempotencyKey', object);
  }

  Id putByOwnerPubkeyIdempotencyKeySync(
    CallPaymentInstallmentRecord object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(
      r'ownerPubkey_idempotencyKey',
      object,
      saveLinks: saveLinks,
    );
  }

  Future<List<Id>> putAllByOwnerPubkeyIdempotencyKey(
    List<CallPaymentInstallmentRecord> objects,
  ) {
    return putAllByIndex(r'ownerPubkey_idempotencyKey', objects);
  }

  List<Id> putAllByOwnerPubkeyIdempotencyKeySync(
    List<CallPaymentInstallmentRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'ownerPubkey_idempotencyKey',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension CallPaymentInstallmentRecordQueryWhereSort
    on
        QueryBuilder<
          CallPaymentInstallmentRecord,
          CallPaymentInstallmentRecord,
          QWhere
        > {
  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhere
  >
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CallPaymentInstallmentRecordQueryWhere
    on
        QueryBuilder<
          CallPaymentInstallmentRecord,
          CallPaymentInstallmentRecord,
          QWhereClause
        > {
  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
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

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  ownerPubkeyEqualToAnyIdempotencyKey(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerPubkey_idempotencyKey',
          value: [ownerPubkey],
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  ownerPubkeyNotEqualToAnyIdempotencyKey(String ownerPubkey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_idempotencyKey',
                lower: [],
                upper: [ownerPubkey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_idempotencyKey',
                lower: [ownerPubkey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_idempotencyKey',
                lower: [ownerPubkey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_idempotencyKey',
                lower: [],
                upper: [ownerPubkey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  ownerPubkeyIdempotencyKeyEqualTo(String ownerPubkey, String idempotencyKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerPubkey_idempotencyKey',
          value: [ownerPubkey, idempotencyKey],
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  ownerPubkeyEqualToIdempotencyKeyNotEqualTo(
    String ownerPubkey,
    String idempotencyKey,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_idempotencyKey',
                lower: [ownerPubkey],
                upper: [ownerPubkey, idempotencyKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_idempotencyKey',
                lower: [ownerPubkey, idempotencyKey],
                includeLower: false,
                upper: [ownerPubkey],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_idempotencyKey',
                lower: [ownerPubkey, idempotencyKey],
                includeLower: false,
                upper: [ownerPubkey],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkey_idempotencyKey',
                lower: [ownerPubkey],
                upper: [ownerPubkey, idempotencyKey],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  ownerPubkeyForWalletOperationEqualToAnyWalletOperationId(
    String ownerPubkeyForWalletOperation,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
          value: [ownerPubkeyForWalletOperation],
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  ownerPubkeyForWalletOperationNotEqualToAnyWalletOperationId(
    String ownerPubkeyForWalletOperation,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
                lower: [],
                upper: [ownerPubkeyForWalletOperation],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
                lower: [ownerPubkeyForWalletOperation],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
                lower: [ownerPubkeyForWalletOperation],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
                lower: [],
                upper: [ownerPubkeyForWalletOperation],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  ownerPubkeyForWalletOperationWalletOperationIdEqualTo(
    String ownerPubkeyForWalletOperation,
    String walletOperationId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
          value: [ownerPubkeyForWalletOperation, walletOperationId],
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterWhereClause
  >
  ownerPubkeyForWalletOperationEqualToWalletOperationIdNotEqualTo(
    String ownerPubkeyForWalletOperation,
    String walletOperationId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
                lower: [ownerPubkeyForWalletOperation],
                upper: [ownerPubkeyForWalletOperation, walletOperationId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
                lower: [ownerPubkeyForWalletOperation, walletOperationId],
                includeLower: false,
                upper: [ownerPubkeyForWalletOperation],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
                lower: [ownerPubkeyForWalletOperation, walletOperationId],
                includeLower: false,
                upper: [ownerPubkeyForWalletOperation],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'ownerPubkeyForWalletOperation_walletOperationId',
                lower: [ownerPubkeyForWalletOperation],
                upper: [ownerPubkeyForWalletOperation, walletOperationId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension CallPaymentInstallmentRecordQueryFilter
    on
        QueryBuilder<
          CallPaymentInstallmentRecord,
          CallPaymentInstallmentRecord,
          QFilterCondition
        > {
  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  amountSatsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'amountSats', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  amountSatsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'amountSats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  amountSatsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'amountSats',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  amountSatsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'amountSats',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'callId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'callId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'callId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'callId', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  callIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'callId', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  claimedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'claimedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  claimedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'claimedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  claimedAtEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'claimedAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  claimedAtGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'claimedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  claimedAtLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'claimedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  claimedAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'claimedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  coversFromSecondEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'coversFromSecond', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  coversFromSecondGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'coversFromSecond',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  coversFromSecondLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'coversFromSecond',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  coversFromSecondBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'coversFromSecond',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  coversToSecondEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'coversToSecond', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  coversToSecondGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'coversToSecond',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  coversToSecondLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'coversToSecond',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  coversToSecondBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'coversToSecond',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  createdAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  createdAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  createdAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'direction',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'direction',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'direction',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'direction', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  directionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'direction', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'errorCode'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'errorCode'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'errorCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'errorCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'errorCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'errorCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'errorCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'errorCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'errorCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'errorCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'errorCode', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  errorCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'errorCode', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'idempotencyKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'idempotencyKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'idempotencyKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'idempotencyKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'idempotencyKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'idempotencyKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'idempotencyKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'idempotencyKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'idempotencyKey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  idempotencyKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'idempotencyKey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mintUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mintUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mintUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mintUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  mintUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mintUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerPubkey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ownerPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ownerPubkey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerPubkey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerPubkey', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerPubkeyForWalletOperation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerPubkeyForWalletOperation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerPubkeyForWalletOperation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerPubkeyForWalletOperation',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ownerPubkeyForWalletOperation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ownerPubkeyForWalletOperation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ownerPubkeyForWalletOperation',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ownerPubkeyForWalletOperation',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerPubkeyForWalletOperation',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  ownerPubkeyForWalletOperationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'ownerPubkeyForWalletOperation',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'paymentSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paymentSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paymentSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paymentSessionId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'paymentSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'paymentSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'paymentSessionId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'paymentSessionId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paymentSessionId', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  paymentSessionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'paymentSessionId', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'purpose',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'purpose',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'purpose',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'purpose',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'purpose',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'purpose',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'purpose',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'purpose',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'purpose', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  purposeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'purpose', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  reclaimedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'reclaimedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  reclaimedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'reclaimedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  reclaimedAtEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reclaimedAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  reclaimedAtGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reclaimedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  reclaimedAtLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reclaimedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  reclaimedAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reclaimedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  refundedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'refundedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  refundedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'refundedAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  refundedAtEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'refundedAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  refundedAtGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'refundedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  refundedAtLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'refundedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  refundedAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'refundedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sentAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sentAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sentAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sentAt'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sentAtEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sentAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sentAtGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sentAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sentAtLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sentAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sentAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sentAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sequenceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sequence', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sequenceGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sequence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sequenceLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sequence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  sequenceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sequence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'tokenHash'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'tokenHash'),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tokenHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tokenHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tokenHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tokenHash',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tokenHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tokenHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tokenHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tokenHash',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tokenHash', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  tokenHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tokenHash', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  updatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  updatedAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'walletOperationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'walletOperationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'walletOperationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'walletOperationId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'walletOperationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'walletOperationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'walletOperationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'walletOperationId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'walletOperationId', value: ''),
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterFilterCondition
  >
  walletOperationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'walletOperationId', value: ''),
      );
    });
  }
}

extension CallPaymentInstallmentRecordQueryObject
    on
        QueryBuilder<
          CallPaymentInstallmentRecord,
          CallPaymentInstallmentRecord,
          QFilterCondition
        > {}

extension CallPaymentInstallmentRecordQueryLinks
    on
        QueryBuilder<
          CallPaymentInstallmentRecord,
          CallPaymentInstallmentRecord,
          QFilterCondition
        > {}

extension CallPaymentInstallmentRecordQuerySortBy
    on
        QueryBuilder<
          CallPaymentInstallmentRecord,
          CallPaymentInstallmentRecord,
          QSortBy
        > {
  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByAmountSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountSats', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByAmountSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountSats', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByCallId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByCallIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByClaimedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByCoversFromSecond() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coversFromSecond', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByCoversFromSecondDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coversFromSecond', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByCoversToSecond() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coversToSecond', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByCoversToSecondDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coversToSecond', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByErrorCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorCode', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByErrorCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorCode', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByIdempotencyKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByIdempotencyKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByMintUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByMintUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByOwnerPubkeyForWalletOperation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkeyForWalletOperation', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByOwnerPubkeyForWalletOperationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkeyForWalletOperation', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByPaymentSessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentSessionId', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByPaymentSessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentSessionId', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByPurpose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purpose', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByPurposeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purpose', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByReclaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reclaimedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByReclaimedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reclaimedAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByRefundedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refundedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByRefundedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refundedAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortBySentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortBySequenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByTokenHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenHash', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByTokenHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenHash', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByWalletOperationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletOperationId', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  sortByWalletOperationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletOperationId', Sort.desc);
    });
  }
}

extension CallPaymentInstallmentRecordQuerySortThenBy
    on
        QueryBuilder<
          CallPaymentInstallmentRecord,
          CallPaymentInstallmentRecord,
          QSortThenBy
        > {
  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByAmountSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountSats', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByAmountSatsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountSats', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByCallId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByCallIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'callId', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByClaimedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'claimedAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByCoversFromSecond() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coversFromSecond', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByCoversFromSecondDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coversFromSecond', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByCoversToSecond() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coversToSecond', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByCoversToSecondDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coversToSecond', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByErrorCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorCode', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByErrorCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorCode', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByIdempotencyKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByIdempotencyKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idempotencyKey', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByMintUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByMintUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mintUrl', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByOwnerPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByOwnerPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkey', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByOwnerPubkeyForWalletOperation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkeyForWalletOperation', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByOwnerPubkeyForWalletOperationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerPubkeyForWalletOperation', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByPaymentSessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentSessionId', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByPaymentSessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentSessionId', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByPurpose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purpose', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByPurposeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purpose', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByReclaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reclaimedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByReclaimedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reclaimedAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByRefundedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refundedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByRefundedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refundedAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenBySentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenBySequenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByTokenHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenHash', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByTokenHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tokenHash', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByWalletOperationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletOperationId', Sort.asc);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QAfterSortBy
  >
  thenByWalletOperationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'walletOperationId', Sort.desc);
    });
  }
}

extension CallPaymentInstallmentRecordQueryWhereDistinct
    on
        QueryBuilder<
          CallPaymentInstallmentRecord,
          CallPaymentInstallmentRecord,
          QDistinct
        > {
  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByAmountSats() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountSats');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByCallId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'callId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByClaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'claimedAt');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByCoversFromSecond() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coversFromSecond');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByCoversToSecond() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coversToSecond');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByDirection({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'direction', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByErrorCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByIdempotencyKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'idempotencyKey',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByMintUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mintUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByOwnerPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByOwnerPubkeyForWalletOperation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'ownerPubkeyForWalletOperation',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByPaymentSessionId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'paymentSessionId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByPurpose({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purpose', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByReclaimedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reclaimedAt');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByRefundedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'refundedAt');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sentAt');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sequence');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByTokenHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tokenHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<
    CallPaymentInstallmentRecord,
    CallPaymentInstallmentRecord,
    QDistinct
  >
  distinctByWalletOperationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'walletOperationId',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension CallPaymentInstallmentRecordQueryProperty
    on
        QueryBuilder<
          CallPaymentInstallmentRecord,
          CallPaymentInstallmentRecord,
          QQueryProperty
        > {
  QueryBuilder<CallPaymentInstallmentRecord, int, QQueryOperations>
  idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int, QQueryOperations>
  amountSatsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountSats');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  callIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'callId');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int?, QQueryOperations>
  claimedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'claimedAt');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int, QQueryOperations>
  coversFromSecondProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coversFromSecond');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int, QQueryOperations>
  coversToSecondProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coversToSecond');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  directionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'direction');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String?, QQueryOperations>
  errorCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorCode');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  idempotencyKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idempotencyKey');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  mintUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mintUrl');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  ownerPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerPubkey');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  ownerPubkeyForWalletOperationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerPubkeyForWalletOperation');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  paymentSessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentSessionId');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  purposeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purpose');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int?, QQueryOperations>
  reclaimedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reclaimedAt');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int?, QQueryOperations>
  refundedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'refundedAt');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int?, QQueryOperations>
  sentAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sentAt');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int, QQueryOperations>
  sequenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sequence');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String?, QQueryOperations>
  tokenHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tokenHash');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, int, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<CallPaymentInstallmentRecord, String, QQueryOperations>
  walletOperationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'walletOperationId');
    });
  }
}
