import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard/broadcast_viewmodel.dart';
import '../../widgets/dashboard/broadcast_stat_card.dart';

class BroadcastView extends StatelessWidget {
  const BroadcastView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BroadcastViewModel>();
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width >= 600 ? (width / 2) - 32 : width - 40;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Centre de diffusion',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: viewModel.stats
                .map(
                  (stat) => BroadcastStatCard(
                    stat: stat,
                    width: itemWidth,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_tethering, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Planifiez votre prochaine diffusion',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez des campagnes ciblées et suivez leurs performances en temps réel.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle diffusion'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
