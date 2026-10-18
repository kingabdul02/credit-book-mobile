import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  final bool isUpdatingAvatar;
  final bool isUpdatingProfile;
  final String? successMessage;
  final String? errorMessage;

  const AuthSuccess(
    this.user, {
    this.isUpdatingAvatar = false,
    this.isUpdatingProfile = false,
    this.successMessage,
    this.errorMessage,
  });

  AuthSuccess copyWith({
    User? user,
    bool? isUpdatingAvatar,
    bool? isUpdatingProfile,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return AuthSuccess(
      user ?? this.user,
      isUpdatingAvatar: isUpdatingAvatar ?? this.isUpdatingAvatar,
      isUpdatingProfile: isUpdatingProfile ?? this.isUpdatingProfile,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [user, isUpdatingAvatar, isUpdatingProfile, successMessage, errorMessage];
}

class AuthNeedsPinSet extends AuthState {
  final User user;

  const AuthNeedsPinSet(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class PinSetSuccess extends AuthState {
  final User? user;
  const PinSetSuccess([this.user]);

  @override
  List<Object?> get props => [user];
}

class ForgotPinCodeSent extends AuthState {
  final String phoneNumber;
  final String message;
  final bool hasEmail;
  final String? debugCode;

  const ForgotPinCodeSent({
    required this.phoneNumber,
    required this.message,
    this.hasEmail = false,
    this.debugCode,
  });

  @override
  List<Object?> get props => [phoneNumber, message, hasEmail, debugCode];
}

class PinResetCodeVerified extends AuthState {
  final String phoneNumber;
  final String resetToken;

  const PinResetCodeVerified({
    required this.phoneNumber,
    required this.resetToken,
  });

  @override
  List<Object?> get props => [phoneNumber, resetToken];
}

class PinResetSuccess extends AuthState {
  final User user;
  final String message;

  const PinResetSuccess({
    required this.user,
    required this.message,
  });

  @override
  List<Object?> get props => [user, message];
}

class AuthRequires2FA extends AuthState {
  final String twoFactorToken;
  final String phoneNumber;
  final String? email;
  final String? debugCode;
  final String method;
  final String defaultMethod;
  final List<String> availableMethods;
  final String? maskedPhone;
  final String? message;

  const AuthRequires2FA({
    required this.twoFactorToken,
    required this.phoneNumber,
    this.email,
    this.debugCode,
    this.method = 'authenticator',
    this.defaultMethod = 'authenticator',
    this.availableMethods = const ['authenticator', 'email', 'phone'],
    this.maskedPhone,
    this.message,
  });

  AuthRequires2FA copyWith({
    String? twoFactorToken,
    String? phoneNumber,
    String? email,
    String? debugCode,
    String? method,
    String? defaultMethod,
    List<String>? availableMethods,
    String? maskedPhone,
    String? message,
  }) {
    return AuthRequires2FA(
      twoFactorToken: twoFactorToken ?? this.twoFactorToken,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      debugCode: debugCode ?? this.debugCode,
      method: method ?? this.method,
      defaultMethod: defaultMethod ?? this.defaultMethod,
      availableMethods: availableMethods ?? this.availableMethods,
      maskedPhone: maskedPhone ?? this.maskedPhone,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        twoFactorToken,
        phoneNumber,
        email,
        debugCode,
        method,
        defaultMethod,
        availableMethods,
        maskedPhone,
        message,
      ];
}

class TwoFactorSetupDataLoaded extends AuthState {
  final String method;
  final String? secret;
  final String? otpauthUrl;
  final String? qrCodeUrl;
  final String? email;
  final String? phoneNumber;
  final String? message;
  final String? debugCode;

  const TwoFactorSetupDataLoaded({
    required this.method,
    this.secret,
    this.otpauthUrl,
    this.qrCodeUrl,
    this.email,
    this.phoneNumber,
    this.message,
    this.debugCode,
  });

  @override
  List<Object?> get props => [
        method,
        secret,
        otpauthUrl,
        qrCodeUrl,
        email,
        phoneNumber,
        message,
        debugCode,
      ];
}

class TwoFactorSetupCodeSent extends AuthState {
  final String email;
  final String message;
  final String? debugCode;

  const TwoFactorSetupCodeSent({
    required this.email,
    required this.message,
    this.debugCode,
  });

  @override
  List<Object?> get props => [email, message, debugCode];
}

class TwoFactorCodeResent extends AuthState {
  final String message;
  final String? debugCode;
  final String? method;

  const TwoFactorCodeResent({
    required this.message,
    this.debugCode,
    this.method,
  });

  @override
  List<Object?> get props => [message, debugCode, method];
}

class AuthSessionExpired extends AuthState {
  final String message;

  const AuthSessionExpired({
    this.message = 'Your session has expired. Please sign in again.',
  });

  @override
  List<Object?> get props => [message];
}

