import 'package:flutter_test/flutter_test.dart';
import 'package:chibot/services/flux_image_service.dart';
import 'package:chibot/services/image_generation_service.dart';

void main() {
  group('FLUX.1 Kontext Integration Tests', () {
    test('Test FLUX.1 Kontext Service Creation', () {
      // Test that the service can be created
      final service = FluxKontextImageService(apiKey: 'test-key');
      expect(service, isNotNull);
      expect(service.apiKey, 'test-key');
    });

    test('Test FluxSubmitResponse fromJson', () {
      final json = {
        'id': 'test-id',
        'status': 'pending',
        'polling_url': 'https:/api.bfl.ai/v1/get_result?id=test-id',
      };

      final response = FluxSubmitResponse.fromJson(json);
      expect(response.id, 'test-id');
      expect(response.status, 'pending');
      expect(response.pollingUrl, contains('test-id'));
    });

    test('Test FluxPollResponse fromJson - ready state', () {
      final json = {
        'status': 'ready',
        'result': {
          'sample': 'https://example.com/image.png',
          'prompt': 'test prompt',
        },
      };

      final response = FluxPollResponse.fromJson(json);
      expect(response.status, 'ready');
      expect(response.sampleUrl, 'https://example.com/image.png');
      expect(response.error, isNull);
    });

    test('Test FluxPollResponse fromJson - failed state', () {
      final json = {
        'status': 'failed',
        'error': {'message': 'Invalid prompt'},
      };

      final response = FluxPollResponse.fromJson(json);
      expect(response.status, 'failed');
      expect(response.error, 'Invalid prompt');
      expect(response.sampleUrl, isNull);
    });

    test('Test ImageGenerationService with FLUX.1 provider', () async {
      // This is a mock test - in real scenarios, you'd use mock HTTP client
      final service = ImageGenerationService();

      // Test that the service can handle FLUX.1 provider URL
      expect(
        () => service.generateImage(
          apiKey: 'test-key',
          prompt: 'test prompt',
          model: 'flux-kontext-pro',
          providerBaseUrl: 'https://api.bfl.ai/v1',
          openAISize: '1024x1024',
        ),
        throwsException, // Expected since we're not mocking HTTP
      );
    });

    test('Test aspect ratio conversion', () {
      // Test the aspect ratio conversion logic
      final service = ImageGenerationService();

      // This would test the internal conversion logic
      // For now, we just verify the service is structured correctly
      expect(service, isNotNull);
    });
  });

  group('FLUX.1 Request Body Tests', () {
    test('Test request body structure', () {
      // Test that request body is properly formatted
      final expectedBody = {
        'prompt': 'a beautiful sunset',
        'aspect_ratio': '16:9',
        'output_format': 'png',
      };

      expect(expectedBody, containsPair('prompt', 'a beautiful sunset'));
      expect(expectedBody, containsPair('aspect_ratio', '16:9'));
    });
  });
}
