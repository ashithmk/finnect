import 'package:flutter/material.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/extensions.dart';

/// Modal sheet for configuring daily expense reminders.
class SetReminderSheet extends StatefulWidget {
  const SetReminderSheet({super.key});

  @override
  State<SetReminderSheet> createState() => _SetReminderSheetState();
}

class _SetReminderSheetState extends State<SetReminderSheet> {
  bool _enabled = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0); // 8:00 PM default
  final TextEditingController _noteController =
      TextEditingController(text: "Don't forget to track your daily expenses!");

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedTime = _selectedTime.format(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Daily Expense Reminder',
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Get notified daily so you never miss logging your spent amount or split bills.',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Enable Toggle Card
          Card(
            child: SwitchListTile(
              title: const Text('Daily Notification', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_enabled ? 'Active daily reminder' : 'Notifications disabled'),
              value: _enabled,
              onChanged: (val) {
                setState(() {
                  _enabled = val;
                });
              },
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Select Time Tile
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time_filled_outlined),
              title: const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(formattedTime),
              trailing: ElevatedButton(
                onPressed: _enabled ? _pickTime : null,
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Change Time'),
              ),
              onTap: _enabled ? _pickTime : null,
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Reminder Note
          TextField(
            controller: _noteController,
            enabled: _enabled,
            decoration: InputDecoration(
              labelText: 'Reminder Message',
              hintText: 'e.g. Log your dinner expense',
              prefixIcon: const Icon(Icons.edit_note),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // Save Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _enabled
                        ? '⏰ Daily reminder set for $formattedTime!'
                        : 'Reminder notifications disabled.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: _enabled ? Colors.teal : Colors.grey[700],
                ),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Reminder Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
