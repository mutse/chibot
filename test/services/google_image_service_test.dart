import 'package:chibot/services/google_image_service.dart';
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
        GoogleImageService.getDisplayName(
          GoogleImageService.nanoBanana2Model,
        ),
        equals('Nano Banana 2'),
      );
      expect(
        GoogleImageService.getDisplayName(
          GoogleImageService.nanoBananaProModel,
        ),
        equals('Nano Banana Pro'),
      );
      expect(
        GoogleImageService.getDisplayName(
          GoogleImageService.nanoBananaModel,
        ),
        equals('Nano Banana'),
      );
    });
  });
}
