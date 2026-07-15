import 'package:dartz/dartz.dart' show Right;
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/input_validators.dart';
import 'package:flutter_apply_ai/domain/entities/app_settings.dart';
import 'package:flutter_apply_ai/domain/entities/enums/app_theme_mode.dart';
import 'package:flutter_apply_ai/domain/entities/resume_profile.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/connect_gmail_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/disconnect_gmail_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/is_gmail_connected_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/add_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/delete_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/get_resumes_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/set_default_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/get_settings_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/save_gemini_api_key_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/update_settings_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';
import 'package:flutter_apply_ai/presentation/settings/controllers/settings_controller.dart';
import 'package:flutter_apply_ai/presentation/shared/controllers/theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetSettings extends Mock implements GetSettingsUseCase {}

class _MockGetResumes extends Mock implements GetResumesUseCase {}

class _MockSaveKey extends Mock implements SaveGeminiApiKeyUseCase {}

class _MockUpdateSettings extends Mock implements UpdateSettingsUseCase {}

class _MockAddResume extends Mock implements AddResumeUseCase {}

class _MockDeleteResume extends Mock implements DeleteResumeUseCase {}

class _MockSetDefault extends Mock implements SetDefaultResumeUseCase {}

class _MockConnect extends Mock implements ConnectGmailUseCase {}

class _MockDisconnect extends Mock implements DisconnectGmailUseCase {}

class _MockIsConnected extends Mock implements IsGmailConnectedUseCase {}

class _SilentLogger implements AppLogger {
  const _SilentLogger();

  @override
  void d(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void i(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void w(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void e(String message, [Object? error, StackTrace? stackTrace]) {}
}

void main() {
  group('InputValidators.geminiApiKey', () {
    test('rejects empty and short keys, accepts long keys', () {
      expect(InputValidators.geminiApiKey(''), isNotNull);
      expect(InputValidators.geminiApiKey('short'), isNotNull);
      expect(
        InputValidators.geminiApiKey('a-sufficiently-long-api-key-1234'),
        isNull,
      );
    });
  });

  group('InputValidators.isValidEmail', () {
    test('validates basic structure', () {
      expect(InputValidators.isValidEmail('jobs@acme.com'), isTrue);
      expect(InputValidators.isValidEmail('bad'), isFalse);
      expect(InputValidators.isValidEmail('a@b'), isFalse);
      expect(InputValidators.isValidEmail('a@@b.com'), isFalse);
    });
  });

  group('SettingsController.loadAll', () {
    setUpAll(() => registerFallbackValue(const NoParams()));

    test('populates settings and resumes on success', () async {
      final _MockGetSettings getSettings = _MockGetSettings();
      final _MockGetResumes getResumes = _MockGetResumes();

      const AppSettings settings = AppSettings(
        geminiApiKey: 'a-sufficiently-long-api-key-1234',
        senderName: 'Jane Doe',
        themeMode: AppThemeMode.dark,
      );
      final ResumeProfile resume = ResumeProfile(
        id: '1',
        label: 'Flutter Resume',
        filePath: '/tmp/resume.pdf',
        isDefault: true,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      when(() => getSettings(any()))
          .thenAnswer((_) async => const Right<Failure, AppSettings>(settings));
      when(() => getResumes(any())).thenAnswer(
        (_) async => Right<Failure, List<ResumeProfile>>(<ResumeProfile>[resume]),
      );

      final SettingsController controller = SettingsController(
        getSettings: getSettings,
        saveGeminiApiKey: _MockSaveKey(),
        updateSettings: _MockUpdateSettings(),
        getResumes: getResumes,
        addResume: _MockAddResume(),
        deleteResume: _MockDeleteResume(),
        setDefaultResume: _MockSetDefault(),
        connectGmail: _MockConnect(),
        disconnectGmail: _MockDisconnect(),
        isGmailConnected: _MockIsConnected(),
        themeController: ThemeController(),
        logger: const _SilentLogger(),
      );

      await controller.loadAll();

      expect(controller.loadState.value, ViewState.success);
      expect(controller.settings.value.senderName, 'Jane Doe');
      expect(controller.apiKeyController.text, settings.geminiApiKey);
      expect(controller.resumes, hasLength(1));
      expect(controller.isGmailConnected, isFalse);
    });
  });
}
