import 'dart:convert';

class CameraConfig {
  final bool lockFocus;
  final double? focusDistance;
  final bool lockExposure;
  final int? exposureCompensation;
  final int? iso;
  final int? shutterSpeed;
  final bool autoWhiteBalance;

  const CameraConfig({
    this.lockFocus = false,
    this.focusDistance,
    this.lockExposure = false,
    this.exposureCompensation,
    this.iso,
    this.shutterSpeed,
    this.autoWhiteBalance = true,
  });

  Map<String, dynamic> toJson() => {
        'lockFocus': lockFocus,
        'focusDistance': focusDistance,
        'lockExposure': lockExposure,
        'exposureCompensation': exposureCompensation,
        'iso': iso,
        'shutterSpeed': shutterSpeed,
        'autoWhiteBalance': autoWhiteBalance,
      };

  factory CameraConfig.fromJson(Map<String, dynamic> json) => CameraConfig(
        lockFocus: json['lockFocus'] ?? false,
        focusDistance: json['focusDistance'],
        lockExposure: json['lockExposure'] ?? false,
        exposureCompensation: json['exposureCompensation'],
        iso: json['iso'],
        shutterSpeed: json['shutterSpeed'],
        autoWhiteBalance: json['autoWhiteBalance'] ?? true,
      );

  String toJsonString() => jsonEncode(toJson());

  factory CameraConfig.fromJsonString(String jsonString) =>
      CameraConfig.fromJson(jsonDecode(jsonString));

  CameraConfig copyWith({
    bool? lockFocus,
    double? focusDistance,
    bool? lockExposure,
    int? exposureCompensation,
    int? iso,
    int? shutterSpeed,
    bool? autoWhiteBalance,
  }) =>
      CameraConfig(
        lockFocus: lockFocus ?? this.lockFocus,
        focusDistance: focusDistance ?? this.focusDistance,
        lockExposure: lockExposure ?? this.lockExposure,
        exposureCompensation:
            exposureCompensation ?? this.exposureCompensation,
        iso: iso ?? this.iso,
        shutterSpeed: shutterSpeed ?? this.shutterSpeed,
        autoWhiteBalance: autoWhiteBalance ?? this.autoWhiteBalance,
      );
}
