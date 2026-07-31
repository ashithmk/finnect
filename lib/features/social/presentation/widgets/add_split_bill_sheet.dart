import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/extensions.dart';
import '../../../auth/data/auth_providers.dart';
import '../../data/social_providers.dart';
import '../../domain/social_models.dart';

class AddSplitBillSheet extends ConsumerStatefulWidget {
  final GroupModel? group;
  final List<UserFriendInfo>? members;

  const AddSplitBillSheet({
    super.key,
    this.group,
    this.members,
  });

  @override
  ConsumerState<AddSplitBillSheet> createState() => _AddSplitBillSheetState();
}

class _AddSplitBillSheetState extends ConsumerState<AddSplitBillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late String _paidByUserId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(currentUserProvider);
    _paidByUserId = currentUser?.uid ?? 'demo_uid_1';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final total = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid bill amount greater than 0.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final memberIds = widget.group?.memberIds ??
        [_paidByUserId, ...?widget.members?.map((m) => m.uid)];
    final groupId = widget.group?.id ?? 'group_quick';

    // Calculate equal split share
    final count = memberIds.isNotEmpty ? memberIds.length : 1;
    final splitAmount = (total / count);

    final List<GroupBillShare> shares = memberIds.map((memberId) {
      final isPayer = memberId == _paidByUserId;
      return GroupBillShare(
        userId: memberId,
        amount: double.parse(splitAmount.toStringAsFixed(2)),
        isSettled: isPayer, // Payer has already settled their portion
        settledAt: isPayer ? DateTime.now() : null,
      );
    }).toList();

    final success = await ref.read(socialControllerProvider.notifier).addSplitBill(
          groupId: groupId,
          title: _titleController.text,
          totalAmount: total,
          paidByUserId: _paidByUserId,
          shares: shares,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill "${_titleController.text}" split among $count members! 💸'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final memberIds = widget.group?.memberIds ??
        [_paidByUserId, ...?widget.members?.map((m) => m.uid)];
    final count = memberIds.isNotEmpty ? memberIds.length : 1;
    final perPerson = count > 0 ? (total / count) : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.group?.name != null
                      ? 'Split Bill in ${widget.group?.name}'
                      : 'Split Bill',
                  style: context.textStyles.titleLarge?.copyWith(
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
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Bill Title',
                hintText: 'e.g. Dinner, Beach Drinks, Cab fare',
                prefixIcon: Icon(Icons.receipt_long_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a bill title';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Total Bill Amount (₹)',
                hintText: '0.00',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter total bill amount';
                }
                if (double.tryParse(val.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.md),

            // Who Paid selector
            Text(
              'Who Paid?',
              style: context.textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Wrap(
              spacing: 8,
              children: (widget.members ?? []).map((member) {
                final isSelected = _paidByUserId == member.uid;
                return ChoiceChip(
                  label: Text(member.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _paidByUserId = member.uid);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: AppSizes.lg),

            // Split calculation summary card
            if (total > 0)
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split Equally ($count members)',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${perPerson.toStringAsFixed(2)} / member',
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.pie_chart_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSizes.xl),
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Send & Split Bill'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
