import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/email_icon_widget.dart';
import '../widgets/email_input_field.dart';
import '../widgets/submit_button.dart';
import '../widgets/email_check_result_section.dart';
import '../../core/routes.dart';
import '../viewmodels/email_check_viewmodel.dart';

class EmailCheckScreen extends StatefulWidget {
  const EmailCheckScreen({super.key});

  @override
  State<EmailCheckScreen> createState() => _EmailCheckScreenState();
}

class _EmailCheckScreenState extends State<EmailCheckScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmailCheckViewModel>(
      builder: (context, vm, _) {
        if (vm.status == EmailCheckStatus.success && vm.isEmailValid) {
          final email = _emailController.text.trim().toLowerCase();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            AppRoutes.goToOtpValidation(context, email);
            vm.reset();
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black87,
              ),
              onPressed: () => AppRoutes.goToLogin(context),
            ),
            title: const Text(
              'Vérification Email',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const EmailIconWidget(),
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EmailInputField(controller: _emailController),
                            const SizedBox(height: 24),
                            SubmitButton(emailController: _emailController),
                            const SizedBox(height: 20),
                            const EmailCheckResultSection(),
                          ],
                        ),
                      ),
                    ),
                    if (vm.status == EmailCheckStatus.error && vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  vm.errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}