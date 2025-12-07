class RegisterUserDto {
  final String firstName;
  final String lastName;
  final String email;
  final String whatsAppNumber;
  final String? roleName; // Optionnel, par défaut "Utilisateur" si omis
  final String password;
  final String confirmPassword; 

  RegisterUserDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.whatsAppNumber,
    this.roleName, // Optionnel - backend assignera "Utilisateur" par défaut
    required this.password,
    required this.confirmPassword, 
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'whatsAppNumber': whatsAppNumber,
      'password': password,
      'confirmPassword': confirmPassword,
    };
    
    // N'ajouter roleName que s'il est spécifié
    if (roleName != null) {
      json['roleName'] = roleName;
    }
    
    return json;
  }
}