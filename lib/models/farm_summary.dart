class FarmSummary {
  final String farmerId;
  final String farmName;
  final String fullName;
  final String county;
  final double? latitude;
  final double? longitude;
  final int productCount;
  final double? distanceKm;

  FarmSummary({
    required this.farmerId,
    required this.farmName,
    required this.fullName,
    required this.county,
    this.latitude,
    this.longitude,
    required this.productCount,
    this.distanceKm,
  });
}