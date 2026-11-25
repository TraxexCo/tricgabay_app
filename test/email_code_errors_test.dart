import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'package:tricgabay_app/core/services/email_code_errors.dart';

void main() {
  group('normalizeEmailCode', () {
    test('accepts exactly six digits', () {
      expect(normalizeEmailCode('123456'), '123456');
      expect(normalizeEmailCode(' 123 456 '), '123456');
      expect(normalizeEmailCode('000000'), '000000');
    });

    test('rejects anything else', () {
      for (final value in [null, '', '12345', '1234567', '12a456', '12-456']) {
        expect(normalizeEmailCode(value), isNull, reason: '$value');
      }
    });
  });

  group('emailCodeFailureFor', () {
    test('a wrong or expired code (one Supabase error for both)', () {
      expect(
        emailCodeFailureFor(
          const AuthException(
            'Token has expired or is invalid',
            statusCode: '403',
            code: 'otp_expired',
          ),
        ),
        EmailCodeFailure.wrongOrExpired,
      );
      expect(
        emailCodeFailureFor(
          const AuthException('Token has expired or is invalid'),
        ),
        EmailCodeFailure.wrongOrExpired,
      );
    });

    test('a rate limit, by status, code or wording', () {
      expect(
        emailCodeFailureFor(
          const AuthException('slow down', statusCode: '429'),
        ),
        EmailCodeFailure.rateLimited,
      );
      expect(
        emailCodeFailureFor(
          const AuthException('x', code: 'over_email_send_rate_limit'),
        ),
        EmailCodeFailure.rateLimited,
      );
      expect(
        emailCodeFailureFor(const AuthException('email rate limit exceeded')),
        EmailCodeFailure.rateLimited,
      );
      expect(
        emailCodeFailureFor(
          const AuthException(
            'For security purposes, you can only request this after 52 seconds.',
          ),
        ),
        EmailCodeFailure.rateLimited,
      );
    });

    test('network trouble', () {
      expect(
        emailCodeFailureFor(const SocketException('no route')),
        EmailCodeFailure.network,
      );
      expect(
        emailCodeFailureFor(TimeoutException('slow')),
        EmailCodeFailure.network,
      );
      expect(
        emailCodeFailureFor(AuthRetryableFetchException(message: 'offline')),
        EmailCodeFailure.network,
      );
    });

    test('anything else', () {
      expect(
        emailCodeFailureFor(const AuthException('Database error')),
        EmailCodeFailure.other,
      );
      expect(emailCodeFailureFor(StateError('x')), EmailCodeFailure.other);
    });
  });

  test('each failure has its own message', () {
    expect(
      emailCodeMessage(EmailCodeFailure.wrongOrExpired),
      MessageCode.codeWrongOrExpired,
    );
    expect(
      emailCodeMessage(EmailCodeFailure.rateLimited),
      MessageCode.codeRateLimited,
    );
    expect(
      emailCodeMessage(EmailCodeFailure.network),
      MessageCode.connectionUnavailableCheckYourInternetConnectionAndTryAgain,
    );
    expect({
      for (final failure in EmailCodeFailure.values) emailCodeMessage(failure),
    }, hasLength(EmailCodeFailure.values.length));
  });
}
