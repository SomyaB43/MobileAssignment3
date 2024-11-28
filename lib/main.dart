import 'package:flutter/material.dart';
import 'food_ordering_page.dart';
import 'edit_order_page.dart';
import 'database_helper.dart';

// Main entry point
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Ordering App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _orderPlans = [];
  Map<String, dynamic>? _searchedOrderPlan;
  TextEditingController _searchDate = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOrderPlans();
  }

  // Fetch all order plans from the database
  Future<void> _fetchOrderPlans() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> orderPlans = await dbHelper.getAllOrderPlans();
    setState(() {
      _orderPlans = orderPlans;
    });
  }

  // Show the order plan for the searched date
  void _searchOrderByDate(String searchDate) {
    final orderPlan = _orderPlans.firstWhere(
          (order) => order['date'] == searchDate,
      orElse: () => {},
    );
    setState(() {
      _searchedOrderPlan = orderPlan.isEmpty ? null : orderPlan;
    });
  }

  // Navigate to the Food Ordering Page to add a new order plan
  void _navigateToFoodOrderingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodOrderingPage()),
    ).then((_) {
      _fetchOrderPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Ordering App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar for order plan by date
            TextField(
              controller: _searchDate,
              decoration: InputDecoration(labelText: 'Search Order Plan by Date'),
              onChanged: (searchDate) {
                _searchOrderByDate(searchDate);
              },
            ),
            SizedBox(height: 20),

            // Display searched order plan (if any)
            _searchedOrderPlan != null
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    'Order Plan for ${_searchedOrderPlan!['date']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Target Cost: \$${_searchedOrderPlan!['target_cost']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Navigate to edit page with the searched order plan
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditOrderPlanPage(orderPlan: _searchedOrderPlan!),
                            ),
                          ).then((_) {
                            // Refresh the list after editing
                            _fetchOrderPlans();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          DatabaseHelper dbHelper = DatabaseHelper();
                          await dbHelper.deleteOrderPlan(_searchedOrderPlan!['id']);
                          _fetchOrderPlans(); // Refresh list after deletion
                        },
                      ),
                    ],
                  ),
                ),
                // Display food items in the searched order plan
                if (_searchedOrderPlan!['food_items'] != null && _searchedOrderPlan!['food_items'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Food Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                        for (var foodItem in _searchedOrderPlan!['food_items'])
                          Text('- $foodItem'),
                      ],
                    ),
                  ),
              ],
            )
                : Text('No order plan found for the selected date'),

            SizedBox(height: 20),

            // Display the existing order plans
            Expanded(
              child: _orderPlans.isEmpty
                  ? Center(child: Text('No order plans available'))
                  : ListView.builder(
                shrinkWrap: true, // Ensures ListView takes up only necessary space
                itemCount: _orderPlans.length,
                itemBuilder: (context, index) {
                  final orderPlan = _orderPlans[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        'Order Plan for ${orderPlan['date']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Target Cost: \$${orderPlan['target_cost']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button inside ListView in HomePage
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // Navigate to EditOrderPlanPage with the selected order
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditOrderPlanPage(orderPlan: orderPlan),
                                ),
                              ).then((_) {
                                // Refresh the list after editing
                                _fetchOrderPlans();
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              DatabaseHelper dbHelper = DatabaseHelper();
                              await dbHelper.deleteOrderPlan(orderPlan['id']);
                              _fetchOrderPlans(); // Refresh list after deletion
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Add New Order Plan button
            SizedBox(height: 20),
            FloatingActionButton(
              onPressed: _navigateToFoodOrderingPage,
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
