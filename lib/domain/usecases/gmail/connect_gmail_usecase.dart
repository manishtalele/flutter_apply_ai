import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/repositories/gmail_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Runs the Gmail OAuth2 consent flow; returns the connected account email.
class ConnectGmailUseCase implements UseCase<String, NoParams> {
  const ConnectGmailUseCase(this._repository);

  final GmailRepository _repository;

  @override
  ResultFuture<String> call(NoParams params) => _repository.connect();
}
