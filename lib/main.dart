import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ColorSortMasterApp());
}

/// ================= ADMOB MANAGER (TEST IDs) =================
class AdManager {
  // Play Store တင်ခါနီးမှ ကိုယ့် AdMob ID အစစ်တွေနဲ့ လဲထည့်ရန်
  static const String bannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String rewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static RewardedAd? _rewardedAd;

  static void loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) => _rewardedAd = null,
      ),
    );
  }

  static void showRewarded(VoidCallback onEarned) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewarded();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadRewarded();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (_, __) => onEarned());
      _rewardedAd = null;
    } else {
      // ကြော်ငြာ Load မပြီးသေးရင် (သို့) Offline ဖြစ်နေရင် ဆုတန်းပေးပြီး နောက်တစ်ခါအတွက် ပြန် Load မယ်
      onEarned();
      loadRewarded();
    }
  }
}

/// ================= GLOBAL STATE & DATA =================
class GameData {
  static int level = 1;
  static int coins = 500;
  static int undoCount = 3;
  static int hintCount = 3;
  static int tubeCount = 2;
  static int totalStars = 0;
  static int dailyDay = 1;
  static String lastDailyDate = '';
  static int selectedTheme = 0;
  static List<String> unlockedThemes = ['0'];
  static bool isMyanmar = false;
  static bool notificationsOn = true;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    level = p.getInt('lv') ?? 1;
    coins = p.getInt('coins') ?? 500;
    undoCount = p.getInt('undo') ?? 3;
    hintCount = p.getInt('hint') ?? 3;
    tubeCount = p.getInt('tube') ?? 2;
    totalStars = p.getInt('stars') ?? 0;
    dailyDay = p.getInt('daily_day') ?? 1;
    lastDailyDate = p.getString('daily_date') ?? '';
    selectedTheme = p.getInt('theme') ?? 0;
    unlockedThemes = p.getStringList('unlocked_themes') ?? ['0'];
    isMyanmar = p.getBool('is_my') ?? false;
    notificationsOn = p.getBool('notif') ?? true;
    SoundEngine.instance.musicOn = p.getBool('music') ?? true;
    SoundEngine.instance.sfxOn = p.getBool('sfx') ?? true;
    SoundEngine.instance.vibOn = p.getBool('vib') ?? true;
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('lv', level);
    await p.setInt('coins', coins);
    await p.setInt('undo', undoCount);
    await p.setInt('hint', hintCount);
    await p.setInt('tube', tubeCount);
    await p.setInt('stars', totalStars);
    await p.setInt('daily_day', dailyDay);
    await p.setString('daily_date', lastDailyDate);
    await p.setInt('theme', selectedTheme);
    await p.setStringList('unlocked_themes', unlockedThemes);
    await p.setBool('is_my', isMyanmar);
    await p.setBool('notif', notificationsOn);
    await p.setBool('music', SoundEngine.instance.musicOn);
    await p.setBool('sfx', SoundEngine.instance.sfxOn);
    await p.setBool('vib', SoundEngine.instance.vibOn);
  }

  static bool get canClaimDaily {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastDailyDate != today;
  }
}

class ThemeSkin {
  final String name;
  final int price;
  final List<Color> bg;
  final Color accent;
  const ThemeSkin(this.name, this.price, this.bg, this.accent);
}

const List<ThemeSkin> kThemes = [
  ThemeSkin('Neon Theme', 0, [Color(0xFF0A0E2A), Color(0xFF1A1048), Color(0xFF070B1E)], Color(0xFF00E5FF)),
  ThemeSkin('Ocean Theme', 1000, [Color(0xFF021B35), Color(0xFF064273), Color(0xFF021426)], Color(0xFF38BDF8)),
  ThemeSkin('Galaxy Theme', 2000, [Color(0xFF1A0633), Color(0xFF4A0E78), Color(0xFF120424)], Color(0xFFE879F9)),
  ThemeSkin('Gold Theme', 5000, [Color(0xFF261A04), Color(0xFF5C3D06), Color(0xFF1A1202)], Color(0xFFFFD166)),
  ThemeSkin('Forest Theme', 5000, [Color(0xFF02261B), Color(0xFF065F46), Color(0xFF021C14)], Color(0xFF34D399)),
  ThemeSkin('Crystal Theme', 5000, [Color(0xFF0F172A), Color(0xFF334155), Color(0xFF0F172A)], Color(0xFF93C5FD)),
];

/// ================= SOUND ENGINE =================
class SoundEngine {
  static final SoundEngine instance = SoundEngine._();
  final AudioPlayer _bgm = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();
  bool musicOn = true, sfxOn = true, vibOn = true, _started = false;

  late Uint8List _bgmWav, _clickWav, _pourWav, _doneWav, _winWav, _loseWav;

  SoundEngine._() {
    _bgmWav = _makeBgm();
    _clickWav = _tone(540, 0.07, 0.35);
    _pourWav = _sweep(320, 720, 0.22, 0.4);
    _doneWav = _melody([659.25, 880.0], 0.10);
    _winWav = _melody([523.25, 659.25, 783.99, 1046.5], 0.13);
    _loseWav = _melody([392.0, 349.23, 311.13, 261.63], 0.2);
  }

  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool _musicOn = true;

  Future<void> setMusic(bool on) async {
    _musicOn = on;
    if (on) {
      await startBgm();
    } else {
      await stopBgm();
    }
  }

  Future<void> startBgm() async {
    if (!_musicOn) return;
    try {
      await _bgmPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      ));
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.7);
      await _bgmPlayer.play(AssetSource('bgm.mp3'));
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  void vib() {
    if (vibOn) HapticFeedback.lightImpact();
  }

  void vibHeavy() {
    if (vibOn) HapticFeedback.heavyImpact();
  }

  void click() => _play(_clickWav);
  void pour() => _play(_pourWav);
  void bottleDone() => _play(_doneWav);
  void win() => _play(_winWav);
  void lose() => _play(_loseWav);

  Future<void> _play(Uint8List b) async {
    if (!sfxOn) return;
    try {
      await _sfx.stop();
      await _sfx.play(BytesSource(b));
    } catch (_) {}
  }

  Uint8List _wav(List<int> s, int sr) {
    final d = ByteData(44 + s.length * 2);
    void w(int o, String t) {
      for (int i = 0; i < t.length; i++) {
        d.setUint8(o + i, t.codeUnitAt(i));
      }
    }
    w(0, 'RIFF'); d.setUint32(4, 36 + s.length * 2, Endian.little);
    w(8, 'WAVE'); w(12, 'fmt '); d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little); d.setUint16(22, 1, Endian.little);
    d.setUint32(24, sr, Endian.little); d.setUint32(28, sr * 2, Endian.little);
    d.setUint16(32, 2, Endian.little); d.setUint16(34, 16, Endian.little);
    w(36, 'data'); d.setUint32(40, s.length * 2, Endian.little);
    for (int i = 0; i < s.length; i++) {
      d.setInt16(44 + i * 2, s[i].clamp(-32767, 32767), Endian.little);
    }
    return d.buffer.asUint8List();
  }

  Uint8List _tone(double f, double dur, double vol) {
    const sr = 22050;
    final n = (sr * dur).toInt();
    return _wav(List.generate(n, (i) => (sin(2 * pi * f * i / sr) * 32767 * vol * (1 - i / n)).toInt()), sr);
  }

  Uint8List _sweep(double f1, double f2, double dur, double vol) {
    const sr = 22050;
    final n = (sr * dur).toInt();
    return _wav(List.generate(n, (i) {
      final p = i / n;
      return (sin(2 * pi * (f1 + (f2 - f1) * p) * i / sr) * 32767 * vol * sin(pi * p)).toInt();
    }), sr);
  }

  Uint8List _melody(List<double> fs, double dur) {
    const sr = 22050;
    final all = <int>[];
    for (final f in fs) {
      final n = (sr * dur).toInt();
      for (int i = 0; i < n; i++) {
        all.add((sin(2 * pi * f * i / sr) * 32767 * 0.35 * (1 - i / n)).toInt());
      }
    }
    return _wav(all, sr);
  }

  Uint8List _makeBgm() {
    const sr = 16000;
    final notes = [261.63, 329.63, 392.0, 440.0, 392.0, 329.63, 293.66, 392.0];
    final all = <int>[];
    for (final f in notes) {
      final n = (sr * 0.65).toInt();
      for (int i = 0; i < n; i++) {
        final v = sin(2 * pi * f * i / sr) * 0.6 + sin(2 * pi * (f / 2) * i / sr) * 0.4;
        all.add((v * 32767 * 0.25 * sin(pi * i / n)).toInt());
      }
    }
    return _wav(all, sr);
  }
}

/// ================= MAIN APP =================
class ColorSortMasterApp extends StatelessWidget {
  const ColorSortMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Sort Master',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0A0E2A)),
      home: const MainShell(),
    );
  }
}

/// ================= MAIN SHELL =================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    GameData.load().then((_) {
      setState(() => _loaded = true);
      SoundEngine.instance.startBgm();
    });
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        await MobileAds.instance.initialize();
        AdManager.loadRewarded();
      } catch (_) {}
    });
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = kThemes[GameData.selectedTheme];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: theme.bg),
        ),
        child: IndexedStack(
          index: _tab,
          children: [
            HomeTab(onRefresh: _refresh, onOpenShop: () => setState(() => _tab = 1)),
            ShopTab(onRefresh: _refresh),
            const RankTab(),
            EventsTab(onRefresh: _refresh),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1433),
          border: Border(top: BorderSide(color: theme.accent.withOpacity(0.35), width: 1.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) {
            SoundEngine.instance.vib();
            SoundEngine.instance.click();
            setState(() => _tab = i);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.accent,
          unselectedItemColor: Colors.white54,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: GameData.isMyanmar ? 'ပင်မ' : 'Home'),
            BottomNavigationBarItem(icon: const Icon(Icons.shopping_cart_rounded), label: GameData.isMyanmar ? 'ဆိုင်' : 'Shop'),
            BottomNavigationBarItem(icon: const Icon(Icons.emoji_events_rounded), label: GameData.isMyanmar ? 'အဆင့်' : 'Rank'),
            BottomNavigationBarItem(icon: const Icon(Icons.star_rounded), label: GameData.isMyanmar ? 'ပွဲများ' : 'Events'),
          ],
        ),
      ),
    );
  }
}

/// ================= 1. HOME TAB =================
class HomeTab extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onOpenShop;
  const HomeTab({super.key, required this.onRefresh, required this.onOpenShop});

  @override
  Widget build(BuildContext context) {
    final theme = kThemes[GameData.selectedTheme];
    final isMy = GameData.isMyanmar;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pill(icon: Icons.workspace_premium, iconColor: Colors.amber, text: 'Lv.${GameData.level}'),
                GestureDetector(
                  onTap: onOpenShop,
                  child: _pill(
                    icon: Icons.monetization_on,
                    iconColor: Colors.amber,
                    text: '${GameData.coins}',
                    trailing: const Icon(Icons.add_circle, color: Color(0xFF00E676), size: 20),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                  onPressed: () async {
                    SoundEngine.instance.click();
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    onRefresh();
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _miniLogoTube(const Color(0xFF00E5FF), -0.06),
              const SizedBox(width: 10),
              _miniLogoTube(const Color(0xFFFF2E93), 0.0),
              const SizedBox(width: 10),
              _miniLogoTube(const Color(0xFFFFD166), 0.06),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'COLOR POUR',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 18)],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7E22CE), Color(0xFFA855F7)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('PUZZLE MASTER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ),
          const SizedBox(height: 10),
          Text(
            isMy ? 'အရောင်စီပါ • အပန်းဖြေပါ • ပျော်ရွှင်ပါ' : 'Sort colors • Relax • Enjoy',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 36),
          GestureDetector(
            onTap: () async {
              SoundEngine.instance.vib();
              SoundEngine.instance.click();
              await Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(levelToPlay: GameData.level)));
              onRefresh();
            },
            child: Container(
              width: 250,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFE066), Color(0xFFFF9F1C)]),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: const Color(0xFFFF9F1C).withOpacity(0.55), blurRadius: 22, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Color(0xFF3D1D00), size: 32),
                      Text(isMy ? 'ကစားမည်' : 'PLAY',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF3D1D00))),
                    ],
                  ),
                  Text(
                    isMy ? 'အဆင့် ${GameData.level} ဆက်ကစားမည်' : 'Continue Level ${GameData.level}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5C2E00)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () async {
              SoundEngine.instance.click();
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelSelectScreen()));
              onRefresh();
            },
            icon: Icon(Icons.map_rounded, color: theme.accent),
            label: Text(
              isMy ? 'အဆင့်များ ရွေးချယ်ရန် (Level Map)' : 'Level Select Map',
              style: TextStyle(color: theme.accent, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _homeFeatureBtn(
                    icon: Icons.card_giftcard_rounded,
                    iconColor: const Color(0xFFFF4D6D),
                    title: isMy ? 'နေ့စဉ်\nလက်ဆောင်' : 'Daily\nReward',
                    badge: GameData.canClaimDaily ? '1' : null,
                    onTap: () {
                      SoundEngine.instance.click();
                      showDialog(context: context, builder: (_) => DailyRewardDialog(onClaimed: onRefresh));
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _homeFeatureBtn(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFFFD166),
                    title: isMy ? 'နေ့စဉ်\nစိန်ခေါ်မှု' : 'Daily\nChallenge',
                    onTap: () async {
                      SoundEngine.instance.click();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => GameScreen(levelToPlay: GameData.level + 5, isChallenge: true)),
                      );
                      onRefresh();
                    },
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _miniLogoTube(Color c, double turns) {
    return Transform.rotate(
      angle: turns * 2,
      child: Container(
        width: 34,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16), top: Radius.circular(4)),
          border: Border.all(color: Colors.white70, width: 2),
          boxShadow: [BoxShadow(color: c.withOpacity(0.5), blurRadius: 14)],
        ),
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 50,
          decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14))),
        ),
      ),
    );
  }

  Widget _homeFeatureBtn({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF16214D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 30),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFFF3366), shape: BoxShape.circle),
                child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

/// ================= 2. LEVEL SELECT MAP + CLAIMABLE STAR CHEST =================
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  void _claimChest() {
    if (GameData.totalStars >= 10) {
      GameData.totalStars -= 10;
      GameData.coins += 200;
      GameData.save();
      SoundEngine.instance.win();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Star Chest Opened! +200 Coins 🪙🎉')),
      );
    } else {
      SoundEngine.instance.click();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Collect ${10 - GameData.totalStars} more ⭐ to open this chest!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = kThemes[GameData.selectedTheme];
    final maxShow = max(20, GameData.level + 5);
    final canOpen = GameData.totalStars >= 10;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: theme.bg)),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
                        Text(GameData.isMyanmar ? 'အဆင့် ရွေးချယ်ရန်' : 'Level Select',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        _pill(icon: Icons.monetization_on, iconColor: Colors.amber, text: '${GameData.coins}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                      itemCount: maxShow,
                      itemBuilder: (context, index) {
                        final lv = index + 1;
                        final isCurrent = lv == GameData.level;
                        final isUnlocked = lv <= GameData.level;
                        final offset = sin(lv * 0.9) * 85;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Transform.translate(
                            offset: Offset(offset, 0),
                            child: Center(
                              child: GestureDetector(
                                onTap: isUnlocked
                                    ? () {
                                        SoundEngine.instance.click();
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (_) => GameScreen(levelToPlay: lv)),
                                        );
                                      }
                                    : null,
                                child: Column(
                                  children: [
                                    if (isCurrent) const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: isCurrent
                                              ? [const Color(0xFFFFD166), const Color(0xFFFF7B00)]
                                              : (isUnlocked
                                                  ? [const Color(0xFF1D4ED8), const Color(0xFF1E3A8A)]
                                                  : [Colors.white12, Colors.white10]),
                                        ),
                                        border: Border.all(
                                          color: isCurrent ? Colors.white : (isUnlocked ? theme.accent : Colors.white24),
                                          width: isCurrent ? 3 : 2,
                                        ),
                                        boxShadow: isCurrent ? [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 18)] : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: isUnlocked
                                          ? Text('$lv', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))
                                          : const Icon(Icons.lock, color: Colors.white38),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        3,
                                        (s) => Icon(Icons.star_rounded, size: 16, color: lv < GameData.level ? Colors.amber : Colors.white24),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // Claimable Star Chest
              Positioned(
                right: 16,
                bottom: 20,
                child: GestureDetector(
                  onTap: _claimChest,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: canOpen ? const Color(0xFF065F46) : const Color(0xFF16214D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: canOpen ? const Color(0xFF00E676) : Colors.amber, width: 2),
                      boxShadow: canOpen ? [BoxShadow(color: const Color(0xFF00E676).withOpacity(0.5), blurRadius: 14)] : null,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_rounded, color: canOpen ? const Color(0xFF00E676) : Colors.amber, size: 32),
                        Text(
                          canOpen ? 'CLAIM! 🎁' : '${GameData.totalStars}/10 ⭐',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= 3. GAMEPLAY SCREEN + CORK + CONFETTI + NO MOVES =================
class GameScreen extends StatefulWidget {
  final int levelToPlay;
  final bool isChallenge;
  const GameScreen({super.key, required this.levelToPlay, this.isChallenge = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int cap = 4;
  final List<Color> palette = [
    const Color(0xFFFF2E63),
    const Color(0xFF00E5FF),
    const Color(0xFF00E676),
    const Color(0xFFFFD166),
    const Color(0xFFA855F7),
    const Color(0xFFFF7B00),
    const Color(0xFF2EC4B6),
    const Color(0xFFF72585),
  ];

  late int level;
  late AnimationController _waveCtrl;
  late AnimationController _confettiCtrl;
  List<List<Color>> bottles = [];
  List<List<List<Color>>> history = [];
  int? selected, pouring, hintFrom, hintTo;
  bool extraUsed = false, paused = false, showConfetti = false;
  int moves = 0, timeLeft = 120, maxTime = 120;
  Timer? _timer;
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    level = widget.levelToPlay;
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerReady = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
    _initLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerAd?.dispose();
    _waveCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _initLevel() {
    _timer?.cancel();
    int numColors = min(3 + (level ~/ 2), palette.length);
    final drops = <Color>[];
    for (int i = 0; i < numColors; i++) {
      for (int j = 0; j < cap; j++) {
        drops.add(palette[i]);
      }
    }
    drops.shuffle(Random());
    bottles = List.generate(numColors, (i) => drops.sublist(i * cap, (i + 1) * cap));
    bottles.addAll([[], []]);
    history.clear();
    selected = pouring = hintFrom = hintTo = null;
    extraUsed = paused = showConfetti = false;
    moves = 0;
    maxTime = 60 + numColors * 15;
    timeLeft = maxTime;
    setState(() {});
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (paused) return;
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        SoundEngine.instance.lose();
        _showTimeUp();
      }
    });
  }

  bool _isDone(List<Color> b) => b.length == cap && b.every((c) => c == b.first);

  void _tapBottle(int i) {
    if (paused || pouring != null || _isDone(bottles[i])) return;
    setState(() => hintFrom = hintTo = null);
    if (selected == null) {
      if (bottles[i].isNotEmpty) {
        SoundEngine.instance.vib();
        SoundEngine.instance.click();
        setState(() => selected = i);
      }
    } else if (selected == i) {
      SoundEngine.instance.click();
      setState(() => selected = null);
    } else {
      _pour(selected!, i);
    }
  }

  Future<void> _pour(int from, int to) async {
    final fb = bottles[from], tb = bottles[to];
    if (fb.isEmpty || tb.length >= cap) {
      setState(() => selected = null);
      return;
    }
    final top = fb.last;
    if (tb.isEmpty || tb.last == top) {
      history.add(bottles.map((b) => List<Color>.from(b)).toList());
      SoundEngine.instance.vib();
      SoundEngine.instance.pour();
      setState(() => pouring = from);
      await Future.delayed(const Duration(milliseconds: 200));

      bool justCompleted = false;
      setState(() {
        while (fb.isNotEmpty && fb.last == top && tb.length < cap) {
          tb.add(fb.removeLast());
        }
        if (_isDone(tb)) justCompleted = true;
        moves++;
        selected = pouring = null;
      });

      if (justCompleted) {
        SoundEngine.instance.vibHeavy();
        SoundEngine.instance.bottleDone();
      }

      if (!_checkWin()) {
        _checkNoMoves();
      }
    } else {
      setState(() => selected = null);
    }
  }

  bool _hasValidMove() {
    for (int i = 0; i < bottles.length; i++) {
      if (bottles[i].isEmpty || _isDone(bottles[i])) continue;
      final top = bottles[i].last;
      for (int j = 0; j < bottles.length; j++) {
        if (i != j && bottles[j].length < cap && (bottles[j].isEmpty || bottles[j].last == top)) {
          return true;
        }
      }
    }
    return false;
  }

  void _checkNoMoves() {
    if (!_hasValidMove()) {
      SoundEngine.instance.vibHeavy();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF131B3E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('No Moves Left! 🤯', textAlign: TextAlign.center),
          content: const Text('You are stuck! Add an extra tube or retry.', textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); _initLevel(); }, child: const Text('Retry')),
            if (!extraUsed)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _addTube();
                },
                child: const Text('+1 Tube'),
              ),
          ],
        ),
      );
    }
  }

  bool _checkWin() {
    for (final b in bottles) {
      if (b.isNotEmpty && !_isDone(b)) return false;
    }
    _timer?.cancel();
    SoundEngine.instance.vibHeavy();
    SoundEngine.instance.win();
    setState(() => showConfetti = true);
    _confettiCtrl.forward(from: 0);

    final elapsed = maxTime - timeLeft;
    final stars = timeLeft > maxTime * 0.5 ? 3 : (timeLeft > maxTime * 0.25 ? 2 : 1);
    final reward = widget.isChallenge ? 150 : 100;

    if (!widget.isChallenge && level >= GameData.level) {
      GameData.level = level + 1;
    }
    GameData.totalStars += stars;
    GameData.save();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131B3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber, size: 46),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(Icons.star_rounded, size: 42, color: i < stars ? Colors.amber : Colors.white24)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7E22CE), Color(0xFFA855F7)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('LEVEL COMPLETED!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            const SizedBox(height: 6),
            const Text('Perfect!', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Text('+$reward Coins 🪙', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Time: ${_fmt(elapsed)}   •   Moves: $moves', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  GameData.coins += reward;
                  GameData.save();
                  Navigator.pop(context);
                  setState(() => level++);
                  _initLevel();
                },
                child: const Text('NEXT LEVEL ➔', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB703),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  AdManager.showRewarded(() {
                    GameData.coins += reward * 2;
                    GameData.save();
                    Navigator.pop(context);
                    setState(() => level++);
                    _initLevel();
                  });
                },
                icon: const Icon(Icons.ondemand_video_rounded),
                label: const Text('DOUBLE COINS x2 (Watch Ad)', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
    return true;
  }

  void _showTimeUp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131B3E),
        title: const Text("Time's Up! 😢", textAlign: TextAlign.center),
        content: const Text('Watch an Ad for +30s or Retry?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _initLevel(); }, child: const Text('Retry')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              setState(() => timeLeft = 30);
              _startTimer();
            },
            child: const Text('+30s (Ad)'),
          ),
        ],
      ),
    );
  }

  /// Power-up 0 ဖြစ်သွားရင် Coins (သို့) Ad တောင်းမယ့် Dialog
  void _showRefillDialog(String itemName, VoidCallback onGranted) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131B3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Out of $itemName!', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Buy +1 $itemName for 50 Coins or Watch an Ad for free?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              if (GameData.coins >= 50) {
                GameData.coins -= 50;
                GameData.save();
                Navigator.pop(context);
                onGranted();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
              }
            },
            child: const Text('50 🪙', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              AdManager.showRewarded(onGranted);
            },
            icon: const Icon(Icons.play_circle_fill, size: 18),
            label: const Text('Watch Ad (Free)'),
          ),
        ],
      ),
    );
  }

  void _useUndo() {
    if (history.isEmpty) return;
    if (GameData.undoCount <= 0) {
      _showRefillDialog('Undo', () {
        setState(() {
          bottles = history.removeLast();
          selected = null;
        });
      });
      return;
    }
    GameData.undoCount--;
    GameData.save();
    SoundEngine.instance.click();
    setState(() {
      bottles = history.removeLast();
      selected = null;
    });
  }

  void _executeHint() {
    for (int i = 0; i < bottles.length; i++) {
      if (bottles[i].isEmpty || _isDone(bottles[i])) continue;
      final top = bottles[i].last;
      for (int j = 0; j < bottles.length; j++) {
        if (i != j && bottles[j].length < cap && (bottles[j].isEmpty || bottles[j].last == top)) {
          SoundEngine.instance.click();
          setState(() { hintFrom = i; hintTo = j; });
          return;
        }
      }
    }
  }

  void _useHint() {
    if (GameData.hintCount <= 0) {
      _showRefillDialog('Hint', _executeHint);
      return;
    }
    GameData.hintCount--;
    GameData.save();
    _executeHint();
  }

  void _executeAddTube() {
    SoundEngine.instance.click();
    setState(() {
      bottles.add([]);
      extraUsed = true;
    });
  }

  void _addTube() {
    if (extraUsed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Extra tube already used for this level!')));
      return;
    }
    if (GameData.tubeCount <= 0) {
      _showRefillDialog('+ Tube', _executeAddTube);
      return;
    }
    GameData.tubeCount--;
    GameData.save();
    _executeAddTube();
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = kThemes[GameData.selectedTheme];

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: theme.bg)),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Level $level', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        _pill(icon: Icons.monetization_on, iconColor: Colors.amber, text: '${GameData.coins}'),
                        IconButton(
                          icon: const Icon(Icons.pause_circle_filled, color: Color(0xFF38BDF8), size: 34),
                          onPressed: () => setState(() => paused = true),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _pill(icon: Icons.timer, iconColor: const Color(0xFF38BDF8), text: _fmt(timeLeft)),
                      const SizedBox(width: 12),
                      _pill(icon: Icons.star_rounded, iconColor: Colors.amber, text: '3'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(GameData.isMyanmar ? 'အရောင်တူများ စုထည့်ပါ' : 'Sort all colors',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 18,
                          runSpacing: 32,
                          alignment: WrapAlignment.center,
                          children: List.generate(bottles.length, _buildTube),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _gameBtn(Icons.undo_rounded, 'Undo', GameData.undoCount, const Color(0xFF1E293B), _useUndo),
                        _gameBtn(Icons.lightbulb_rounded, 'Hint', GameData.hintCount, const Color(0xFFFF9F1C), _useHint),
                        _gameBtn(Icons.add_box_rounded, '+ Tube', GameData.tubeCount, const Color(0xFF0284C7), _addTube),
                      ],
                    ),
                  ),
                  if (_bannerReady && _bannerAd != null)
                    SizedBox(
                      height: _bannerAd!.size.height.toDouble(),
                      width: _bannerAd!.size.width.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                ],
              ),
            ),
          ),

          // CONFETTI OVERLAY
          if (showConfetti)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) => CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ConfettiPainter(_confettiCtrl.value),
                ),
              ),
            ),

          // PAUSE OVERLAY
          if (paused)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0.65),
                alignment: Alignment.center,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B3E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.accent, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pause_rounded, size: 46, color: Colors.white),
                      const Text('PAUSED', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 18),
                      _pauseBtn(Icons.play_arrow_rounded, 'Resume', const Color(0xFF0284C7), () => setState(() => paused = false)),
                      _pauseBtn(Icons.refresh_rounded, 'Restart Level', const Color(0xFF1E293B), _initLevel),
                      _pauseBtn(Icons.home_rounded, 'Home', const Color(0xFF1E293B), () => Navigator.pop(context)),
                      _pauseBtn(Icons.settings, 'Settings', const Color(0xFF1E293B), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      }),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTube(int i) {
    final isSel = selected == i, isPour = pouring == i, isHint = hintFrom == i || hintTo == i;
    final b = bottles[i], done = _isDone(b);
    final border = done ? const Color(0xFF00E676) : (isHint ? Colors.amber : (isSel ? const Color(0xFF00E5FF) : Colors.white60));

    return GestureDetector(
      onTap: () => _tapBottle(i),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedRotation(
            turns: isPour ? 0.08 : 0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.translationValues(0, (isSel || isPour) ? -20 : 0, 0),
              width: 56,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: border, width: (isSel || isHint || done) ? 3 : 2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26), top: Radius.circular(6)),
                boxShadow: [BoxShadow(color: border.withOpacity(0.35), blurRadius: 12)],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24), top: Radius.circular(4)),
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _waveCtrl,
                      builder: (_, __) => CustomPaint(
                        size: const Size(56, 170),
                        painter: _LiquidPainter(b, cap, _waveCtrl.value * 2 * pi),
                      ),
                    ),
                    if (done)
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
          // Bottle Rim
          Positioned(
            top: (isSel || isPour) ? -24 : -4,
            child: Container(
              width: 62,
              height: 7,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6), border: Border.all(color: border)),
            ),
          ),
          // Bottle Complete Cork
          if (done)
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

  Widget _gameBtn(IconData icon, String label, int count, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 96,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
              boxShadow: [BoxShadow(color: c.withOpacity(0.45), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: const BoxDecoration(color: Color(0xFFFF2E63), shape: BoxShape.circle),
              child: Text(count > 0 ? '$count' : 'AD', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pauseBtn(IconData icon, String text, Color c, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: c,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final List<Color> colors;
  final int cap;
  final double phase;
  _LiquidPainter(this.colors, this.cap, this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;
    final h = (size.height - 14) / cap;
    for (int i = 0; i < colors.length; i++) {
      final bY = size.height - i * h, tY = bY - h;
      final paint = Paint()..color = colors[i];
      if (i < colors.length - 1) {
        canvas.drawRect(Rect.fromLTRB(0, tY, size.width, bY + 1), paint);
      } else {
        final path = Path()..moveTo(0, bY + 1)..lineTo(0, tY);
        for (double x = 0; x <= size.width; x++) {
          path.lineTo(x, tY + sin((x / size.width * 2 * pi) + phase) * 3);
        }
        path..lineTo(size.width, bY + 1)..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) => true;
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Random _rng = Random(42);
  final List<Color> _c = [const Color(0xFFFF2E63), const Color(0xFF00E5FF), const Color(0xFF00E676), const Color(0xFFFFD166), const Color(0xFFE879F9)];
  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 60; i++) {
      final x = _rng.nextDouble() * size.width + sin(progress * 10 + i) * 20;
      final y = (progress * size.height * 1.4 * (0.6 + _rng.nextDouble() * 0.8)) - _rng.nextDouble() * 180;
      if (y > 0 && y < size.height) {
        final p = Paint()..color = _c[i % _c.length].withOpacity((1 - progress).clamp(0.0, 1.0));
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * 8 + i);
        canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 12), p);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}

/// ================= 4. SHOP TAB (THEMES, HINTS, MORE + REMOVE ADS) =================
class ShopTab extends StatefulWidget {
  final VoidCallback onRefresh;
  const ShopTab({super.key, required this.onRefresh});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  int subTab = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shop', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                _pill(icon: Icons.monetization_on, iconColor: Colors.amber, text: '${GameData.coins}'),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabChip('Themes', 0),
              const SizedBox(width: 8),
              _tabChip('Hints', 1),
              const SizedBox(width: 8),
              _tabChip('More', 2),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: subTab == 0
                ? GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: kThemes.length,
                    itemBuilder: (_, i) {
                      final t = kThemes[i];
                      final owned = GameData.unlockedThemes.contains('$i');
                      final eq = GameData.selectedTheme == i;
                      return GestureDetector(
                        onTap: () {
                          if (owned) {
                            GameData.selectedTheme = i;
                            GameData.save();
                            SoundEngine.instance.click();
                            setState(() {});
                            widget.onRefresh();
                          } else if (GameData.coins >= t.price) {
                            GameData.coins -= t.price;
                            GameData.unlockedThemes.add('$i');
                            GameData.selectedTheme = i;
                            GameData.save();
                            SoundEngine.instance.win();
                            setState(() {});
                            widget.onRefresh();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: t.bg),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: eq ? const Color(0xFF00E676) : t.accent, width: eq ? 2.5 : 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.science_rounded, color: t.accent, size: 42),
                              Text(t.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(
                                eq ? '✔ Equipped' : (owned ? 'Use' : '${t.price} 🪙'),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: eq ? const Color(0xFF00E676) : Colors.amber),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : subTab == 1
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buyTile('5x Hints Pack 💡', 200, () { GameData.hintCount += 5; }),
                          _buyTile('5x Undo Pack ↩️', 150, () { GameData.undoCount += 5; }),
                          _buyTile('3x Extra Tubes 🧪', 300, () { GameData.tubeCount += 3; }),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Free +50 Coins 🪙', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                                  onPressed: () {
                                    GameData.coins += 50;
                                    GameData.save();
                                    SoundEngine.instance.win();
                                    setState(() {});
                                    widget.onRefresh();
                                  },
                                  child: const Text('Watch Ad', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          _buyTile('Starter Bundle (5 Hints + 5 Undo + 2 Tubes)', 500, () {
                            GameData.hintCount += 5;
                            GameData.undoCount += 5;
                            GameData.tubeCount += 2;
                          }),
                        ],
                      ),
          ),
          // Clickable Remove Ads $1.99 Banner
          GestureDetector(
            onTap: () {
              SoundEngine.instance.click();
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF131B3E),
                  title: const Text('Remove Ads (\$1.99)'),
                  content: const Text('Google Play Billing will be activated once published on Play Store!'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7E22CE), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.block_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Remove Ads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Text('\$1.99', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.amber)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String title, int i) {
    final active = subTab == i;
    return GestureDetector(
      onTap: () => setState(() => subTab = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: active ? const Color(0xFF0284C7) : Colors.white12, borderRadius: BorderRadius.circular(20)),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buyTile(String title, int price, VoidCallback grant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () {
              if (GameData.coins >= price) {
                GameData.coins -= price;
                grant();
                GameData.save();
                SoundEngine.instance.win();
                setState(() {});
                widget.onRefresh();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins!')));
              }
            },
            child: Text('$price 🪙', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// ================= 5. DAILY REWARD (ACTUAL 7-DAY REWARDS) =================
class DailyRewardDialog extends StatelessWidget {
  final VoidCallback onClaimed;
  const DailyRewardDialog({super.key, required this.onClaimed});

  void _grantReward(BuildContext context) {
    String msg = '';
    switch (GameData.dailyDay) {
      case 1:
        GameData.coins += 100;
        msg = 'Day 1 Claimed: +100 Coins 🪙';
        break;
      case 2:
        GameData.coins += 150;
        msg = 'Day 2 Claimed: +150 Coins 🪙';
        break;
      case 3:
        GameData.hintCount += 1;
        msg = 'Day 3 Claimed: +1 Hint 💡';
        break;
      case 4:
        GameData.coins += 250;
        msg = 'Day 4 Claimed: +250 Coins 🪙';
        break;
      case 5:
        GameData.undoCount += 3;
        msg = 'Day 5 Claimed: +3 Undo ↩️';
        break;
      case 6:
        GameData.coins += 500;
        msg = 'Day 6 Claimed: +500 Coins 🪙';
        break;
      case 7:
        if (!GameData.unlockedThemes.contains('2')) {
          GameData.unlockedThemes.add('2');
          msg = 'Day 7 Claimed: Galaxy Theme Unlocked! 🌌';
        } else {
          GameData.coins += 1000;
          msg = 'Day 7 Claimed: +1000 Bonus Coins! 🪙';
        }
        break;
    }
    GameData.dailyDay = (GameData.dailyDay % 7) + 1;
    GameData.lastDailyDate = DateTime.now().toIso8601String().substring(0, 10);
    GameData.save();
    SoundEngine.instance.win();
    onClaimed();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final rewards = ['100 🪙', '150 🪙', '1 Hint', '250 🪙', '3 Undo', '500 🪙'];

    return AlertDialog(
      backgroundColor: const Color(0xFF131B3E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF38BDF8), width: 2),
      ),
      title: const Column(
        children: [
          Text('Daily Reward', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 22)),
          SizedBox(height: 4),
          Text('Login every day to get amazing rewards!', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.9,
              ),
              itemCount: 6,
              itemBuilder: (_, i) {
                final day = i + 1;
                final active = day == GameData.dailyDay;
                return Container(
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF065F46) : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? const Color(0xFF00E676) : Colors.white24, width: active ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Day $day', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 22),
                      const SizedBox(height: 4),
                      Text(rewards[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF7E22CE)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GameData.dailyDay == 7 ? const Color(0xFF00E676) : Colors.amber, width: GameData.dailyDay == 7 ? 2.5 : 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 30),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Day 7', style: TextStyle(fontSize: 12, color: Colors.amber)),
                      Text('Galaxy Theme Skin', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameData.canClaimDaily ? const Color(0xFF00E676) : Colors.white24,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: GameData.canClaimDaily ? () => _grantReward(context) : null,
                child: Text(GameData.canClaimDaily ? 'Claim' : 'Claimed Today ✔',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= 6. SETTINGS SCREEN =================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = kThemes[GameData.selectedTheme];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: theme.bg)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
                  const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 10),
              _card([
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up, color: Color(0xFF38BDF8)),
                  title: const Text('Sound'),
                  value: SoundEngine.instance.sfxOn,
                  onChanged: (v) { setState(() => SoundEngine.instance.sfxOn = v); GameData.save(); },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.music_note, color: Color(0xFF38BDF8)),
                  title: const Text('Music'),
                  value: SoundEngine.instance.musicOn,
                  onChanged: (v) async { await SoundEngine.instance.setMusic(v); setState(() {}); GameData.save(); },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration, color: Color(0xFF38BDF8)),
                  title: const Text('Vibration'),
                  value: SoundEngine.instance.vibOn,
                  onChanged: (v) { setState(() => SoundEngine.instance.vibOn = v); GameData.save(); },
                ),
                ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFF38BDF8)),
                  title: const Text('Language'),
                  trailing: Text(GameData.isMyanmar ? 'မြန်မာ 🇲🇲' : 'English 🇺🇸', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  onTap: () { setState(() => GameData.isMyanmar = !GameData.isMyanmar); GameData.save(); },
                ),
                const ListTile(
                  leading: Icon(Icons.dark_mode, color: Color(0xFF38BDF8)),
                  title: Text('Theme'),
                  trailing: Text('Dark', style: TextStyle(color: Colors.white70)),
                ),
                const ListTile(
                  leading: Icon(Icons.cloud_done, color: Color(0xFF00E676)),
                  title: Text('Save Progress'),
                  trailing: Icon(Icons.check_circle, color: Color(0xFF00E676)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications, color: Color(0xFF00E676)),
                  title: const Text('Notifications'),
                  value: GameData.notificationsOn,
                  onChanged: (v) { setState(() => GameData.notificationsOn = v); GameData.save(); },
                ),
              ]),
              const SizedBox(height: 16),
              _card([
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.white70),
                  title: const Text('How to Play'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _info(context, 'How to Play', 'Tap a tube to pick up the top color, then tap another tube to pour. Group all matching colors into one tube!'),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _info(context, 'Privacy Policy', 'Your game progress is stored locally on your device. Ads are served via Google AdMob.'),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline, color: Colors.white70),
                  title: const Text('Contact Us'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _info(context, 'Contact Us', 'Support Email: support@colorsortmaster.com'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131B3E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(children: children),
      );

  void _info(BuildContext ctx, String t, String msg) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131B3E),
        title: Text(t),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }
}

/// ================= 7. RANK & EVENTS TABS =================
class RankTab extends StatelessWidget {
  const RankTab({super.key});

  @override
  Widget build(BuildContext context) {
    final leaders = [
      ('AlexPro', 142),
      ('LunaSort', 118),
      ('MasterKai', 95),
      ('You', GameData.level),
      ('NovaStar', 10),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Leaderboard 🏆', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: leaders.length,
              itemBuilder: (_, i) {
                final item = leaders[i];
                final isMe = item.$1 == 'You';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF0284C7).withOpacity(0.35) : Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isMe ? const Color(0xFF38BDF8) : Colors.white12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('#${i + 1}   ${item.$1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Lv.${item.$2}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EventsTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const EventsTab({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Special Events ⭐', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF7E22CE)]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                children: [
                  const Icon(Icons.casino_rounded, color: Colors.amber, size: 54),
                  const SizedBox(height: 8),
                  const Text('Lucky Spin Wheel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const Text('Spin to win up to +200 Coins!', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    onPressed: () {
                      AdManager.showRewarded(() {
                        final prize = [20, 50, 100, 200][Random().nextInt(4)];
                        GameData.coins += prize;
                        GameData.save();
                        SoundEngine.instance.win();
                        onRefresh();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You won +$prize Coins! 🎉')));
                      });
                    },
                    child: const Text('SPIN NOW (AD)', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= HELPER WIDGET =================
Widget _pill({required IconData icon, required Color iconColor, required String text, Widget? trailing}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF16214D),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        if (trailing != null) ...[const SizedBox(width: 6), trailing],
      ],
    ),
  );
}