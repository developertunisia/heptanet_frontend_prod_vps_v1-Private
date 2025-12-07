import 'package:flutter/material.dart';
import '../../../domain/models/user_response_dto.dart';

class MemberListItem extends StatelessWidget {
  const MemberListItem({super.key, required this.member});

  final UserResponseDto member;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.black,
          radius: 24,
          child: Text(
            member.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member.fullName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _getRoleDisplayName(member.roleName),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String roleName) {
    final role = roleName.toLowerCase();
    if (role.contains('superadmin')) {
      return 'SuperAdmin';
    } else if (role.contains('admin')) {
      return 'Admin';
    } else {
      return 'User';
    }
  }
}
