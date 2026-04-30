import 'package:isar/isar.dart';
import 'package:noscall/core/account/model/userDB_isar.dart';
import 'package:noscall/core/common/database/db_isar.dart';

abstract class AccountPersistence {
  Future<List<UserDBISAR>> loadAllUsers();
  Future<UserDBISAR?> findUserByPubkey(String pubkey);
  Future<void> saveUser(UserDBISAR user);
  Future<void> close();
}

class DefaultAccountPersistence implements AccountPersistence {
  const DefaultAccountPersistence();

  @override
  Future<List<UserDBISAR>> loadAllUsers() async {
    final users =
        await DBISAR.sharedInstance.isar.userDBISARs.where().findAll();
    return users.whereType<UserDBISAR>().toList();
  }

  @override
  Future<UserDBISAR?> findUserByPubkey(String pubkey) async {
    return DBISAR.sharedInstance.isar.userDBISARs
        .where()
        .pubKeyEqualTo(pubkey)
        .findFirst();
  }

  @override
  Future<void> saveUser(UserDBISAR user) async {
    await DBISAR.sharedInstance.saveToDB(user);
  }

  @override
  Future<void> close() async {
    await DBISAR.sharedInstance.closeDatabase();
  }
}
