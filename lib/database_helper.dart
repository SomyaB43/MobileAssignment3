import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'foodDatabase.db';

  // Create the database
  Future<Database> get database async {
    if (_database == null) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(path, onCreate: (db, version) async {
      // Create the food_items table
      await db.execute('''  
        CREATE TABLE IF NOT EXISTS food_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          cost REAL NOT NULL
        )
      ''');

      // Create the order_plans table
      await db.execute('''  
        CREATE TABLE IF NOT EXISTS order_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          target_cost REAL NOT NULL,
          date TEXT NOT NULL
        )
      ''');

      // Create the order_items table
      await db.execute('''  
        CREATE TABLE IF NOT EXISTS order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_plan_id INTEGER,
          food_item_id INTEGER,
          FOREIGN KEY (order_plan_id) REFERENCES order_plans(id),
          FOREIGN KEY (food_item_id) REFERENCES food_items(id)
        )
      ''');

      // Populate the food_items table with provided data
      List<Map<String, dynamic>> foodItems = [
        {'name': 'Chocolate', 'cost': 15.00},
        {'name': 'Burger', 'cost': 8.00},
        {'name': 'Pasta', 'cost': 12.50},
        {'name': 'Shawarma', 'cost': 6.00},
        {'name': 'Salad', 'cost': 20.00},
        {'name': 'Burritos', 'cost': 10.00},
        {'name': 'Ice Cream', 'cost': 5.50},
        {'name': 'Fries', 'cost': 3.00},
        {'name': 'Spaghetti', 'cost': 25.00},
        {'name': 'Waffles', 'cost': 7.00},
        {'name': 'Pancakes', 'cost': 5.00},
        {'name': 'Pastry', 'cost': 9.00},
        {'name': 'Popcorn', 'cost': 4.00},
        {'name': 'Nuggets', 'cost': 3.50},
        {'name': 'Soup', 'cost': 6.50},
        {'name': 'Gummy Bears', 'cost': 11.00},
        {'name': 'Noodles', 'cost': 7.50},
        {'name': 'Donuts', 'cost': 4.50},
        {'name': 'Bagel', 'cost': 30.00},
        {'name': 'Chili', 'cost': 8.50},
      ];

      for (var foodItem in foodItems) {
        await db.insert('food_items', foodItem);
      }
    }, version: 1);
  }

  // Insert food item into the database
  Future<int> insertFoodItem(Map<String, dynamic> foodItem) async {
    final db = await database;
    return await db.insert('food_items', foodItem);
  }

  // Fetch all food items from the database
  Future<List<Map<String, dynamic>>> getAllFoodItems() async {
    final db = await database;
    return await db.query('food_items');
  }

  // Insert order plan into the database
  Future<int> insertOrderPlan(double targetCost, String date) async {
    final db = await database;
    Map<String, dynamic> orderPlan = {
      'target_cost': targetCost,
      'date': date,
    };
    return await db.insert('order_plans', orderPlan);
  }

  // Insert food item into the order_items table
  Future<void> insertOrderItem(int orderPlanId, int foodItemId) async {
    final db = await database;
    Map<String, dynamic> orderItem = {
      'order_plan_id': orderPlanId,
      'food_item_id': foodItemId,
    };
    await db.insert('order_items', orderItem);
  }

  // Fetch an order plan by date
  Future<Map<String, dynamic>?> getOrderPlanByDate(String date) async {
    final db = await database;
    var result = await db.query('order_plans',
        where: 'date = ?', whereArgs: [date]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Fetch all food items related to an order plan
  Future<List<Map<String, dynamic>>> getFoodItemsByOrderPlan(int orderPlanId) async {
    final db = await database;
    var result = await db.query('order_items',
        where: 'order_plan_id = ?', whereArgs: [orderPlanId]);

    List<Map<String, dynamic>> foodItems = [];
    for (var orderItem in result) {
      var foodItemId = orderItem['food_item_id'];
      var foodItem = await db.query('food_items', where: 'id = ?', whereArgs: [foodItemId]);
      if (foodItem.isNotEmpty) {
        foodItems.add(foodItem.first);
      }
    }
    return foodItems;
  }

  // Delete an order plan
  Future<void> deleteOrderPlan(int id) async {
    final db = await database;
    await db.delete('order_plans', where: 'id = ?', whereArgs: [id]);
    await db.delete('order_items', where: 'order_plan_id = ?', whereArgs: [id]);
  }

  // Delete all order items associated with a specific order plan ID
  Future<void> deleteOrderItemsforUpdate(int orderPlanId) async {
    final db = await database;
    await db.delete('order_items', where: 'order_plan_id = ?', whereArgs: [orderPlanId]);
  }

  // Update an order plan
  Future<void> updateOrderPlan(int id, double targetCost, String date) async {
    final db = await database;

    // Prepare the map for the updated order plan
    Map<String, dynamic> updatedOrderPlan = {
      'target_cost': targetCost,
      'date': date, // Convert list to a comma-separated string for storage
    };

    await db.update(
      'order_plans',
      updatedOrderPlan,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Fetch all order plans
  Future<List<Map<String, dynamic>>> getAllOrderPlans() async {
    final db = await database;
    return await db.query('order_plans');
  }

  Future<Map<String, dynamic>?> getFoodItemById(int id) async {
    final db = await database;  // Get the database instance
    List<Map<String, dynamic>> result = await db.query(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;  // Return null if no item is found
    }
  }

}
