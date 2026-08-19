import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<SetPinRequested>(_onSetPinRequested);
  }

  /// Strips the "Exception: " prefix Dart adds to Exception.toString().
  String _cleanError(Object e) {
    final msg = e.toString();
    return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.phoneNumber, event.pin);
      if (!user.hasPin) {
        emit(AuthNeedsPinSet(user));
      } else {
        emit(AuthSuccess(user));
      }
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }

  Future<void> _onSignupRequested(SignupRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(event.name, event.phoneNumber);
      // After signup, we need to set PIN
      emit(AuthNeedsPinSet(user));
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }

  Future<void> _onSetPinRequested(SetPinRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.setLoginPin(event.pin);
      emit(PinSetSuccess());
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }
}
