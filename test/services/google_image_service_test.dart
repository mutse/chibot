import 'dart:convert';

import 'package:chibot/services/google_image_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleImageService', () {
    test('normalizes Nano Banana aliases to the official API model ids', () {
      expect(
        GoogleImageService.normalizeModel('nano-banana'),
        equals(GoogleImageService.nanoBananaModel),
      );
      expect(
        GoogleImageService.normalizeModel('nano banana 2'),
        equals(GoogleImageService.nanoBanana2Model),
      );
      expect(
        GoogleImageService.normalizeModel('nano banada 2'),
        equals(GoogleImageService.nanoBanana2Model),
      );
      expect(
        GoogleImageService.normalizeModel('nano-banana-pro'),
        equals(GoogleImageService.nanoBananaProModel),
      );
    });

    test('supported models expose official Google image model ids', () {
      expect(
        GoogleImageService.getSupportedModels(),
        containsAll([
          GoogleImageService.nanoBanana2Model,
          GoogleImageService.nanoBananaProModel,
          GoogleImageService.nanoBananaModel,
        ]),
      );
    });

    test('maps official Google image model ids to friendly display names', () {
      expect(
        GoogleImageService.getDisplayName(GoogleImageService.nanoBanana2Model),
        equals('Nano Banana 2'),
      );
      expect(
        GoogleImageService.getDisplayName(
          GoogleImageService.nanoBananaProModel,
        ),
        equals('Nano Banana Pro'),
      );
      expect(
        GoogleImageService.getDisplayName(GoogleImageService.nanoBananaModel),
        equals('Nano Banana'),
      );
    });

    test(
      'uses responseFormat image payload for Google text-to-image requests',
      () async {
        late Map<String, dynamic> sentBody;
        final service = GoogleImageService(
          apiKey: 'test-key',
          client: MockClient((request) async {
            sentBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'image/png',
                            'data': 'abc123',
                          },
                        },
                      ],
                    },
                  },
                ],
              }),
              200,
            );
          }),
        );

        final result = await service.generateImage(
          prompt: 'draw a banana astronaut',
          model: GoogleImageService.nanoBanana2Model,
          aspectRatio: '16:9',
        );

        expect(result, equals('data:image/png;base64,abc123'));
        expect(
          sentBody['generationConfig']['responseFormat']['image']['aspectRatio'],
          equals('16:9'),
        );
        expect(
          (sentBody['generationConfig'] as Map<String, dynamic>).containsKey(
            'imageConfig',
          ),
          isFalse,
        );
        expect(
          (sentBody['generationConfig'] as Map<String, dynamic>).containsKey(
            'responseModalities',
          ),
          isFalse,
        );
      },
    );

    test(
      'falls back to legacy imageConfig payload when responseFormat is rejected',
      () async {
        final sentBodies = <Map<String, dynamic>>[];
        int requestCount = 0;
        final service = GoogleImageService(
          apiKey: 'test-key',
          client: MockClient((request) async {
            requestCount += 1;
            sentBodies.add(jsonDecode(request.body) as Map<String, dynamic>);

            if (requestCount == 1) {
              return http.Response(
                jsonEncode({
                  'error': {
                    'message':
                        'Invalid JSON payload received. Unknown name "responseFormat" at \'generation_config\'.',
                  },
                }),
                400,
              );
            }

            return http.Response(
              jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'image/png',
                            'data': 'legacy456',
                          },
                        },
                      ],
                    },
                  },
                ],
              }),
              200,
            );
          }),
        );

        final result = await service.generateImage(
          prompt: 'banana city skyline',
          model: GoogleImageService.nanoBanana2Model,
          aspectRatio: '1:1',
        );

        expect(result, equals('data:image/png;base64,legacy456'));
        expect(requestCount, equals(2));
        expect(
          sentBodies
              .first['generationConfig']['responseFormat']['image']['aspectRatio'],
          equals('1:1'),
        );
        expect(
          sentBodies.last['generationConfig']['responseModalities'],
          equals(['IMAGE']),
        );
        expect(
          sentBodies.last['generationConfig']['imageConfig']['aspectRatio'],
          equals('1:1'),
        );
      },
    );
  });
}
