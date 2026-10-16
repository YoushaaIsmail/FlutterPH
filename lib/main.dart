import 'package:flutter/material.dart';
import 'screens/medicine_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/comments_screen.dart';
import 'screens/address_list_screen.dart';
import 'screens/address_form_screen.dart';
import 'screens/chat_users_screen.dart'; // Add this import
import 'screens/chat_room_screen.dart'; // Add this import
import 'models/medicine.dart';
import 'models/address.dart';
import 'models/chat_user.dart'; // Add this import
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/address_service.dart';
import 'services/chat_service.dart'; // Add this import (optional, for WebSocket)

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkAuthStatus(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PH Medicine',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const MedicineScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/addresses': (context) => _buildAddressListScreen(context),
        '/chat': (context) => _buildChatUsersScreen(context), // Add chat route
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/comments':
            final medicine = settings.arguments as Medicine?;
            if (medicine != null) {
              return MaterialPageRoute(
                builder: (context) => CommentsScreen(medicine: medicine),
              );
            }
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Medicine not found')),
              ),
            );

          case '/wallet':
            if (settings.arguments != null) {
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args.containsKey('tab')) {
                return MaterialPageRoute(
                  builder: (context) => WalletScreen(initialTab: args['tab']),
                );
              }
            }
            return MaterialPageRoute(
              builder: (context) => const WalletScreen(),
            );

          case '/address-form':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => AddressFormScreen(
                address: args?['address'],
                addressService: _getAddressService(context),
              ),
            );

          case '/address':
            return MaterialPageRoute(
              builder: (context) => AddressListScreen(
                addressService: _getAddressService(context),
              ),
            );

          case '/address-edit':
            final address = settings.arguments as Address?;
            return MaterialPageRoute(
              builder: (context) => AddressFormScreen(
                address: address,
                addressService: _getAddressService(context),
              ),
            );

          // Add chat room route
          case '/chat-room':
            final otherUser = settings.arguments as ChatUser?;
            if (otherUser != null) {
              return MaterialPageRoute(
                builder: (context) => ChatRoomScreen(otherUser: otherUser),
              );
            }
            return MaterialPageRoute(
              builder: (context) =>
                  const Scaffold(body: Center(child: Text('User not found'))),
            );

          default:
            return null;
        }
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('The requested page does not exist.'),
            ),
          ),
        );
      },
    );
  }

  // Helper function to build AddressListScreen with token
  static Widget _buildAddressListScreen(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final addressService = AddressService(token);
    return AddressListScreen(addressService: addressService);
  }

  // Helper function to build ChatUsersScreen with token check
  static Widget _buildChatUsersScreen(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const ChatUsersScreen();
  }

  // Helper function to get AddressService with current token
  static AddressService _getAddressService(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      throw Exception('User not authenticated');
    }

    return AddressService(token);
  }
}
