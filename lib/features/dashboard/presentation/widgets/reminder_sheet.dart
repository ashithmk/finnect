import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/utils/extensions.dart';
import '../../../../core/services/notification_service.dart';

/// Modal sheet allowing users to set custom daily reminder time and preferences.
/// Preserves user settings across app sessions without auto-resetting.
class SetReminderSheet extends StatefulWidget {
  final TimeOfDay? initialTime;
  const SetReminderSheet({super.key, this.initialTime});

  @override
  State<SetReminderSheet> createState() => _SetReminderSheetState();
}

class _SetReminderSheetState extends State<SetReminderSheet> {
  bool _enabled = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0); // Default 8:00 PM
  final TextEditingController _noteController =
      TextEditingController(text: "Don't forget to track your daily expenses!");
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Load saved settings so time is NEVER reset automatically
    final savedEnabled = prefs.getBool('reminder_enabled') ?? true;
    final savedHour = prefs.getInt('reminder_hour') ?? 20;
    final savedMinute = prefs.getInt('reminder_minute') ?? 0;
    final savedMessage = prefs.getString('reminder_message');

    setState(() {
      _enabled = savedEnabled;
      _selectedTime = widget.initialTime ?? TimeOfDay(hour: savedHour, minute: savedMinute);
      if (savedMessage != null && savedMessage.isNotEmpty) {
        _noteController.text = savedMessage;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'SELECT DAILY REMINDER TIME',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _selectPresetTime(int hour, int minute) {
    setState(() {
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _sendTestNotification() async {
    final formattedTime = _selectedTime.format(context);
    final message = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : "Don't forget to track your daily expenses!";

    try {
      await NotificationService.instance.showImmediateNotification(
        title: 'Finnect Test Reminder 🔔',
        body: 'Phone notifications active! Scheduled for $formattedTime: "$message"',
      );
    } catch (e) {
      debugPrint('Test notification error: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.notifications_active, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('⚡ Test notification sent! Check your phone notification shade.'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _saveReminderSettings() async {
    final formattedTime = _selectedTime.format(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', _enabled);
    await prefs.setInt('reminder_hour', _selectedTime.hour);
    await prefs.setInt('reminder_minute', _selectedTime.minute);
    await prefs.setString('reminder_message', _noteController.text.trim());

    try {
      if (_enabled) {
        final message = _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : "Don't forget to track your daily expenses!";

        await NotificationService.instance.scheduleDailyReminder(
          time: _selectedTime,
          title: 'Finnect  Reminder',
          body: message,
        );
      } else {
        await NotificationService.instance.cancelDailyReminder();
      }
    } catch (e) {
      debugPrint('Notification scheduling notice: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _enabled
                ? '⏰ Daily reminder saved for $formattedTime every day!'
                : 'Reminder notifications disabled.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _enabled ? Colors.teal : Colors.grey[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedTime = _selectedTime.format(context);
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        padding: EdgeInsets.only(
          left: AppSizes.lg,
          right: AppSizes.lg,
          top: AppSizes.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
        ),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.alarm_on_rounded, color: theme.colorScheme.primary, size: 26),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              'Daily Reminder',
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
                    

                    // Enable Toggle Card
                    Card(
                      child: SwitchListTile(
                        title: const Text('Daily Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                        value: _enabled,
                        onChanged: (val) {
                          setState(() {
                            _enabled = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Giant Interactive Time Display Card
                    Card(
                      elevation: 3,
                      color: _enabled
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        side: BorderSide(
                          color: _enabled ? theme.colorScheme.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: _enabled ? _pickTime : null,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          child: Center(
                            child: Text(
                              formattedTime,
                              style: context.textStyles.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _enabled
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Quick Preset Time Options
                    if (_enabled) ...[
                      Text(
                        'Quick Presets:',
                        style: context.textStyles.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('8:00 AM (Morning)'),
                            selected: _selectedTime.hour == 8 && _selectedTime.minute == 0,
                            onSelected: (_) => _selectPresetTime(8, 0),
                          ),
                          ChoiceChip(
                            label: const Text('1:00 PM (Lunch)'),
                            selected: _selectedTime.hour == 13 && _selectedTime.minute == 0,
                            onSelected: (_) => _selectPresetTime(13, 0),
                          ),
                          ChoiceChip(
                            label: const Text('8:00 PM (Dinner)'),
                            selected: _selectedTime.hour == 20 && _selectedTime.minute == 0,
                            onSelected: (_) => _selectPresetTime(20, 0),
                          ),
                          ChoiceChip(
                            label: const Text('10:00 PM (Night)'),
                            selected: _selectedTime.hour == 22 && _selectedTime.minute == 0,
                            onSelected: (_) => _selectPresetTime(22, 0),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                    ],

                    // Reminder Note
                    TextField(
                      controller: _noteController,
                      enabled: _enabled,
                      decoration: InputDecoration(
                        labelText: 'Reminder Message',
                        hintText: 'e.g. Log your daily expenses',
                        prefixIcon: const Icon(Icons.edit_note),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Test Notification Flash Button
                    OutlinedButton.icon(
                      onPressed: _enabled ? _sendTestNotification : null,
                      icon: const Icon(Icons.flash_on, color: Colors.amber),
                      label: const Text('⚡ Send Test Notification Now'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Save Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _saveReminderSettings,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        _enabled ? 'Save $formattedTime Reminder' : 'Turn Off Reminders',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
