import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/frequency_selector_widget.dart';
import './widgets/notification_section_widget.dart';
import './widgets/notification_toggle_widget.dart';
import './widgets/permission_status_widget.dart';

class PushNotificationSettings extends StatefulWidget {
  const PushNotificationSettings({super.key});

  @override
  State<PushNotificationSettings> createState() =>
      _PushNotificationSettingsState();
}

class _PushNotificationSettingsState extends State<PushNotificationSettings> {
  // Notification preferences state
  bool tripUpdatesEnabled = true;
  bool destinationAlertsEnabled = true;
  bool priceDropsEnabled = false;
  bool travelTipsEnabled = true;
  bool marketingEnabled = false;
  bool locationBasedEnabled = true;
  bool proximityAlertsEnabled = true;
  bool travelRemindersEnabled = true;

  // Advanced settings
  String selectedFrequency = 'Real-time';
  String quietHoursStart = '22:00';
  String quietHoursEnd = '08:00';
  String notificationSound = 'Default';
  bool vibrationEnabled = true;
  bool permissionGranted = true;

  final List<String> frequencyOptions = [
    'Real-time',
    'Daily Digest',
    'Weekly Summary'
  ];
  final List<String> soundOptions = [
    'Default',
    'Chime',
    'Bell',
    'Ping',
    'None'
  ];

  @override
  void initState() {
    super.initState();
    _checkNotificationPermissions();
  }

  void _checkNotificationPermissions() {
    // Simulate permission check
    setState(() {
      permissionGranted = true; // Mock permission status
    });
  }

  void _saveSettings() {
    // Simulate saving settings to Firebase/backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification settings saved successfully'),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
      ),
    );
  }

  void _sendTestNotification(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test notification sent: \$type'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openSystemSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening system notification settings...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        title: Text(
          'Push Notifications',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission Status
            if (!permissionGranted) ...[
              PermissionStatusWidget(
                onEnablePressed: _openSystemSettings,
              ),
              SizedBox(height: 3.h),
            ],

            // Trip Updates Section
            NotificationSectionWidget(
              title: 'Trip Updates',
              subtitle:
                  'Flight delays, gate changes, and booking confirmations',
              children: [
                NotificationToggleWidget(
                  title: 'Trip Updates',
                  subtitle: 'Real-time updates about your bookings',
                  value: tripUpdatesEnabled,
                  onChanged: (value) =>
                      setState(() => tripUpdatesEnabled = value),
                  onTestPressed: () => _sendTestNotification('Trip Update'),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Destination Alerts Section
            NotificationSectionWidget(
              title: 'Destination Alerts',
              subtitle: 'Weather updates, local events, and travel advisories',
              children: [
                NotificationToggleWidget(
                  title: 'Destination Alerts',
                  subtitle:
                      'Weather and local information for your destinations',
                  value: destinationAlertsEnabled,
                  onChanged: (value) =>
                      setState(() => destinationAlertsEnabled = value),
                  onTestPressed: () =>
                      _sendTestNotification('Destination Alert'),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Price Drops Section
            NotificationSectionWidget(
              title: 'Price Drops',
              subtitle: 'Alerts when prices drop for your saved trips',
              children: [
                NotificationToggleWidget(
                  title: 'Price Drop Alerts',
                  subtitle: 'Get notified when flight or hotel prices decrease',
                  value: priceDropsEnabled,
                  onChanged: (value) =>
                      setState(() => priceDropsEnabled = value),
                  onTestPressed: () => _sendTestNotification('Price Drop'),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Travel Tips Section
            NotificationSectionWidget(
              title: 'Travel Tips',
              subtitle: 'Helpful travel advice and destination guides',
              children: [
                NotificationToggleWidget(
                  title: 'Travel Tips',
                  subtitle: 'Weekly tips and destination recommendations',
                  value: travelTipsEnabled,
                  onChanged: (value) =>
                      setState(() => travelTipsEnabled = value),
                  onTestPressed: () => _sendTestNotification('Travel Tip'),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Marketing Section
            NotificationSectionWidget(
              title: 'Marketing',
              subtitle: 'Promotional offers and travel deals',
              children: [
                NotificationToggleWidget(
                  title: 'Promotional Offers',
                  subtitle: 'Special deals and exclusive travel offers',
                  value: marketingEnabled,
                  onChanged: (value) =>
                      setState(() => marketingEnabled = value),
                  onTestPressed: () =>
                      _sendTestNotification('Promotional Offer'),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Frequency Settings
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Frequency',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Choose how often you receive notifications',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                  SizedBox(height: 2.h),
                  FrequencySelectorWidget(
                    selectedFrequency: selectedFrequency,
                    options: frequencyOptions,
                    onChanged: (value) =>
                        setState(() => selectedFrequency = value),
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // Location-based Notifications
            NotificationSectionWidget(
              title: 'Location-based Notifications',
              subtitle: 'Alerts based on your current location',
              children: [
                NotificationToggleWidget(
                  title: 'Location Alerts',
                  subtitle: 'Notifications when you arrive at destinations',
                  value: locationBasedEnabled,
                  onChanged: (value) =>
                      setState(() => locationBasedEnabled = value),
                ),
                if (locationBasedEnabled) ...[
                  SizedBox(height: 1.h),
                  Padding(
                    padding: EdgeInsets.only(left: 4.w),
                    child: Column(
                      children: [
                        NotificationToggleWidget(
                          title: 'Proximity Alerts',
                          subtitle: 'Alerts when near saved destinations',
                          value: proximityAlertsEnabled,
                          onChanged: (value) =>
                              setState(() => proximityAlertsEnabled = value),
                          isSubOption: true,
                        ),
                        NotificationToggleWidget(
                          title: 'Travel Reminders',
                          subtitle: 'Reminders for upcoming trips',
                          value: travelRemindersEnabled,
                          onChanged: (value) =>
                              setState(() => travelRemindersEnabled = value),
                          isSubOption: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: 2.h),

            // Advanced Settings
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced Settings',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Quiet Hours
                  _buildAdvancedOption(
                    'Quiet Hours',
                    '\$quietHoursStart - \$quietHoursEnd',
                    () => _showQuietHoursDialog(),
                  ),

                  SizedBox(height: 1.5.h),

                  // Notification Sound
                  _buildAdvancedOption(
                    'Notification Sound',
                    notificationSound,
                    () => _showSoundDialog(),
                  ),

                  SizedBox(height: 1.5.h),

                  // Vibration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vibration',
                              style: AppTheme.lightTheme.textTheme.bodyLarge,
                            ),
                            Text(
                              'Vibrate when notifications arrive',
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: vibrationEnabled,
                        onChanged: (value) =>
                            setState(() => vibrationEnabled = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOption(String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 2.w),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quiet Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set the hours when you don\'t want to receive notifications'),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // Show time picker for start time
                    },
                    child: Text('Start: \$quietHoursStart'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // Show time picker for end time
                    },
                    child: Text('End: \$quietHoursEnd'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notification Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: soundOptions
              .map((sound) => RadioListTile<String>(
                    title: Text(sound),
                    value: sound,
                    groupValue: notificationSound,
                    onChanged: (value) {
                      setState(() => notificationSound = value ?? 'Default');
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
