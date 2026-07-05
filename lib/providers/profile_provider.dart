import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/user_profile.dart';
import '../services/database_helper.dart';

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(DatabaseHelper.instance.getProfile);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await DatabaseHelper.instance.saveProfile(profile);
    state = AsyncValue.data(profile);
  }

  Future<void> deleteProfile() async {
    await DatabaseHelper.instance.deleteProfile();
    state = const AsyncValue.data(null);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return ProfileNotifier();
});

final hasProfileProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider);
  return profile.maybeWhen(data: (p) => p != null, orElse: () => false);
});
