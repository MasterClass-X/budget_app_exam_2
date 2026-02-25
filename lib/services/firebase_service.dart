import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
// ignore: unused_import
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream d'utilisateur (pour savoir si connecté ou non)
  Stream<User?> get user => _auth.authStateChanges();

  // Inscription avec email et mot de passe
  Future<String?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    print("=== FIREBASE SERVICE: SIGN UP ===");
    print("Email: $email");
    print("Name: $name");

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      print("Utilisateur créé: ${user?.uid}");

      if (user != null) {
        try {
          // Mettre à jour le nom d'affichage
          await user.updateDisplayName(name);
          print("Nom d'affichage mis à jour: $name");
        } catch (e) {
          print("Erreur updateDisplayName: $e");
          // Continue même si ça échoue
        }

        try {
          // Créer l'utilisateur dans Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email,
            'displayName': name,
            'totalBalance': 0.0,
            'monthlyBudget': 0.0,
          });
          print("Document Firestore créé pour: ${user.uid}");
        } catch (e) {
          print("Erreur création Firestore: $e");
          // Si Firestore échoue, on devrait peut-être supprimer l'utilisateur Auth ?
          return "Erreur lors de la création du profil";
        }

        return null;
      }
      return "Erreur lors de l'inscription";
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      return e.message;
    } catch (e) {
      print("Exception inattendue: $e");
      return "Une erreur est survenue: $e";
    }
  }

  // Connexion avec email et mot de passe
  Future<String?> signInWithEmail(String email, String password) async {
    print("=== FIREBASE SERVICE: SIGN IN ===");
    print("Email: $email");

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print("Connexion réussie");
      return null;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");

      // Traduire les erreurs courantes
      if (e.code == 'user-not-found') {
        return "Aucun utilisateur trouvé avec cet email";
      } else if (e.code == 'wrong-password') {
        return "Mot de passe incorrect";
      } else if (e.code == 'invalid-email') {
        return "Email invalide";
      } else if (e.code == 'user-disabled') {
        return "Ce compte a été désactivé";
      } else if (e.code == 'too-many-requests') {
        return "Trop de tentatives. Réessayez plus tard";
      }

      return e.message;
    } catch (e) {
      print("Exception inattendue: $e");
      return "Une erreur est survenue: $e";
    }
  }

  // Connexion avec Google
  Future<String?> signInWithGoogle() async {
    print("=== FIREBASE SERVICE: SIGN IN WITH GOOGLE ===");

    try {
      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // if (googleUser == null) {
      //   print("Utilisateur a annulé la connexion Google");
      //   return "Connexion Google annulée";
      // }

      // print("Google Sign-in réussi: ${googleUser.email}");

      // final GoogleSignInAuthentication googleAuth =
      //     await googleUser.authentication;

      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );

      // UserCredential result = await _auth.signInWithCredential(credential);
      // User? user = result.user;
      GoogleSignIn gInstance = GoogleSignIn.instance;
      await gInstance.initialize(
        serverClientId:
            "595540566419-5l41mv51v8dj7ao8d8le279d4io3qqe1.apps.googleusercontent.com",
      );
      final GoogleSignInAccount? googleUser = await gInstance.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser!.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      User? user = result.user;

      if (user != null) {
        print("Utilisateur Firebase créé/connecté: ${user.uid}");

        // Vérifier si l'utilisateur existe dans Firestore
        final docSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!docSnapshot.exists) {
          // C'est un nouvel utilisateur, créer son profil
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName ?? 'Utilisateur',
            'photoURL': user.photoURL,
            'totalBalance': 0.0,
            'monthlyBudget': 0.0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print("Profil utilisateur créé dans Firestore");
        }

        return null; // Succès
      }

      return "Erreur lors de la connexion";
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      return e.message ?? "Erreur Firebase";
    } catch (e) {
      print("Exception inattendue: $e");
      return "Une erreur est survenue: $e";
    }
  }

  Future<void> signOut() async {
    print("=== FIREBASE SERVICE: SIGN OUT ===");
    try {
      await _auth.signOut();
      print("Déconnexion réussie");
    } catch (e) {
      print("Erreur déconnexion: $e");
    }
  }

  // Récupérer les données de l'utilisateur connecté
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    print("=== FIREBASE SERVICE: GET USER DATA ===");

    final User? user = _auth.currentUser;
    if (user == null) {
      print("Aucun utilisateur connecté");
      return null;
    }

    print("Utilisateur connecté: ${user.uid}");

    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        print("Document trouvé pour: ${user.uid}");
        return doc.data() as Map<String, dynamic>;
      } else {
        print("Aucun document trouvé pour: ${user.uid}");
        return null;
      }
    } catch (e) {
      print("Erreur récupération données: $e");
      return null;
    }
  }
}
