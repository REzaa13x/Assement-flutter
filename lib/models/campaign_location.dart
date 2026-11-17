class CampaignLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String district;
  final String city;
  final String province;
  final String postalCode;

  const CampaignLocation(
      {required this.latitude,
      required this.longitude,
      required this.address,
      this.district = '',
      this.city = '',
      this.province = '',
      this.postalCode = ''});

  factory CampaignLocation.fromJson(Map<String, dynamic> json) =>
      CampaignLocation(
        latitude: double.parse('${json['latitude']}'),
        longitude: double.parse('${json['longitude']}'),
        address: json['address']?.toString() ?? '',
        district: json['district']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        province: json['province']?.toString() ?? '',
        postalCode: json['postal_code']?.toString() ?? '',
      );

  Map<String, String> toFields() => {
        'latitude': latitude.toStringAsFixed(7),
        'longitude': longitude.toStringAsFixed(7),
        'lokasi': address.length > 255 ? address.substring(0, 255) : address,
        'alamat_lengkap': address,
        'kecamatan': district,
        'kabupaten': city,
        'provinsi': province,
        'kode_pos': postalCode,
      };
}
