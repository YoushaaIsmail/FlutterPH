import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isLoading = authProvider.isLoadingProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade800,
                Colors.green.shade600,
                Colors.teal.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.green.shade200.withOpacity(0.5),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                ).then((_) {
                  // Refresh profile data when returning from edit screen
                  authProvider.refreshUserData();
                });
              },
              tooltip: 'Edit Profile',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => authProvider.refreshUserData(),
              tooltip: 'Refresh',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                _showLogoutDialog(context, authProvider);
              },
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade700,
                    ),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading profile...',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No user data available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => authProvider.refreshUserData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => authProvider.refreshUserData(),
              color: Colors.green.shade700,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header with Gradient
                    _buildProfileHeader(context, authProvider, user),

                    const SizedBox(height: 20),

                    // Personal Information Section
                    _buildSectionTitle('Personal Information'),

                    // Email Card
                    _buildInfoCard(
                      icon: Icons.email,
                      label: 'Email',
                      value: user['email'] ?? 'Not provided',
                      iconColor: Colors.green,
                      trailing: _buildVerificationStatus(user),
                    ),

                    // Phone Number Card
                    if (user['phone'] != null &&
                        user['phone'].toString().isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.phone,
                        label: 'Phone Number',
                        value: user['phone'],
                        iconColor: Colors.teal,
                      ),

                    // First Name Card
                    if (user['first_name'] != null &&
                        user['first_name'].toString().isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.person,
                        label: 'First Name',
                        value: user['first_name'],
                        iconColor: Colors.blue,
                      ),

                    // Last Name Card
                    if (user['last_name'] != null &&
                        user['last_name'].toString().isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        label: 'Last Name',
                        value: user['last_name'],
                        iconColor: Colors.blue,
                      ),

                    // Birthday Card
                    _buildInfoCard(
                      icon: Icons.cake,
                      label: 'Birthday',
                      value: authProvider.getFormattedBirthday(),
                      iconColor: Colors.orange,
                      subtitle: authProvider.getUserAge() != null
                          ? '${authProvider.getUserAge()} years old'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // Account Section Title
                    _buildSectionTitle('Account Settings'),

                    // Account Actions
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildAccountAction(
                            icon: Icons.edit,
                            label: 'Edit Profile',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              ).then((_) {
                                authProvider.refreshUserData();
                              });
                            },
                          ),
                          _buildAccountAction(
                            icon: Icons.security,
                            label: 'Privacy & Security',
                            onTap: () {
                              // Navigate to privacy settings
                              _showPrivacyDialog(context);
                            },
                          ),
                          if (authProvider.getMissingProfileFields().isNotEmpty)
                            _buildAccountAction(
                              icon: Icons.warning,
                              label: 'Complete Profile',
                              onTap: () {
                                _showMissingFieldsDialog(
                                  context,
                                  authProvider.getMissingProfileFields(),
                                );
                              },
                            ),
                          _buildAccountAction(
                            icon: Icons.logout,
                            label: 'Logout',
                            onTap: () =>
                                _showLogoutDialog(context, authProvider),
                            isDestructive: true,
                            showDivider: true,
                          ),
                        ],
                      ),
                    ),

                    // Profile Completion Section
                    // In the build method, where you call _buildProfileCompletionCard
                    if (authProvider.getProfileCompletionPercentage() < 100)
                      _buildProfileCompletionCard(
                        context,
                        authProvider,
                      ), // Pass context here

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AuthProvider authProvider,
    Map<String, dynamic> user,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Photo
          Stack(
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.green.shade100,
                backgroundImage: authProvider.getUserPhotoUrl() != null
                    ? NetworkImage(authProvider.getUserPhotoUrl()!)
                    : null,
                child: authProvider.getUserPhotoUrl() == null
                    ? Icon(Icons.person, size: 70, color: Colors.green.shade700)
                    : null,
              ),
              if (user['is_verified'] == true)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // User Full Name
          Text(
            authProvider.getDisplayName(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
            textAlign: TextAlign.center,
          ),

          // Username
          if (user['username'] != null &&
              user['username'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '@${user['username']}',
                style: TextStyle(fontSize: 16, color: Colors.green.shade600),
              ),
            ),

          // Member since
          if (user['date_joined'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Member since ${_formatDateShort(user['date_joined'])}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor iconColor,
    Widget? trailing,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor.shade700, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildAccountAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey.shade200,
          ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDestructive
                  ? Colors.red.shade700
                  : Colors.green.shade700,
              size: 22,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDestructive ? Colors.red.shade700 : Colors.grey.shade800,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _buildProfileCompletionCard(
    BuildContext context, // Add this parameter
    AuthProvider authProvider,
  ) {
    final percentage = authProvider.getProfileCompletionPercentage();
    final missingFields = authProvider.getMissingProfileFields();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Profile ${percentage.toStringAsFixed(0)}% Complete',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.orange.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your profile by adding: ${missingFields.join(', ')}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context, // Now context is available
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orange.shade700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Complete Profile',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus(Map<String, dynamic> user) {
    final isVerified = user['is_verified'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.warning_amber_rounded,
            color: isVerified ? Colors.green.shade700 : Colors.orange.shade700,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verified' : 'Not verified',
            style: TextStyle(
              color: isVerified
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Not provided';

    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  String _formatDateShort(String? date) {
    if (date == null || date.isEmpty) return 'Unknown';

    try {
      final parsedDate = DateTime.parse(date);
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${monthNames[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                authProvider.logout();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showMissingFieldsDialog(
    BuildContext context,
    List<String> missingFields,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Your Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please complete the following information:'),
              const SizedBox(height: 12),
              ...missingFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(field),
                    ],
                  ),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
              child: const Text('Complete Now'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy & Security'),
          content: const Text(
            'Your data is securely stored and protected. '
            'We use industry-standard encryption to keep your information safe.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
