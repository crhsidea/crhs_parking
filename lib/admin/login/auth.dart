import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:crhs_parking_app/login/google_sign_in.dart';

bool hasError;
bool done = false;

class AdminAuthService{
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _db = Firestore.instance;

  Stream<FirebaseUser> user;
  Stream<Map<String,dynamic>> profile;
  PublishSubject loading = PublishSubject();

  AdminAuthService() {
    user = _auth.onAuthStateChanged;
    profile = user.switchMap((FirebaseUser u) {
      if(u!=null) {
        return _db.collection('users').document(u.uid).snapshots().map((snap) => snap.data);
      }
      else{
        return Stream.value({

        });
      }
    });
  }
  Future<FirebaseUser> googleSignIn(String key) async {
    done = false;
    loading.add(true);
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
    final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;
    if(user.email.endsWith('@katyisd.org')||user.email=='k0910022@students.katyisd.org') {
      await updateUserData(user, key);
    }
    print(user.displayName+' has been signed in');
    loading.add(false);
    return user;
  }
  Future updateUserData(FirebaseUser user, String key) async {
    DocumentReference ref = _db.collection('admin').document(user.uid);
    await ref.setData({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'signDate': DateTime.now(),
      'key': key,
      'emailProvider': user.email.substring(user.email.indexOf('@'))
    }, merge: true).whenComplete(() {
      done = true;
      hasError = false;
    }).catchError((onError) {
      hasError = true;
      done = true;
      print('denied');
      signOut();
    });
  }

  void signOut() {
    print('signed out');
    _auth.signOut();
    _googleSignIn.signOut();
  }
}

final AdminAuthService adminAuthService = AdminAuthService();