import 'package:flutter_contacts/flutter_contacts.dart';
bool get contactsSupported => true;
Future<List<String>> pickContactNumbers() async {
  if (!await FlutterContacts.requestPermission(readonly: true)) return [];
  final picked = await FlutterContacts.openExternalPick();
  if (picked == null) return [];
  final full = await FlutterContacts.getContact(picked.id, withProperties: true);
  final phones = (full ?? picked)
      .phones
      .map((p) => p.number.replaceAll(' ', ''))
      .where((n) => n.isNotEmpty)
      .toList();
  return phones;
}