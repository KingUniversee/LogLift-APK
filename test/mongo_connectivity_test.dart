import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/data/database/mongo_database.dart';
import 'package:liftlog/data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('verify live MongoDB Atlas connection and auth registration/login', () async {
    final mongoDb = MongoDatabase.instance;
    await mongoDb.connect();
    expect(mongoDb.isConnected, isTrue);

    final authService = AuthService();
    final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@liftlog.test';
    
    // 1. Register new user
    final user = await authService.register(
      name: 'Test Athlete',
      email: testEmail,
      password: 'StrongPassword123!',
    );
    expect(user, isNotNull);
    expect(user.email, equals(testEmail));
    expect(user.name, equals('Test Athlete'));

    // 2. Login with credentials
    final loggedInUser = await authService.login(
      email: testEmail,
      password: 'StrongPassword123!',
    );
    expect(loggedInUser, isNotNull);
    expect(loggedInUser?.id, equals(user.id));

    // Clean up test user
    final usersColl = await mongoDb.usersCollection;
    await usersColl.deleteOne({'email': testEmail});
    await mongoDb.close();
  });
}

