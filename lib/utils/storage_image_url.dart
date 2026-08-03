import '../data/api_config.dart';

/// Resolve URLs de imagem para exibição no cardápio.
///
/// URLs que apontam diretamente para o storage S3 são redirecionadas
/// para o proxy do backend (`/api/v1/storage/object`), que faz o download
/// autenticado do objeto e devolve os bytes. Outras URLs são mantidas
/// inalteradas.
class StorageImageUrl {
  const StorageImageUrl._();

  static String resolve(String rawUrl) {
    final originalUrl = rawUrl.trim();
    if (originalUrl.isEmpty) return originalUrl;

    final imageUri = Uri.tryParse(originalUrl);
    final storageUri = Uri.tryParse(ApiConfig.storageEndpoint);
    if (imageUri == null ||
        storageUri == null ||
        imageUri.host.isEmpty ||
        imageUri.host.toLowerCase() != storageUri.host.toLowerCase()) {
      return originalUrl;
    }

    final apiBase = Uri.parse(ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), ''));
    return apiBase
        .resolve('/api/v1/storage/object')
        .replace(queryParameters: {'url': originalUrl})
        .toString();
  }
}
