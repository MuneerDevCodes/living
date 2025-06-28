import 'package:firebase_database/firebase_database.dart';
import 'package:living/models/book.dart';

class BookDao {
  final _databaseRef = FirebaseDatabase.instance.ref("books");

  void saveBook(Book book) {
    _databaseRef.push().set(book.toJson());
  }

  Query getBookList() {
    return _databaseRef;
  }

  void deleteBook(String key) {
    _databaseRef.child(key).remove();
  }

  void updateBook(String key, Book book) {
    _databaseRef.child(key).update(book.toMap());
  }

  Future<Book?> getBookById(String bookId) async {
    final snapshot = await _databaseRef.child(bookId).get();
    if (snapshot.exists) {
      return Book.fromJson(snapshot.value as Map<dynamic, dynamic>);
    }
    return null;
  }
}
