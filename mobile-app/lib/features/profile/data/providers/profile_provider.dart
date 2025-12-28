import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';
import '../models/certification.dart';
import '../models/skill.dart';
import '../models/language.dart';
import '../models/volunteering.dart';
import '../models/publication.dart';
import '../models/interest.dart';
import '../models/achievement.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  // State
  List<Certification> _certifications = [];
  List<Skill> _skills = [];
  List<Language> _languages = [];
  List<Volunteering> _volunteering = [];
  List<Publication> _publications = [];
  List<Interest> _interests = [];
  List<Achievement> _achievements = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Certification> get certifications => _certifications;
  List<Skill> get skills => _skills;
  List<Language> get languages => _languages;
  List<Volunteering> get volunteering => _volunteering;
  List<Publication> get publications => _publications;
  List<Interest> get interests => _interests;
  List<Achievement> get achievements => _achievements;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all profile data (optimized - parallel loading)
  Future<void> loadAllProfileData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load all in parallel for maximum speed
      await Future.wait([
        loadCertifications(),
        loadSkills(),
        loadLanguages(),
        loadVolunteering(),
        loadPublications(),
        loadInterests(),
        loadAchievements(),
      ], eagerError: false); // Don't stop on first error
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Certifications ---

  Future<void> loadCertifications() async {
    try {
      _certifications = await _profileService.getCertifications();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load certifications: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createCertification(Map<String, dynamic> data) async {
    try {
      final cert = await _profileService.createCertification(data);
      _certifications.add(cert);
      _certifications.sort((a, b) => b.displayOrder.compareTo(a.displayOrder));
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create certification: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCertification(String id, Map<String, dynamic> data) async {
    try {
      await _profileService.updateCertification(id, data);
      await loadCertifications(); // Reload to get updated data
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update certification: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCertification(String id) async {
    try {
      await _profileService.deleteCertification(id);
      _certifications.removeWhere((c) => c.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete certification: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // --- Skills ---

  Future<void> loadSkills() async {
    try {
      _skills = await _profileService.getSkills();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load skills: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createSkill(Map<String, dynamic> data) async {
    try {
      final skill = await _profileService.createSkill(data);
      _skills.add(skill);
      _skills.sort((a, b) => b.displayOrder.compareTo(a.displayOrder));
      _error = null;
      notifyListeners();
      // Reload to ensure consistency
      await loadSkills();
    } catch (e) {
      _error = 'Failed to create skill: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSkill(String id, Map<String, dynamic> data) async {
    try {
      await _profileService.updateSkill(id, data);
      await loadSkills();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update skill: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSkill(String id) async {
    try {
      await _profileService.deleteSkill(id);
      _skills.removeWhere((s) => s.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete skill: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // --- Languages ---

  Future<void> loadLanguages() async {
    try {
      _languages = await _profileService.getLanguages();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load languages: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createLanguage(Map<String, dynamic> data) async {
    try {
      final lang = await _profileService.createLanguage(data);
      _languages.add(lang);
      _languages.sort((a, b) => b.displayOrder.compareTo(a.displayOrder));
      _error = null;
      notifyListeners();
      // Reload to ensure consistency
      await loadLanguages();
    } catch (e) {
      _error = 'Failed to create language: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateLanguage(String id, Map<String, dynamic> data) async {
    try {
      await _profileService.updateLanguage(id, data);
      await loadLanguages();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update language: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLanguage(String id) async {
    try {
      await _profileService.deleteLanguage(id);
      _languages.removeWhere((l) => l.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete language: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // --- Volunteering ---

  Future<void> loadVolunteering() async {
    try {
      _volunteering = await _profileService.getVolunteering();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load volunteering: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createVolunteering(Map<String, dynamic> data) async {
    try {
      final vol = await _profileService.createVolunteering(data);
      _volunteering.add(vol);
      _volunteering.sort((a, b) => b.displayOrder.compareTo(a.displayOrder));
      _error = null;
      notifyListeners();
      // Reload to ensure consistency
      await loadVolunteering();
    } catch (e) {
      _error = 'Failed to create volunteering: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateVolunteering(String id, Map<String, dynamic> data) async {
    try {
      await _profileService.updateVolunteering(id, data);
      await loadVolunteering();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update volunteering: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteVolunteering(String id) async {
    try {
      await _profileService.deleteVolunteering(id);
      _volunteering.removeWhere((v) => v.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete volunteering: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // --- Publications ---

  Future<void> loadPublications() async {
    try {
      _publications = await _profileService.getPublications();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load publications: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createPublication(Map<String, dynamic> data) async {
    try {
      final pub = await _profileService.createPublication(data);
      _publications.add(pub);
      _publications.sort((a, b) => b.displayOrder.compareTo(a.displayOrder));
      _error = null;
      notifyListeners();
      // Reload to ensure consistency
      await loadPublications();
    } catch (e) {
      _error = 'Failed to create publication: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePublication(String id, Map<String, dynamic> data) async {
    try {
      await _profileService.updatePublication(id, data);
      await loadPublications();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update publication: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePublication(String id) async {
    try {
      await _profileService.deletePublication(id);
      _publications.removeWhere((p) => p.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete publication: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // --- Interests ---

  Future<void> loadInterests() async {
    try {
      _interests = await _profileService.getInterests();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load interests: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createInterest(Map<String, dynamic> data) async {
    try {
      final interest = await _profileService.createInterest(data);
      _interests.add(interest);
      _interests.sort((a, b) => b.displayOrder.compareTo(a.displayOrder));
      _error = null;
      notifyListeners();
      // Reload to ensure consistency
      await loadInterests();
    } catch (e) {
      _error = 'Failed to create interest: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateInterest(String id, Map<String, dynamic> data) async {
    try {
      await _profileService.updateInterest(id, data);
      await loadInterests();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update interest: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteInterest(String id) async {
    try {
      await _profileService.deleteInterest(id);
      _interests.removeWhere((i) => i.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete interest: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // --- Achievements ---

  Future<void> loadAchievements() async {
    try {
      _achievements = await _profileService.getAchievements();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load achievements: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createAchievement(Map<String, dynamic> data) async {
    try {
      final achievement = await _profileService.createAchievement(data);
      _achievements.add(achievement);
      _achievements.sort((a, b) => b.displayOrder.compareTo(a.displayOrder));
      _error = null;
      notifyListeners();
      // Reload to ensure consistency
      await loadAchievements();
    } catch (e) {
      _error = 'Failed to create achievement: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAchievement(String id, Map<String, dynamic> data) async {
    try {
      await _profileService.updateAchievement(id, data);
      await loadAchievements();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update achievement: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAchievement(String id) async {
    try {
      await _profileService.deleteAchievement(id);
      _achievements.removeWhere((a) => a.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete achievement: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Clear all data
  void clear() {
    _certifications = [];
    _skills = [];
    _languages = [];
    _volunteering = [];
    _publications = [];
    _interests = [];
    _achievements = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
