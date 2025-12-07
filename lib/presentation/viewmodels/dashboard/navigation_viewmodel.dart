import 'package:flutter/material.dart';
import '../../../domain/models/auth_model.dart';

enum AppSection { messages, members, broadcast, management }

class NavigationItem {
  const NavigationItem({
    required this.section,
    required this.label,
    required this.icon,
  });

  final AppSection section;
  final String label;
  final IconData icon;
}

class NavigationViewModel extends ChangeNotifier {
  NavigationViewModel({required User user}) : _user = user {
    _items = _buildItemsForRole(user);
    _selectedIndex = 0;
  }

  final User _user;
  late final List<NavigationItem> _items;
  late int _selectedIndex;

  User get user => _user;

  List<NavigationItem> get items => List.unmodifiable(_items);

  int get selectedIndex => _selectedIndex;

  AppSection get currentSection => _items[_selectedIndex].section;

  String get currentLabel => _items[_selectedIndex].label;

  void selectIndex(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  List<NavigationItem> _buildItemsForRole(User user) {
    const List<NavigationItem> allItems = [
      NavigationItem(
        section: AppSection.messages,
        label: 'Messages',
        icon: Icons.message_outlined,
      ),
      NavigationItem(
        section: AppSection.members,
        label: 'Membres',
        icon: Icons.people_alt_outlined,
      ),
      NavigationItem(
        section: AppSection.broadcast,
        label: 'Diffusion',
        icon: Icons.wifi_tethering,
      ),
      NavigationItem(
        section: AppSection.management,
        label: 'Gestion',
        icon: Icons.settings_outlined,
      ),
    ];

    List<NavigationItem> itemsForRoleName(String? roleName) {
      switch ((roleName ?? '').toLowerCase()) {
        case 'superadmin':
          return List<NavigationItem>.from(allItems);
        case 'admin':
          return allItems
              .where(
                (item) =>
                    item.section == AppSection.messages ||
                    item.section == AppSection.members ||
                    item.section == AppSection.broadcast,
              )
              .toList(growable: false);
        case 'utilisateur':
          return allItems
              .where(
                (item) =>
                    item.section == AppSection.messages ||
                    item.section == AppSection.members,
              )
              .toList(growable: false);
        default:
          return [];
      }
    }

    List<NavigationItem> items = itemsForRoleName(user.roleName);

    if (items.isEmpty) {
      // Fallback : au moins deux onglets pour respecter NavigationBar
      return allItems
          .where(
            (item) =>
                item.section == AppSection.messages ||
                item.section == AppSection.members,
          )
          .toList(growable: false);
    }

    if (items.length >= 2) {
      return items;
    }

    // Fallback : au moins deux onglets pour respecter NavigationBar
    return allItems
        .where(
          (item) =>
              item.section == AppSection.messages ||
              item.section == AppSection.members,
        )
        .toList(growable: false);
  }
}
