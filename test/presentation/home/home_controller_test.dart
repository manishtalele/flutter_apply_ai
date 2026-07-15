import 'package:dartz/dartz.dart' show Right;
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/domain/entities/job_posting.dart';
import 'package:flutter_apply_ai/domain/usecases/ai/analyze_job_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/check_duplicate_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/send_application_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/resume/get_resumes_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/settings/get_settings_usecase.dart';
import 'package:flutter_apply_ai/presentation/home/controllers/home_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyze extends Mock implements AnalyzeJobUseCase {}

class _MockCheckDuplicate extends Mock implements CheckDuplicateUseCase {}

class _MockSendApplication extends Mock implements SendApplicationUseCase {}

class _MockGetResumes extends Mock implements GetResumesUseCase {}

class _MockGetSettings extends Mock implements GetSettingsUseCase {}

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

const JobPosting _posting = JobPosting(
  company: 'Acme',
  email: 'jobs@acme.com',
  role: 'Flutter Developer',
  location: 'Remote',
  experience: '3+ years',
  skills: <String>['Flutter', 'Dart'],
  subject: 'Application for Flutter Developer',
  emailBody: '<p>Hello</p>',
  matchScore: 88,
  shouldApply: true,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const AnalyzeJobParams(rawText: 'seed'));
  });

  late _MockAnalyze analyze;
  late HomeController controller;

  setUp(() {
    analyze = _MockAnalyze();
    controller = HomeController(
      analyzeJob: analyze,
      checkDuplicate: _MockCheckDuplicate(),
      sendApplication: _MockSendApplication(),
      getResumes: _MockGetResumes(),
      getSettings: _MockGetSettings(),
      logger: const _SilentLogger(),
    );
  });

  test('analyze sets the posting and success state on a Right result',
      () async {
    when(() => analyze(any())).thenAnswer(
      (_) async => const Right<Failure, JobPosting>(_posting),
    );
    controller.pasteController.text = 'A pasted job description';

    await controller.analyze();

    expect(controller.state.value, ViewState.success);
    expect(controller.posting.value, _posting);
    expect(controller.hasResult, isTrue);
    expect(controller.canApply, isTrue);
  });

  test('clear resets the controller to its initial state', () async {
    when(() => analyze(any())).thenAnswer(
      (_) async => const Right<Failure, JobPosting>(_posting),
    );
    controller.pasteController.text = 'A pasted job description';
    await controller.analyze();

    controller.clear();

    expect(controller.state.value, ViewState.initial);
    expect(controller.posting.value, isNull);
    expect(controller.pasteController.text, isEmpty);
    expect(controller.hasResult, isFalse);
  });
}
