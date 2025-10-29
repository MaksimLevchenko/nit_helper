import 'models/user.dart';

void main() {
  final user = User(name: 'John', age: 30, email: 'john@example.com');
  final updatedUser = user.copyWith(age: 31);

  print('Original user: $user');
  print('Updated user: $updatedUser');
}
