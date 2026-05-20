import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../repositories/user_repository.dart';
import '../../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository;
  final GoogleSignIn _googleSignIn;

  AuthBloc(this._userRepository, {GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthAnonymousSignInRequested>(_onAuthAnonymousSignInRequested);
    on<AuthPhoneVerificationRequested>(_onAuthPhoneVerificationRequested);
    on<AuthPhoneCodeSubmitted>(_onAuthPhoneCodeSubmitted);

    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      if (user != null && state is! AuthPhoneCodeSent) {
        add(const AuthCheckRequested());
      } else if (user == null && state is! AuthPhoneCodeSent) {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> _onSignInWithGoogleRequested(
      SignInWithGoogleRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(AuthUnauthenticated());
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        final userModel = await _userRepository.getUserById(result.user!.uid);
        if (userModel == null) {
          await _userRepository.createOrUpdateUser(
            UserModel(
              uid: result.user!.uid,
              email: result.user!.email ?? '',
            ),
          );
        }
        emit(AuthAuthenticated(result.user!));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Google sign in failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthAnonymousSignInRequested(
      AuthAnonymousSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _auth.signInAnonymously();
      if (result.user != null) {
        final userModel = await _userRepository.getUserById(result.user!.uid);
        if (userModel == null) {
          await _userRepository.createOrUpdateUser(
            UserModel(
              uid: result.user!.uid,
              email: '',
            ),
          );
        }
        emit(AuthAuthenticated(result.user!));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Anonymous sign in failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthPhoneVerificationRequested(
      AuthPhoneVerificationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final result = await _auth.signInWithCredential(credential);
          if (result.user != null) {
            final userModel =
                await _userRepository.getUserById(result.user!.uid);
            if (userModel == null) {
              await _userRepository.createOrUpdateUser(
                UserModel(
                  uid: result.user!.uid,
                  email: result.user!.phoneNumber ?? '',
                ),
              );
            }
            emit(AuthAuthenticated(result.user!));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          emit(AuthError(e.message ?? 'Phone verification failed'));
        },
        codeSent: (String verificationId, int? resendToken) {
          emit(AuthPhoneCodeSent(
            verificationId: verificationId,
            phoneNumber: event.phoneNumber,
          ));
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthPhoneCodeSubmitted(
      AuthPhoneCodeSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        final userModel = await _userRepository.getUserById(result.user!.uid);
        if (userModel == null) {
          await _userRepository.createOrUpdateUser(
            UserModel(
              uid: result.user!.uid,
              email: result.user!.phoneNumber ?? '',
            ),
          );
        }
        emit(AuthAuthenticated(result.user!));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Invalid code'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  void _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Ensure user document exists
      final userModel = await _userRepository.getUserById(user.uid);
      if (userModel == null) {
        await _userRepository.createOrUpdateUser(
          UserModel(
            uid: user.uid,
            email: user.email ?? '',
          ),
        );
      }
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  void _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      if (credential.user != null) {
        final userModel = await _userRepository.getUserById(credential.user!.uid);
        if (userModel == null) {
          await _userRepository.createOrUpdateUser(
            UserModel(
              uid: credential.user!.uid,
              email: credential.user!.email ?? '',
            ),
          );
        }
        emit(AuthAuthenticated(credential.user!));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Login failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      if (credential.user != null) {
        await _userRepository.createOrUpdateUser(
          UserModel(
            uid: credential.user!.uid,
            email: credential.user!.email ?? '',
          ),
        );
        emit(AuthAuthenticated(credential.user!));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Sign up failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _auth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
