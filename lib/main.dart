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

/// ================= LANGUAGE HELPER (EN / MY) =================
class Lang {
  static bool isMy = false;

  static String t(String key) {
    final map = isMy ? _my : _en;
    return map[key] ?? key;
  }

  static const Map<String, String> _en = {
    'play': 'PLAY',
    'level': 'LEVEL',
    'shop': 'SHOP',
    'daily': 'DAILY',
    'themes': 'THEMES',
    'bottles': 'BOTTLES',
    'equipped': 'Equipped',
    'use': 'Use',
    'not_enough_coins': 'Not enough coins! Play more levels.',
    'undo': 'Undo',
    'hint': 'Hint',
    'add_bottle': '+1 Bottle',
    'times_up': 'Time\'s Up! 😢',
    'times_up_msg': 'Out of time! Watch an Ad for +30s?',
    'no_moves': 'No Moves Left! 🤯',
    'no_moves_msg': 'You are stuck! Add an extra bottle to continue.',
    'retry': 'Retry',
    'level_complete': 'LEVEL COMPLETE!',
    'reward': 'Reward',
    'next': 'Next',
    'settings': 'SETTINGS',
    'music': 'Background Music',
    'sfx': 'Sound Effects',
    'vibration': 'Vibration',
    'privacy': 'Privacy Policy',
    'privacy_msg': 'We respect your privacy. Game progress and coins are stored locally on your device. Ads may be served by Google AdMob.',
    'close': 'Close',
    'daily_title': 'DAILY REWARD 🎁',
    'daily_claimed': 'Come back tomorrow for your next reward!',
    'claim': 'Claim +50 🪙',
    'claim_2x': '2x (+100 🪙 Ad)',
    'extra_used': 'Extra bottle already used for this level!',
    'mystery_badge': 'MYSTERY MODE',
  };

  static const Map<String, String> _my = {
    'play': 'ကစားမည်',
    'level': 'အဆင့်',
    'shop': 'ဆိုင်',
    'daily': 'လက်ဆောင်',
    'themes': 'နောက်ခံများ',
    'bottles': 'ပုလင်းပုံစံ',
    'equipped': 'သုံးနေသည်',
    'use': 'ရွေးမည်',
    'not_enough_coins': 'Coins မလောက်သေးပါ။ Level တွေ ထပ်ဆော့ပြီး စုပါ။',
    'undo': 'နောက်ပြန်',
    'hint': 'အကြံယူ',
    'add_bottle': '+၁ ခွက်',
    'times_up': 'အချိန်ပြည့်သွားပြီ 😢',
    'times_up_msg': 'ကြော်ငြာကြည့်ပြီး အချိန် +30s ထပ်ယူမလား?',
    'no_moves': 'ရွှေ့စရာမရှိတော့ပါ 🤯',
    'no_moves_msg': 'ပိတ်မိသွားပါပြီ။ ဖန်ခွက်အပိုယူပြီး ဆက်ဆော့မလား?',
    'retry': 'ပြန်ဆော့မည်',
    'level_complete': 'အောင်မြင်ပါပြီ!',
    'reward': 'ဆုကြေး',
    'next': 'နောက်အဆင့်',
    'settings': 'ဆက်တင်များ',
    'music': 'နောက်ခံတီးလုံး',
    'sfx': 'ဂိမ်းအသံများ',
    'vibration': 'တုန်ခါမှု (Vibration)',
    'privacy': 'Privacy Policy',
    'privacy_msg': 'သင့်ကိုယ်ရေးအချက်အလက်ကို လေးစားပါသည်။ Level နှင့် Coins များကို သင့်ဖုန်းထဲတွင်သာ သိမ်းဆည်းထားပါသည်။',
    'close': 'ပိတ်မည်',
    'daily_title': 'နေ့စဉ်လက်ဆောင် 🎁',
    'daily_claimed': 'ဒီနေ့အတွက် ယူပြီးပါပြီ။ မနက်ဖြန် ပြန်လာယူပါ။',
    'claim': 'ယူမည် (+50 🪙)',
    'claim_2x': '၂ ဆယူ (+100 🪙 Ad)',
    'extra_used': 'ဒီ Level အတွက် ဖန်ခွက်အပို ယူပြီးပါပြီ။',
    'mystery_badge': 'လျှို့ဝှက်အရောင် (?)',
  };
}

/// ================= THEMES & BOTTLE SKINS =================
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

class BottleSkinData {
  final String name;
  final int price;
  final double bottomRadius;
  final double topRadius;
  final bool hasNeonGlow;

  const BottleSkinData({
    required this.name,
    required this.price,
    required this.bottomRadius,
    required this.topRadius,
    this.hasNeonGlow = false,
  });
}

const List<BottleSkinData> bottleSkins = [
  BottleSkinData(name: 'Classic Tube', price: 0, bottomRadius: 26, topRadius: 6),
  BottleSkinData(name: 'Potion Flask', price: 100, bottomRadius: 34, topRadius: 12),
  BottleSkinData(name: 'Crystal Box', price: 150, bottomRadius: 8, topRadius: 4),
  BottleSkinData(name: 'Neon Cyber', price: 200, bottomRadius: 22, topRadius: 8, hasNeonGlow: true),
];

/// ================= SOUND & SETTINGS ENGINE =================
class SoundEngine {
  static final SoundEngine instance = SoundEngine._internal();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool musicOn = true;
  bool sfxOn = true;
  bool vibrationOn = true;
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
    if (!musicOn || _bgmStarted) return;
    try {
      _bgmStarted = true;
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.25);
      // ကိုယ်ပိုင် assets/audio/bgm.mp3 ရှိရင် အရင်ဖွင့်မယ်၊ မရှိရင် Built-in ဖွင့်မယ်
      try {
        await _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
      } catch (_) {
        await _bgmPlayer.play(BytesSource(_bgmWav));
      }
    } catch (_) {
      _bgmStarted = false;
    }
  }

  Future<void> setMusic(bool on) async {
    musicOn = on;
    if (!musicOn) {
      await _bgmPlayer.pause();
    } else {
      _bgmStarted = false;
      await startBgm();
    }
  }

  void vibrateLight() {
    if (vibrationOn) HapticFeedback.lightImpact();
  }

  void vibrateMedium() {
    if (vibrationOn) HapticFeedback.mediumImpact();
  }

  void vibrateHeavy() {
    if (vibrationOn) HapticFeedback.heavyImpact();
  }

  void playClick() => _playSfx(_clickWav);
  void playPour() => _playSfx(_pourWav);
  void playBottleDone() => _playSfx(_bottleDoneWav);
  void playWin() => _playSfx(_winWav);
  void playLose() => _playSfx(_loseWav);

  Future<void> _playSfx(Uint8List bytes) async {
    if (!sfxOn) return;
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

/// ================= MAIN APP =================
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

/// ================= ANIMATED BOKEH BACKGROUND =================
class BokehBackground extends StatefulWidget {
  final List<Color> gradient;
  final Color accent;
  final Widget child;

  const BokehBackground({
    super.key,
    required this.gradient,
    required this.accent,
    required this.child,
  });

  @override
  State<BokehBackground> createState() => _BokehBackgroundState();
}

class _BokehBackgroundState extends State<BokehBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.gradient,
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _BokehPainter(progress: _ctrl.value, color: widget.accent),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _BokehPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Random _rng = Random(99);

  _BokehPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 14; i++) {
      final baseX = _rng.nextDouble() * size.width;
      final baseY = _rng.nextDouble() * size.height;
      final radius = 12.0 + _rng.nextDouble() * 34.0;
      final dy = (baseY - progress * size.height * (0.3 + (i % 3) * 0.2)) % size.height;
      final dx = baseX + sin(progress * 2 * pi + i) * 18;

      final paint = Paint()
        ..color = color.withOpacity(0.06 + (i % 3) * 0.02)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(dx, dy < 0 ? dy + size.height : dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BokehPainter oldDelegate) => true;
}

/// ================= HOME SCREEN =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int savedLevel = 1;
  int coins = 50;
  int selectedThemeIndex = 0;
  int selectedBottleIndex = 0;
  List<String> unlockedThemes = ['0'];
  List<String> unlockedBottles = ['0'];
  bool canClaimDaily = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastClaim = prefs.getString('last_daily_claim') ?? '';

    Lang.isMy = prefs.getBool('is_myanmar') ?? false;
    SoundEngine.instance.musicOn = prefs.getBool('music_on') ?? true;
    SoundEngine.instance.sfxOn = prefs.getBool('sfx_on') ?? true;
    SoundEngine.instance.vibrationOn = prefs.getBool('vib_on') ?? true;

    setState(() {
      savedLevel = prefs.getInt('saved_level') ?? 1;
      coins = prefs.getInt('coins') ?? 50;
      selectedThemeIndex = prefs.getInt('selected_theme') ?? 0;
      selectedBottleIndex = prefs.getInt('selected_bottle') ?? 0;
      unlockedThemes = prefs.getStringList('unlocked_themes') ?? ['0'];
      unlockedBottles = prefs.getStringList('unlocked_bottles') ?? ['0'];
      canClaimDaily = lastClaim != today;
    });

    SoundEngine.instance.startBgm();
  }

  Future<void> _toggleLanguage() async {
    SoundEngine.instance.vibrateLight();
    SoundEngine.instance.playClick();
    final prefs = await SharedPreferences.getInstance();
    setState(() => Lang.isMy = !Lang.isMy);
    await prefs.setBool('is_myanmar', Lang.isMy);
  }

  void _openDailyReward() {
    SoundEngine.instance.vibrateLight();
    SoundEngine.instance.playClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(Lang.t('daily_title'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          canClaimDaily ? '+50 🪙' : Lang.t('daily_claimed'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: canClaimDaily ? 28 : 15,
            fontWeight: FontWeight.bold,
            color: canClaimDaily ? Colors.amber : Colors.white70,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: canClaimDaily
            ? [
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final today = DateTime.now().toIso8601String().substring(0, 10);
                    coins += 50;
                    await prefs.setInt('coins', coins);
                    await prefs.setString('last_daily_claim', today);
                    SoundEngine.instance.playWin();
                    setState(() => canClaimDaily = false);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(Lang.t('claim'), style: const TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final today = DateTime.now().toIso8601String().substring(0, 10);
                    coins += 100;
                    await prefs.setInt('coins', coins);
                    await prefs.setString('last_daily_claim', today);
                    SoundEngine.instance.playWin();
                    setState(() => canClaimDaily = false);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(Lang.t('claim_2x'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(Lang.t('close')),
                ),
              ],
      ),
    );
  }

  void _openSettings() {
    SoundEngine.instance.vibrateLight();
    SoundEngine.instance.playClick();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(Lang.t('settings'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(Lang.t('music')),
                  value: SoundEngine.instance.musicOn,
                  activeColor: const Color(0xFF00D2FF),
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('music_on', val);
                    await SoundEngine.instance.setMusic(val);
                    setDialogState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(Lang.t('sfx')),
                  value: SoundEngine.instance.sfxOn,
                  activeColor: const Color(0xFF00D2FF),
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('sfx_on', val);
                    SoundEngine.instance.sfxOn = val;
                    setDialogState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(Lang.t('vibration')),
                  value: SoundEngine.instance.vibrationOn,
                  activeColor: const Color(0xFF00D2FF),
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('vib_on', val);
                    SoundEngine.instance.vibrationOn = val;
                    setDialogState(() {});
                  },
                ),
                const Divider(color: Colors.white24),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        title: Text(Lang.t('privacy')),
                        content: Text(Lang.t('privacy_msg')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text(Lang.t('close'))),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
                  label: Text(Lang.t('privacy'), style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(Lang.t('close'))),
            ],
          );
        },
      ),
    );
  }

  void _openShop() {
    SoundEngine.instance.vibrateLight();
    SoundEngine.instance.playClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        int tab = 0; // 0 = Themes, 1 = Bottles
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
                      Text('${Lang.t('shop')} 🛍️', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text('$coins 🪙', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tab == 0 ? const Color(0xFF00D2FF) : Colors.white12,
                            foregroundColor: tab == 0 ? Colors.black : Colors.white,
                          ),
                          onPressed: () => setModalState(() => tab = 0),
                          child: Text(Lang.t('themes'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tab == 1 ? const Color(0xFF00D2FF) : Colors.white12,
                            foregroundColor: tab == 1 ? Colors.black : Colors.white,
                          ),
                          onPressed: () => setModalState(() => tab = 1),
                          child: Text(Lang.t('bottles'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (tab == 0)
                    ...List.generate(appThemes.length, (i) {
                      final theme = appThemes[i];
                      final isUnlocked = unlockedThemes.contains(i.toString());
                      final isSelected = selectedThemeIndex == i;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: theme.bgGradient),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? theme.accentColor : Colors.white24, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(theme.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.white24 : (isUnlocked ? theme.accentColor : Colors.amber),
                                foregroundColor: isSelected ? Colors.white : Colors.black,
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
                                    SnackBar(content: Text(Lang.t('not_enough_coins'))),
                                  );
                                }
                              },
                              child: Text(isSelected ? Lang.t('equipped') : (isUnlocked ? Lang.t('use') : '${theme.price} 🪙')),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    ...List.generate(bottleSkins.length, (i) {
                      final skin = bottleSkins[i];
                      final isUnlocked = unlockedBottles.contains(i.toString());
                      final isSelected = selectedBottleIndex == i;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? const Color(0xFF00D2FF) : Colors.white24, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(skin.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.white24 : (isUnlocked ? const Color(0xFF00D2FF) : Colors.amber),
                                foregroundColor: isSelected ? Colors.white : Colors.black,
                              ),
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                if (isUnlocked) {
                                  SoundEngine.instance.playClick();
                                  await prefs.setInt('selected_bottle', i);
                                  setState(() => selectedBottleIndex = i);
                                  setModalState(() {});
                                } else if (coins >= skin.price) {
                                  SoundEngine.instance.playWin();
                                  coins -= skin.price;
                                  unlockedBottles.add(i.toString());
                                  await prefs.setInt('coins', coins);
                                  await prefs.setStringList('unlocked_bottles', unlockedBottles);
                                  await prefs.setInt('selected_bottle', i);
                                  setState(() => selectedBottleIndex = i);
                                  setModalState(() {});
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(Lang.t('not_enough_coins'))),
                                  );
                                }
                              },
                              child: Text(isSelected ? Lang.t('equipped') : (isUnlocked ? Lang.t('use') : '${skin.price} 🪙')),
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
    final skin = bottleSkins[selectedBottleIndex];

    return Scaffold(
      body: BokehBackground(
        gradient: theme.bgGradient,
        accent: theme.accentColor,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar: Coins, Language Switcher, Settings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                      ),
                      child: Text('$coins 🪙', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber)),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleLanguage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.accentColor.withOpacity(0.6)),
                            ),
                            child: Text(
                              Lang.isMy ? 'မြန်မာ 🇲🇲' : 'EN 🇺🇸',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 26),
                          onPressed: _openSettings,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accentColor.withOpacity(0.12),
                  boxShadow: [BoxShadow(color: theme.accentColor.withOpacity(0.35), blurRadius: 30)],
                ),
                child: Icon(Icons.science_rounded, size: 74, color: theme.accentColor),
              ),
              const SizedBox(height: 18),
              const Text(
                'COLOR SORT',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
              Text(
                'PUZZLE PRO',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 6, color: theme.accentColor),
              ),

              const SizedBox(height: 44),

              // PLAY Button
              GestureDetector(
                onTap: () async {
                  SoundEngine.instance.vibrateMedium();
                  SoundEngine.instance.playClick();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GameScreen(theme: theme, skin: skin)),
                  );
                  _loadData();
                },
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [theme.accentColor, theme.accentColor.withOpacity(0.75)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: theme.accentColor.withOpacity(0.5), blurRadius: 22, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      Text(
                        Lang.t('play'),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 2),
                      ),
                      Text(
                        '${Lang.t('level')} $savedLevel',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Shop & Daily Reward Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    onPressed: _openShop,
                    icon: const Icon(Icons.storefront_rounded),
                    label: Text(Lang.t('shop'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber,
                          side: const BorderSide(color: Colors.amber, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: _openDailyReward,
                        icon: const Icon(Icons.card_giftcard_rounded),
                        label: Text(Lang.t('daily'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (canClaimDaily)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(color: Color(0xFFFF3366), shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                ],
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
  final BottleSkinData skin;
  const GameScreen({super.key, required this.theme, required this.skin});

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
  List<List<bool>> revealed = []; // Mystery Mode (?) အတွက်
  List<List<List<Color>>> history = [];

  int? selectedBottleIndex;
  int? pouringBottleIndex;
  int? hintFromIndex;
  int? hintToIndex;
  bool extraBottleUsed = false;
  bool showConfetti = false;
  bool isMysteryLevel = false;

  Timer? _countdownTimer;
  int maxTime = 60;
  int timeLeft = 60;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
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
    isMysteryLevel = level >= 5 && (level % 2 == 1); // Level 5, 7, 9... မှာ Mystery (?) ပါမယ်

    List<Color> allDrops = [];
    for (int i = 0; i < numColors; i++) {
      for (int j = 0; j < maxCapacity; j++) {
        allDrops.add(palette[i]);
      }
    }
    allDrops.shuffle(Random());

    List<List<Color>> newBottles = [];
    List<List<bool>> newRevealed = [];
    for (int i = 0; i < numColors; i++) {
      newBottles.add(allDrops.sublist(i * maxCapacity, (i + 1) * maxCapacity));
      // Mystery Level ဆိုရင် အပေါ်ဆုံးအလွှာပဲ ပြထားပြီး အောက်အလွှာတွေ ဖုံးထားမယ်
      newRevealed.add(List.generate(maxCapacity, (idx) => !isMysteryLevel || idx == maxCapacity - 1));
    }

    newBottles.add([]);
    newBottles.add([]);
    newRevealed.add([]);
    newRevealed.add([]);

    maxTime = 50 + (numColors * 12);

    setState(() {
      bottles = newBottles;
      revealed = newRevealed;
      history.clear();
      selectedBottleIndex = null;
      pouringBottleIndex = null;
      hintFromIndex = null;
      hintToIndex = null;
      extraBottleUsed = false;
      isGameOver = false;
      showConfetti = false;
      timeLeft = maxTime;
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
    SoundEngine.instance.vibrateHeavy();
    SoundEngine.instance.playLose();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.timer_off, color: Color(0xFFFF3366), size: 48),
            const SizedBox(height: 8),
            Text(Lang.t('times_up'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(Lang.t('times_up_msg'), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initLevel(currentLevel);
            },
            child: Text(Lang.t('retry'), style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
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
    if (_isBottleComplete(bottles[index])) return;

    setState(() {
      hintFromIndex = null;
      hintToIndex = null;
    });

    if (selectedBottleIndex == null) {
      if (bottles[index].isNotEmpty) {
        SoundEngine.instance.vibrateLight();
        SoundEngine.instance.playClick();
        setState(() => selectedBottleIndex = index);
      }
    } else if (selectedBottleIndex == index) {
      SoundEngine.instance.vibrateLight();
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

      SoundEngine.instance.vibrateMedium();
      SoundEngine.instance.playPour();
      setState(() => pouringBottleIndex = from);

      await Future.delayed(const Duration(milliseconds: 200));

      bool becameComplete = false;
      setState(() {
        while (fromBottle.isNotEmpty &&
            fromBottle.last == topColor &&
            toBottle.length < maxCapacity) {
          toBottle.add(fromBottle.removeLast());
          if (revealed[from].isNotEmpty) revealed[from].removeLast();
          revealed[to].add(true);
        }
        // အပေါ်အရောင်ဖယ်လိုက်ရင် အောက်က Mystery (?) ကို ဖွင့်ပေးမယ်
        if (revealed[from].isNotEmpty) {
          revealed[from][revealed[from].length - 1] = true;
        }
        if (_isBottleComplete(toBottle)) {
          becameComplete = true;
        }
        selectedBottleIndex = null;
        pouringBottleIndex = null;
      });

      if (becameComplete) {
        SoundEngine.instance.vibrateHeavy();
        SoundEngine.instance.playBottleDone();
      }

      if (!_checkWin()) {
        _checkNoMoves();
      }
    } else {
      setState(() => selectedBottleIndex = null);
    }
  }

  bool _hasAnyValidMove() {
    for (int i = 0; i < bottles.length; i++) {
      if (bottles[i].isEmpty || _isBottleComplete(bottles[i])) continue;
      Color top = bottles[i].last;
      for (int j = 0; j < bottles.length; j++) {
        if (i == j || bottles[j].length >= maxCapacity) continue;
        if (bottles[j].isEmpty || bottles[j].last == top) {
          return true;
        }
      }
    }
    return false;
  }

  void _checkNoMoves() {
    if (!_hasAnyValidMove() && !isGameOver) {
      SoundEngine.instance.vibrateHeavy();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(Lang.t('no_moves'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(Lang.t('no_moves_msg'), textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _initLevel(currentLevel);
              },
              child: Text(Lang.t('retry'), style: const TextStyle(color: Colors.white70)),
            ),
            if (!extraBottleUsed)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _addExtraBottle();
                },
                child: Text('${Lang.t('add_bottle')} (Ad)', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      );
    }
  }

  bool _checkWin() {
    for (var bottle in bottles) {
      if (bottle.isEmpty) continue;
      if (!_isBottleComplete(bottle)) return false;
    }

    _countdownTimer?.cancel();
    SoundEngine.instance.vibrateHeavy();
    SoundEngine.instance.playWin();

    setState(() => showConfetti = true);
    _confettiController.forward(from: 0);

    // 3-Star Calculation
    double ratio = timeLeft / maxTime;
    int stars = ratio > 0.5 ? 3 : (ratio > 0.25 ? 2 : 1);
    int rewardCoins = stars * 10;
    int nextLevel = currentLevel + 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(
                Icons.star_rounded,
                size: 40,
                color: i < stars ? const Color(0xFFFFD166) : Colors.white24,
              )),
            ),
            const SizedBox(height: 8),
            Text(Lang.t('level_complete'), style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
          child: Text(
            '${Lang.t('reward')}: +$rewardCoins 🪙',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              int updatedCoins = coins + rewardCoins;
              _saveProgress(nextLevel, updatedCoins);
              setState(() {
                currentLevel = nextLevel;
                coins = updatedCoins;
              });
              _initLevel(currentLevel);
            },
            child: Text('${Lang.t('next')} (+$rewardCoins 🪙)', style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              int updatedCoins = coins + (rewardCoins * 2);
              _saveProgress(nextLevel, updatedCoins);
              setState(() {
                currentLevel = nextLevel;
                coins = updatedCoins;
              });
              _initLevel(currentLevel);
            },
            icon: const Icon(Icons.play_circle_fill, size: 18),
            label: Text('2x (+${rewardCoins * 2} 🪙 Ad)', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return true;
  }

  void _undo() {
    if (history.isNotEmpty) {
      SoundEngine.instance.vibrateLight();
      SoundEngine.instance.playClick();
      setState(() {
        bottles = history.removeLast();
        // Undo လုပ်ရင် revealed list ကို အကုန် true ပြန်ညှိပေးမယ်
        revealed = bottles.map((b) => List.filled(b.length, true, growable: true)).toList();
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
      SoundEngine.instance.vibrateMedium();
      SoundEngine.instance.playClick();
      setState(() {
        hintFromIndex = bestFrom;
        hintToIndex = bestTo;
      });
    }
  }

  void _addExtraBottle() {
    if (extraBottleUsed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Lang.t('extra_used'))));
      return;
    }
    SoundEngine.instance.vibrateMedium();
    SoundEngine.instance.playClick();
    setState(() {
      bottles.add([]);
      revealed.add([]);
      extraBottleUsed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    String timerText = '${(timeLeft ~/ 60).toString().padLeft(2, '0')}:${(timeLeft % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      body: Stack(
        children: [
          BokehBackground(
            gradient: widget.theme.bgGradient,
            accent: widget.theme.accentColor,
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
                            Row(
                              children: [
                                Text(
                                  '${Lang.t('level')} $currentLevel',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                ),
                                if (isMysteryLevel) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(8)),
                                    child: Text(Lang.t('mystery_badge'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: timeLeft <= 15 ? const Color(0xFFFF3366).withOpacity(0.25) : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: timeLeft <= 15 ? const Color(0xFFFF3366) : Colors.white24),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.timer, size: 14, color: timeLeft <= 15 ? const Color(0xFFFF3366) : widget.theme.accentColor),
                                      const SizedBox(width: 4),
                                      Text(timerText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: timeLeft <= 15 ? const Color(0xFFFF3366) : Colors.white)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                                  child: Text('$coins 🪙', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
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

                  // 3D ဖန်ပုလင်းများ
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 18,
                          runSpacing: 34,
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
                        _actionButton(icon: Icons.undo, label: Lang.t('undo'), color: const Color(0xFF334155), onTap: _undo),
                        _actionButton(icon: Icons.lightbulb, label: Lang.t('hint'), isAd: true, color: const Color(0xFFD97706), onTap: _useHint),
                        _actionButton(icon: Icons.add_box_rounded, label: Lang.t('add_bottle'), isAd: true, color: const Color(0xFF0284C7), onTap: _addExtraBottle),
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
                    child: const Text('AD BANNER SPACE (AdMob Ready)', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.2)),
                  ),
                ],
              ),
            ),
          ),

          if (showConfetti)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) => CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: ConfettiPainter(progress: _confettiController.value),
                ),
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
    List<bool> rev = revealed[index];
    bool isComplete = _isBottleComplete(colors);

    Color borderColor = widget.skin.hasNeonGlow ? widget.theme.accentColor.withOpacity(0.7) : Colors.white54;
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
                color: Colors.white.withOpacity(0.07),
                border: Border.all(color: borderColor, width: (isSelected || isHint || isComplete || widget.skin.hasNeonGlow) ? 3 : 2),
                boxShadow: (isSelected || isHint || isComplete || widget.skin.hasNeonGlow)
                    ? [BoxShadow(color: borderColor.withOpacity(0.45), blurRadius: 16, spreadRadius: 1)]
                    : [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 4))],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(widget.skin.bottomRadius),
                  bottomRight: Radius.circular(widget.skin.bottomRadius),
                  topLeft: Radius.circular(widget.skin.topRadius),
                  topRight: Radius.circular(widget.skin.topRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(max(0, widget.skin.bottomRadius - 2)),
                  bottomRight: Radius.circular(max(0, widget.skin.bottomRadius - 2)),
                  topLeft: Radius.circular(max(0, widget.skin.topRadius - 2)),
                  topRight: Radius.circular(max(0, widget.skin.topRadius - 2)),
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
                            revealed: rev,
                            maxCapacity: maxCapacity,
                            wavePhase: _waveController.value * 2 * pi,
                          ),
                        );
                      },
                    ),
                    // 3D Glass Highlight
                    Positioned(
                      left: 6,
                      top: 12,
                      bottom: 20,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.28), Colors.white.withOpacity(0.05)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (isComplete)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Color(0xFF00E676), size: 24),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3D Bottle Rim (ပုလင်းနှုတ်ခမ်းသား)
          Positioned(
            top: (isSelected || isPouring) ? -26 : -4,
            child: Container(
              width: 64,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor, width: 1.5),
              ),
            ),
          ),

          // Cork (ပြည့်သွားရင် အဖုံးပိတ်မယ်)
          if (isComplete)
            Positioned(
              top: -15,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 5),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          if (isAd)
            Positioned(
              top: -8,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFF3366), borderRadius: BorderRadius.circular(8)),
                child: const Text('AD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

/// ================= 3D GRADIENT LIQUID + BUBBLES + MYSTERY (?) =================
class LiquidBottlePainter extends CustomPainter {
  final List<Color> colors;
  final List<bool> revealed;
  final int maxCapacity;
  final double wavePhase;

  LiquidBottlePainter({
    required this.colors,
    required this.revealed,
    required this.maxCapacity,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final double layerHeight = (size.height - 16) / maxCapacity;

    for (int i = 0; i < colors.length; i++) {
      final bool isVisible = i < revealed.length ? revealed[i] : true;
      final Color baseColor = isVisible ? colors[i] : const Color(0xFF334155);

      final double bottomY = size.height - (i * layerHeight);
      final double topY = bottomY - layerHeight;
      final bool isTopLayer = (i == colors.length - 1);

      final rect = Rect.fromLTRB(0, topY, size.width, bottomY + 1);
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            baseColor.withOpacity(0.85),
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.25)!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rect);

      if (!isTopLayer) {
        canvas.drawRect(rect, paint);
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

        // Surface Glow Line
        final glowPaint = Paint()
          ..color = Colors.white.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        final glowPath = Path();
        for (double x = 0; x <= size.width; x++) {
          final y = topY + sin((x / size.width * 2 * pi) + wavePhase) * 3.5;
          if (x == 0) {
            glowPath.moveTo(x, y);
          } else {
            glowPath.lineTo(x, y);
          }
        }
        canvas.drawPath(glowPath, glowPaint);
      }

      // Mystery (?) Text
      if (!isVisible) {
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '?',
            style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset((size.width - textPainter.width) / 2, topY + (layerHeight - textPainter.height) / 2),
        );
      } else {
        // Rising Bubbles inside liquid
        final bubblePaint = Paint()..color = Colors.white.withOpacity(0.25);
        final bx = 14 + ((i * 17) % 30).toDouble();
        final by = bottomY - (((wavePhase / (2 * pi)) + i * 0.3) % 1.0) * layerHeight;
        canvas.drawCircle(Offset(bx, by), 2.5, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LiquidBottlePainter oldDelegate) => true;
}

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
        final paint = Paint()..color = _colors[i % _colors.length].withOpacity((1 - progress).clamp(0.0, 1.0));
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