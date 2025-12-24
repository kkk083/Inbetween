# Inbetween - Marketplace Étudiante 🎓🇲🇺

**Inbetween** est une application mobile conçue pour faciliter l'achat et la vente d'articles d'occasion entre étudiants à Maurice. Elle vise à rendre le matériel académique et technologique plus accessible tout en encourageant l'économie circulaire sur le campus.

## 🚀 Fonctionnalités Clés
- **Authentification Sécurisée :** Connexion via Firebase avec option "Mot de passe oublié".
- **Catalogue Dynamique :** Visualisation des annonces avec prix en Rs.
- **Mise en vente simplifiée :** Ajout de produits avec compression automatique des images.
- **Contact Instantané :** Boutons d'appel et redirection automatique vers WhatsApp avec message pré-rempli.
- **Gestion Vendeur :** Possibilité de modifier ou supprimer ses propres annonces.

## 🛠️ Stack Technique
- **Frontend :** [Flutter](https://flutter.dev) (Dart)
- **Backend :** [Firebase](https://firebase.google.com) (Firestore & Auth)
- **Gestion d'état :** Provider
- **Localisation :** Île Maurice (Devise : Rs, Préfixe : +230)

## 📦 Installation et Test

### Pour les utilisateurs (Android)
L'application peut être testée directement en installant le fichier APK :
1. Téléchargez le fichier `app_build/Inbetween.apk`.
2. Transférez-le sur votre smartphone Android.
3. Autorisez l'installation de sources inconnues et installez l'application.

### Pour les développeurs
Si vous souhaitez compiler le projet depuis les sources :
1. Clonez ce dépôt : `git clone [URL_DU_REPO]`
2. Installez les dépendances : `flutter pub get`
3. Connectez un appareil ou un émulateur.
4. Lancez l'application : `flutter run`

> **Note :** Un fichier `google-services.json` valide est requis dans le dossier `android/app/` pour que les services Firebase fonctionnent.

## 📐 Architecture du Projet
Le projet suit une architecture modulaire pour une meilleure maintenance :
- `lib/models/` : Modèles de données (Produits, Utilisateurs).
- `lib/providers/` : Logique métier et gestion d'état.
- `lib/screens/` : Interfaces utilisateur (Auth, Home, Details).
- `lib/services/` : Communication avec Firebase.
