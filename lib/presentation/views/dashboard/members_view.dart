import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard/members_viewmodel.dart';
import '../../widgets/dashboard/member_list_item.dart';

class MembersView extends StatefulWidget {
  const MembersView({super.key});

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  @override
  void initState() {
    super.initState();
    // Charger les membres après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MembersViewModel>().loadMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MembersViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading && viewModel.members.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: viewModel.searchController,
                    onChanged: viewModel.updateSearch,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un membre...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<MemberFilter>(
                    segments: const [
                      ButtonSegment(value: MemberFilter.all, label: Text('Tous')),
                      ButtonSegment(value: MemberFilter.users, label: Text('Utilisateurs')),
                      ButtonSegment(value: MemberFilter.admins, label: Text('Admins')),
                    ],
                    selected: {viewModel.filter},
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    onSelectionChanged: (newSelection) {
                      viewModel.updateFilter(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => viewModel.loadMembers(refresh: true),
                child: viewModel.members.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun membre trouvé',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: viewModel.members.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final member = viewModel.members[index];
                          return MemberListItem(member: member);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
