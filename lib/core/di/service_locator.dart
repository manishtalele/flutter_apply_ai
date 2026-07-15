import 'package:dio/dio.dart';
import 'package:flutter_apply_ai/core/constants/api_constants.dart';
import 'package:flutter_apply_ai/core/network/dio_client.dart';
import 'package:flutter_apply_ai/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/data/datasources/local/app_database.dart';
import 'package:flutter_apply_ai/data/datasources/local/application_local_datasource.dart';
import 'package:flutter_apply_ai/data/datasources/local/secure_storage_datasource.dart';
import 'package:flutter_apply_ai/data/datasources/local/settings_local_datasource.dart';
import 'package:flutter_apply_ai/data/datasources/remote/openai_remote_datasource.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_auth_service.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_remote_datasource.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_token_store.dart';
import 'package:flutter_apply_ai/data/repositories/ai_repository_impl.dart';
import 'package:flutter_apply_ai/data/repositories/application_repository_impl.dart';
import 'package:flutter_apply_ai/data/repositories/gmail_repository_impl.dart';
import 'package:flutter_apply_ai/data/repositories/resume_repository_impl.dart';
import 'package:flutter_apply_ai/data/repositories/settings_repository_impl.dart';
import 'package:flutter_apply_ai/domain/repositories/ai_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/gmail_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/resume_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/settings_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/ai/analyze_job_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/check_duplicate_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/delete_application_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/export_applications_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/get_applications_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/send_application_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/dashboard/get_dashboard_stats_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/connect_gmail_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/disconnect_gmail_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/is_gmail_connected_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/sync_replies_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/add_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/delete_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/get_resumes_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/set_default_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/get_settings_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/save_gemini_api_key_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/update_settings_usecase.dart';
import 'package:flutter_apply_ai/presentation/shared/controllers/theme_controller.dart';
import 'package:flutter_apply_ai/presentation/shared/theme_mode_x.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Composition root.
///
/// Builds and registers the application's dependency graph — infrastructure,
/// datasources, and repositories — as permanent GetX singletons. Called once
/// from [main] before `runApp`. AI and Gmail repositories are registered in
/// their own modules (9/10) once implemented; per-feature controllers are
/// provided by route bindings, not here.
abstract final class ServiceLocator {
  const ServiceLocator._();

  static Future<void> init() async {
    // ── Cross-cutting ────────────────────────────────────────────────
    final AppLogger logger = ConsoleAppLogger();
    Get.put<AppLogger>(logger, permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);

    // ── Infrastructure ───────────────────────────────────────────────
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(preferences, permanent: true);

    const FlutterSecureStorage secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    Get.put<FlutterSecureStorage>(secureStorage, permanent: true);

    final AppDatabase appDatabase = AppDatabase(logger: logger);
    Get.put<AppDatabase>(appDatabase, permanent: true);

    // ── Datasources ──────────────────────────────────────────────────
    Get.put<ApplicationLocalDataSource>(
      ApplicationLocalDataSourceImpl(database: appDatabase, logger: logger),
      permanent: true,
    );
    Get.put<SettingsLocalDataSource>(
      SettingsLocalDataSourceImpl(preferences: preferences, logger: logger),
      permanent: true,
    );
    Get.put<SecureStorageDataSource>(
      SecureStorageDataSourceImpl(storage: secureStorage, logger: logger),
      permanent: true,
    );

    // ── Repositories ─────────────────────────────────────────────────
    Get.put<ApplicationRepository>(
      ApplicationRepositoryImpl(
        localDataSource: Get.find<ApplicationLocalDataSource>(),
        logger: logger,
      ),
      permanent: true,
    );
    Get.put<SettingsRepository>(
      SettingsRepositoryImpl(
        settingsDataSource: Get.find<SettingsLocalDataSource>(),
        secureDataSource: Get.find<SecureStorageDataSource>(),
        logger: logger,
      ),
      permanent: true,
    );
    Get.put<ResumeRepository>(
      ResumeRepositoryImpl(
        settingsDataSource: Get.find<SettingsLocalDataSource>(),
        logger: logger,
      ),
      permanent: true,
    );

    // ── Networking + AI ──────────────────────────────────────────────
    final DioClient dioClient = DioClient(logger: logger);
    Get.put<DioClient>(dioClient, permanent: true);

    final Dio openAiDio = dioClient.create(baseUrl: ApiConstants.openAiBaseUrl);
    Get.put<OpenAiRemoteDataSource>(
      OpenAiRemoteDataSourceImpl(dio: openAiDio, logger: logger),
      permanent: true,
    );
    Get.put<AiRepository>(
      AiRepositoryImpl(
        remoteDataSource: Get.find<OpenAiRemoteDataSource>(),
        settingsRepository: Get.find<SettingsRepository>(),
        logger: logger,
      ),
      permanent: true,
    );

    // ── Gmail (OAuth2 + REST) ────────────────────────────────────────
    final GmailTokenStore tokenStore = GmailTokenStoreImpl(
      secureStorage: Get.find<SecureStorageDataSource>(),
    );
    Get.put<GmailTokenStore>(tokenStore, permanent: true);

    final Dio authDio = dioClient.create(baseUrl: '');
    final GmailAuthService gmailAuthService = GmailOAuthService(
      authDio: authDio,
      tokenStore: tokenStore,
      logger: logger,
    );
    Get.put<GmailAuthService>(gmailAuthService, permanent: true);

    final Dio gmailDio = dioClient.create(
      baseUrl: ApiConstants.gmailBaseUrl,
      extraInterceptors: <Interceptor>[
        AuthInterceptor(
          logger: logger,
          tokenProvider: () async {
            final GmailTokens? tokens = await tokenStore.read();
            if (tokens == null) {
              return null;
            }
            if (tokens.isExpired) {
              return await gmailAuthService.refreshAccessToken() ??
                  tokens.accessToken;
            }
            return tokens.accessToken;
          },
          refresher: gmailAuthService.refreshAccessToken,
        ),
      ],
    );
    Get.put<GmailRemoteDataSource>(
      GmailRemoteDataSourceImpl(dio: gmailDio),
      permanent: true,
    );
    Get.put<GmailRepository>(
      GmailRepositoryImpl(
        authService: gmailAuthService,
        remoteDataSource: Get.find<GmailRemoteDataSource>(),
        tokenStore: tokenStore,
        settingsRepository: Get.find<SettingsRepository>(),
        logger: logger,
      ),
      permanent: true,
    );

    // ── Use cases ────────────────────────────────────────────────────
    final SettingsRepository settingsRepository =
        Get.find<SettingsRepository>();
    final ResumeRepository resumeRepository = Get.find<ResumeRepository>();
    final GmailRepository gmailRepository = Get.find<GmailRepository>();

    Get.put<AnalyzeJobUseCase>(
      AnalyzeJobUseCase(Get.find<AiRepository>()),
      permanent: true,
    );
    final ApplicationRepository applicationRepository =
        Get.find<ApplicationRepository>();
    Get.put<GetApplicationsUseCase>(
      GetApplicationsUseCase(applicationRepository),
      permanent: true,
    );
    Get.put<DeleteApplicationUseCase>(
      DeleteApplicationUseCase(applicationRepository),
      permanent: true,
    );
    Get.put<ExportApplicationsUseCase>(
      ExportApplicationsUseCase(applicationRepository),
      permanent: true,
    );
    Get.put<CheckDuplicateUseCase>(
      CheckDuplicateUseCase(applicationRepository),
      permanent: true,
    );
    Get.put<SendApplicationUseCase>(
      SendApplicationUseCase(
        gmailRepository: gmailRepository,
        applicationRepository: applicationRepository,
      ),
      permanent: true,
    );
    Get.put<GetSettingsUseCase>(
      GetSettingsUseCase(settingsRepository),
      permanent: true,
    );
    Get.put<SaveGeminiApiKeyUseCase>(
      SaveGeminiApiKeyUseCase(settingsRepository),
      permanent: true,
    );
    Get.put<UpdateSettingsUseCase>(
      UpdateSettingsUseCase(settingsRepository),
      permanent: true,
    );
    Get.put<GetResumesUseCase>(
      GetResumesUseCase(resumeRepository),
      permanent: true,
    );
    Get.put<AddResumeUseCase>(
      AddResumeUseCase(resumeRepository),
      permanent: true,
    );
    Get.put<DeleteResumeUseCase>(
      DeleteResumeUseCase(resumeRepository),
      permanent: true,
    );
    Get.put<SetDefaultResumeUseCase>(
      SetDefaultResumeUseCase(resumeRepository),
      permanent: true,
    );
    Get.put<ConnectGmailUseCase>(
      ConnectGmailUseCase(gmailRepository),
      permanent: true,
    );
    Get.put<DisconnectGmailUseCase>(
      DisconnectGmailUseCase(gmailRepository),
      permanent: true,
    );
    Get.put<IsGmailConnectedUseCase>(
      IsGmailConnectedUseCase(gmailRepository),
      permanent: true,
    );
    Get.put<SyncRepliesUseCase>(
      SyncRepliesUseCase(
        gmailRepository: gmailRepository,
        aiRepository: Get.find<AiRepository>(),
        applicationRepository: applicationRepository,
      ),
      permanent: true,
    );
    Get.put<GetDashboardStatsUseCase>(
      GetDashboardStatsUseCase(applicationRepository),
      permanent: true,
    );

    // ── Apply persisted theme ────────────────────────────────────────
    final settingsResult = await settingsRepository.getSettings();
    settingsResult.fold(
      (_) {},
      (settings) => Get.find<ThemeController>()
          .setMode(settings.themeMode.toThemeMode),
    );

    logger.i('ServiceLocator initialized: infrastructure + repositories ready.');
  }
}
