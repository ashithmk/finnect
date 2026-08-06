import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';

/// Redesigned Daily Reminder Sheet strictly matching `finnect_design/reminder/code.html` and `DESIGN.md`.
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
      TextEditingController(text: "Don't forget to track your daily expenses");
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

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
            : "Don't forget to track your daily expenses";

        await NotificationService.instance.scheduleDailyReminder(
          time: _selectedTime,
          title: 'Finnect Reminder',
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
          backgroundColor: _enabled ? const Color(0xFF009668) : Colors.grey[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _selectedTime.format(context);
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
                        Icons.alarm_on_rounded,
                        size: 22,
                        color: Color(0xFF4C4546),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Daily Reminder',
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

            // Sheet Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 8,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 96,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Daily Notification Toggle ──
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.70),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Daily Notification',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF191C1D),
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _enabled,
                                      activeTrackColor: Colors.black,
                                      activeThumbColor: Colors.white,
                                      onChanged: (val) {
                                        setState(() => _enabled = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Hero Time Display Card ──
                          Opacity(
                            opacity: _enabled ? 1.0 : 0.45,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _enabled ? _pickTime : null,
                                borderRadius: BorderRadius.circular(24),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE1E0FF).withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: const Color(0xFFC0C1FF).withValues(alpha: 0.60),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 25,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          formattedTime,
                                          style: GoogleFonts.inter(
                                            fontSize: 38,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                            color: const Color(0xFF07006C),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Quick Presets ──
                          if (_enabled) ...[
                            Text(
                              'QUICK PRESETS:',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                                color: const Color(0xFF4C4546),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildPresetChip('8:00 AM', 8, 0),
                                const SizedBox(width: 10),
                                _buildPresetChip('8:00 PM', 20, 0),
                                const SizedBox(width: 10),
                                _buildPresetChip('10:00 PM', 22, 0),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── Reminder Message Input ──
                          Text(
                            'REMINDER MESSAGE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              color: const Color(0xFF4C4546),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.50),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.70),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: Color(0xFF4C4546),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _noteController,
                                        enabled: _enabled,
                                        maxLines: 2,
                                        minLines: 1,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFF191C1D),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Don't forget to track your daily expenses",
                                          hintStyle: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: const Color(0xFF4C4546).withValues(alpha: 0.50),
                                          ),
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                      ),
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
                  onPressed: _saveReminderSettings,
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _enabled ? 'Save Reminder' : 'Turn Off Reminders',
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

  Widget _buildPresetChip(String label, int hour, int minute) {
    final bool selected = _selectedTime.hour == hour && _selectedTime.minute == minute;

    return Expanded(
      child: InkWell(
        onTap: () => _selectPresetTime(hour, minute),
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF4648D4).withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4648D4)
                  : Colors.white.withValues(alpha: 0.80),
              width: selected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              color: selected ? const Color(0xFF4648D4) : const Color(0xFF191C1D),
            ),
          ),
        ),
      ),
    );
  }
}
