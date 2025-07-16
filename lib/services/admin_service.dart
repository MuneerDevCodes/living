import 'package:living/services/auth_helper.dart';
import 'package:living/services/user_dao.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  Future<bool> isAdmin() async {
    final user = AuthService().currentUser;
    if (user == null) return false;
    
    final role = await UserDao().getUserRole(user.uid);
    return role == 'admin';
  }

  Future<String?> getCurrentUserRole() async {
    final user = AuthService().currentUser;
    if (user == null) return null;
    
    return await UserDao().getUserRole(user.uid);
  }

  bool isAuthenticated() {
    return AuthService().currentUser != null;
  }
} 