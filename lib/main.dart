// lib/main.dart 
import 'package:flutter/material.dart';
import 'package:truechain/screens/blockchain_analytics_screen.dart';
import 'package:truechain/screens/order_management_screen.dart';
import 'package:truechain/screens/product_management_screen.dart';
import 'package:truechain/screens/customer_transparency_screen.dart';
import 'package:truechain/screens/dashboard_customer.dart';
import 'package:truechain/screens/welcome_screen.dart';
import 'package:truechain/screens/admin_login_screen.dart';
import 'package:truechain/screens/customer_login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/simple_auth_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  print(' Simple Auth Service ready for authentication');
  
  // Initialize other services (remove blockchain if causing issues)
  print(' App initialized successfully');
  
  runApp(TrueChainApp());
}

class TrueChainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrueChain',
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF5B5CE6, {
          50: Color(0xFFEEF2FF),
          100: Color(0xFFE0E7FF),
          200: Color(0xFFC7D2FE),
          300: Color(0xFFA5B4FC),
          400: Color(0xFF818CF8),
          500: Color(0xFF5B5CE6),
          600: Color(0xFF4338CA),
          700: Color(0xFF3730A3),
          800: Color(0xFF312E81),
          900: Color(0xFF1E1B4B),
        }),
        fontFamily: 'Roboto',
      ),
      
      home: SimpleAuthWrapper(),
      
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/admin-login': (context) => AdminLoginScreen(),
        '/customer-login': (context) => CustomerLoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/customer-dashboard': (context) => const CustomerDashboardScreen(),
        '/products': (context) => ProductManagementScreen(),
        '/blockchain': (context) => ProductAnalyticsScreen(),
        '/customer-portal': (context) => const CustomerTransparencyScreen(),
        '/orders': (context) => const OrderManagementScreen(),
      },
      
      debugShowCheckedModeBanner: false,
    );
  }
}

class SimpleAuthWrapper extends StatefulWidget {
  @override
  _SimpleAuthWrapperState createState() => _SimpleAuthWrapperState();
}

class _SimpleAuthWrapperState extends State<SimpleAuthWrapper> {
  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    if (SimpleAuthService.isLoggedIn) {
      // Route based on user role
      String? userRole = SimpleAuthService.currentUserRole;
      
      if (userRole == 'admin') {
        return const DashboardScreen();
      } else if (userRole == 'customer') {
        return const CustomerDashboardScreen();
      } else {
        // Fallback to welcome screen if role is unknown
        return WelcomeScreen();
      }
    } else {
      // User not logged in, show welcome screen
      return WelcomeScreen();
    }
  }
}

// Auth wrapper widget that can be used in other parts of the app
class AuthWrapper extends StatelessWidget {
  final Widget authenticatedWidget;
  final Widget unauthenticatedWidget;

  const AuthWrapper({
    Key? key,
    required this.authenticatedWidget,
    required this.unauthenticatedWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (SimpleAuthService.isLoggedIn) {
      return authenticatedWidget;
    } else {
      return unauthenticatedWidget;
    }
  }
}

// User info widget that can be used to display current user information
class UserInfoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = SimpleAuthService.currentUser;
    
    if (currentUser == null) {
      return Container();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${currentUser['name']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentUser['email'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: currentUser['role'] == 'admin' 
                ? Colors.blue.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentUser['role'] == 'admin' 
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Text(
              currentUser['role'].toString().toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: currentUser['role'] == 'admin' 
                  ? Colors.blue[700]
                  : Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Logout button widget
class LogoutButton extends StatelessWidget {
  final VoidCallback? onLogout;

  const LogoutButton({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () async {
        // Show confirmation dialog
        final bool? shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        if (shouldLogout == true) {
          await SimpleAuthService().logout();
          
          if (onLogout != null) {
            onLogout!();
          }
          
          // Navigate to welcome screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/welcome',
            (route) => false,
          );
        }
      },
    );
  }
}