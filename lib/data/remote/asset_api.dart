import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';

/// Un pion ou une carte dont le serveur héberge l'image, ajouté depuis le
/// backoffice.
///
/// `imageHash` est la version de l'image : la copie gardée sur l'appareil en
/// porte le nom, et une image qui n'a pas changé ne se retélécharge pas.
class RemoteAsset {
  const RemoteAsset({
    required this.key,
    required this.name,
    required this.kind,
    required this.imageHash,
    this.width,
    this.height,
  });

  factory RemoteAsset.fromJson(Map<String, dynamic> json) => RemoteAsset(
        key: json['key'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String,
        imageHash: json['imageHash'] as String,
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
      );

  /// La nature d'une carte : un fond de plateau, pas un pion.
  static const mapKind = 'map';

  final String key;
  final String name;
  final String kind;
  final String imageHash;

  /// En pixels. Ceux d'une carte font les proportions du plateau ; un pion
  /// hébergé avant les cartes n'en a pas.
  final int? width;
  final int? height;

  bool get isMap => kind == mapKind;

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'kind': kind,
        'imageHash': imageHash,
        'width': width,
        'height': height,
      };
}

class AssetApi {
  AssetApi(this._client);

  final ApiClient _client;

  Future<List<RemoteAsset>> list() {
    return _client.send(
      (dio) => dio.get<dynamic>('/assets'),
      parse: parseList,
    );
  }

  static List<RemoteAsset> parseList(Object? data) {
    final assets = (data as Map)['assets'];
    if (assets is! List) return const <RemoteAsset>[];
    return assets
        .whereType<Map>()
        .map((entry) => RemoteAsset.fromJson(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Uint8List> image(String key) {
    return _client.send(
      (dio) => dio.get<List<int>>(
        '/assets/${Uri.encodeComponent(key)}/image',
        options: Options(responseType: ResponseType.bytes),
      ),
      parse: (data) => Uint8List.fromList(data as List<int>),
    );
  }
}
