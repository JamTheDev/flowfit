/// Data model representing heart rate measurement with inter-beat intervals
/// 
/// This model is used for watch-to-phone data synchronization and matches
/// the Kotlin TrackedData model structure.
class TrackedData {
  /// Heart rate in beats per minute
  final int hr;
  
  /// List of inter-beat intervals in milliseconds
  final List<int> ibi;
  
  TrackedData({
    required this.hr,
    required this.ibi,
  });
  
  /// Create TrackedData from JSON map
  factory TrackedData.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('hr')) {
      throw ArgumentError('TrackedData JSON must contain "hr" field');
    }
    if (!json.containsKey('ibi')) {
      throw ArgumentError('TrackedData JSON must contain "ibi" field');
    }
    
    return TrackedData(
      hr: json['hr'] as int? ?? 0,
      ibi: (json['ibi'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }
  
  /// Convert TrackedData to JSON map
  Map<String, dynamic> toJson() {
    return {
      'hr': hr,
      'ibi': ibi,
    };
  }
  
  @override
  String toString() {
    return 'TrackedData(hr: $hr, ibi: ${ibi.length} values)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TrackedData) return false;
    
    return hr == other.hr && 
           ibi.length == other.ibi.length &&
           ibi.asMap().entries.every((entry) => entry.value == other.ibi[entry.key]);
  }
  
  @override
  int get hashCode => Object.hash(hr, Object.hashAll(ibi));
}
