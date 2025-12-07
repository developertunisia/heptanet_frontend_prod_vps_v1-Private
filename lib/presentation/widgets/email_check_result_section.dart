import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/email_check_viewmodel.dart';
import 'result_card.dart';
import 'error_card.dart';

class EmailCheckResultSection extends StatelessWidget {
  const EmailCheckResultSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EmailCheckViewModel>(
      builder: (context, viewModel, child) {
        switch (viewModel.status) {
          case EmailCheckStatus.success:
            return ResultCard(
              isSuccess: viewModel.isEmailValid,
              message: viewModel.isEmailValid
                  ? '✅ Cet email est autorisé'
                  : '❌ Cet email n\'est pas autorisé',
            );

          case EmailCheckStatus.error:
            return ErrorCard(
              errorMessage: viewModel.errorMessage ?? 'Erreur inconnue',
            );

          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}