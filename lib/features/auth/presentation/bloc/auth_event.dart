import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

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
