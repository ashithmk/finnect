import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../core/widgets/buttons.dart';
import '../../data/goal_providers.dart';
import '../../domain/goal_model.dart';

class AddGoalSheet extends ConsumerStatefulWidget {
  final GoalModel? existingGoal;

  const AddGoalSheet({super.key, this.existingGoal});

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      final g = widget.existingGoal!;
      _titleController.text = g.title;
      _targetPriceController.text = g.targetPrice.toStringAsFixed(0);
      _imageUrlController.text = g.imageUrl ?? '';
      _descriptionController.text = g.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetPriceController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final targetPrice = double.tryParse(_targetPriceController.text.trim()) ?? 0.0;
    final imageUrl = _imageUrlController.text.trim();
    final description = _descriptionController.text.trim();

    if (targetPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target price greater than 0.')),
      );
      return;
    }

    final isEdit = widget.existingGoal != null;
    final goal = GoalModel(
      id: isEdit ? widget.existingGoal!.id : '',
      title: title,
      targetPrice: targetPrice,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      description: description.isNotEmpty ? description : null,
      createdAt: isEdit ? widget.existingGoal!.createdAt : DateTime.now(),
      isPurchased: isEdit ? widget.existingGoal!.isPurchased : false,
      isArchived: isEdit ? widget.existingGoal!.isArchived : false,
      notified: isEdit ? widget.existingGoal!.notified : false,
    );

    final notifier = ref.read(goalControllerProvider.notifier);
    final success = isEdit ? await notifier.updateGoal(goal) : await notifier.addGoal(goal);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Goal "${goal.title}" updated!' : 'Goal "${goal.title}" created!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(goalControllerProvider);
    final isLoading = controllerState.isLoading;
    final isEdit = widget.existingGoal != null;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Goal' : 'Add New Wishlist Goal',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

                // Item Name
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name / Goal Title',
                    hintText: 'e.g. New Smartphone, Vacation',
                    prefixIcon: Icon(Icons.stars_outlined),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter an item name' : null,
                  enabled: !isLoading,
                  autofocus: true,
                ),
                const SizedBox(height: AppSizes.md),

                // Target Price
                TextFormField(
                  controller: _targetPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Target Price',
                    prefixText: '₹ ',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter target price';
                    final v = double.tryParse(val.trim());
                    if (v == null || v <= 0) return 'Enter valid target price';
                    return null;
                  },
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSizes.md),

                // Image URL / Path (Optional)
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL or Path (Optional)',
                    hintText: 'https://example.com/image.png',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSizes.md),

                // Note / Description (Optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Note / Description (Optional)',
                    hintText: 'e.g. Target buy date, specs',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSizes.xl),

                PrimaryButton(
                  label: isEdit ? 'Update Goal' : 'Create Goal',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
