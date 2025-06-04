// lib/presentation/pages/auth/register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/register/register_bloc.dart';
import 'package:hivmeet/presentation/blocs/register/register_event.dart';
import 'package:hivmeet/presentation/blocs/register/register_state.dart';
import 'package:hivmeet/presentation/widgets/common/app_button.dart';
import 'package:hivmeet/presentation/widgets/common/app_text_field.dart';
import 'package:hivmeet/presentation/widgets/dialogs/hiv_dialogs.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedBirthDate;
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RegisterBloc>(),
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<RegisterBloc, RegisterState>(
            listener: (context, state) {
              if (state.isSuccess) {
                HIVDialog.show(
                  context: context,
                  title: 'Inscription réussie',
                  content: 'Un email de vérification a été envoyé à ${state.email}. Veuillez vérifier votre boîte de réception.',
                  actions: [
                    DialogAction(
                      label: 'OK',
                      onPressed: (context) {
                        Navigator.of(context).pop();
                        context.go('/login');
                      },
                    ),
                  ],
                );
              }
              
              if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                HIVToast.showError(
                  context: context,
                  message: state.errorMessage!,
                );
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bouton retour
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/login'),
                      ),
                    ),
                    
                    // Titre
                    Text(
                      'Créer un compte',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    Text(
                      'Rejoignez notre communauté bienveillante',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Formulaire
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'votre@email.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            onChanged: (value) {
                              context.read<RegisterBloc>().add(
                                EmailChanged(email: value),
                              );
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'L\'email est requis';
                              }
                              if (!state.emailValid && value.isNotEmpty) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Mot de passe
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                controller: _passwordController,
                                label: 'Mot de passe',
                                hintText: '••••••••',
                                obscureText: true,
                                prefixIcon: Icons.lock_outline,
                                onChanged: (value) {
                                  context.read<RegisterBloc>().add(
                                    PasswordChanged(password: value),
                                  );
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Le mot de passe est requis';
                                  }
                                  if (!state.passwordValid && value.isNotEmpty) {
                                    return 'Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule, un chiffre et un caractère spécial';
                                  }
                                  return null;
                                },
                              ),
                              if (_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                _PasswordStrengthIndicator(
                                  strength: state.passwordStrength,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Confirmation mot de passe
                          AppTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirmer le mot de passe',
                            hintText: '••••••••',
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            onChanged: (value) {
                              context.read<RegisterBloc>().add(
                                ConfirmPasswordChanged(
                                  confirmPassword: value,
                                  password: _passwordController.text,
                                ),
                              );
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez confirmer votre mot de passe';
                              }
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Nom d'affichage
                          AppTextField(
                            controller: _displayNameController,
                            label: 'Nom d\'affichage',
                            hintText: 'Comment souhaitez-vous être appelé(e) ?',
                            prefixIcon: Icons.person_outline,
                            maxLength: 30,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Le nom est requis';
                              }
                              if (value.length < 3) {
                                return 'Le nom doit contenir au moins 3 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Date de naissance
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(
                                  const Duration(days: 365 * 18),
                                ),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now().subtract(
                                  const Duration(days: 365 * 18),
                                ),
                                locale: const Locale('fr', 'FR'),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedBirthDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date de naissance',
                                prefixIcon: const Icon(Icons.cake_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _selectedBirthDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                                    : 'Sélectionner votre date de naissance',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: _selectedBirthDate != null
                                      ? null
                                      : AppColors.slate,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Téléphone (optionnel)
                          AppTextField(
                            controller: _phoneController,
                            label: 'Téléphone (optionnel)',
                            hintText: '+33 6 12 34 56 78',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Conditions d'utilisation
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                },
                                activeColor: AppColors.primaryPurple,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _acceptTerms = !_acceptTerms;
                                    });
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      children: [
                                        const TextSpan(text: 'J\'accepte les '),
                                        TextSpan(
                                          text: 'conditions d\'utilisation',
                                          style: TextStyle(
                                            color: AppColors.primaryPurple,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        const TextSpan(text: ' et la '),
                                        TextSpan(
                                          text: 'politique de confidentialité',
                                          style: TextStyle(
                                            color: AppColors.primaryPurple,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          
                          // Bouton d'inscription
                          AppButton(
                            onPressed: state.isSubmitting ? null : () {
                              if (_formKey.currentState!.validate() &&
                                  _selectedBirthDate != null &&
                                  _acceptTerms) {
                                context.read<RegisterBloc>().add(
                                  RegisterSubmitted(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                    confirmPassword: _confirmPasswordController.text,
                                    displayName: _displayNameController.text.trim(),
                                    birthDate: _selectedBirthDate!,
                                    phoneNumber: _phoneController.text.isEmpty
                                        ? null
                                        : _phoneController.text.trim(),
                                    acceptTerms: _acceptTerms,
                                  ),
                                );
                              } else {
                                if (_selectedBirthDate == null) {
                                  HIVToast.showError(
                                    context: context,
                                    message: 'Veuillez sélectionner votre date de naissance',
                                  );
                                }
                                if (!_acceptTerms) {
                                  HIVToast.showError(
                                    context: context,
                                    message: 'Veuillez accepter les conditions d\'utilisation',
                                  );
                                }
                              }
                            },
                            text: 'Créer mon compte',
                            isLoading: state.isSubmitting,
                            type: ButtonType.primary,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Lien vers connexion
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Déjà un compte ? ',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () {
                                  context.go('/login');
                                },
                                child: Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    color: AppColors.primaryPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const _PasswordStrengthIndicator({
    Key? key,
    required this.strength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    double progress;

    switch (strength) {
      case PasswordStrength.weak:
        color = AppColors.error;
        label = 'Faible';
        progress = 0.33;
        break;
      case PasswordStrength.medium:
        color = AppColors.warning;
        label = 'Moyen';
        progress = 0.66;
        break;
      case PasswordStrength.strong:
        color = AppColors.success;
        label = 'Fort';
        progress = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.platinum,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
