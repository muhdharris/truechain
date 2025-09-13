// lib/widgets/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:truechain/screens/blockchain_analytics_screen.dart';
import 'package:truechain/screens/dashboard_screen.dart';
import 'package:truechain/screens/product_management_screen.dart';
import 'package:truechain/screens/order_management_screen.dart';

class AppSidebar extends StatefulWidget {
  final String currentRoute;
  final bool blockchainEnabled;
  final VoidCallback? onTestBlockchain;

  const AppSidebar({
    Key? key,
    required this.currentRoute,
    required this.blockchainEnabled,
    this.onTestBlockchain,
  }) : super(key: key);

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    
    // Slide animation for sections
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 91, 137, 230),
            const Color.fromARGB(255, 91, 137, 230),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 91, 137, 230).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Header
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _slideController,
                child: _buildHeader(),
              ),
            ),

            const SizedBox(height: 20),

            // Navigation with staggered animation
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    ..._buildAnimatedNavItems(),
                    
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                      )),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.7, 1.0),
                        ),
                        child: const Divider(color: Colors.white30, height: 1),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ..._buildAnimatedSettingsItems(),
                  ],
                ),
              ),
            ),

            // Animated Version info
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: const Interval(0.9, 1.0, curve: Curves.easeOut),
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.9, 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'v1.0.0 Beta',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Transform.rotate(
                  angle: (1 - value) * 3.14159 * 2,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.link,
                      color: Color(0xFF5B5CE6),
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'TrueChain',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedNavItems() {
    final navItems = [
      ('Dashboard', Icons.dashboard, 'dashboard'),
      ('Product\nManagement', Icons.inventory_2, 'products'),
      ('Order\nManagement', Icons.receipt_long, 'orders'),
      ('Blockchain\nAnalytics', Icons.analytics, 'blockchain'),
      ('Customer\nManagement', Icons.people, 'customers'),
    ];

    return navItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.5, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            0.1 + (index * 0.1),
            0.4 + (index * 0.1),
            curve: Curves.easeOutBack,
          ),
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _slideController,
            curve: Interval(
              0.1 + (index * 0.1),
              0.4 + (index * 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildNavItem(
              context,
              item.$1,
              item.$2,
              item.$3,
              () => _navigateTo(context, item.$3),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildAnimatedSettingsItems() {
    final settingsItems = [
      ('Settings', Icons.settings, 'settings'),
      ('Help & Support', Icons.help_outline, 'help'),
    ];

    return settingsItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.5, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            0.75 + (index * 0.05),
            0.9 + (index * 0.05),
            curve: Curves.easeOut,
          ),
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _slideController,
            curve: Interval(
              0.75 + (index * 0.05),
              0.9 + (index * 0.05),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildNavItem(
              context,
              item.$1,
              item.$2,
              item.$3,
              item.$3 == 'settings'
                  ? () => _showSettingsDialog(context)
                  : () => _showHelpDialog(context),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    VoidCallback onTap,
  ) {
    final isActive = widget.currentRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isNavigating ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.all(16),
            transform: Matrix4.identity()
              ..scale(isActive ? 1.03 : 1.0)
              ..translate(isActive ? 4.0 : 0.0, 0.0, 0.0),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: Colors.white.withOpacity(0.3))
                  : null,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isActive ? 22 : 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isActive ? 15 : 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      height: 1.2,
                    ),
                    child: Text(title),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isActive ? 1.0 : 0.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 6 : 0,
                    height: isActive ? 6 : 0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    if (widget.currentRoute == route || _isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    // Show loading indicator
    _showNavigationLoader(context);

    Widget targetPage;
    switch (route) {
      case 'dashboard':
        targetPage = const DashboardScreen();
        break;
      case 'products':
        targetPage = ProductManagementScreen();
        break;
      case 'orders':
        targetPage = const OrderManagementScreen();
        break;
      case 'blockchain':
        targetPage = ProductAnalyticsScreen();
        break;
      default:
        setState(() {
          _isNavigating = false;
        });
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route not implemented yet')),
        );
        return;
    }

    // Simulate loading delay for smoother UX
    Future.delayed(const Duration(milliseconds: 800), () {
      Navigator.pop(context); // Close loader
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => targetPage,
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth slide and fade transition
            final slideAnimation = Tween(
              begin: const Offset(0.15, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            ));
            
            final fadeAnimation = Tween(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
            ));

            final scaleAnimation = Tween(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
        ),
      );
      
      setState(() {
        _isNavigating = false;
      });
    });
  }

  void _showNavigationLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 100,
              minHeight: 100,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF5B5CE6),
                    ),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dialog methods remain the same but with enhanced animations
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.settings, color: Color(0xFF5B5CE6)),
            SizedBox(width: 8),
            Text('Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Application Settings',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: Switch(value: true, onChanged: (value) {}),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(value: false, onChanged: (value) {}),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              trailing: const Text('English'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            const Text('Blockchain Settings',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Network'),
              trailing: const Text('Ethereum'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Auto-verify Orders'),
              trailing: Switch(value: widget.blockchainEnabled, onChanged: (value) {}),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5CE6),
            ),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.help_outline, color: Color(0xFF5B5CE6)),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Help',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildHelpItem('Getting Started',
                  'Learn how to use TrueChain for supply chain management'),
              _buildHelpItem('Product Management',
                  'Add, edit, and track your products with blockchain verification'),
              _buildHelpItem('Order Management',
                  'Process customer orders and track shipments end-to-end'),
              _buildHelpItem('Blockchain Features',
                  'Understand blockchain registration and verification process'),
              _buildHelpItem('Customer Portal',
                  'Provide transparency to your customers with real-time tracking'),
              const SizedBox(height: 20),
              const Text('Support',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('support@truechain.com'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('+1 (555) 123-4567'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.web, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('www.truechain.com/help'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B5CE6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF5B5CE6).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lightbulb, color: Color(0xFF5B5CE6), size: 16),
                        SizedBox(width: 8),
                        Text('Pro Tip', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use blockchain verification to build trust with your customers and ensure product authenticity.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening support chat...')),
              );
            },
            icon: const Icon(Icons.chat, color: Colors.white, size: 16),
            label: const Text('Contact Support', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5CE6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF5B5CE6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}