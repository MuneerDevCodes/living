import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/contact_us_model.dart';

class ContactDao {
  final _databaseRef = FirebaseDatabase.instance.ref("contacts");

  void saveContact(Contact contact) {
    _databaseRef.push().set(contact.toJson());
  }

  Query getContactList() {
    return _databaseRef;
  }

  void deleteContact(String key) {
    _databaseRef.child(key).remove();
  }

  void updateContact(String key, Contact contact) {
    _databaseRef.child(key).update(contact.toMap());
  }
}
