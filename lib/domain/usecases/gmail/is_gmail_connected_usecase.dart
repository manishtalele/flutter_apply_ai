import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/repositories/gmail_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Reports whether a Gmail OAuth token currently exists in secure storage.
/// Used to reconcile the persisted "connected" label against the real
/// credential state (they can drift if tokens are revoked/cleared).
class IsGmailConnectedUseCase implements UseCase<bool, NoParams> {
  const IsGmailConnectedUseCase(this._repository);

  final GmailRepository _repository;

  @override
  ResultFuture<bool> call(NoParams params) => _repository.isConnected();
}
