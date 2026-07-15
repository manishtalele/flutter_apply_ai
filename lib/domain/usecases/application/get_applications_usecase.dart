import 'package:equatable/equatable.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/entities/application.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_apply_ai/domain/repositories/application_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Parameters for [GetApplicationsUseCase].
class GetApplicationsParams extends Equatable {
  const GetApplicationsParams({
    this.search,
    this.status,
    this.limit,
    this.offset,
  });

  final String? search;
  final ApplicationStatus? status;
  final int? limit;
  final int? offset;

  @override
  List<Object?> get props => <Object?>[search, status, limit, offset];
}

/// Returns applications newest-first with optional search/status filtering.
class GetApplicationsUseCase
    implements UseCase<List<Application>, GetApplicationsParams> {
  const GetApplicationsUseCase(this._repository);

  final ApplicationRepository _repository;

  @override
  ResultFuture<List<Application>> call(GetApplicationsParams params) {
    return _repository.getApplications(
      search: params.search,
      status: params.status,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
