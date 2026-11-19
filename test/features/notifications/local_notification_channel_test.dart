import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/notifications/data/datasources/local_notification_data_source.dart';
import 'package:next_on/features/notifications/data/datasources/push_constants.dart';

/// The Android channel every push lands on (the manifest names it as
/// Firebase's default channel too).
void main() {
  test('the channel puts no dot or number on the App icon: the bell inside '
      'the App is the only count', () {
    const channel = LocalNotificationDataSourceImpl.channel;

    expect(channel.id, PushConstants.androidChannelId);
    expect(channel.showBadge, isFalse);
  });

  test('a foreground pop-up asks for the same channel, also without a badge',
      () {
    const details = LocalNotificationDataSourceImpl.androidDetails;

    expect(details.channelId, PushConstants.androidChannelId);
    expect(details.channelShowBadge, isFalse);
  });
}
