import 'package:flutter_apply_ai/core/constants/prompt_constants.dart';
import 'package:flutter_apply_ai/data/models/app_settings_model.dart';
import 'package:flutter_apply_ai/data/models/job_posting_model.dart';
import 'package:flutter_apply_ai/domain/entities/app_settings.dart';
import 'package:flutter_apply_ai/domain/entities/enums/candidate_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings.candidateDetails', () {
    test('includes only the details the user actually filled in', () {
      const AppSettings settings = AppSettings(
        senderName: 'Manish Talele',
        currentLocation: 'Pune, India',
        noticePeriod: '30 days',
        // currentCtc / expectedCtc / totalExperience deliberately left blank.
      );

      expect(settings.candidateDetails, <String, String>{
        'Full name': 'Manish Talele',
        'Current location': 'Pune, India',
        'Notice period': '30 days',
      });
    });

    test('treats whitespace-only values as unset', () {
      const AppSettings settings = AppSettings(currentCtc: '   ');

      expect(settings.candidateDetails, isEmpty);
    });
  });

  group('AppSettingsModel persistence', () {
    test('round-trips the candidate detail fields through prefs JSON', () {
      const AppSettingsModel original = AppSettingsModel(
        senderName: 'Manish Talele',
        currentLocation: 'Pune, India',
        totalExperience: '3.5 years',
        currentCtc: '8 LPA',
        expectedCtc: '12 LPA',
        noticePeriod: '30 days',
      );

      final AppSettingsModel restored = AppSettingsModel.fromPrefsJson(
        original.toPrefsJson(),
        openAiApiKey: 'sk-test',
      );

      expect(restored.currentLocation, 'Pune, India');
      expect(restored.totalExperience, '3.5 years');
      expect(restored.currentCtc, '8 LPA');
      expect(restored.expectedCtc, '12 LPA');
      expect(restored.noticePeriod, '30 days');
    });

    test('defaults the new fields to empty for a pre-existing bundle', () {
      // A bundle written before these fields existed has none of the keys.
      final AppSettingsModel restored = AppSettingsModel.fromPrefsJson(
        const <String, dynamic>{'senderName': 'Manish Talele'},
        openAiApiKey: '',
      );

      expect(restored.senderName, 'Manish Talele');
      expect(restored.currentLocation, isEmpty);
      expect(restored.noticePeriod, isEmpty);
      expect(restored.candidateDetails, <String, String>{
        'Full name': 'Manish Talele',
      });
    });
  });

  group('requestedDetails response schema', () {
    test('constrains the AI to the CandidateDetail tokens', () {
      final Map<String, dynamic> properties = PromptConstants
          .jobPostingResponseSchema['properties'] as Map<String, dynamic>;
      final Map<String, dynamic> requested =
          properties['requestedDetails'] as Map<String, dynamic>;
      final Map<String, dynamic> items =
          requested['items'] as Map<String, dynamic>;

      expect(requested['type'], 'array');
      expect(items['enum'], CandidateDetail.allValues);
      // Strict structured output requires every property to be listed.
      expect(
        PromptConstants.jobPostingResponseSchema['required'],
        contains('requestedDetails'),
      );
    });
  });

  group('JobPostingModel.requestedDetails', () {
    Map<String, dynamic> jsonWith(Object? requestedDetails) {
      return <String, dynamic>{
        'company': 'Fourbrick Technology',
        'email': 'hr@fourbrick.com',
        'role': 'Android Developer',
        'subject': 'Android Developer | 3.5 years | Pune, India',
        'emailBody': '<p>Hello</p>',
        'matchScore': 80,
        'shouldApply': true,
        'requestedDetails': requestedDetails,
      };
    }

    test('maps the AI tokens onto the enum', () {
      final JobPostingModel posting = JobPostingModel.fromJson(
        jsonWith(<String>['currentLocation', 'totalExperience']),
      );

      expect(posting.requestedDetails, <CandidateDetail>[
        CandidateDetail.currentLocation,
        CandidateDetail.totalExperience,
      ]);
    });

    test('drops unrecognized tokens and duplicates', () {
      final JobPostingModel posting = JobPostingModel.fromJson(
        jsonWith(<dynamic>[
          'currentLocation',
          'bloodGroup',
          'currentLocation',
          42,
        ]),
      );

      expect(
        posting.requestedDetails,
        <CandidateDetail>[CandidateDetail.currentLocation],
      );
    });

    test('is empty when the field is missing or not a list', () {
      expect(
        JobPostingModel.fromJson(jsonWith(null)).requestedDetails,
        isEmpty,
      );
      expect(
        JobPostingModel.fromJson(jsonWith('currentLocation')).requestedDetails,
        isEmpty,
      );
    });
  });

  group('PromptConstants.extractionUserContent', () {
    test('lists the supplied candidate details as label/value lines', () {
      final String content = PromptConstants.extractionUserContent(
        jobDescription: 'Hiring a Flutter dev. Mention your current location.',
        candidateProfile: '4 years Flutter.',
        candidateDetails: const <String, String>{
          'Current location': 'Pune, India',
          'Notice period': '30 days',
        },
      );

      expect(content, contains('- Current location: Pune, India'));
      expect(content, contains('- Notice period: 30 days'));
      expect(content, contains('4 years Flutter.'));
      expect(content, contains('Mention your current location.'));
    });

    test('states explicitly when no details were provided', () {
      final String content = PromptConstants.extractionUserContent(
        jobDescription: 'Hiring a Flutter dev.',
        candidateProfile: '',
      );

      expect(content, contains('do not invent any'));
      expect(content, contains('(No candidate profile provided.)'));
    });
  });
}
