// Aggregateur de mocks pour tous les tests
import 'package:mockito/annotations.dart';

// Types Supabase/Gotrue utilisés dans les tests
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;
import 'package:gotrue/gotrue.dart' show GoTrueClient, AuthResponse, Session, User;

// AuthService (adapter l'import si besoin)
import 'package:ml_pp_mvp/core/services/auth_service.dart';

// Le builder Mockito exige la directive 'part' dans le même fichier:
part '_mocks.mocks.dart';

// Liste des types à mocker
@GenerateMocks([SupabaseClient, GoTrueClient, AuthResponse, Session, User, AuthService])
void main() {}
