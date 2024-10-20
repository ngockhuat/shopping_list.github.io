  import 'dart:convert';

  import 'package:flutter/material.dart';
  import 'package:shopping_list/data/categories.dart';
  import 'package:shopping_list/models/grocery_item.dart';
  import 'package:shopping_list/widgets/new_item.dart';
  import 'package:http/http.dart' as http;

  class GroceryList extends StatefulWidget {
    const GroceryList({super.key}); // Thêm const để tối ưu hiệu suất

    @override
    State<GroceryList> createState() => _GroceryListState();
  }

  class _GroceryListState extends State<GroceryList> {
    List<GroceryItem> _groceryItems = [];
    // var _isLoading = true;
    late Future<List<GroceryItem>> _loadedItems;
    String? _error;
    @override
    void initState() {
      // TODO: implement initState
      super.initState();
      _loadedItems = _loadItem();
    }

    Future<List<GroceryItem>> _loadItem() async {
      final url = Uri.https(
          'flutter-demo-a6dde-default-rtdb.firebaseio.com', 'shopping-list.json');

      final response = await http.get(url);
      if (response.statusCode >= 400) {
        // setState(() {
        //   _error = 'Failed to fetch data. Please try again later';
        // });
        throw Exception('Failed to fetch grocery items.Please  try again later');
      }
      if (response.body == 'null') {
        return [];
      }

      final Map<String, dynamic> listData =
          json.decode(response.body); // hien thi ma json
      final List<GroceryItem> loadItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value; // tim kiem phan tu dau tien tren http
        loadItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }
      // setState(() {
      //   _groceryItems = loadItems;
      //   _isLoading = false;
      // });
      return loadItems;
    }

    void _addItem(BuildContext context) async {
      final newItem = await Navigator.of(context).push<GroceryItem>(
          MaterialPageRoute(builder: (ctx) => const NewItem()));
      // lay ra du lieu
      // _loadItem();
      if (newItem == null) {
        return;
      }
      setState(() {
        _groceryItems.add(newItem);
      });
    }

    void _removeItem(GroceryItem item) async {
      final index = _groceryItems.indexOf(item);
      setState(() {
        _groceryItems.remove(item);
      });
      final url = Uri.https('flutter-demo-a6dde-default-rtdb.firebaseio.com',
          'shopping-list/${item.id}.json');
      final response = await http.delete(url);
      final removedItem = item;
      if (response.statusCode >= 400) {
        //Optional: show error message
        setState(() {
          _groceryItems.insert(index, item);
        });
      }

      // Thông báo Snackbar sau khi xóa và cung cấp tùy chọn hoàn tác (undo)

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${removedItem.name} removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Khôi phục lại item khi người dùng chọn undo
              setState(() {
                _groceryItems.add(removedItem);
              });
            },
          ),
        ),
      );
    }

      @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your categories'),
          actions: [
            IconButton(
              onPressed: () {
                _addItem(context);
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: FutureBuilder(
          future: _loadedItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            }
            // kiểm tra dữ liệu cuối cùng
            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No items added yet.'),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (ctx, index) => Dismissible(
                key: ValueKey(snapshot.data![index].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                onDismissed: (direction) {
                  _removeItem(snapshot.data![index]);
                },
                child: ListTile(
                  title: Text(snapshot.data![index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: snapshot.data![index].category.color,
                  ),
                  trailing: Text(snapshot.data![index].quantity.toString()),
                ),
              ),
            );
          },
        ),
      );
    }
  }