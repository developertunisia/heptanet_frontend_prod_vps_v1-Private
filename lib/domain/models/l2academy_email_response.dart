class L2AcademyEmailResponse {
  final bool exists;
  final String? email;

  L2AcademyEmailResponse({
    required this.exists,
    this.email,
  });

  factory L2AcademyEmailResponse.fromJson(Map<String, dynamic> json) {
    return L2AcademyEmailResponse(
      exists: json['exists'] as bool? ?? false,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exists': exists,
      'email': email,
    };
  }
}

