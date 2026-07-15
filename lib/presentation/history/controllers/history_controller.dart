import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart' show Either;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/enums/view_state.dart';
import 'package:flutter_apply_ai/core/errors/failures.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/usecases/application/delete_application_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/export_applications_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/application/get_applications_usecase.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// ViewModel for the History screen: lists applications with search/status
/// filtering, supports delete, CSV export, and opening the thread in Gmail.
class HistoryController extends GetxController {
  HistoryController({
    required GetApplicationsUseCase getApplications,
    required DeleteApplicationUseCase deleteApplication,
    required ExportApplicationsUseCase exportApplications,
    required AppLogger logger,
  })  : _getApplications = getApplications,
        _deleteApplication = deleteApplication,
        _exportApplications = exportApplications,
        _logger = logger;

  final GetApplicationsUseCase _getApplications;
  final DeleteApplicationUseCase _deleteApplication;
  final ExportApplicationsUseCase _exportApplications;
  final AppLogger _logger;

  final TextEditingController searchController = TextEditingController();

  final Rx<ViewState> state = ViewState.initial.obs;
  final RxList<Application> applications = <Application>[].obs;
  final RxString searchQuery = ''.obs;
  final Rxn<ApplicationStatus> statusFilter = Rxn<ApplicationStatus>();
  final RxBool exporting = false.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    state.value = ViewState.loading;
    final result = await _getApplications(
      GetApplicationsParams(
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
        status: statusFilter.value,
      ),
    );
    result.fold(
      (Failure failure) {
        _logger.w('Failed to load applications: ${failure.message}');
        state.value = ViewState.error;
      },
      (List<Application> list) {
        applications.assignAll(list);
        state.value = ViewState.success;
      },
    );
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      searchQuery.value = value.trim();
      unawaited(load());
    });
  }

  Future<void> setStatusFilter(ApplicationStatus? status) async {
    statusFilter.value = status;
    await load();
  }

  Future<void> reload() => load();

  Future<void> deleteApplication(int id) async {
    final result = await _deleteApplication(id);
    if (result.isRight()) {
      await load();
      _notify('Deleted', 'Application removed.');
    } else {
      _notify('Error', _messageOf(result));
    }
  }

  Future<void> exportCsv() async {
    if (exporting.value) {
      return;
    }
    exporting.value = true;
    final result = await _exportApplications(const NoParams());
    exporting.value = false;

    if (result.isLeft()) {
      _notify('Export failed', _messageOf(result));
      return;
    }

    final String csv = result.getOrElse(() => '');
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export applications to CSV',
      fileName: 'applications_export.csv',
      type: FileType.custom,
      allowedExtensions: <String>['csv'],
    );
    if (path == null) {
      return;
    }
    try {
      await File(path).writeAsString(csv);
      _notify('Exported', 'Saved to $path');
    } catch (error, stackTrace) {
      _logger.e('CSV write failed', error, stackTrace);
      _notify('Export failed', 'Could not write the file.');
    }
  }

  Future<void> openInGmail(Application application) async {
    final String query = Uri.encodeComponent(application.email);
    final Uri url = Uri.parse(
      'https://mail.google.com/mail/u/0/#search/$query',
    );
    final bool launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _notify('Could not open', 'Unable to open Gmail in the browser.');
    }
  }

  String _messageOf<T>(Either<Failure, T> result) {
    return result.fold((Failure failure) => failure.message, (_) => 'Error.');
  }

  void _notify(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
