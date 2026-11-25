import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const ColorSortApp());
}

class AppThemeData {
  final String name;
  final int price;
  final List<Color> bgGradient;
  final Color accentColor;

  const AppThemeData({
    required this.name,
    required this.price,
    required this.bgGradient,
    required this.accentColor,
  });
}

const List<AppThemeData> appThemes = [
  AppThemeData(
    name: 'Midnight Neon',
    price: 0,
    bgGradient: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
    accentColor: Color(0xFF00D2FF),
  ),
  AppThemeData(
    name: 'Galaxy Purple',
    price: 100,
    bgGradient: [Color(0xFF1A0B2E), Color(0xFF3B0764), Color(0xFF1A0B2E)],
    accentColor: Color(0xFFE879F9),
  ),
  AppThemeData(
    name: 'Sunset Glow',
    price: 150,
    bgGradient: [Color(0xFF2A0800), Color(0xFF7C2D12), Color(0xFF1C0A00)],
    accentColor: Color(0xFFFF9F1C),
  ),
  AppThemeData(
    name: 'Emerald Forest',
    price: 200,
    bgGradient: [Color(0xFF022C22), Color(0xFF064E3B), Color(0xFF022C22)],
    accentColor: Color(0xFF34D399),
  ),
];

/// Global Sound Engine
class SoundEngine {
  static final SoundEngine instance = SoundEngine._internal();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool isMuted = false;
  bool _bgmStarted = false;

  late Uint8List _bgmWav;
  late Uint8List _clickWav;
  late Uint8List _pourWav;
  late Uint8List _bottleDoneWav;
  late Uint8List _winWav;
  late Uint8List _loseWav;

  SoundEngine._internal() {
    _bgmWav = _generateChillBgm();
    _clickWav = _generateTone(520, 0.08, volume: 0.35);
    _pourWav = _generateSweep(300, 680, 0.25, volume: 0.4);
    _bottleDoneWav = _generateMelody([659.25, 880.00], 0.10);
    _winWav = _generateMelody([523.25, 659.25, 783.99, 1046.50], 0.14);
    _loseWav = _generateMelody([392.00, 349.23, 311.13, 261.63], 0.22);
  }

  Future<void> startBgm() async {
    if (isMuted || _bgmStarted) return;
    try {
      _bgmStarted = true;
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.25);
      await _bgmPlayer.play(BytesSource(_bgmWav));
    } catch (_) {
      _bgmStarted = false;
    }
  }

  Future<void> toggleMute() async {
    isMuted = !isMuted;
    if (isMuted) {
      await _bgmPlayer.pause();
    } else {
      _bgmStarted = false;
      await startBgm();
    }
  }

  void playClick() => _playSfx(_clickWav);
  void playPour() => _playSfx(_pourWav);
  void playBottleDone() => _playSfx(_bottleDoneWav);
  void playWin() => _playSfx(_winWav);
  void playLose() => _playSfx(_loseWav);

  Future<void> _playSfx(Uint8List bytes) async {
    if (isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(BytesSource(bytes));
    } catch (_) {}
  }

  Uint8List _encodeWav(List<int> samples, int sampleRate) {
    final byteData = ByteData(44 + samples.length * 2);
    void writeStr(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        byteData.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    byteData.setUint32(4, 36 + samples.length * 2, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    byteData.setUint32(40, samples.length * 2, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      byteData.setInt16(44 + i * 2, samples[i].clamp(-32767, 32767), Endian.little);
    }
    return byteData.buffer.asUint8List();
  }

  Uint8List _generateTone(double freq, double dur, {double volume = 0.4}) {
    const sr = 22050;
    final count = (sr * dur).toInt();
    final samples = List<int>.generate(count, (i) {
      final t = i / sr;
      final env = (1 - i / count);
      return (sin(2 * pi * freq * t) * 32767 * volume * env).toInt();
    });
    return _encodeWav(samples, sr);
  }

  Uint8List _generateSweep(double f1, double f2, double dur, {double volume = 0.4}) {
    const sr = 22050;
    final count = (sr * dur).toInt();
    final samples = List<int>.generate(count, (i) {
      final progress = i / count;
      final freq = f1 + (f2 - f1) * progress;
      final env = sin(pi * progress);
      return (sin(2 * pi * freq * (i / sr)) * 32767 * volume * env).toInt();
    });
    return _encodeWav(samples, sr);
  }

  Uint8List _generateMelody(List<double> freqs, double noteDur) {
    const sr = 22050;
    final List<int> all = [];
    for (final f in freqs) {
      final count = (sr * noteDur).toInt();
      for (int i = 0; i < count; i++) {
        final t = i / sr;
        final env = (1 - i / count);
        all.add((sin(2 * pi * f * t) * 32767 * 0.35 * env).toInt());
      }
    }
    return _encodeWav(all, sr);
  }

  Uint8List _generateChillBgm() {
    const sr = 16000;
    final notes = [261.63, 329.63, 392.00, 440.00, 392.00, 329.63, 293.66, 392.00];
    const noteDur = 0.65;
    final List<int> all = [];
    for (final f in notes) {
      final count = (sr * noteDur).toInt();
      for (int i = 0; i < count; i++) {
        final t = i / sr;
        final env = sin(pi * (i / count));
        final val = (sin(2 * pi * f * t) * 0.6 + sin(2 * pi * (f / 2) * t) * 0.4);
        all.add((val * 32767 * 0.25 * env).toInt());
      }
    }
    return _encodeWav(all, sr);
  }
}

class ColorSortApp extends StatelessWidget {
  const ColorSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Sort Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const HomeScreen(),
    );
  }
}

/// ================= HOME SCREEN (START MENU) =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int savedLevel = 1;
  int coins = 50;
  int selectedThemeIndex = 0;
  List<String> unlockedThemes = ['0'];

  @override
  void initState() {
    super.initState();
    _loadData();
    SoundEngine.instance.startBgm();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedLevel = prefs.getInt('saved_level') ?? 1;
      coins = prefs.getInt('coins') ?? 50;
      selectedThemeIndex = prefs.getInt('selected_theme') ?? 0;
      unlockedThemes = prefs.getStringList('unlocked_themes') ?? ['0'];
    });
  }

  void _openThemeShop() {
    SoundEngine.instance.playClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'THEME SHOP 🎨',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(appThemes.length, (i) {
                    final theme = appThemes[i];
                    final isUnlocked = unlockedThemes.contains(i.toString());
                    final isSelected = selectedThemeIndex == i;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: theme.bgGradient),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? theme.accentColor : Colors.white24,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            theme.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors.white24
                                  : (isUnlocked ? theme.accentColor : Colors.amber),
                              foregroundColor: isSelected ? Colors.white : Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              if (isUnlocked) {
                                SoundEngine.instance.playClick();
                                await prefs.setInt('selected_theme', i);
                                setState(() => selectedThemeIndex = i);
                                setModalState(() {});
                              } else if (coins >= theme.price) {
                                SoundEngine.instance.playWin();
                                coins -= theme.price;
                                unlockedThemes.add(i.toString());
                                await prefs.setInt('coins', coins);
                                await prefs.setStringList('unlocked_themes', unlockedThemes);
                                await prefs.setInt('selected_theme', i);
                                setState(() => selectedThemeIndex = i);
                                setModalState(() {});
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coins မလောက်သေးပါ။ Level တွေ ထပ်ဆော့ပြီး စုပါ။')),
                                );
                              }
                            },
                            child: Text(
                              isSelected
                                  ? 'Equipped'
                                  : (isUnlocked ? 'Use' : '${theme.price} 🪙'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = appThemes[selectedThemeIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '$coins',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        SoundEngine.instance.isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        await SoundEngine.instance.toggleMute();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Logo Title
              Icon(Icons.water_drop_rounded, size: 80, color: theme.accentColor),
              const SizedBox(height: 16),
              const Text(
                'COLOR SORT',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
              Text(
                'PUZZLE PRO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: theme.accentColor,
                ),
              ),

              const SizedBox(height: 50),

              // PLAY Button
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  SoundEngine.instance.playClick();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(theme: theme),
                    ),
                  );
                  _loadData(); // ပြန်ထွက်လာရင် Coins နဲ့ Level Update လုပ်မယ်
                },
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.accentColor, theme.accentColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: theme.accentColor.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'PLAY',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'LEVEL $savedLevel',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Theme Shop Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: _openThemeShop,
                icon: const Icon(Icons.palette_outlined),
                label: const Text('THEMES SHOP', style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= GAME SCREEN =================
class GameScreen extends StatefulWidget {
  final AppThemeData theme;
  const GameScreen({super.key, required this.theme});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int maxCapacity = 4;

  final List<Color> palette = [
    const Color(0xFFFF3366),
    const Color(0xFF00D2FF),
    const Color(0xFF00E676),
    const Color(0xFFFFD166),
    const Color(0xFF9D4EDD),
    const Color(0xFFFF7B00),
    const Color(0xFF2EC4B6),
    const Color(0xFFF72585),
  ];

  late AnimationController _waveController;
  late AnimationController _confettiController;

  int currentLevel = 1;
  int coins = 50;
  List<List<Color>> bottles = [];
  List<List<List<Color>>> history = [];

  int? selectedBottleIndex;
  int? pouringBottleIndex;
  int? hintFromIndex;
  int? hintToIndex;
  bool extraBottleUsed = false;
  bool showConfetti = false;

  Timer? _countdownTimer;
  int timeLeft = 60;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _loadGameData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _waveController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLevel = prefs.getInt('saved_level') ?? 1;
      coins = prefs.getInt('coins') ?? 50;
    });
    _initLevel(currentLevel);
  }

  Future<void> _saveProgress(int level, int newCoins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_level', level);
    await prefs.setInt('coins', newCoins);
  }

  bool _isBottleComplete(List<Color> bottle) {
    return bottle.length == maxCapacity && bottle.every((c) => c == bottle.first);
  }

  void _initLevel(int level) {
    _countdownTimer?.cancel();

    int numColors = min(3 + (level ~/ 2), palette.length);
    List<Color> allDrops = [];

    for (int i = 0; i < numColors; i++) {
      for (int j = 0; j < maxCapacity; j++) {
        allDrops.add(palette[i]);
      }
    }

    allDrops.shuffle(Random());

    List<List<Color>> newBottles = [];
    for (int i = 0; i < numColors; i++) {
      newBottles.add(allDrops.sublist(i * maxCapacity, (i + 1) * maxCapacity));
    }

    newBottles.add([]);
    newBottles.add([]);

    setState(() {
      bottles = newBottles;
      history.clear();
      selectedBottleIndex = null;
      pouringBottleIndex = null;
      hintFromIndex = null;
      hintToIndex = null;
      extraBottleUsed = false;
      isGameOver = false;
      showConfetti = false;
      timeLeft = 45 + (numColors * 12);
    });

    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        timer.cancel();
        _triggerGameOver();
      }
    });
  }

  void _triggerGameOver() {
    if (isGameOver) return;
    setState(() => isGameOver = true);
    HapticFeedback.heavyImpact();
    SoundEngine.instance.playLose();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.timer_off, color: Color(0xFFFF3366), size: 48),
            SizedBox(height: 8),
            Text('Time\'s Up! 😢', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'အချိန်ပြည့်သွားပါပြီ။ ကြော်ငြာကြည့်ပြီး အချိန် +30s ထပ်ယူမလား?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initLevel(currentLevel);
            },
            child: const Text('Retry', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isGameOver = false;
                timeLeft = 30;
              });
              _startTimer();
            },
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('+30s (Ad)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onBottleTap(int index) {
    if (isGameOver || pouringBottleIndex != null) return;

    // ပြည့်ပြီးသား အဖုံးပိတ်ခွက်ကို နှိပ်လို့မရအောင် ကာထားမယ်
    if (_isBottleComplete(bottles[index])) return;

    setState(() {
      hintFromIndex = null;
      hintToIndex = null;
    });

    if (selectedBottleIndex == null) {
      if (bottles[index].isNotEmpty) {
        HapticFeedback.lightImpact();
        SoundEngine.instance.playClick();
        setState(() => selectedBottleIndex = index);
      }
    } else if (selectedBottleIndex == index) {
      HapticFeedback.lightImpact();
      SoundEngine.instance.playClick();
      setState(() => selectedBottleIndex = null);
    } else {
      _pourWater(selectedBottleIndex!, index);
    }
  }

  Future<void> _pourWater(int from, int to) async {
    List<Color> fromBottle = bottles[from];
    List<Color> toBottle = bottles[to];

    if (fromBottle.isEmpty || toBottle.length >= maxCapacity) {
      setState(() => selectedBottleIndex = null);
      return;
    }

    Color topColor = fromBottle.last;

    if (toBottle.isEmpty || toBottle.last == topColor) {
      history.add(bottles.map((b) => List<Color>.from(b)).toList());

      HapticFeedback.mediumImpact();
      SoundEngine.instance.playPour();
      setState(() => pouringBottleIndex = from);

      await Future.delayed(const Duration(milliseconds: 220));

      bool becameComplete = false;
      setState(() {
        while (fromBottle.isNotEmpty &&
            fromBottle.last == topColor &&
            toBottle.length < maxCapacity) {
          toBottle.add(fromBottle.removeLast());
        }
        if (_isBottleComplete(toBottle)) {
          becameComplete = true;
        }
        selectedBottleIndex = null;
        pouringBottleIndex = null;
      });

      if (becameComplete) {
        HapticFeedback.heavyImpact();
        SoundEngine.instance.playBottleDone();
      }

      _checkWin();
    } else {
      setState(() => selectedBottleIndex = null);
    }
  }

  void _checkWin() {
    bool won = true;
    for (var bottle in bottles) {
      if (bottle.isEmpty) continue;
      if (!_isBottleComplete(bottle)) {
        won = false;
        break;
      }
    }

    if (won) {
      _countdownTimer?.cancel();
      HapticFeedback.heavyImpact();
      SoundEngine.instance.playWin();

      setState(() => showConfetti = true);
      _confettiController.forward(from: 0);

      int nextLevel = currentLevel + 1;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFFFD166), size: 54),
              SizedBox(height: 8),
              Text('LEVEL COMPLETE!', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Level $currentLevel ကို အောင်မြင်စွာ ဖြတ်ကျော်နိုင်ပါပြီ 🎉', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Reward: +20 🪙',
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                int updatedCoins = coins + 20;
                _saveProgress(nextLevel, updatedCoins);
                setState(() {
                  currentLevel = nextLevel;
                  coins = updatedCoins;
                });
                _initLevel(currentLevel);
              },
              child: const Text('Next (+20 🪙)', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // TODO: AdMob Rewarded Ad for 2x Coins
                Navigator.pop(context);
                int updatedCoins = coins + 40;
                _saveProgress(nextLevel, updatedCoins);
                setState(() {
                  currentLevel = nextLevel;
                  coins = updatedCoins;
                });
                _initLevel(currentLevel);
              },
              icon: const Icon(Icons.play_circle_fill, size: 18),
              label: const Text('2x (+40 🪙 Ad)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _undo() {
    if (history.isNotEmpty) {
      HapticFeedback.lightImpact();
      SoundEngine.instance.playClick();
      setState(() {
        bottles = history.removeLast();
        selectedBottleIndex = null;
      });
    }
  }

  void _useHint() {
    int? bestFrom;
    int? bestTo;

    for (int i = 0; i < bottles.length; i++) {
      if (bottles[i].isEmpty || _isBottleComplete(bottles[i])) continue;
      Color top = bottles[i].last;
      for (int j = 0; j < bottles.length; j++) {
        if (i == j || bottles[j].length >= maxCapacity) continue;
        if (bottles[j].isNotEmpty && bottles[j].last == top) {
          bestFrom = i;
          bestTo = j;
          break;
        }
      }
      if (bestFrom != null) break;
    }

    if (bestFrom == null) {
      for (int i = 0; i < bottles.length; i++) {
        if (bottles[i].isEmpty || bottles[i].every((c) => c == bottles[i].first)) continue;
        for (int j = 0; j < bottles.length; j++) {
          if (bottles[j].isEmpty) {
            bestFrom = i;
            bestTo = j;
            break;
          }
        }
        if (bestFrom != null) break;
      }
    }

    if (bestFrom != null && bestTo != null) {
      HapticFeedback.mediumImpact();
      SoundEngine.instance.playClick();
      setState(() {
        hintFromIndex = bestFrom;
        hintToIndex = bestTo;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ရွှေ့စရာမရှိတော့ပါ။ +1 Bottle ယူပါ သို့မဟုတ် Restart နှိပ်ပါ။')),
      );
    }
  }

  void _addExtraBottle() {
    if (extraBottleUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ဒီ Level အတွက် ဖန်ခွက်အပို ယူပြီးပါပြီ။')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    SoundEngine.instance.playClick();
    setState(() {
      bottles.add([]);
      extraBottleUsed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    String timerText = '${(timeLeft ~/ 60).toString().padLeft(2, '0')}:${(timeLeft % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.theme.bgGradient,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.home_rounded, color: Colors.white70, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Column(
                          children: [
                            Text(
                              'LEVEL $currentLevel',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: timeLeft <= 15
                                        ? const Color(0xFFFF3366).withOpacity(0.25)
                                        : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: timeLeft <= 15 ? const Color(0xFFFF3366) : Colors.white24,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        size: 14,
                                        color: timeLeft <= 15 ? const Color(0xFFFF3366) : widget.theme.accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timerText,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: timeLeft <= 15 ? const Color(0xFFFF3366) : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '$coins 🪙',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white70, size: 26),
                          onPressed: () => _initLevel(currentLevel),
                        ),
                      ],
                    ),
                  ),

                  // ဖန်ခွက်များ
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 18,
                          runSpacing: 32,
                          alignment: WrapAlignment.center,
                          children: List.generate(bottles.length, (index) => _buildBottle(index)),
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _actionButton(
                          icon: Icons.undo,
                          label: 'Undo',
                          color: const Color(0xFF334155),
                          onTap: _undo,
                        ),
                        _actionButton(
                          icon: Icons.lightbulb,
                          label: 'Hint',
                          isAd: true,
                          color: const Color(0xFFD97706),
                          onTap: _useHint,
                        ),
                        _actionButton(
                          icon: Icons.add_box_rounded,
                          label: '+1 Bottle',
                          isAd: true,
                          color: const Color(0xFF0284C7),
                          onTap: _addExtraBottle,
                        ),
                      ],
                    ),
                  ),

                  // Banner Ad Placeholder UI
                  Container(
                    height: 52,
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AD BANNER SPACE (AdMob Ready)',
                      style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti Overlay on Win
          if (showConfetti)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: ConfettiPainter(progress: _confettiController.value),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottle(int index) {
    bool isSelected = selectedBottleIndex == index;
    bool isPouring = pouringBottleIndex == index;
    bool isHint = hintFromIndex == index || hintToIndex == index;
    List<Color> colors = bottles[index];
    bool isComplete = _isBottleComplete(colors);

    Color borderColor = Colors.white54;
    if (isComplete) {
      borderColor = const Color(0xFF00E676);
    } else if (isHint) {
      borderColor = const Color(0xFFFFD166);
    } else if (isSelected) {
      borderColor = widget.theme.accentColor;
    }

    return GestureDetector(
      onTap: () => _onBottleTap(index),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedRotation(
            turns: isPouring ? 0.08 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              transform: Matrix4.translationValues(0, (isSelected || isPouring) ? -22 : 0, 0),
              width: 58,
              height: 174,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: borderColor,
                  width: (isSelected || isHint || isComplete) ? 3 : 2,
                ),
                boxShadow: (isSelected || isHint || isComplete)
                    ? [BoxShadow(color: borderColor.withOpacity(0.45), blurRadius: 14, spreadRadius: 1)]
                    : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(58, 174),
                          painter: LiquidBottlePainter(
                            colors: colors,
                            maxCapacity: maxCapacity,
                            wavePhase: _waveController.value * 2 * pi,
                          ),
                        );
                      },
                    ),
                    // Glass Highlight
                    Positioned(
                      left: 6,
                      top: 12,
                      bottom: 20,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    // Complete Checkmark Overlay
                    if (isComplete)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Color(0xFF00E676), size: 24),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ဖန်ခွက်ပြည့်သွားရင် အပေါ်မှာ အဖုံး (Cork) ပိတ်သွားမယ့် Effect
          if (isComplete)
            Positioned(
              top: -12,
              child: Container(
                width: 34,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  border: Border.all(color: const Color(0xFFFFD166), width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isAd = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isAd)
            Positioned(
              top: -8,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3366),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LiquidBottlePainter extends CustomPainter {
  final List<Color> colors;
  final int maxCapacity;
  final double wavePhase;

  LiquidBottlePainter({
    required this.colors,
    required this.maxCapacity,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final double layerHeight = (size.height - 16) / maxCapacity;

    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()..color = colors[i];
      final double bottomY = size.height - (i * layerHeight);
      final double topY = bottomY - layerHeight;

      final bool isTopLayer = (i == colors.length - 1);

      if (!isTopLayer) {
        canvas.drawRect(Rect.fromLTRB(0, topY, size.width, bottomY + 1), paint);
      } else {
        final path = Path();
        path.moveTo(0, bottomY + 1);
        path.lineTo(0, topY);

        for (double x = 0; x <= size.width; x++) {
          final y = topY + sin((x / size.width * 2 * pi) + wavePhase) * 3.5;
          path.lineTo(x, y);
        }

        path.lineTo(size.width, bottomY + 1);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LiquidBottlePainter oldDelegate) => true;
}

/// Level နိုင်သွားရင် ကျလာမယ့် စက္ကူရောင်စုံ (Confetti Painter)
class ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _rng = Random(42);
  final List<Color> _colors = [
    const Color(0xFFFF3366),
    const Color(0xFF00D2FF),
    const Color(0xFF00E676),
    const Color(0xFFFFD166),
    const Color(0xFFE879F9),
  ];

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 65; i++) {
      final startX = _rng.nextDouble() * size.width;
      final speed = 0.6 + _rng.nextDouble() * 0.8;
      final y = (progress * size.height * 1.4 * speed) - (_rng.nextDouble() * 200);
      final x = startX + sin(progress * 10 + i) * 25;

      if (y > 0 && y < size.height) {
        final paint = Paint()
          ..color = _colors[i % _colors.length].withOpacity((1 - progress).clamp(0.0, 1.0));
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * 8 + i);
        canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 12), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}