import 'package:isar/isar.dart';
import '../models/contact_group_isar.dart';
import '../../core/common/database/db_isar.dart';

class ContactGroupService {
  static final ContactGroupService sharedInstance = ContactGroupService._internal();
  ContactGroupService._internal();
  factory ContactGroupService() => sharedInstance;

  Isar get _isar => DBISAR.sharedInstance.isar;

  /// Get all groups
  Future<List<ContactGroup>> getAllGroups() async {
    return await _isar.contactGroups.where().sortByCreateTime().findAll();
  }

  /// Create a new group
  Future<ContactGroup> createGroup({String name = 'Untitled'}) async {
    final group = ContactGroup.create(name: name);
    await DBISAR.sharedInstance.saveToDB(group);
    return group;
  }

  /// Update group name
  Future<void> updateGroupName(int groupId, String newName) async {
    final group = await _isar.contactGroups.get(groupId);
    if (group != null) {
      group.updateName(newName);
      await DBISAR.sharedInstance.saveToDB(group);
    }
  }

  /// Delete a group
  Future<void> deleteGroup(int groupId) async {
    await _isar.writeTxn(() async {
      // Delete the group
      await _isar.contactGroups.delete(groupId);
      // Delete all member associations
      await _isar.contactGroupMembers
          .filter()
          .groupIdEqualTo(groupId)
          .deleteAll();
    });
  }

  /// Get all contact pubkeys in a group
  Future<List<String>> getGroupContactPubKeys(int groupId) async {
    final members = await _isar.contactGroupMembers
        .filter()
        .groupIdEqualTo(groupId)
        .findAll();
    return members.map((m) => m.contactPubKey).toList();
  }

  /// Add contacts to a group
  Future<void> addContactsToGroup(int groupId, List<String> contactPubKeys) async {
    final existingMembers = await _isar.contactGroupMembers
        .filter()
        .groupIdEqualTo(groupId)
        .findAll();
    final existingPubKeys = existingMembers.map((m) => m.contactPubKey).toSet();

    final newMembers = contactPubKeys
        .where((pubKey) => !existingPubKeys.contains(pubKey))
        .map((pubKey) => ContactGroupMember(
              groupId: groupId,
              contactPubKey: pubKey,
            ))
        .toList();

    if (newMembers.isNotEmpty) {
      await DBISAR.sharedInstance.saveObjectsToDB(newMembers);
    }
  }

  /// Remove contacts from a group
  Future<void> removeContactsFromGroup(int groupId, List<String> contactPubKeys) async {
    await _isar.writeTxn(() async {
      for (final pubKey in contactPubKeys) {
        await _isar.contactGroupMembers
            .filter()
            .groupIdEqualTo(groupId)
            .and()
            .contactPubKeyEqualTo(pubKey)
            .deleteAll();
      }
    });
  }

  /// Get all groups that contain a contact
  Future<List<ContactGroup>> getGroupsForContact(String contactPubKey) async {
    final members = await _isar.contactGroupMembers
        .filter()
        .contactPubKeyEqualTo(contactPubKey)
        .findAll();
    final groupIds = members.map((m) => m.groupId).toSet();

    if (groupIds.isEmpty) return [];

    final groups = <ContactGroup>[];
    for (final groupId in groupIds) {
      final group = await _isar.contactGroups.get(groupId);
      if (group != null) {
        groups.add(group);
      }
    }
    return groups;
  }

  /// Get the number of contacts in a group
  Future<int> getGroupContactCount(int groupId) async {
    return await _isar.contactGroupMembers
        .filter()
        .groupIdEqualTo(groupId)
        .count();
  }
}

