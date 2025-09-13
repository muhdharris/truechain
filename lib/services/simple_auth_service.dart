// lib/services/simple_auth_service.dart
class SimpleAuthService {
  // Mock user database - In a real app, this would be a proper database
  static final Map<String, Map<String, dynamic>> _users = {
    // Admin users
    'admin@truechain.com': {
      'password': 'admin123',
      'role': 'admin',
      'name': 'System Administrator',
    },
    'manager@truechain.com': {
      'password': 'manager123',
      'role': 'admin',
      'name': 'Supply Chain Manager',
    },
    
    // Customer users
    'customer@example.com': {
      'password': 'customer123',
      'role': 'customer',
      'name': 'John Customer',
    },
    'buyer@company.com': {
      'password': 'buyer123',
      'role': 'customer',
      'name': 'Jane Buyer',
    },
  };

  static Map<String, dynamic>? _currentUser;
  
  // Get current logged-in user
  static Map<String, dynamic>? get currentUser => _currentUser;
  
  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;
  
  // Get current user role
  static String? get currentUserRole => _currentUser?['role'];
  
  // Email validation
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  // Admin login
  Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    final user = _users[email.toLowerCase()];
    
    if (user == null) {
      throw Exception('No account found with this email address');
    }
    
    if (user['password'] != password) {
      throw Exception('Incorrect password');
    }
    
    if (user['role'] != 'admin') {
      throw Exception('Access denied. Admin privileges required.');
    }
    
    _currentUser = {
      'email': email.toLowerCase(),
      'role': user['role'],
      'name': user['name'],
    };
    
    return _currentUser!;
  }

  // Customer login
  Future<Map<String, dynamic>> customerLogin({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    final user = _users[email.toLowerCase()];
    
    if (user == null) {
      throw Exception('No account found with this email address');
    }
    
    if (user['password'] != password) {
      throw Exception('Incorrect password');
    }
    
    if (user['role'] != 'customer') {
      throw Exception('Access denied. Customer account required.');
    }
    
    _currentUser = {
      'email': email.toLowerCase(),
      'role': user['role'],
      'name': user['name'],
    };
    
    return _currentUser!;
  }

  // General login (for backward compatibility)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    final user = _users[email.toLowerCase()];
    
    if (user == null) {
      throw Exception('No account found with this email address');
    }
    
    if (user['password'] != password) {
      throw Exception('Incorrect password');
    }
    
    _currentUser = {
      'email': email.toLowerCase(),
      'role': user['role'],
      'name': user['name'],
    };
    
    return _currentUser!;
  }

  // Sign up new user
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'customer',
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (_users.containsKey(email.toLowerCase())) {
      throw Exception('An account with this email already exists');
    }
    
    // Add new user to mock database
    _users[email.toLowerCase()] = {
      'password': password,
      'role': role,
      'name': name,
    };
    
    _currentUser = {
      'email': email.toLowerCase(),
      'role': role,
      'name': name,
    };
    
    return _currentUser!;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (!_users.containsKey(email.toLowerCase())) {
      throw Exception('No account found with this email address');
    }
    
    // In a real app, this would send an email
    // For demo purposes, we'll just simulate success
    print('Password reset link sent to $email');
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
  }

  // Add a new user (for admin purposes)
  static void addUser({
    required String email,
    required String password,
    required String role,
    required String name,
  }) {
    _users[email.toLowerCase()] = {
      'password': password,
      'role': role,
      'name': name,
    };
  }

  // Get all users (for admin purposes)
  static Map<String, Map<String, dynamic>> getAllUsers() {
    return Map.from(_users);
  }

  // Remove user (for admin purposes)
  static void removeUser(String email) {
    _users.remove(email.toLowerCase());
  }
}