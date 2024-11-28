import 'package:flutter/material.dart';
import 'database_helper.dart';

class EditOrderPlanPage extends StatefulWidget {
  final Map<String, dynamic> orderPlan;

  EditOrderPlanPage({required this.orderPlan});

  @override
  _EditOrderPlanPageState createState() => _EditOrderPlanPageState();
}

class _EditOrderPlanPageState extends State<EditOrderPlanPage> {
  late TextEditingController _targetCost;
  late TextEditingController _date;
  double totalCost = 0.0;
  List<int> selectedFoodItems = [];

  @override
  void initState() {
    super.initState();
    _targetCost= TextEditingController(text: widget.orderPlan['target_cost'].toString());
    _date = TextEditingController(text: widget.orderPlan['date']);

    _fetchOrderPlanFoodItems();
  }

  // Fetch order plan food items
  void _fetchOrderPlanFoodItems() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> foodItems = await dbHelper.getFoodItemsByOrderPlan(widget.orderPlan['id']);
    setState(() {
      selectedFoodItems = foodItems.map<int>((item) => item['id'] as int).toList();
    });
    _calculateTotalCost();
  }

  void _calculateTotalCost() async {
    totalCost = 0.0;
    DatabaseHelper dbHelper = DatabaseHelper();
    for (var foodItemId in selectedFoodItems) {
      var foodItem = await dbHelper.getFoodItemById(foodItemId);
      if (foodItem != null && foodItem['cost'] != null) {
        totalCost += foodItem['cost'];
      }
    }
    setState(() {});
  }

  Future<void> _updateOrderPlan() async {
    double targetCost = double.tryParse(_targetCost.text) ?? 0.0;
    String date = _date.text;

    if (targetCost > 0 && selectedFoodItems.isNotEmpty) {
      DatabaseHelper dbHelper = DatabaseHelper();

      // Update order plan
      await dbHelper.updateOrderPlan(widget.orderPlan['id'], targetCost, date);

      // Delete existing order items and add new ones
      await dbHelper.deleteOrderItemsforUpdate(widget.orderPlan['id']);

      for (var foodItemId in selectedFoodItems) {
        await dbHelper.insertOrderItem(widget.orderPlan['id'], foodItemId);
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order Plan Updated Successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid target cost and select items')));
    }
  }

  void _onFoodItemSelected(int foodItemId, bool selected) {
    double targetCost = double.tryParse(_targetCost.text) ?? 0.0;

    if (selected) {
      DatabaseHelper dbHelper = DatabaseHelper();
      dbHelper.getFoodItemById(foodItemId).then((foodItem) {
        if (foodItem != null && foodItem['cost'] != null) {
          double newTotalCost = totalCost + foodItem['cost'];

          if (newTotalCost <= targetCost) {
            setState(() {
              selectedFoodItems.add(foodItemId);
              totalCost = newTotalCost;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Cannot add this item. It exceeds the target cost!'),
            ));
          }
        }
      });
    } else {
      setState(() {
        selectedFoodItems.remove(foodItemId);
        _calculateTotalCost();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double targetCost = double.tryParse(_targetCost.text) ?? 0.0;
    bool isSaveButtonEnabled = totalCost <= targetCost;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Order Plan')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _targetCost,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Target Cost'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _date,
              decoration: InputDecoration(labelText: 'Select Date'),
              readOnly: true,
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (selectedDate != null) {
                  String selectedDateStr = "${selectedDate.toLocal()}".split(' ')[0];
                  setState(() {
                    _date.text = selectedDateStr;
                  });
                }
              },
            ),
            SizedBox(height: 10),
            Text('Total Selected Cost: \$${totalCost.toStringAsFixed(2)}'),
            SizedBox(height: 20),
            Text("Select Food Items:"),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper().getAllFoodItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error loading food items');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No food items available');
                } else {
                  List<Map<String, dynamic>> foodItems = snapshot.data!;

                  return Column(
                    children: foodItems.map((foodItem) {
                      return CheckboxListTile(
                        title: Text("${foodItem['name']} - \$${foodItem['cost']}"),
                        value: selectedFoodItems.contains(foodItem['id']),
                        onChanged: (bool? selected) {
                          if (selected != null) {
                            _onFoodItemSelected(foodItem['id'], selected);
                          }
                        },
                      );
                    }).toList(),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaveButtonEnabled ? _updateOrderPlan : null,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
