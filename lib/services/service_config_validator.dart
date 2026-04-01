class ServiceConfigValidator {
  const ServiceConfigValidator._();

  static bool hasText(String? value) {
    return value?.trim().isNotEmpty ?? false;
  }

  static String requireText(String? value, String message) {
    if (!hasText(value)) {
      throw Exception(message);
    }

    return value!.trim();
  }
}
