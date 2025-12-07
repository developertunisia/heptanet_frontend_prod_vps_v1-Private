import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/email_check_viewmodel.dart';

class SubmitButton extends StatelessWidget {
  final TextEditingController emailController;

  const SubmitButton({
    super.key,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EmailCheckViewModel>(
      builder: (context, viewModel, child) {
        final isLoading = viewModel.status == EmailCheckStatus.loading;

        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: emailController,
          builder: (context, value, child) {
            final email = value.text;
            final isEnabled = !isLoading && email.isNotEmpty;

            return Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isEnabled ? Colors.black87 : Colors.grey[300],
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: isEnabled
                    ? () {
                        if (email.isNotEmpty) {
                          viewModel.checkEmail(email);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Vérifier',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}