import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String phoneNumber;
  final String pin;

  const LoginRequested({required this.phoneNumber, required this.pin});

  @override
  List<Object?> get props => [phoneNumber, pin];
}

class SignupRequested extends AuthEvent {
  final String name;
  final String phoneNumber;

  const SignupRequested({required this.name, required this.phoneNumber});

  @override
  List<Object?> get props => [name, phoneNumber];
}

class LogoutRequested extends AuthEvent {}

class SetPinRequested extends AuthEvent {
  final String pin;

  const SetPinRequested({required this.pin});

  @override
  List<Object?> get props => [pin];
}

class UpdateProfileRequested extends AuthEvent {
  final String? name;
  final String? email;
  final String? defaultCurrency;

  const UpdateProfileRequested({
    this.name,
    this.email,
    this.defaultCurrency,
  });

  @override
  List<Object?> get props => [name, email, defaultCurrency];
}

class UploadAvatarRequested extends AuthEvent {
  final File imageFile;

  const UploadAvatarRequested(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class DeleteAvatarRequested extends AuthEvent {}

class UpdateUserLocally extends AuthEvent {
  final User user;

  const UpdateUserLocally(this.user);

  @override
  List<Object?> get props => [user];
}

class ForgotPinRequested extends AuthEvent {
  final String phoneNumber;

  const ForgotPinRequested({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyPinResetCodeRequested extends AuthEvent {
  final String phoneNumber;
  final String code;

  const VerifyPinResetCodeRequested({
    required this.phoneNumber,
    required this.code,
  });

  @override
  List<Object?> get props => [phoneNumber, code];
}

class ResetPinRequested extends AuthEvent {
  final String phoneNumber;
  final String resetToken;
  final String newPin;

  const ResetPinRequested({
    required this.phoneNumber,
    required this.resetToken,
    required this.newPin,
  });

  @override
  List<Object?> get props => [phoneNumber, resetToken, newPin];
}
