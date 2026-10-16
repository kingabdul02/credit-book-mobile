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
