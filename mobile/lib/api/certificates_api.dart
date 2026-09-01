import 'package:dio/dio.dart';

import '../models/certificate.dart';

class CertificatesApi {
  CertificatesApi(this._dio);
  final Dio _dio;

  Future<List<Certificate>> me() async {
    final response = await _dio.get<List<dynamic>>('/certificates/me');
    return response.data!
        .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
