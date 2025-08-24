class HealthResponseModel {
  final String status;
  final DateTime timestamp;
  final String? version;
  final Map<String, dynamic>? details;

  HealthResponseModel({
    required this.status,
    required this.timestamp,
    this.version,
    this.details,
  });

  factory HealthResponseModel.fromJson(Map<String, dynamic> json) {
    return HealthResponseModel(
      status: json['status'] ?? 'unknown',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      version: json['version'],
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
      'details': details,
    };
  }

  bool get isHealthy => status.toLowerCase() == 'healthy';
  bool get isUnhealthy => status.toLowerCase() == 'unhealthy';
  
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'healthy':
        return 'Healthy';
      case 'unhealthy':
        return 'Unhealthy';
      case 'degraded':
        return 'Degraded';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'HealthResponseModel(status: $status, timestamp: $timestamp)';
  }
}
