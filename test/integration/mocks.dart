// test/integration/mocks.dart
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ml_pp_mvp/core/services/auth_service.dart';
import 'package:ml_pp_mvp/features/profil/data/profil_service.dart';

@GenerateMocks([
  AuthService,
  ProfilService,
  User,
])
void main() {}
