import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/error_handler.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<SetPinRequested>(_onSetPinRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<UploadAvatarRequested>(_onUploadAvatarRequested);
    on<DeleteAvatarRequested>(_onDeleteAvatarRequested);
    on<UpdateUserLocally>(_onUpdateUserLocally);
    on<ForgotPinRequested>(_onForgotPinRequested);
    on<VerifyPinResetCodeRequested>(_onVerifyPinResetCodeRequested);
    on<ResetPinRequested>(_onResetPinRequested);
  }

  /// Sanitizes exceptions into friendly messages (detecting network issues, 401s, etc.)
  String _cleanError(Object e) {
    return ErrorHandler.getFriendlyMessage(e);
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    final cached = await authRepository.getCachedUser();
    if (cached != null) {
      emit(AuthSuccess(cached));
    }
    try {
      final fresh = await authRepository.getCurrentUser();
      emit(AuthSuccess(fresh));
    } catch (_) {
      // If offline, continue using cached user if available
      if (cached == null && state is! AuthSuccess) {
        emit(AuthInitial());
      }
    }
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
    } catch (_) {
      // Local tokens and cache are cleared even if remote call fails
    }
    emit(AuthInitial());
  }

  Future<void> _onSetPinRequested(SetPinRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.setLoginPin(event.pin);
      User? user;
      try {
        user = await authRepository.getCurrentUser();
      } catch (_) {
        user = await authRepository.getCachedUser();
      }
      emit(PinSetSuccess(user));
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }

  Future<void> _onUpdateProfileRequested(UpdateProfileRequested event, Emitter<AuthState> emit) async {
    if (state is AuthSuccess) {
      final current = state as AuthSuccess;
      emit(current.copyWith(isUpdatingProfile: true, clearMessages: true));
      try {
        final updatedUser = await authRepository.updateProfile(
          name: event.name,
          email: event.email,
          defaultCurrency: event.defaultCurrency,
        );
        emit(current.copyWith(
          user: updatedUser,
          isUpdatingProfile: false,
          successMessage: 'Profile updated successfully.',
        ));
      } catch (e) {
        emit(current.copyWith(
          isUpdatingProfile: false,
          errorMessage: _cleanError(e),
        ));
      }
    }
  }

  Future<void> _onUploadAvatarRequested(UploadAvatarRequested event, Emitter<AuthState> emit) async {
    User? currentUser;
    if (state is AuthSuccess) {
      currentUser = (state as AuthSuccess).user;
      emit((state as AuthSuccess).copyWith(isUpdatingAvatar: true, clearMessages: true));
    } else if (state is PinSetSuccess) {
      currentUser = (state as PinSetSuccess).user;
      emit(AuthLoading());
    } else {
      emit(AuthLoading());
    }

    try {
      final updatedUser = await authRepository.uploadAvatar(event.imageFile);
      emit(AuthSuccess(
        updatedUser,
        isUpdatingAvatar: false,
        successMessage: 'Profile photo updated successfully.',
      ));
    } catch (e) {
      if (currentUser != null) {
        emit(AuthSuccess(
          currentUser,
          isUpdatingAvatar: false,
          errorMessage: _cleanError(e),
        ));
      } else {
        emit(AuthError(_cleanError(e)));
      }
    }
  }

  Future<void> _onDeleteAvatarRequested(DeleteAvatarRequested event, Emitter<AuthState> emit) async {
    User? currentUser;
    if (state is AuthSuccess) {
      currentUser = (state as AuthSuccess).user;
      emit((state as AuthSuccess).copyWith(isUpdatingAvatar: true, clearMessages: true));
    } else if (state is PinSetSuccess) {
      currentUser = (state as PinSetSuccess).user;
      emit(AuthLoading());
    } else {
      emit(AuthLoading());
    }

    try {
      final updatedUser = await authRepository.deleteAvatar();
      emit(AuthSuccess(
        updatedUser,
        isUpdatingAvatar: false,
        successMessage: 'Profile photo removed.',
      ));
    } catch (e) {
      if (currentUser != null) {
        emit(AuthSuccess(
          currentUser,
          isUpdatingAvatar: false,
          errorMessage: _cleanError(e),
        ));
      } else {
        emit(AuthError(_cleanError(e)));
      }
    }
  }

  void _onUpdateUserLocally(UpdateUserLocally event, Emitter<AuthState> emit) {
    if (state is AuthSuccess) {
      emit((state as AuthSuccess).copyWith(user: event.user));
    } else {
      emit(AuthSuccess(event.user));
    }
  }

  Future<void> _onForgotPinRequested(ForgotPinRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await authRepository.forgotPin(event.phoneNumber);
      emit(ForgotPinCodeSent(
        phoneNumber: event.phoneNumber,
        message: result['message'] as String? ?? 'Verification code sent.',
        hasEmail: result['has_email'] as bool? ?? false,
        debugCode: result['debug_code'] as String?,
      ));
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }

  Future<void> _onVerifyPinResetCodeRequested(
    VerifyPinResetCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final resetToken = await authRepository.verifyPinResetCode(event.phoneNumber, event.code);
      emit(PinResetCodeVerified(
        phoneNumber: event.phoneNumber,
        resetToken: resetToken,
      ));
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }

  Future<void> _onResetPinRequested(
    ResetPinRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.resetPin(
        event.phoneNumber,
        event.resetToken,
        event.newPin,
      );
      emit(PinResetSuccess(
        user: user,
        message: 'Your PIN has been reset successfully.',
      ));
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }
}
