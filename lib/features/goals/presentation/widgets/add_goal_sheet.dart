import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants/app_colors.dart';
import '../../data/goal_providers.dart';
import '../../domain/goal_model.dart';

/// Redesigned Liquid Minimalist Goal Creation Sheet.
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
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      final g = widget.existingGoal!;
      _titleController.text = g.title;
      _targetPriceController.text = g.targetPrice.toStringAsFixed(0);
      _descriptionController.text = g.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final targetPrice = double.tryParse(_targetPriceController.text.trim()) ?? 0.0;
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
      imageUrl: isEdit ? widget.existingGoal!.imageUrl : null,
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
          backgroundColor: const Color(0xFF009668),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(goalControllerProvider);
    final isLoading = controllerState.isLoading;
    final isEdit = widget.existingGoal != null;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;

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

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.track_changes_rounded,
                        size: 22,
                        color: Color(0xFF4648D4),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'Edit Goal' : 'Add Goal',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF191C1D),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 34,
                      height: 34,
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

            // Sheet Body Form
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 96,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Liquid Glass Form Container ──
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.65),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Item Name / Goal Title Field
                                Text(
                                  'ITEM NAME',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    color: const Color(0xFF4C4546),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildGlassTextField(
                                  controller: _titleController,
                                  hintText: '',
                                  icon: Icons.stars_outlined,
                                  enabled: !isLoading,
                                  autofocus: true,
                                  validator: (val) => val == null || val.trim().isEmpty
                                      ? 'Please enter an item name'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Target Price Field
                                Text(
                                  'TARGET PRICE',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    color: const Color(0xFF4C4546),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildGlassTextField(
                                  controller: _targetPriceController,
                                  hintText: '0.00',
                                  prefixText: '₹ ',
                                  icon: Icons.sell_outlined,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  enabled: !isLoading,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Enter target price';
                                    final v = double.tryParse(val.trim());
                                    if (v == null || v <= 0) return 'Enter valid target price';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),



                                // Note / Description Field (Optional)
                                Text(
                                  'NOTE ',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                    color: const Color(0xFF4C4546),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildGlassTextField(
                                  controller: _descriptionController,
                                  hintText: '',
                                  icon: Icons.note_alt_outlined,
                                  enabled: !isLoading,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Sticky Save Button ──
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
              child: SizedBox(
                height: 54,
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
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    isEdit ? 'Update ' : 'Create ',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    bool enabled = true,
    bool autofocus = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF191C1D),
          ),
          decoration: InputDecoration(
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
            prefixText: prefixText,
            prefixStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF191C1D),
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
          validator: validator,
        ),
      ),
    );
  }
}
