import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../core/widgets/loaders.dart';

/// Budget tab stub.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navBudget),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
      ),
      body: const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No budgets set yet',
        subtitle: 'Set a spending limit per category to stay on track.',
        actionLabel: 'Create a budget',
      ),
    );
  }
}
