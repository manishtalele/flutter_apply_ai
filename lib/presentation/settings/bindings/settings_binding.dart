import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/connect_gmail_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/disconnect_gmail_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/gmail/is_gmail_connected_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/add_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/delete_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/get_resumes_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/set_default_resume_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/get_settings_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/save_openai_api_key_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/update_settings_usecase.dart';
import 'package:flutter_apply_ai/presentation/settings/controllers/settings_controller.dart';
import 'package:flutter_apply_ai/presentation/shared/controllers/theme_controller.dart';
import 'package:get/get.dart';

/// Provides [SettingsController] and its use cases.
class SettingsBinding extends Bindings {
  SettingsBinding();

  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        getSettings: Get.find<GetSettingsUseCase>(),
        saveOpenAiApiKey: Get.find<SaveOpenAiApiKeyUseCase>(),
        updateSettings: Get.find<UpdateSettingsUseCase>(),
        getResumes: Get.find<GetResumesUseCase>(),
        addResume: Get.find<AddResumeUseCase>(),
        deleteResume: Get.find<DeleteResumeUseCase>(),
        setDefaultResume: Get.find<SetDefaultResumeUseCase>(),
        connectGmail: Get.find<ConnectGmailUseCase>(),
        disconnectGmail: Get.find<DisconnectGmailUseCase>(),
        isGmailConnected: Get.find<IsGmailConnectedUseCase>(),
        themeController: Get.find<ThemeController>(),
        logger: Get.find<AppLogger>(),
      ),
    );
  }
}
