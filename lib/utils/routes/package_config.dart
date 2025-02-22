class PackageConfig {
  final Map<String, String> packages;

  PackageConfig(this.packages);

  factory PackageConfig.fromJson(Map<String, dynamic> json) {
    final packages = <String, String>{};
    for (final package in json['packages'] as List) {
      packages[package['name'] as String] = package['rootUri'] as String;
    }
    return PackageConfig(packages);
  }

  Uri? resolve(Uri uri) {
    if (uri.scheme != 'package') return null;
    final parts = uri.pathSegments;
    if (parts.isEmpty) return null;

    final packageName = parts.first;
    final packageUri = packages[packageName];
    if (packageUri == null) return null;

    final packagePath = Uri.parse(packageUri);
    final relativePath = parts.skip(1).join('/');
    return packagePath.resolve(relativePath);
  }
}
