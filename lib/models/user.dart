class UserProfile {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? phone;
  final Set<String> favoriteProducts;

  UserProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.phone,
    Set<String>? favoriteProducts,
  }) : favoriteProducts = favoriteProducts ?? {};

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return 'Користувач';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      favoriteProducts: (json['favorite_products'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ?? {},
    );
  }
} 