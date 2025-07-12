import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'; // Only for User type
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:bookstore_app/models/book.dart';
import 'package:bookstore_app/services/book_dao.dart';
import 'package:bookstore_app/services/cart_dao.dart';
import 'package:bookstore_app/services/wish_dao.dart';
import 'package:bookstore_app/services/auth_helper.dart';
import 'package:bookstore_app/widgets/header.dart';
import 'package:bookstore_app/widgets/footer.dart';
import 'package:bookstore_app/widgets/loader.dart';

class BookDetailPage extends StatefulWidget {
  final String bookKey;
  const BookDetailPage({super.key, required this.bookKey});
  static const String routeName = '/book-detail';

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  Book? _book;
  String? _error;
  final _reviewCtrl = TextEditingController();
  int _rating = 0;
  bool _loading = false;

  User? get _user => AuthService().currentUser;

  @override
  void initState() {
    super.initState();
    _fetchBook();
  }

  Future<void> _fetchBook() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('books/${widget.bookKey}').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value;
        if (data is Map) {
          setState(() {
            _book = Book.fromJson(Map<dynamic, dynamic>.from(data));
          });
        } else {
          setState(() {
            _error = "Invalid book data format.";
          });
        }
      } else {
        setState(() {
          _error = "Book not found in database.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load book: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_book == null) return;
    if (_rating == 0 || _reviewCtrl.text.trim().isEmpty) {
      setState(() => _error = "Please provide a rating and comment.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = _user!.uid;
      final review = Review(
        userId: userId,
        rating: _rating,
        comment: _reviewCtrl.text.trim(),
        likes: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final updatedReviews = Map<String, Review>.from(_book!.reviews);
      updatedReviews[userId] = review;
      final allRatings = updatedReviews.values.map((r) => r.rating).toList();
      final avg =
          allRatings.isEmpty
              ? 0.0
              : allRatings.reduce((a, b) => a + b) / allRatings.length;
      final updatedBook = Book(
        title: _book!.title,
        author: _book!.author,
        category: _book!.category,
        description: _book!.description,
        coverImageURL: _book!.coverImageURL,
        price: _book!.price,
        isBestseller: _book!.isBestseller,
        isNewArrival: _book!.isNewArrival,
        ratings: Ratings(average: avg, count: allRatings.length),
        reviews: updatedReviews,
      );
      BookDao().updateBook(widget.bookKey, updatedBook);
      setState(() {
        _book = updatedBook;
        _reviewCtrl.clear();
        _rating = 0;
      });
    } catch (e) {
      setState(() => _error = "Failed to submit review: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: Loader()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_book == null) {
      return const Scaffold(body: Center(child: Text('Book not found')));
    }

    final book = _book!;
    final cover =
        book.coverImageURL.isNotEmpty
            ? Image.memory(
              base64Decode(book.coverImageURL),
              width: 120,
              height: 160,
              fit: BoxFit.fill,
            )
            : Container(
              width: 120,
              height: 160,
              color: Colors.grey[300],
              child: const Icon(Icons.book, size: 60),
            );
    final reviews =
        book.reviews.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final canReview = _user != null;

    return Scaffold(
      drawer: BookstoreHeader.buildDrawer(context),
      body: Column(
        children: [
          const BookstoreHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      cover,
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'by ${book.author}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text('Category: ${book.category.name}'),
                            Text('Price: \$${book.price.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${book.ratings.average.toStringAsFixed(1)} (${book.ratings.count} reviews)',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.shopping_cart),
                                  tooltip: 'Add to Cart',
                                  onPressed:
                                      _user == null
                                          ? null
                                          : () async {
                                            final userId = _user!.uid;
                                            await CartDao().addToCart(
                                              userId,
                                              book,
                                              1,
                                              widget.bookKey,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Added to cart',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.favorite_border),
                                  tooltip: 'Add to Wishlist',
                                  onPressed:
                                      _user == null
                                          ? null
                                          : () async {
                                            final userId = _user!.uid;
                                            await WishDao().addToWishList(
                                              userId,
                                              book,
                                              widget.bookKey,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Added to wishlist',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(book.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 18),
                  const Divider(),
                  Text(
                    'Reviews',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (reviews.isEmpty)
                    const Text(
                      'No reviews yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ...reviews.map(
                    (r) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            r.userId.isNotEmpty
                                ? r.userId[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < r.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber[700],
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.comment),
                            if (_user != null && r.userId == _user!.uid)
                              Row(
                                children: [
                                  TextButton(
                                    onPressed:
                                        _loading
                                            ? null
                                            : () {
                                              _reviewCtrl.text = r.comment;
                                              setState(() {
                                                _rating = r.rating;
                                              });
                                            },
                                    child: const Text(
                                      'Edit',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        _loading
                                            ? null
                                            : () async {
                                              final updatedReviews =
                                                  Map<String, Review>.from(
                                                    _book!.reviews,
                                                  );
                                              updatedReviews.remove(_user!.uid);
                                              final allRatings =
                                                  updatedReviews.values
                                                      .map((r) => r.rating)
                                                      .toList();
                                              final avg =
                                                  allRatings.isEmpty
                                                      ? 0.0
                                                      : allRatings.reduce(
                                                            (a, b) => a + b,
                                                          ) /
                                                          (allRatings.isEmpty
                                                              ? 1
                                                              : allRatings
                                                                  .length);
                                              final updatedBook = Book(
                                                title: _book!.title,
                                                author: _book!.author,
                                                category: _book!.category,
                                                description: _book!.description,
                                                coverImageURL:
                                                    _book!.coverImageURL,
                                                price: _book!.price,
                                                isBestseller:
                                                    _book!.isBestseller,
                                                isNewArrival:
                                                    _book!.isNewArrival,
                                                ratings: Ratings(
                                                  average: avg,
                                                  count: allRatings.length,
                                                ),
                                                reviews: updatedReviews,
                                              );
                                              BookDao().updateBook(
                                                widget.bookKey,
                                                updatedBook,
                                              );
                                              setState(() {
                                                _book = updatedBook;
                                                _reviewCtrl.clear();
                                                _rating = 0;
                                              });
                                            },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: Text(
                          DateTime.fromMillisecondsSinceEpoch(
                            r.createdAt,
                          ).toLocal().toString().split(' ')[0],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (canReview) ...[
                    const Divider(),
                    Text(
                      'Add Your Review',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => IconButton(
                            icon: Icon(
                              i < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber[700],
                            ),
                            onPressed:
                                _loading
                                    ? null
                                    : () => setState(() => _rating = i + 1),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _reviewCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Your review',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                      enabled: !_loading,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitReview,
                      child:
                          _loading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: Loader(),
                              )
                              : const Text('Submit Review'),
                    ),
                  ] else ...[
                    const Divider(),
                    const Text(
                      'Login to add your review.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const BookstoreFooter(),
        ],
      ),
    );
  }
}
