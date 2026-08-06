import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../auth/data/auth_providers.dart';
import '../../data/transaction_providers.dart';
import '../../domain/transaction_model.dart';

/// Class representing a draft category expense item before saving.
class _DraftExpenseItem {
  final String category;
  final double amount;

  const _DraftExpenseItem({
    required this.category,
    required this.amount,
  });
}

/// Redesigned Liquid Minimalist Add Entry Modal Sheet strictly matching `finnect_design/add/code.html` and `DESIGN.md`.
class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionType initialType;
  final bool lockType;

  const AddTransactionSheet({
    super.key,
    this.initialType = TransactionType.expense,
    this.lockType = false,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _amountFocusNode = FocusNode();

  late TransactionType _selectedType;
  bool _isTransferToSavings = false;

  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _lendPersonController = TextEditingController();
  late String _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  // Sub-addition items for the current category (e.g. 50 + 20 = 70)
  final List<double> _subAdditionItems = [];

  // Draft list of items created across categories before final single-tap save
  final List<_DraftExpenseItem> _draftItems = [];

  static const List<String> _incomeCategories = [
    'Salary',
    'Business',
    'Freelance',
    'Gift',
    'Investment',
    'Refund',
    'Scholarship',
    'Pocket Money',
    'Other',
  ];

  static const List<String> _expenseCategories = [
    'Food',
    'Petrol',
    'Accessories',
    'Lend',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategory =
        _selectedType == TransactionType.income ? 'Salary' : 'Food';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    _lendPersonController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  double get _currentInputTotal {
    double inputVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    double subSum = _subAdditionItems.fold(0.0, (sum, v) => sum + v);
    return subSum + inputVal;
  }

  double get _combinedTotalDayExpense {
    double draftSum = _draftItems.fold(0.0, (sum, item) => sum + item.amount);
    return draftSum + _currentInputTotal;
  }

  void _addSubAdditionItem() {
    final val = double.tryParse(_amountController.text.trim());
    if (val != null && val > 0) {
      setState(() {
        _subAdditionItems.add(val);
        _amountController.clear();
      });
      _amountFocusNode.requestFocus();
    }
  }

  void _onCategoryChanged(String newCategory) {
    if (newCategory == _selectedCategory) return;

    if (_currentInputTotal > 0) {
      String catName = _selectedCategory;
      if (_selectedCategory == 'Lend' &&
          _lendPersonController.text.trim().isNotEmpty) {
        catName = 'Lend (${_lendPersonController.text.trim()})';
      } else if ((_selectedCategory == 'Others' ||
              _selectedCategory == 'Other') &&
          _customCategoryController.text.trim().isNotEmpty) {
        catName = _customCategoryController.text.trim();
      }

      _draftItems.add(
          _DraftExpenseItem(category: catName, amount: _currentInputTotal));
      _subAdditionItems.clear();
      _amountController.clear();
      _customCategoryController.clear();
      _lendPersonController.clear();
    }

    setState(() {
      _selectedCategory = newCategory;
    });
    _amountFocusNode.requestFocus();
  }

  void _removeDraftItem(int index) {
    setState(() {
      _draftItems.removeAt(index);
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.work_outline_rounded;
      case 'business':
        return Icons.business_center_outlined;
      case 'freelance':
        return Icons.laptop_mac_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'refund':
        return Icons.replay_rounded;
      case 'scholarship':
        return Icons.school_outlined;
      case 'pocket money':
        return Icons.account_balance_wallet_outlined;
      case 'food':
        return Icons.restaurant_rounded;
      case 'petrol':
        return Icons.local_gas_station_rounded;
      case 'accessories':
        return Icons.shopping_bag_outlined;
      case 'lend':
        return Icons.handshake_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getCategoryBadgeBg(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFFDAD6);
      case 'petrol':
        return const Color(0xFFFFDBCF);
      case 'accessories':
        return const Color(0xFFE1E0FF);
      case 'lend':
        return const Color(0xFF6FFBBE).withValues(alpha: 0.35);
      case 'salary':
        return const Color(0xFFE1E0FF);
      case 'business':
        return const Color(0xFFE2E2E2);
      case 'freelance':
        return const Color(0xFFC6F6D5);
      case 'gift':
        return const Color(0xFFFED7E2);
      case 'investment':
        return const Color(0xFF6FFBBE).withValues(alpha: 0.40);
      default:
        return const Color(0xFFE1E3E4);
    }
  }

  Color _getCategoryIconColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFBA1A1A);
      case 'petrol':
        return const Color(0xFFD97706);
      case 'accessories':
        return const Color(0xFF4648D4);
      case 'lend':
        return const Color(0xFF005236);
      case 'salary':
        return const Color(0xFF4648D4);
      case 'business':
        return const Color(0xFF1B1B1B);
      case 'freelance':
        return const Color(0xFF059669);
      case 'gift':
        return const Color(0xFFD53F8C);
      case 'investment':
        return const Color(0xFF005236);
      default:
        return const Color(0xFF4C4546);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4648D4),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF191C1D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitBalance() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add transactions.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount greater than 0.')),
      );
      return;
    }

    final summary = ref.read(dashboardSummaryProvider);
    final availableBalance = summary.totalBalance;

    if (_isTransferToSavings) {
      if (amount > availableBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transfer amount cannot exceed available Total Balance (₹${availableBalance.toStringAsFixed(2)}).',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final now = DateTime.now();
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      final transaction = TransactionModel(
        id: '',
        userId: user.uid,
        title: 'Transferred to Savings',
        amount: amount,
        type: TransactionType.income,
        category: 'Savings',
        date: finalDateTime,
        paymentMethod: 'cash',
      );

      final success = await ref
          .read(transactionControllerProvider.notifier)
          .addTransaction(transaction);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transferred ₹${amount.toStringAsFixed(2)} to Savings successfully!',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF009668),
          ),
        );
      }
      return;
    }

    String catName = _selectedCategory;
    if (_selectedCategory == 'Other' &&
        _customCategoryController.text.trim().isNotEmpty) {
      catName = _customCategoryController.text.trim();
    }

    final now = DateTime.now();
    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final transaction = TransactionModel(
      id: '',
      userId: user.uid,
      title: catName,
      amount: amount,
      type: TransactionType.income,
      category: catName,
      date: finalDateTime,
      paymentMethod: 'cash',
    );

    final success = await ref
        .read(transactionControllerProvider.notifier)
        .addTransaction(transaction);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '₹${amount.toStringAsFixed(2)} Balance added ($catName)!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF009668),
        ),
      );
    }
  }

  Future<void> _submitAllExpenses() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add transactions.')),
      );
      return;
    }

    if (_currentInputTotal > 0) {
      String catName = _selectedCategory;
      if (_selectedCategory == 'Lend' &&
          _lendPersonController.text.trim().isNotEmpty) {
        catName = 'Lend (${_lendPersonController.text.trim()})';
      } else if (_selectedCategory == 'Others' &&
          _customCategoryController.text.trim().isNotEmpty) {
        catName = _customCategoryController.text.trim();
      }
      _draftItems.add(
          _DraftExpenseItem(category: catName, amount: _currentInputTotal));
      _subAdditionItems.clear();
      _amountController.clear();
      _lendPersonController.clear();
    }

    if (_draftItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter an amount for at least one category.')),
      );
      return;
    }

    final now = DateTime.now();
    final controllerNotifier = ref.read(transactionControllerProvider.notifier);
    double totalDaySum = 0.0;

    for (int i = 0; i < _draftItems.length; i++) {
      final item = _draftItems[i];
      totalDaySum += item.amount;

      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
        i * 100,
      );

      String categoryStr = item.category;
      if (item.category.startsWith('Lend')) {
        categoryStr = 'Lend';
      }

      final tx = TransactionModel(
        id: '',
        userId: user.uid,
        title: item.category,
        amount: item.amount,
        type: TransactionType.expense,
        category: categoryStr,
        date: finalDateTime,
        paymentMethod: 'cash',
      );
      await controllerNotifier.addTransaction(tx);
    }

    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved ${_draftItems.length} ${_draftItems.length == 1 ? "expense" : "expenses"} (Total: ₹${totalDaySum.toStringAsFixed(2)}) for ${DateFormat.MMMd().format(_selectedDate)}!',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF009668),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(transactionControllerProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final isLoading = controllerState.isLoading;
    final isIncomeMode = _selectedType == TransactionType.income;
    final formattedDate = DateFormat.yMMMd().format(_selectedDate);
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final displayDateStr = isToday ? 'Today' : formattedDate;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;

    final categoriesList = isIncomeMode ? _incomeCategories : _expenseCategories;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFC4C5),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ),

            // Top Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top-Left Date Picker Pill Button
                  InkWell(
                    onTap: isLoading ? null : _pickDate,
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.60),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.80),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: Color(0xFF191C1D),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayDateStr,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF191C1D),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.expand_more_rounded,
                            size: 18,
                            color: Color(0xFF191C1D),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Mode Title / Segment
                  Text(
                    isIncomeMode
                        ? (_isTransferToSavings ? 'Move to Savings' : 'Add Balance')
                        : 'Add Expense',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF191C1D),
                    ),
                  ),

                  // Close Button
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.glassSubtleFill,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF191C1D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Scrollable Content Form
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 110,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sub-Segmented Selector for Income Mode (Add Balance vs Move to Savings)
                      if (isIncomeMode && !widget.lockType) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildSegmentButton(
                                label: 'Add Balance',
                                icon: Icons.add_circle_outline_rounded,
                                isSelected: !_isTransferToSavings,
                                onTap: () => setState(() => _isTransferToSavings = false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSegmentButton(
                                label: 'Move to Savings',
                                icon: Icons.savings_outlined,
                                isSelected: _isTransferToSavings,
                                onTap: () => setState(() => _isTransferToSavings = true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Transfer Available Balance Info Box
                      if (isIncomeMode && _isTransferToSavings) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1E0FF).withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFC0C1FF).withValues(alpha: 0.60),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available Total Balance:',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF191C1D),
                                ),
                              ),
                              Text(
                                '₹${summary.totalBalance.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4648D4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── AMOUNT INPUT SECTION ──
                      Text(
                        'AMOUNT',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: const Color(0xFF4C4546),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.only(bottom: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFCFC4C5),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₹',
                              style: GoogleFonts.inter(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF191C1D),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                focusNode: _amountFocusNode,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                autofocus: true,
                                enabled: !isLoading,
                                style: GoogleFonts.inter(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF191C1D),
                                ),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4C4546).withValues(alpha: 0.35),
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            if (!isIncomeMode) ...[
                              InkWell(
                                onTap: isLoading ? null : _addSubAdditionItem,
                                borderRadius: BorderRadius.circular(9999),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.60),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.80),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 24,
                                    color: Color(0xFF4648D4),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Sub-addition chips list if user tapped +
                      if (!isIncomeMode && _subAdditionItems.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (int i = 0; i < _subAdditionItems.length; i++)
                              Chip(
                                label: Text(
                                  '+₹${_subAdditionItems[i].toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4648D4),
                                  ),
                                ),
                                backgroundColor: const Color(0xFFE1E0FF).withValues(alpha: 0.50),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ── CATEGORY SECTION ──
                      if (!isIncomeMode || !_isTransferToSavings) ...[
                        Text(
                          'CATEGORY',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: const Color(0xFF4C4546),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Visual Category Grid Cards
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: categoriesList.length,
                          itemBuilder: (context, index) {
                            final cat = categoriesList[index];
                            final isSelected = _selectedCategory == cat;

                            return InkWell(
                              onTap: isLoading ? null : () => _onCategoryChanged(cat),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF4648D4).withValues(alpha: 0.12)
                                      : Colors.white.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF4648D4)
                                        : Colors.white.withValues(alpha: 0.70),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getCategoryBadgeBg(cat),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(cat),
                                        size: 20,
                                        color: _getCategoryIconColor(cat),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF4648D4)
                                            : const Color(0xFF191C1D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Dynamic Custom Inputs (Lend Person or Custom Category Name)
                        if (_selectedCategory == 'Lend') ...[
                          _buildGlassInputField(
                            controller: _lendPersonController,
                            labelText: 'Lent To (Person Name)',
                            hintText: 'e.g. Alex, Sam',
                            icon: Icons.person_outline_rounded,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),
                        ] else if (_selectedCategory == 'Others' || _selectedCategory == 'Other') ...[
                          _buildGlassInputField(
                            controller: _customCategoryController,
                            labelText: 'Custom Category Name',
                            hintText: 'e.g. Repairs, Subscriptions',
                            icon: Icons.edit_outlined,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // ── DRAFT ITEMS LIST ──
                      if (_draftItems.isNotEmpty) ...[
                        Text(
                          'ITEMS IN THIS ENTRY',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: const Color(0xFF4C4546),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            for (int i = 0; i < _draftItems.length; i++)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.70),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(_draftItems[i].category),
                                          size: 18,
                                          color: const Color(0xFF4C4546),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _draftItems[i].category,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF191C1D),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${_draftItems[i].amount.toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF191C1D),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _removeDraftItem(i),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: Color(0xFFBA1A1A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── STICKY TOTAL & SAVE ENTRY BAR ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isIncomeMode && _combinedTotalDayExpense > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Entry',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4C4546),
                          ),
                        ),
                        Text(
                          '₹${_combinedTotalDayExpense.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF191C1D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000000),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : (isIncomeMode ? _submitBalance : _submitAllExpenses),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        isIncomeMode
                            ? (_isTransferToSavings ? 'Transfer to Savings' : 'Save Balance')
                            : 'Save Entry',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4648D4).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4648D4)
                : Colors.white.withValues(alpha: 0.70),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF4648D4) : const Color(0xFF4C4546),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFF4648D4) : const Color(0xFF191C1D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    bool enabled = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF191C1D),
          ),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF4C4546),
            ),
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4C4546).withValues(alpha: 0.50),
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: const Color(0xFF4C4546),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.50),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.60),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.60),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF4648D4),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
