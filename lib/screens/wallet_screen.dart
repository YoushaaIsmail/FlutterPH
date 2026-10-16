// wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/wallet.dart';
import '../models/operation.dart';

class WalletScreen extends StatefulWidget {
  final int? initialTab;
  const WalletScreen({super.key, this.initialTab});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Wallet data
  Wallet? _wallet;
  List<Operation> _operations = [];
  double? _walletBalance;

  // UI state
  bool _isLoading = true;
  bool _isLoadingOperations = true;
  String? _errorMessage;

  // Add money form
  final _addMoneyFormKey = GlobalKey<FormState>();
  String? _selectedAddType;
  final _addAmountController = TextEditingController();
  final _addCodeController = TextEditingController();
  final _addAccountController = TextEditingController();
  File? _selectedImage;
  bool _isSubmittingAdd = false;

  // Withdraw form
  final _withdrawFormKey = GlobalKey<FormState>();
  String? _selectedWithdrawType;
  final _withdrawAmountController = TextEditingController();
  final _withdrawAccountController = TextEditingController();
  bool _isSubmittingWithdraw = false;

  final ImagePicker _imagePicker = ImagePicker();

  // Operation types
  final List<String> _operationTypes = ['Syriatel', 'MTN'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );

    // Load data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
      _loadOperations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addAmountController.dispose();
    _addCodeController.dispose();
    _addAccountController.dispose();
    _withdrawAmountController.dispose();
    _withdrawAccountController.dispose();
    super.dispose();
  }

  // Load wallet data
  Future<void> _loadWalletData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('Please login first');
      }

      final walletData = await ApiService.getWallet(token);

      if (!mounted) return;

      setState(() {
        _wallet = Wallet.fromJson(walletData['data']);
        _walletBalance = _wallet?.amount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // Load transaction history
  Future<void> _loadOperations() async {
    if (!mounted) return;

    setState(() {
      _isLoadingOperations = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Please login first');
      }

      final operationsData = await ApiService.getOperations(token);

      if (!mounted) return;

      setState(() {
        _operations = (operationsData['data'] as List)
            .map((e) => Operation.fromJson(e))
            .toList();
        _isLoadingOperations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingOperations = false;
      });
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e', isError: true);
    }
  }

  // Submit deposit request
  Future<void> _submitAddMoney() async {
    if (!_addMoneyFormKey.currentState!.validate()) return;

    if (_selectedAddType == null) {
      _showSnackBar('Please select a payment method', isError: true);
      return;
    }

    setState(() => _isSubmittingAdd = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Please login first');
      }

      await ApiService.addMoney(
        token: token,
        type: _selectedAddType!,
        amount: double.parse(_addAmountController.text),
        code: _addCodeController.text.isNotEmpty
            ? _addCodeController.text
            : null,
        accountNumber: _addAccountController.text.isNotEmpty
            ? _addAccountController.text
            : null,
        image: _selectedImage,
      );

      if (!mounted) return;

      _showSnackBar(
        'Deposit request submitted successfully! Waiting for approval',
        isSuccess: true,
      );

      // Reset form
      setState(() {
        _selectedAddType = null;
        _addAmountController.clear();
        _addCodeController.clear();
        _addAccountController.clear();
        _selectedImage = null;
      });

      // Refresh data
      _loadOperations();
      _loadWalletData();

      // Switch to history tab
      _tabController.animateTo(2);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Error: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingAdd = false);
      }
    }
  }

  // Submit withdrawal request
  Future<void> _submitWithdraw() async {
    if (!_withdrawFormKey.currentState!.validate()) return;

    if (_selectedWithdrawType == null) {
      _showSnackBar('Please select a withdrawal method', isError: true);
      return;
    }

    setState(() => _isSubmittingWithdraw = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Please login first');
      }

      await ApiService.withdrawMoney(
        token: token,
        type: _selectedWithdrawType!,
        amount: double.parse(_withdrawAmountController.text),
        accountNumber: _withdrawAccountController.text,
      );

      if (!mounted) return;

      _showSnackBar(
        'Withdrawal request submitted successfully! Waiting for approval',
        isSuccess: true,
      );

      // Reset form
      setState(() {
        _selectedWithdrawType = null;
        _withdrawAmountController.clear();
        _withdrawAccountController.clear();
      });

      // Refresh data
      _loadWalletData();
      _loadOperations();

      // Switch to history tab
      _tabController.animateTo(2);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Error: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingWithdraw = false);
      }
    }
  }

  // Cancel pending operation
  Future<void> _cancelOperation(int operationId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Please login first');
      }

      await ApiService.cancelOperation(token, operationId);

      _showSnackBar('Operation cancelled successfully', isSuccess: true);
      _loadOperations();
      _loadWalletData();
    } catch (e) {
      _showSnackBar(
        'Error cancelling operation: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    }
  }

  // Show snackbar message
  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: isError ? Colors.red.shade700 : Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade50 : Colors.green.shade50,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Cancel operation confirmation dialog
  void _showCancelDialog(int operationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Operation'),
        content: const Text('Are you sure you want to cancel this operation?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOperation(operationId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Wallet',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle), text: 'Deposit'),
            Tab(icon: Icon(Icons.remove_circle), text: 'Withdraw'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : Column(
              children: [
                // Wallet balance card
                _buildWalletBalanceCard(),

                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Deposit tab
                      _buildAddMoneyTab(),

                      // Withdraw tab
                      _buildWithdrawTab(),

                      // History tab
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading wallet...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadWalletData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Wallet balance card
  Widget _buildWalletBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_walletBalance?.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Wallet ID: ${_wallet?.id ?? ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Deposit tab
  Widget _buildAddMoneyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _addMoneyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Money to Wallet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a payment method and enter details',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Payment method selection
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: _operationTypes.map((type) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAddType = type;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedAddType == type
                            ? Colors.green.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedAddType == type
                              ? Colors.green.shade700
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type == 'Syriatel'
                                ? Icons.phone_android
                                : Icons.sim_card,
                            color: _selectedAddType == type
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type,
                            style: TextStyle(
                              color: _selectedAddType == type
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: _selectedAddType == type
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Amount field
            _buildTextField(
              controller: _addAmountController,
              label: 'Amount',
              icon: Icons.attach_money,
              color: Colors.green,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Account number field (optional)
            _buildTextField(
              controller: _addAccountController,
              label: 'Account Number (Optional)',
              icon: Icons.credit_card,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),

            // Operation code field (optional)
            _buildTextField(
              controller: _addCodeController,
              label: 'Operation Code (Optional)',
              icon: Icons.code,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),

            // Receipt image upload
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.image,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Payment Receipt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedImage != null) ...[
                    Container(
                      height: 150,
                      width: double.infinity,
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(
                              Icons.upload_file,
                              color: Colors.green.shade700,
                            ),
                            label: Text(
                              _selectedImage == null
                                  ? 'Upload Image'
                                  : 'Change Image',
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        if (_selectedImage != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            icon: Icon(Icons.close, color: Colors.red.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.teal.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmittingAdd ? null : _submitAddMoney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmittingAdd
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Withdraw tab
  Widget _buildWithdrawTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _withdrawFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Withdraw Money',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Withdraw funds to your mobile account',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Withdrawal method selection
            const Text(
              'Withdraw to',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: _operationTypes.map((type) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedWithdrawType = type;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedWithdrawType == type
                            ? Colors.green.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedWithdrawType == type
                              ? Colors.green.shade700
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type == 'Syriatel'
                                ? Icons.phone_android
                                : Icons.sim_card,
                            color: _selectedWithdrawType == type
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type,
                            style: TextStyle(
                              color: _selectedWithdrawType == type
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: _selectedWithdrawType == type
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Amount field
            _buildTextField(
              controller: _withdrawAmountController,
              label: 'Amount',
              icon: Icons.attach_money,
              color: Colors.green,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                final amount = double.parse(value);
                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                if (_wallet != null && amount > _wallet!.amount) {
                  return 'Insufficient balance';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Account number field
            _buildTextField(
              controller: _withdrawAccountController,
              label: 'Account Number',
              icon: Icons.credit_card,
              color: Colors.blue,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Balance information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your balance: \$${_wallet?.amount.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Withdraw button
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.orange.shade700, Colors.deepOrange.shade600],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmittingWithdraw ? null : _submitWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmittingWithdraw
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Withdraw',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Transaction history tab
  Widget _buildHistoryTab() {
    if (_isLoadingOperations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_operations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transactions will appear here',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _operations.length,
      itemBuilder: (context, index) {
        final operation = _operations[index];
        return _buildOperationCard(operation);
      },
    );
  }

  // Operation card
  Widget _buildOperationCard(Operation operation) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (operation.state) {
      case 'Success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Success';
        break;
      case 'Failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Failed';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
    }

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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: operation.method == 'Add'
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    operation.method == 'Add'
                        ? Icons.add_circle
                        : Icons.remove_circle,
                    color: operation.method == 'Add'
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            operation.method == 'Add' ? 'Deposit' : 'Withdraw',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        operation.type,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${operation.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: operation.method == 'Add'
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(operation.date1),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (operation.state == 'pending') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCancelDialog(operation.id),
                    icon: Icon(
                      Icons.cancel,
                      color: Colors.red.shade700,
                      size: 18,
                    ),
                    label: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Custom text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required MaterialColor color,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color.shade700, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }

  // Format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
