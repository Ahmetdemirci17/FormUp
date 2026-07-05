import 'package:flutter_riverpod/legacy.dart';

import '../models/user_profile.dart';

final onboardingDraftProvider = StateProvider<UserProfile>((ref) => UserProfile.initial());
