import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../core/widgets/buttons.dart';
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

/// Pop-out modal bottom sheet for adding Balance, transferring to Savings, or logging Expenses.
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

  /// Total sum for the current active input (sub-items + current text field value)
  double get _currentInputTotal {
    double inputVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    double subSum = _subAdditionItems.fold(0.0, (sum, v) => sum + v);
    return subSum + inputVal;
  }

  /// Total sum across all draft category items + current active input
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

    // If an amount is currently typed under the old category, capture it to draft list!
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
        return Icons.work;
      case 'business':
        return Icons.business_center;
      case 'freelance':
        return Icons.laptop_mac;
      case 'gift':
        return Icons.card_giftcard;
      case 'investment':
        return Icons.trending_up;
      case 'refund':
        return Icons.replay;
      case 'scholarship':
        return Icons.school;
      case 'pocket money':
        return Icons.account_balance_wallet;
      case 'food':
        return Icons.restaurant;
      case 'petrol':
        return Icons.local_gas_station;
      case 'accessories':
        return Icons.shopping_bag;
      case 'lend':
        return Icons.handshake_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'petrol':
        return Colors.redAccent;
      case 'accessories':
        return Colors.purpleAccent;
      case 'lend':
        return Colors.tealAccent;
      default:
        return Colors.lightBlueAccent;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    // Handle "Move to Savings" transfer mode & validation
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
          ),
        );
      }
      return;
    }

    // Standard Add Balance mode
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

    // Auto-capture current active input if valid
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

      // Determine category (e.g. 'Lend' for Lend entries) and title (e.g. 'Lend (Alex)')
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header with Top-Left Date/Month/Year Selector Chip & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top-Left Date Picker Chip (Plain & Subtle style matching History section)
                    InkWell(
                      onTap: isLoading ? null : _pickDate,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Text(
                      isIncomeMode
                          ? (_isTransferToSavings
                              ? 'Move to Savings'
                              : 'Add Balance')
                          : 'Add Expense',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Sub-Segmented Selector for Income Mode: Add Balance vs Move to Savings
                if (isIncomeMode) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Add Balance'),
                        icon: Icon(Icons.add_circle_outline, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Move to Savings'),
                        icon: Icon(Icons.savings_outlined, size: 18),
                      ),
                    ],
                    selected: {_isTransferToSavings},
                    onSelectionChanged: isLoading
                        ? null
                        : (Set<bool> selected) {
                            setState(() {
                              _isTransferToSavings = selected.first;
                            });
                          },
                  ),
                  const SizedBox(height: AppSizes.md),
                ],

                // Balance / Transfer Form Layout
                if (isIncomeMode) ...[
                  // Transfer Mode Info Box displaying available balance
                  if (_isTransferToSavings) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSizes.sm + 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Total Balance:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '₹ ${summary.totalBalance.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],

                  // Balance Amount Input
                  TextFormField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    decoration: InputDecoration(
                      labelText: _isTransferToSavings
                          ? 'Amount to Move to Savings'
                          : 'Enter Balance Amount',
                      prefixText: '₹ ',
                      prefixStyle:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      hintText: '0.00',
                    ),
                    enabled: !isLoading,
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Mandatory Source Category Selector (Standard Add Balance mode)
                  if (!_isTransferToSavings) ...[
                    DropdownButtonFormField<String>(
                      initialValue:
                          _incomeCategories.contains(_selectedCategory)
                              ? _selectedCategory
                              : _incomeCategories.first,
                      decoration: const InputDecoration(
                        labelText: 'Source Category (Income Source)',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: _incomeCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(_getCategoryIcon(cat), size: 18),
                              const SizedBox(width: 8),
                              Text(cat),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                    ),

                    // Custom Category Name if 'Other' is selected
                    if (_selectedCategory == 'Other') ...[
                      const SizedBox(height: AppSizes.sm),
                      TextFormField(
                        controller: _customCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Source Name',
                          hintText: 'e.g. Dividend, Property Sale',
                          prefixIcon: Icon(Icons.edit_outlined),
                        ),
                        enabled: !isLoading,
                      ),
                    ],
                  ],

                  const SizedBox(height: AppSizes.xl),
                  PrimaryButton(
                    label: _isTransferToSavings
                        ? 'Transfer to Savings'
                        : 'Save Balance',
                    isLoading: isLoading,
                    onPressed: _submitBalance,
                  ),
                ],

                // Expense Form Layout
                if (!isIncomeMode) ...[
                  // Full-width Price Input Field with inline + addition key
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          decoration: InputDecoration(
                            labelText: 'Price / Amount',
                            prefixText: '₹ ',
                            prefixStyle: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            hintText: '0.00',
                          ),
                          onChanged: (_) => setState(() {}),
                          enabled: !isLoading,
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      // Inline + Addition Function Key
                      ElevatedButton(
                        onPressed: isLoading ? null : _addSubAdditionItem,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(54, 54),
                          padding: EdgeInsets.zero,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                        child: const Icon(Icons.add,
                            size: 26, color: Colors.white),
                      ),
                    ],
                  ),

                  // Sub-addition chips list if user used + key
                  if (_subAdditionItems.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (int i = 0; i < _subAdditionItems.length; i++)
                          Chip(
                            label: Text(
                                '+₹${_subAdditionItems[i].toStringAsFixed(0)}'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSizes.md),

                  // Full-width Category Dropdown Selector
                  DropdownButtonFormField<String>(
                    initialValue: _expenseCategories.contains(_selectedCategory)
                        ? _selectedCategory
                        : _expenseCategories.first,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _expenseCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: isLoading
                        ? null
                        : (val) {
                            if (val != null) _onCategoryChanged(val);
                          },
                  ),

                  // Borrower Name field strictly for "Lend" Category Only!
                  if (_selectedCategory == 'Lend') ...[
                    const SizedBox(height: AppSizes.sm),
                    TextFormField(
                      controller: _lendPersonController,
                      decoration: const InputDecoration(
                        labelText: 'Lent To',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      enabled: !isLoading,
                    ),
                  ],

                  // Custom input if "Others" category is selected
                  if (_selectedCategory == 'Others') ...[
                    const SizedBox(height: AppSizes.sm),
                    TextFormField(
                      controller: _customCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Category Name',
                        hintText: 'e.g. Snacks, Repairs',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                      enabled: !isLoading,
                    ),
                  ],
                  const SizedBox(height: AppSizes.md),

                  // Draft Category Items List (if multiple items are added across categories)
                  if (_draftItems.isNotEmpty) ...[
                    Text(
                      'Items in this Day Entry:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _draftItems.length; i++) ...[
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      _getCategoryColor(_draftItems[i].category)
                                          .withValues(alpha: 0.15),
                                  child: Icon(
                                    _getCategoryIcon(_draftItems[i].category),
                                    size: 14,
                                    color: _getCategoryColor(
                                        _draftItems[i].category),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _draftItems[i].category,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                Text(
                                  '₹ ${_draftItems[i].amount.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 16, color: Colors.redAccent),
                                  onPressed: () => _removeDraftItem(i),
                                ),
                              ],
                            ),
                            if (i < _draftItems.length - 1)
                              const Divider(height: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                  ],

                  // Combined Total Day Expense Summary Box
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Day Expense:',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '₹ ${_combinedTotalDayExpense.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Single Primary Action Button
                  PrimaryButton(
                    label: 'Save Expense',
                    isLoading: isLoading,
                    onPressed: _submitAllExpenses,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
