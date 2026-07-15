import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/domain/repositories/gmail_repository.dart';
import 'package:flutter_apply_ai/domain/usecases/usecase.dart';

/// Revokes and clears the Gmail session.
class DisconnectGmailUseCase implements UseCase<void, NoParams> {
  const DisconnectGmailUseCase(this._repository);

  final GmailRepository _repository;

  @override
  ResultVoid call(NoParams params) => _repository.disconnect();
}
