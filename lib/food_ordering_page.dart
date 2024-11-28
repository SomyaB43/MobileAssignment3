import 'package:flutter/material.dart';
import 'database_helper.dart';

class FoodOrderingPage extends StatefulWidget {
  @override
  _FoodOrderingPageState createState() => _FoodOrderingPageState();
}

class _FoodOrderingPageState extends State<FoodOrderingPage> {
  List<Map<String, dynamic>> _foodItems = [];
  TextEditingController _targetCost = TextEditingController();
  TextEditingController _date = TextEditingController();
  List<int> selectedFoodItems = [];
  double totalCost = 0.00;

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
  }

  // Fetch food items from the database
  Future<void> _fetchFoodItems() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> foodItems = await dbHelper.getAllFoodItems();
    setState(() {
      _foodItems = foodItems;
    });
  }

  // Save the order plan to the database
  Future<void> _saveOrderPlan() async {
    double targetCost = double.tryParse(_targetCost.text) ?? 0.0;
    String date = _date.text;

    if (targetCost > 0 && selectedFoodItems.isNotEmpty && totalCost <= targetCost) {
      DatabaseHelper dbHelper = DatabaseHelper();
      int orderPlanId = await dbHelper.insertOrderPlan(targetCost, date);

      for (var foodItemId in selectedFoodItems) {
        await dbHelper.insertOrderItem(orderPlanId, foodItemId);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order plan saved successfully!')));
      Navigator.pop(context);

    } else if (totalCost > targetCost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Target cost reached. Can\'t buy more items!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid target cost and select items')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Ordering App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Cost Input Field
            TextField(
              controller: _targetCost,
              decoration: InputDecoration(labelText: 'Target Cost'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),

            // Date Picker
            TextField(
              controller: _date,
              decoration: InputDecoration(labelText: 'Date (yyyy-mm-dd)'),
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2025),
                );

                if (selectedDate != null) {
                  String selectedDateString = "${selectedDate.toLocal()}".split(' ')[0];
                  DatabaseHelper dbHelper = DatabaseHelper();
                  var existingOrderPlan = await dbHelper.getOrderPlanByDate(selectedDateString);

                  if (existingOrderPlan != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("An order plan already exists for this date. Please choose another date.")),
                    );
                  } else {
                    setState(() {
                      _date.text = selectedDateString;
                    });
                  }
                }
              },
            ),
            SizedBox(height: 10),

            // Display Total Selected Cost
            Text('Total Selected Cost: \$${totalCost.toStringAsFixed(2)}'),
            SizedBox(height: 20),

            // Food Items List (Checkbox List)
            _foodItems.isEmpty
                ? CircularProgressIndicator()
                : Column(
              children: _foodItems.map<Widget>((foodItem) {
                return CheckboxListTile(
                  title: Text("${foodItem['name']} - \$${foodItem['cost']}"),
                  value: selectedFoodItems.contains(foodItem['id']),
                  onChanged: (bool? selected) {
                    setState(() {
                      double targetCost = double.tryParse(_targetCost.text) ?? 0.0;

                      if (selected == true) {
                        if (totalCost + foodItem['cost'] <= targetCost) {
                          selectedFoodItems.add(foodItem['id']);
                          totalCost += foodItem['cost'];
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Target cost reached. Can't buy more items!"),
                            ),
                          );
                        }
                      } else {
                        selectedFoodItems.remove(foodItem['id']);
                        totalCost -= foodItem['cost'];
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _saveOrderPlan,
              child: Text('Save Order Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
