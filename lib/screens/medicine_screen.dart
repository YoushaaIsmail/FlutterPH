import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../widgets/medicine_card.dart';
import 'package:provider/provider.dart';
import 'package:app2/providers/auth_provider.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  // Data
  List<Medicine> allMedicines = [];
  List<Category> categories = [];
  List<Ingredient> ingredients = [];

  // Selected filters
  String? selectedCategorySlug;
  String? selectedIngredientId;

  bool isLoading = true;
  String? errorMessage;

  // Responsive variables
  ScrollController? _scrollController;
  bool _showBackToTop = false;

  // New variable for filter visibility
  bool _showFilters = true; // Default to showing filters

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(() {
      if (_scrollController!.offset > 300 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_scrollController!.offset <= 300 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });
    _fetchData();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await ApiService.fetchAllData(
        categorySlug: selectedCategorySlug,
        ingredientId: selectedIngredientId,
      );
      if (!mounted) return;
      setState(() {
        allMedicines = (data['medicines'] as List)
            .map((e) => Medicine.fromJson(e))
            .toList();
        categories = (data['categories'] as List)
            .map((e) => Category.fromJson(e))
            .toList();
        ingredients = (data['active_ingredients'] as List)
            .map((e) => Ingredient.fromJson(e))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      selectedCategorySlug = null;
      selectedIngredientId = null;
    });
    _fetchData();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  bool get hasActiveFilters =>
      selectedCategorySlug != null || selectedIngredientId != null;

  // Responsive grid configuration
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 2; // Mobile
    } else if (width < 900) {
      return 3; // Tablet portrait
    } else if (width < 1200) {
      return 4; // Tablet landscape / Small desktop
    } else {
      return 5; // Desktop
    }
  }

  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 0.7; // Mobile - taller cards
    } else {
      return 0.75; // Tablet/Desktop - normal ratio
    }
  }

  double _getGridSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 12.0; // Mobile
    } else {
      return 16.0; // Tablet/Desktop
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAuthenticated = authProvider.isAuthenticated;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context, user, isAuthenticated),
      body: Stack(
        children: [
          _buildBody(isLandscape),
          if (_showBackToTop)
            Positioned(bottom: 20, right: 20, child: _buildBackToTopButton()),
        ],
      ),
      floatingActionButton:
          isLandscape && (categories.isNotEmpty || ingredients.isNotEmpty)
          ? _buildFloatingFilterButton()
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Medicines',
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
        // Show/Hide Filters Button
        if (categories.isNotEmpty || ingredients.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  key: ValueKey<bool>(_showFilters),
                ),
              ),
              onPressed: _toggleFilters,
              tooltip: _showFilters ? 'Hide filters' : 'Show filters',
            ),
          ),

        // Clear Filters Button (only shows when filters are active)
        if (hasActiveFilters)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: _clearFilters,
                  tooltip: 'Clear all filters',
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBackToTopButton() {
    return FloatingActionButton.small(
      onPressed: () {
        _scrollController?.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      },
      backgroundColor: Colors.green.shade700,
      child: const Icon(Icons.arrow_upward, color: Colors.white),
    );
  }

  Widget _buildFloatingFilterButton() {
    return FloatingActionButton(
      onPressed: () => _showFilterBottomSheet(),
      backgroundColor: Colors.green.shade700,
      child: const Icon(Icons.filter_alt, color: Colors.white),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (categories.isNotEmpty)
                      _buildFilterSectionResponsive(
                        title: 'Categories',
                        items: categories.map((c) => c.name).toList(),
                        selectedItem: selectedCategorySlug != null
                            ? categories
                                  .firstWhere(
                                    (c) => c.slug == selectedCategorySlug,
                                  )
                                  .name
                            : null,
                        onSelected: (index) {
                          setState(() {
                            selectedCategorySlug = index == 0
                                ? null
                                : categories[index - 1].slug;
                          });
                          _fetchData();
                          Navigator.pop(context);
                        },
                        allLabel: 'All Categories',
                        color: Colors.green,
                      ),
                    const SizedBox(height: 16),
                    if (ingredients.isNotEmpty)
                      _buildFilterSectionResponsive(
                        title: 'Active Ingredients',
                        items: ingredients.map((i) => i.name).toList(),
                        selectedItem: selectedIngredientId != null
                            ? ingredients
                                  .firstWhere(
                                    (i) => i.id == selectedIngredientId,
                                  )
                                  .name
                            : null,
                        onSelected: (index) {
                          setState(() {
                            selectedIngredientId = index == 0
                                ? null
                                : ingredients[index - 1].id;
                          });
                          _fetchData();
                          Navigator.pop(context);
                        },
                        allLabel: 'All Ingredients',
                        color: Colors.blue,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isLandscape) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Welcome Section for Authenticated Users
            if (Provider.of<AuthProvider>(context).isAuthenticated)
              _buildWelcomeSection(),

            // Animated Filter Sections
            if (_showFilters && !isLandscape)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showFilters
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    if (categories.isNotEmpty)
                      _buildFilterSectionCompact(
                        'Categories',
                        categories,
                        selectedCategorySlug,
                        (slug) {
                          setState(() => selectedCategorySlug = slug);
                          _fetchData();
                        },
                        Colors.green,
                      ),
                    if (ingredients.isNotEmpty)
                      _buildFilterSectionCompact(
                        'Ingredients',
                        ingredients,
                        selectedIngredientId,
                        (id) {
                          setState(() => selectedIngredientId = id);
                          _fetchData();
                        },
                        Colors.blue,
                      ),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),

            // Results info
            if (hasActiveFilters) _buildResultsInfo(),

            // Medicine grid
            Expanded(
              child: allMedicines.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(_getGridSpacing(context)),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        mainAxisSpacing: _getGridSpacing(context),
                        crossAxisSpacing: _getGridSpacing(context),
                        childAspectRatio: _getChildAspectRatio(context),
                      ),
                      itemCount: allMedicines.length,
                      itemBuilder: (context, index) {
                        return MedicineCard(medicine: allMedicines[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

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
            'Loading medicines...',
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

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services,
              color: Colors.green.shade800,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  'Find the medicines you need',
                  style: TextStyle(fontSize: 14, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade800,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${allMedicines.length} items',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSectionCompact(
    String title,
    List<dynamic> items,
    String? selectedId,
    Function(String?) onSelect,
    MaterialColor color,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
                if (selectedId != null)
                  GestureDetector(
                    onTap: () => onSelect(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCompactChip(
                  'All',
                  selectedId == null,
                  () => onSelect(null),
                  color,
                ),
                ...items.map((item) {
                  final id = item is Category ? item.slug : item.id;
                  final name = item is Category ? item.name : item.name;
                  final isSelected = selectedId == id;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildCompactChip(
                      name,
                      isSelected,
                      () => onSelect(isSelected ? null : id),
                      color,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    MaterialColor color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.shade700 : color.shade200,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.shade700.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color.shade800,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSectionResponsive({
    required String title,
    required List<String> items,
    required String? selectedItem,
    required Function(int) onSelected,
    required String allLabel,
    required MaterialColor color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildResponsiveChip(
                label: allLabel,
                isSelected: selectedItem == null,
                onTap: () => onSelected(0),
                color: color,
              ),
              ...List.generate(items.length, (i) {
                return _buildResponsiveChip(
                  label: items[i],
                  isSelected: selectedItem == items[i],
                  onTap: () => onSelected(i + 1),
                  color: color,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required MaterialColor color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color.shade700 : color.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.shade700.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color.shade800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.green.shade700,
            Colors.green.shade700,
            Colors.green.shade50,
            Colors.green.shade100,
          ],
          stops: const [0.0, 0.02, 0.02, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.info_outline,
              color: Colors.green.shade700,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Showing ${allMedicines.length} medicine${allMedicines.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
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
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No medicines found',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters to see more results',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    Map<String, dynamic>? user,
    bool isAuthenticated,
  ) {
    return Drawer(
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green.shade50],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade700, Colors.teal.shade600],
                ),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        foregroundImage:
                            isAuthenticated &&
                                user?['photo'] != null &&
                                user!['photo'].toString().isNotEmpty
                            ? NetworkImage(user['photo'])
                            : null,
                        child:
                            !isAuthenticated ||
                                user?['photo'] == null ||
                                user!['photo'].toString().isEmpty
                            ? Icon(
                                Icons.person,
                                size: 28,
                                color: Colors.green.shade700,
                              )
                            : null,
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          isAuthenticated
                              ? (() {
                                  final firstName =
                                      user?['first_name']?.toString() ?? '';
                                  final lastName =
                                      user?['last_name']?.toString() ?? '';
                                  final username =
                                      user?['username']?.toString() ?? '';

                                  if (firstName.isNotEmpty &&
                                      lastName.isNotEmpty) {
                                    return '$firstName $lastName';
                                  } else if (firstName.isNotEmpty) {
                                    return firstName;
                                  } else if (lastName.isNotEmpty) {
                                    return lastName;
                                  } else if (username.isNotEmpty) {
                                    return username;
                                  } else {
                                    return 'User';
                                  }
                                })()
                              : 'Guest',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            _buildDrawerItem(
              Icons.home_rounded,
              'Home',
              () => Navigator.pop(context),
              isSelected: true,
            ),

            _buildDrawerItem(
              Icons.person_rounded,
              isAuthenticated ? 'Profile' : 'Login',
              () {
                Navigator.pop(context);
                if (isAuthenticated) {
                  Navigator.pushNamed(context, '/profile');
                } else {
                  Navigator.pushNamed(context, '/login');
                }
              },
            ),

            if (isAuthenticated)
              _buildDrawerItem(Icons.wallet, 'Wallet', () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/wallet');
              }),

            if (isAuthenticated)
              _buildDrawerItem(Icons.location_city, 'Address', () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/address');
              }),

            if (isAuthenticated)
              _buildDrawerItem(Icons.location_city, 'Chat', () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chat');
              }),

            if (isAuthenticated)
              _buildDrawerItem(Icons.logout_rounded, 'Logout', () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              }, color: Colors.red),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.black87,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.green.shade700 : color),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.green.shade700 : color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
                Provider.of<AuthProvider>(context, listen: false).logout();
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
}
