import 'package:flutter_local_db/flutter_local_db.dart';

void main() async {
  // Initialize the database
  await LocalDB.init('my_database');

  // Create a record
  final result = await LocalDB.Post('user_1', {
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30,
  });

  result.when(
    ok: (model) => print('Created: ${model.id}'),
    err: (error) => print('Error: $error'),
  );

  // Get a record
  final getResult = await LocalDB.GetById('user_1');
  final user = getResult.unwrapOr(null);
  print('User: $user');

  // Update a record
  await LocalDB.Put('user_1', {
    'name': 'Jane Doe',
    'email': 'jane@example.com',
    'age': 25,
  });

  // Get all records
  final allResult = await LocalDB.GetAll();
  allResult.when(
    ok: (models) => print('Total records: ${models.length}'),
    err: (error) => print('Error: $error'),
  );

  // Delete a record
  await LocalDB.Delete('user_1');

  // Clear all data
  await LocalDB.ClearData();

  // Close database (optional)
  await LocalDB.close();
}
