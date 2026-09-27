import '../../l10n/gen/app_localizations.dart';
import 'failure.dart';

String failureMessage(AppLocalizations l10n, Failure failure) {
  return switch (failure.code) {
    FailureCode.network => l10n.errorNetwork,
    FailureCode.timeout => l10n.errorTimeout,
    FailureCode.server => l10n.errorServer,
    FailureCode.notFound => l10n.errorNotFound,
    FailureCode.unauthorized => l10n.errorUnauthorized,
    FailureCode.invalidCredentials => l10n.errorInvalidCredentials,
    FailureCode.emailNotConfirmed => l10n.errorEmailNotConfirmed,
    FailureCode.userAlreadyExists => l10n.errorUserAlreadyExists,
    FailureCode.weakPassword => l10n.errorWeakPassword,
    FailureCode.rateLimited => l10n.errorRateLimited,
    FailureCode.outdatedDatabase => l10n.errorOutdatedDatabase,
    FailureCode.unknown => l10n.errorUnknown,
  };
}
