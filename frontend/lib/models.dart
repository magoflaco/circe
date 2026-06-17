class Measurement {
  final int id;
  final int heartRate;
  final int spo2;
  final double temperature;
  final String status;
  final DateTime recordedAt;
  Measurement({
    required this.id,
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.status,
    required this.recordedAt,
  });
  bool get isAlert => status == 'Alerta';
  factory Measurement.fromJson(Map<String, dynamic> j) => Measurement(
        id: j['id'] ?? 0,
        heartRate: j['heart_rate'],
        spo2: j['spo2'],
        temperature: (j['temperature'] as num).toDouble(),
        status: j['status'] ?? 'Normal',
        recordedAt: DateTime.parse(j['recorded_at']).toLocal(),
      );
}
class Alert {
  final int id;
  final String alertType;
  final String description;
  final String severity;
  final DateTime createdAt;
  Alert({
    required this.id,
    required this.alertType,
    required this.description,
    required this.severity,
    required this.createdAt,
  });
  factory Alert.fromJson(Map<String, dynamic> j) => Alert(
        id: j['id'],
        alertType: j['alert_type'],
        description: j['description'],
        severity: j['severity'] ?? 'warning',
        createdAt: DateTime.parse(j['created_at']).toLocal(),
      );
}
class HealthProfile {
  int? age;
  String? gender;
  double? weightKg;
  double? heightCm;
  String? bloodType;
  String? conditions;
  String? medications;
  String? emergencyContact;
  double? bmi;
  HealthProfile({
    this.age,
    this.gender,
    this.weightKg,
    this.heightCm,
    this.bloodType,
    this.conditions,
    this.medications,
    this.emergencyContact,
    this.bmi,
  });
  factory HealthProfile.fromJson(Map<String, dynamic> j) => HealthProfile(
        age: j['age'],
        gender: j['gender'],
        weightKg: (j['weight_kg'] as num?)?.toDouble(),
        heightCm: (j['height_cm'] as num?)?.toDouble(),
        bloodType: j['blood_type'],
        conditions: j['conditions'],
        medications: j['medications'],
        emergencyContact: j['emergency_contact'],
        bmi: (j['bmi'] as num?)?.toDouble(),
      );
  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'blood_type': bloodType,
        'conditions': conditions,
        'medications': medications,
        'emergency_contact': emergencyContact,
      };
}
class Device {
  final int id;
  final String deviceUid;
  final String name;
  final bool isPaired;
  final String mode;
  final String? smsNumbers;
  final DateTime? lastSeen;
  Device({
    required this.id,
    required this.deviceUid,
    required this.name,
    required this.isPaired,
    required this.mode,
    this.smsNumbers,
    this.lastSeen,
  });
  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'],
        deviceUid: j['device_uid'],
        name: j['name'],
        isPaired: j['is_paired'],
        mode: j['mode'],
        smsNumbers: j['sms_numbers'],
        lastSeen: j['last_seen'] != null
            ? DateTime.parse(j['last_seen']).toLocal()
            : null,
      );
}
class ChatMessage {
  final String role; 
  final String content;
  ChatMessage(this.role, this.content);
  bool get isUser => role == 'user';
}