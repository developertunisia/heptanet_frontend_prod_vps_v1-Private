class EmailCheckResponse {
  final bool exists;
  final String email;

  EmailCheckResponse({
    required this.exists,
    required this.email,
  });

  factory EmailCheckResponse.fromJson(Map<String, dynamic> json) {
    return EmailCheckResponse(
      exists: json['exists'] as bool,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exists': exists,
      'email': email,
    };
  }
}