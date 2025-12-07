import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/auth_model.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../viewmodels/dashboard/broadcast_viewmodel.dart';
import '../viewmodels/dashboard/management_viewmodel.dart';
import '../viewmodels/dashboard/members_viewmodel.dart';
import '../viewmodels/dashboard/messages_viewmodel.dart';
import '../viewmodels/dashboard/navigation_viewmodel.dart';
import 'dashboard/broadcast_view.dart';
import 'dashboard/management_view.dart';
import 'dashboard/members_view.dart';
import 'dashboard/messages_view.dart';
import '../../core/routes.dart';
import '../../core/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialUser});

  final User? initialUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthRepositoryImpl();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();  
    }

  Future<void> _loadUserData() async {
    // ✅ Forcer le chargement depuis le storage local
    await _auth.checkAuthStatus();  // Charge l'utilisateur dans _currentUser
    final user = _auth.currentUser;
    
    // 🔍 DEBUG
    print('========================================');
    print('🔍 DEBUG HomeScreen - _loadUserData()');
    print('========================================');
    print('  User exists: ${user != null}');
    if (user != null) {
      print('  User ID: ${user.id}');
      print('  Email: ${user.email}');
      print('  Roles: ${user.roles}');
      print('  Roles length: ${user.roles.length}');
      print('  Is Admin?: ${AppRoles.isAdministratorAuth(user)}');
    } else {
      print('  ❌ User is NULL');
    }
    print('========================================');
    
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
    
    // Connect to SignalR after user is loaded
    if (user != null && mounted) {
      _connectToSignalR();
    }
  }

  Future<void> _connectToSignalR() async {
    try {
      final messagingRepo = context.read<MessagingRepository>();
      await messagingRepo.connectSignalR();
      print('✅ SignalR connected successfully');
    } catch (e) {
      print('❌ Failed to connect to SignalR: $e');
      // Don't block the user from using the app if SignalR connection fails
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Disconnect from SignalR before logout
      try {
        final messagingRepo = context.read<MessagingRepository>();
        await messagingRepo.disconnectSignalR();
        print('✅ SignalR disconnected');
      } catch (e) {
        print('❌ Failed to disconnect SignalR: $e');
      }
      
      await _auth.logout();

      if (mounted) {
        AppRoutes.goToLogin(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      Future.microtask(() => AppRoutes.goToLogin(context));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NavigationViewModel(user: _currentUser!),
        ),
        ChangeNotifierProvider(create: (_) => MessagesViewModel()),
        ChangeNotifierProvider(create: (_) => MembersViewModel()),
        ChangeNotifierProvider(create: (_) => BroadcastViewModel()),
        ChangeNotifierProvider(create: (_) => ManagementViewModel()),
      ],
      child: _HomeContent(onLogout: _handleLogout),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          navigation.currentLabel,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,  
            tooltip: 'Déconnexion',
          ),
          IconButton(
            onPressed: () => _showProfileSheet(context),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _SectionView(
          key: ValueKey(navigation.currentSection),
          section: navigation.currentSection,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigation.selectedIndex,
        onDestinationSelected: navigation.selectIndex,
        destinations: navigation.items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  static String _getInitials(User user) {
    final first = (user.firstName ?? '').trim();
    final last = (user.lastName ?? '').trim();
    
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) {
      return first[0].toUpperCase();
    }
    if (last.isNotEmpty) {
      return last[0].toUpperCase();
    }
    return user.email.isNotEmpty ? user.email[0].toUpperCase() : '?';
  }

  static void _showProfileSheet(BuildContext context) {
    final navigation = context.read<NavigationViewModel>();
    final user = navigation.user;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.black,
                    child: Text(
                      _getInitials(user),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rôles : ${user.roles.join(", ")}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (user.roleName.isNotEmpty) 
                          Text(
                            'Nom du rôle : ${user.roleName}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section, super.key});

  final AppSection section;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case AppSection.messages:
        return const MessagesView();
      case AppSection.members:
        return const MembersView();
      case AppSection.broadcast:
        return const BroadcastView();
      case AppSection.management:
        return const ManagementView();
    }
  }
}
