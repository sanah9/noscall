import 'package:isar/isar.dart';

part 'contact_group_isar.g.dart';

@collection
class ContactGroup {
  Id id = Isar.autoIncrement;

  String name;

  int createTime;
  
  @Index()
  int updateTime;

  ContactGroup({
    this.name = '',
    this.createTime = 0,
    this.updateTime = 0,
  });

  factory ContactGroup.create({String name = ''}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ContactGroup(
      name: name.isEmpty ? 'Untitled' : name,
      createTime: now,
      updateTime: now,
    );
  }

  void updateName(String newName) {
    name = newName;
    updateTime = DateTime.now().millisecondsSinceEpoch;
  }
}

@collection
class ContactGroupMember {
  Id id = Isar.autoIncrement;

  int groupId;
  String contactPubKey;

  ContactGroupMember({
    required this.groupId,
    required this.contactPubKey,
  });
}

