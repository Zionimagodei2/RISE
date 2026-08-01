import '../constants/app_constants.dart';
import '../models/buddy_contact.dart';

class BuddyEscalation {
  const BuddyEscalation({required this.minute, required this.contact});
  final int minute;
  final BuddyContact contact;
}

class BuddyNotificationService {
  bool initialized = false;
  BuddyNotificationService();
  Future<void> initialize() async { initialized = true; }

  List<BuddyEscalation> buildEscalationChain(List<BuddyContact> contacts) {
    return contacts.take(AppConstants.buddyEscalationMinutes.length).toList().asMap().entries.map((entry) {
      return BuddyEscalation(minute: AppConstants.buddyEscalationMinutes[entry.key], contact: entry.value);
    }).toList();
  }
}
