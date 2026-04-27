import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAdtRp2xna_PxVbRiPtvXFiXhLC98OTyJ4",
      appId: "1:471265177683:web:a724992567f3d3bac3d6a6",
      messagingSenderId: "471265177683",
      projectId: "gen-lang-client-0783281423",
      authDomain: "gen-lang-client-0783281423.firebaseapp.com",
      storageBucket: "gen-lang-client-0783281423.firebasestorage.app",
    ),
  );
  runApp(const EduCintaApp());
}

class EduCintaApp extends StatelessWidget {
  const EduCintaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduCinta AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF43F5E)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          String role = 'Bintang Harapan (Siswa)';
          if (user.email == 'ahlanhabibana@gmail.com') {
            role = 'Pusat Cinta (Admin)';
          }
          await userDoc.set({
            'name': user.displayName ?? 'Bintang Baru',
            'email': user.email,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(LucideIcons.heart, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'EduCinta AI',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF881337)),
                ),
                const Text(
                  'Masuk ke Ruang Kebahagiaan Belajar',
                  style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _signInWithGoogle(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF43F5E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(LucideIcons.logIn),
                  label: const Text('Masuk dengan Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'By Design : Habib Ismail Al Qadri',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (mounted) {
          setState(() {
            _userProfile = doc.data();
            _userProfile?['id'] = doc.id;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userProfile!['fase'] == null && _userProfile!['role'] != 'Pusat Cinta (Admin)') {
      return _buildFasePicker();
    }

    final List<Widget> screens = [
      const DashboardTab(),
      const MaterialsTab(),
      const TasksTab(),
      const CommunityTab(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFFF43F5E).withOpacity(0.2),
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.layoutDashboard), label: 'Beranda'),
            NavigationDestination(icon: Icon(LucideIcons.book), label: 'Ilmu'),
            NavigationDestination(icon: Icon(LucideIcons.graduationCap), label: 'Tantangan'),
            NavigationDestination(icon: Icon(LucideIcons.messageSquare), label: 'Apresiasi'),
          ],
        ),
      ),
    );
  }

  Widget _buildFasePicker() {
    final fases = [
      {'id': 'Fase A', 'label': 'Fase A (Kelas 1-2)'},
      {'id': 'Fase B', 'label': 'Fase B (Kelas 3-4)'},
      {'id': 'Fase C', 'label': 'Fase C (Kelas 5-6)'},
      {'id': 'Fase D', 'label': 'Fase D (Kelas 7-9)'},
      {'id': 'Fase E', 'label': 'Fase E (Kelas 10)'},
      {'id': 'Fase F', 'label': 'Fase F (Kelas 11-12)'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.map, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            const Text('Pilih Fase Belajarmu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tentukan fase belajarmu agar kami dapat menyesuaikan materi EduCinta yang paling tepat untukmu.', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ...fases.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                tileColor: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(f['label']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () {
                  FirebaseFirestore.instance.collection('users').doc(_userProfile!['id']).update({'fase': f['id']});
                },
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda Kasih', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 24),
          const Text('Aktivitas Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF43F5E), Colors.orangeAccent]),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Halo, ${user?.displayName ?? 'Bintang'}!', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Selamat datang kembali di Ruang EduCinta.', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class MaterialsTab extends StatelessWidget {
  const MaterialsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruang Ilmu')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('materials').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(LucideIcons.book, color: Color(0xFFF43F5E)),
                  title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Oleh: ${data['author']}'),
                  onTap: () {
                     showModalBottomSheet(
                       context: context,
                       isScrollControlled: true,
                       builder: (context) => MaterialViewer(data: data),
                     );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MaterialViewer extends StatelessWidget {
  final Map<String, dynamic> data;
  const MaterialViewer({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(LucideIcons.book, color: Color(0xFFF43F5E)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
            ],
          ),
          const SizedBox(height: 16),
          Text(data['title'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Markdown(data: data['content']),
            ),
          ),
        ],
      ),
    );
  }
}

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tantangan')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              data['id'] = docs[index].id;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(LucideIcons.graduationCap, color: Colors.amber),
                  title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => TaskSolver(task: data),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TaskSolver extends StatefulWidget {
  final Map<String, dynamic> task;
  const TaskSolver({super.key, required this.task});
  @override
  State<TaskSolver> createState() => _TaskSolverState();
}

class _TaskSolverState extends State<TaskSolver> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isLoading = true);

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: 'AIzaSyAdtRp2xna_PxVbRiPtvXFiXhLC98OTyJ4');
    final prompt = "Tantangan: ${widget.task['content']}. Jawaban Siswa: ${_controller.text}. Berikan umpan balik yang lembut, memotivasi, dan fokus pada nilai cinta serta pengembangan karakter. Jangan hanya memberi nilai, berikan hikmah.";
    
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final feedback = response.text ?? "Terima kasih atas refleksimu.";

      await FirebaseFirestore.instance.collection('submissions').add({
        'taskId': widget.task['id'],
        'studentName': FirebaseAuth.instance.currentUser?.displayName,
        'studentId': FirebaseAuth.instance.currentUser?.uid,
        'answer': _controller.text,
        'feedback': feedback,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refleksi Terkirim!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(LucideIcons.clipboardList, color: Color(0xFFF43F5E)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Ruang Refleksi Hati', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            child: Markdown(data: widget.task['content']),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Tuliskan Refleksi Kasihmu...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text('Kirim Refleksi'),
              ),
        ],
      ),
    );
  }
}

class CommunityTab extends StatelessWidget {
  const CommunityTab({super.key});
  @override
  Widget build(BuildContext context) {
    final TextEditingController msgController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Kotak Apresiasi')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('messages').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Align(
                      alignment: data['senderId'] == FirebaseAuth.instance.currentUser?.uid ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: data['senderId'] == FirebaseAuth.instance.currentUser?.uid ? const Color(0xFFFFF1F2) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['sender'] ?? 'Anonim', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(data['text'] ?? ''),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: msgController, decoration: const InputDecoration(hintText: 'Tulis apresiasi...'))),
                IconButton(
                  icon: const Icon(LucideIcons.send, color: Color(0xFFF43F5E)),
                  onPressed: () {
                    if (msgController.text.isNotEmpty) {
                      FirebaseFirestore.instance.collection('messages').add({
                        'text': msgController.text,
                        'sender': FirebaseAuth.instance.currentUser?.displayName,
                        'senderId': FirebaseAuth.instance.currentUser?.uid,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      msgController.clear();
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
