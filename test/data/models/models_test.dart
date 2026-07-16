import 'package:flutter_apply_ai/core/constants/db_constants.dart';
import 'package:flutter_apply_ai/data/models/application_model.dart';
import 'package:flutter_apply_ai/data/models/job_posting_model.dart';
import 'package:flutter_apply_ai/domain/entities/enums/application_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobPostingModel.fromJson', () {
    test('parses a well-formed OpenAI response', () {
      final JobPostingModel model = JobPostingModel.fromJson(const <String, dynamic>{
        'company': 'Acme Corp',
        'email': 'jobs@acme.com',
        'phone': '+91 9655573339',
        'role': 'Flutter Developer',
        'location': 'Remote',
        'experience': '3+ years',
        'skills': <String>['Flutter', 'Dart', 'GetX'],
        'subject': 'Application for Flutter Developer',
        'emailBody': '<p>Hello</p>',
        'matchScore': 87,
        'shouldApply': true,
        'matchSummary': 'Strong fit.',
      });

      expect(model.company, 'Acme Corp');
      expect(model.phone, '+91 9655573339');
      expect(model.hasPhone, isTrue);
      expect(model.skills, const <String>['Flutter', 'Dart', 'GetX']);
      expect(model.matchScore, 87);
      expect(model.shouldApply, isTrue);
      expect(model.isSendable, isTrue);
    });

    test('coerces loose types and clamps the score', () {
      final JobPostingModel model = JobPostingModel.fromJson(const <String, dynamic>{
        'company': 'Acme',
        'email': '',
        'role': 'Dev',
        'location': 'NYC',
        'experience': '2',
        'skills': 'Flutter, Dart , , Firebase',
        'subject': 'Hi',
        'emailBody': 'Body',
        'matchScore': '150',
        'shouldApply': 'yes',
      });

      expect(model.skills, const <String>['Flutter', 'Dart', 'Firebase']);
      expect(model.matchScore, 100, reason: 'score is clamped to 0..100');
      expect(model.shouldApply, isTrue);
      expect(model.hasRecipient, isFalse);
    });

    test('tolerates missing fields without throwing', () {
      final JobPostingModel model =
          JobPostingModel.fromJson(const <String, dynamic>{});
      expect(model.company, '');
      expect(model.skills, isEmpty);
      expect(model.matchScore, 0);
      expect(model.shouldApply, isFalse);
    });
  });

  group('ApplicationModel SQLite mapping', () {
    test('round-trips through toMap/fromMap', () {
      final DateTime applied = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final DateTime updated = DateTime.fromMillisecondsSinceEpoch(1700000500000);

      final ApplicationModel original = ApplicationModel(
        id: 42,
        company: 'Acme',
        email: 'jobs@acme.com',
        role: 'Flutter Developer',
        location: 'Remote',
        subject: 'Application',
        emailBody: '<p>Body</p>',
        matchScore: 91,
        status: ApplicationStatus.interview,
        resumeName: 'Flutter Resume',
        gmailMessageId: 'msg-1',
        gmailThreadId: 'thr-1',
        appliedAt: applied,
        updatedAt: updated,
      );

      final Map<String, Object?> map = original.toMap();
      final ApplicationModel restored = ApplicationModel.fromMap(map);

      expect(restored, equals(original));
      expect(map[DbConstants.colStatus], 'interview');
      expect(map[DbConstants.colAppliedAt], applied.millisecondsSinceEpoch);
    });

    test('omits the primary key when id is null (for insert)', () {
      final ApplicationModel model = ApplicationModel(
        company: 'Acme',
        email: 'a@b.com',
        role: 'Dev',
        location: 'Remote',
        subject: 'Subj',
        emailBody: 'Body',
        matchScore: 50,
        status: ApplicationStatus.applied,
        resumeName: 'Default',
        appliedAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(model.toMap().containsKey(DbConstants.colId), isFalse);
    });
  });
}
