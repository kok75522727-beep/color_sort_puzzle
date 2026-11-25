import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const ColorSortApp());
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
      home: const GameScreen(),
    );
  }
}

/// Copyright-Free Built-in Sound & BGM Synthesizer (MP3 ဖိုင်မလိုဘဲ အသံထွက်မည်)
class SoundEngine {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool isMuted = false;

  late Uint8List _bgmWav;
  late Uint8List _clickWav;
  late Uint8List _pourWav;
  late Uint8List _winWav;
  late Uint8List _loseWav;

  SoundEngine() {
    _bgmWav = _generateChillBgm();
    _clickWav = _generateTone(520, 0.08, volume: 0.35);
    _pourWav = _generateSweep(300, 680, 0.25, volume: 0.4);
    _winWav = _generateMelody([523.25, 659.25, 783.99, 1046.50], 0.14);
    _loseWav = _generateMelody([392.00, 349.23, 311.13, 261.63], 0.22);
  }

  Future<void> startBgm() async {
    if (isMuted) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.28);
      await _bgmPlayer.play(BytesSource(_bgmWav));
    } catch (_) {}
  }

  Future<void> toggleMute() async {
    isMuted = !isMuted;
    if (isMuted) {
      await _bgmPlayer.pause();
    } else {
      await startBgm();
    }
  }

  void playClick() => _playSfx(_clickWav);
  void playPour() => _playSfx(_pourWav);
  void playWin() => _playSfx(_winWav);
  void playLose() => _playSfx(_loseWav);

  Future<void> _playSfx(Uint8List bytes) async {
    if (isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(BytesSource(bytes));
    } catch (_) {}
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }

  // WAV Header & PCM Generator
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

  // အေးအေးဆေးဆေး နားထောင်ကောင်းမယ့် Pentatonic Ambient BGM
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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int maxCapacity = 4;

  final List<Color> palette = [
    const Color(0xFFFF3366), // Neon Red
    const Color(0xFF00D2FF), // Cyan Blue
    const Color(0xFF00E676), // Emerald Green
    const Color(0xFFFFD166), // Warm Yellow
    const Color(0xFF9D4EDD), // Royal Purple
    const Color(0xFFFF7B00), // Bright Orange
    const Color(0xFF2EC4B6), // Teal
    const Color(0xFFF72585), // Hot Pink
  ];

  late SoundEngine sound;
  late AnimationController _waveController;

  int currentLevel = 1;
  List<List<Color>> bottles = [];
  List<List<List<Color>>> history = [];

  int? selectedBottleIndex;
  int? pouringBottleIndex;
  int? hintFromIndex;
  int? hintToIndex;
  bool extraBottleUsed = false;

  // Timer & Lose State
  Timer? _countdownTimer;
  int timeLeft = 60;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    sound = SoundEngine();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadSavedLevel();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _waveController.dispose();
    sound.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLevel = prefs.getInt('saved_level') ?? 1;
    });
    _initLevel(currentLevel);
    sound.startBgm();
  }

  Future<void> _saveLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('saved_level', level);
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

    // ဖန်ခွက်အလွတ် ၂ ခွက်
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
      timeLeft = 45 + (numColors * 12); // Level မြင့်လေ အချိန်ပိုပေးမယ်
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
    sound.playLose();

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
              // TODO: နောက်ပိုင်း AdMob Rewarded Ad ချိတ်မယ့်နေရာ
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

    setState(() {
      hintFromIndex = null;
      hintToIndex = null;
    });

    if (selectedBottleIndex == null) {
      if (bottles[index].isNotEmpty) {
        sound.playClick();
        setState(() => selectedBottleIndex = index);
      }
    } else if (selectedBottleIndex == index) {
      sound.playClick();
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

      // ဖန်ခွက်စောင်းပြီး လောင်းထည့်တဲ့ Animation
      sound.playPour();
      setState(() {
        pouringBottleIndex = from;
      });

      await Future.delayed(const Duration(milliseconds: 220));

      setState(() {
        while (fromBottle.isNotEmpty &&
            fromBottle.last == topColor &&
            toBottle.length < maxCapacity) {
          toBottle.add(fromBottle.removeLast());
        }
        selectedBottleIndex = null;
        pouringBottleIndex = null;
      });

      _checkWin();
    } else {
      setState(() => selectedBottleIndex = null);
    }
  }

  void _checkWin() {
    bool won = true;
    for (var bottle in bottles) {
      if (bottle.isEmpty) continue;
      if (bottle.length != maxCapacity) {
        won = false;
        break;
      }
      Color first = bottle.first;
      if (!bottle.every((c) => c == first)) {
        won = false;
        break;
      }
    }

    if (won) {
      _countdownTimer?.cancel();
      sound.playWin();
      int nextLevel = currentLevel + 1;
      _saveLevel(nextLevel);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFFFD166), size: 52),
              SizedBox(height: 8),
              Text('LEVEL COMPLETE!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Level $currentLevel ကို အောင်မြင်စွာ ဖြတ်ကျော်နိုင်ပါပြီ 🎉',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D2FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() => currentLevel = nextLevel);
                _initLevel(currentLevel);
              },
              child: const Text('NEXT LEVEL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _undo() {
    if (history.isNotEmpty) {
      sound.playClick();
      setState(() {
        bottles = history.removeLast();
        selectedBottleIndex = null;
      });
    }
  }

  // Smart Hint (အကြံတောင်းခြင်း - Ad UI)
  void _useHint() {
    // TODO: နောက်ပိုင်း AdMob Rewarded Ad ချိတ်မယ့်နေရာ
    int? bestFrom;
    int? bestTo;

    for (int i = 0; i < bottles.length; i++) {
      if (bottles[i].isEmpty) continue;
      // ပြည့်ပြီးသား အရောင်တူခွက်ကို မရွှေ့ဘူး
      if (bottles[i].length == maxCapacity &&
          bottles[i].every((c) => c == bottles[i].first)) continue;

      Color top = bottles[i].last;
      for (int j = 0; j < bottles.length; j++) {
        if (i == j || bottles[j].length >= maxCapacity) continue;

        // အရောင်တူတဲ့ခွက်ထဲ လောင်းထည့်တာကို ဦးစားပေးမယ်
        if (bottles[j].isNotEmpty && bottles[j].last == top) {
          bestFrom = i;
          bestTo = j;
          break;
        }
      }
      if (bestFrom != null) break;
    }

    // အရောင်တူမရှိရင် ခွက်အလွတ်ထဲ ရွှေ့ဖို့ ရှာမယ်
    if (bestFrom == null) {
      for (int i = 0; i < bottles.length; i++) {
        if (bottles[i].isEmpty) continue;
        if (bottles[i].every((c) => c == bottles[i].first)) continue;
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
      sound.playClick();
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
    // TODO: နောက်ပိုင်း AdMob Rewarded Ad ချိတ်မယ့်နေရာ
    sound.playClick();
    setState(() {
      bottles.add([]);
      extraBottleUsed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    String timerText = '${(timeLeft ~/ 60).toString().padLeft(2, '0')}:${(timeLeft % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar (Sound, Level, Timer, Restart)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        sound.isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white70,
                      ),
                      onPressed: () async {
                        await sound.toggleMute();
                        setState(() {});
                      },
                    ),
                    Column(
                      children: [
                        Text(
                          'LEVEL $currentLevel',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: timeLeft <= 15
                                ? const Color(0xFFFF3366).withOpacity(0.25)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: timeLeft <= 15 ? const Color(0xFFFF3366) : Colors.white24,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                size: 16,
                                color: timeLeft <= 15 ? const Color(0xFFFF3366) : const Color(0xFF00D2FF),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                timerText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: timeLeft <= 15 ? const Color(0xFFFF3366) : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: () => _initLevel(currentLevel),
                    ),
                  ],
                ),
              ),

              // ဖန်ခွက်များ ပြသမယ့်နေရာ
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 28,
                      alignment: WrapAlignment.center,
                      children: List.generate(bottles.length, (index) => _buildBottle(index)),
                    ),
                  ),
                ),
              ),

              // အောက်ခြေ ခလုတ်များ (Undo, Hint Ad, +1 Bottle Ad)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

              // Banner Ad Placeholder UI (နောက်ပိုင်း AdMob Banner ထည့်မယ့်နေရာ)
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
    );
  }

  Widget _buildBottle(int index) {
    bool isSelected = selectedBottleIndex == index;
    bool isPouring = pouringBottleIndex == index;
    bool isHint = hintFromIndex == index || hintToIndex == index;
    List<Color> colors = bottles[index];

    Color borderColor = Colors.white54;
    if (isHint) {
      borderColor = const Color(0xFFFFD166);
    } else if (isSelected) {
      borderColor = const Color(0xFF00D2FF);
    }

    return GestureDetector(
      onTap: () => _onBottleTap(index),
      child: AnimatedRotation(
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
              width: (isSelected || isHint) ? 3 : 2,
            ),
            boxShadow: (isSelected || isHint)
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
                // အရည်အရှင် (Liquid Wave CustomPainter)
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
                // ဖန်ခွက် မှန်ရောင်ပြန် (Glass Highlight)
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
              ],
            ),
          ),
        ),
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

/// ဖန်ခွက်ထဲက ရေလှိုင်း Animation ဆွဲပေးမယ့် CustomPainter
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
        // အပေါ်ဆုံးအလွှာကို ရေလှိုင်းပုံစံ (Sine Wave) ဆွဲမယ်
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