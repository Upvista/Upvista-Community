import '../../../../core/api/api_client.dart';
import '../models/certification.dart';
import '../models/skill.dart';
import '../models/language.dart';
import '../models/volunteering.dart';
import '../models/publication.dart';
import '../models/interest.dart';
import '../models/achievement.dart';
import '../models/company.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  // --- Certifications ---

  Future<List<Certification>> getCertifications() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/account/certifications',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final List<dynamic> jsonList = response['certifications'] ?? [];
    return jsonList
        .map((json) => Certification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Certification> createCertification(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/account/certifications',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return Certification.fromJson(
      response['certification'] as Map<String, dynamic>,
    );
  }

  Future<void> updateCertification(String id, Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/account/certifications/$id',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> deleteCertification(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      '/account/certifications/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // --- Skills ---

  Future<List<Skill>> getSkills() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/account/skills',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final List<dynamic> jsonList = response['skills'] ?? [];
    return jsonList
        .map((json) => Skill.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Skill> createSkill(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/account/skills',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return Skill.fromJson(response['skill'] as Map<String, dynamic>);
  }

  Future<void> updateSkill(String id, Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/account/skills/$id',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> deleteSkill(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      '/account/skills/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // --- Languages ---

  Future<List<Language>> getLanguages() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/account/languages',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final List<dynamic> jsonList = response['languages'] ?? [];
    return jsonList
        .map((json) => Language.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Language> createLanguage(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/account/languages',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return Language.fromJson(response['language'] as Map<String, dynamic>);
  }

  Future<void> updateLanguage(String id, Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/account/languages/$id',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> deleteLanguage(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      '/account/languages/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // --- Volunteering ---

  Future<List<Volunteering>> getVolunteering() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/account/volunteering',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final List<dynamic> jsonList = response['volunteering'] ?? [];
    return jsonList
        .map((json) => Volunteering.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Volunteering> createVolunteering(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/account/volunteering',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return Volunteering.fromJson(
      response['volunteering'] as Map<String, dynamic>,
    );
  }

  Future<void> updateVolunteering(String id, Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/account/volunteering/$id',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> deleteVolunteering(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      '/account/volunteering/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // --- Publications ---

  Future<List<Publication>> getPublications() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/account/publications',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final List<dynamic> jsonList = response['publications'] ?? [];
    return jsonList
        .map((json) => Publication.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Publication> createPublication(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/account/publications',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return Publication.fromJson(
      response['publication'] as Map<String, dynamic>,
    );
  }

  Future<void> updatePublication(String id, Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/account/publications/$id',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> deletePublication(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      '/account/publications/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // --- Interests ---

  Future<List<Interest>> getInterests() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/account/interests',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final List<dynamic> jsonList = response['interests'] ?? [];
    return jsonList
        .map((json) => Interest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Interest> createInterest(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/account/interests',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return Interest.fromJson(response['interest'] as Map<String, dynamic>);
  }

  Future<void> updateInterest(String id, Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/account/interests/$id',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> deleteInterest(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      '/account/interests/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // --- Achievements ---

  Future<List<Achievement>> getAchievements() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/account/achievements',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final List<dynamic> jsonList = response['achievements'] ?? [];
    return jsonList
        .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Achievement> createAchievement(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/account/achievements',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return Achievement.fromJson(
      response['achievement'] as Map<String, dynamic>,
    );
  }

  Future<void> updateAchievement(String id, Map<String, dynamic> data) async {
    await _apiClient.patch<Map<String, dynamic>>(
      '/account/achievements/$id',
      data: data,
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> deleteAchievement(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      '/account/achievements/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // --- Companies ---

  Future<List<Company>> searchCompanies(String query, {int limit = 10}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/account/companies/search',
      queryParameters: {'q': query, 'limit': limit.toString()},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    final List<dynamic> jsonList = response['companies'] ?? [];
    return jsonList
        .map((json) => Company.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Company> createCompany(String name) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/account/companies',
      data: {'name': name},
      fromJson: (json) => json as Map<String, dynamic>,
    );
    return Company.fromJson(response['company'] as Map<String, dynamic>);
  }
}
