import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const ColorSortApp());
}

class ColorSortApp extends StatelessWidget {
  const ColorSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Color Sort Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int maxCapacity = 4;

  // ဂိမ်းထဲမှာ သုံးမယ့် အရောင်များ
  final List<Color> palette = [
    const Color(0xFFFF4D6D), // အနီ
    const Color(0xFF4CC9F0), // အပြာနု
    const Color(0xFF80ED99), // အစိမ်း
    const Color(0xFFFFD166), // အဝါ
    const Color(0xFF9D4EDD), // ခရမ်း
    const Color(0xFFFF9F1C), // လိမ္မော်
    const Color(0xFF06D6A0), // စိမ်းပြာ
    const Color(0xFFF72585), // ပန်းရောင်
  ];

  int currentLevel = 1;
  List<List<Color>> bottles = [];
  List<List<List<Color>>> history = []; // Undo အတွက် မှတ်တမ်း
  int? selectedBottleIndex;
  bool extraBottleUsed = false;

  @override
  void initState() {
    super.initState();
    _initLevel(currentLevel);
  }

  // Level အလိုက် ဖန်ခွက်နဲ့ အရောင်များ ထုတ်ပေးခြင်း
  void _initLevel(int level) {
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
      newBottles.add(
        allDrops.sublist(i * maxCapacity, (i + 1) * maxCapacity),
      );
    }

    // ဖန်ခွက်အလွတ် ၂ ခွက် ထည့်မယ်
    newBottles.add([]);
    newBottles.add([]);

    setState(() {
      bottles = newBottles;
      history.clear();
      selectedBottleIndex = null;
      extraBottleUsed = false;
    });
  }

  // ဖန်ခွက်ကို နှိပ်တဲ့အခါ အလုပ်လုပ်မယ့် Logic
  void _onBottleTap(int index) {
    if (selectedBottleIndex == null) {
      // အရောင်ရှိတဲ့ ဖန်ခွက်ကိုပဲ ရွေးခွင့်ပေးမယ်
      if (bottles[index].isNotEmpty) {
        setState(() {
          selectedBottleIndex = index;
        });
      }
    } else if (selectedBottleIndex == index) {
      // ရွေးထားတဲ့ခွက်ကိုပဲ ပြန်နှိပ်ရင် ရွေးတာပြန်ဖြုတ်မယ်
      setState(() {
        selectedBottleIndex = null;
      });
    } else {
      _pourWater(selectedBottleIndex!, index);
    }
  }

  // ရေလောင်းထည့်ခြင်း Logic
  void _pourWater(int from, int to) {
    List<Color> fromBottle = bottles[from];
    List<Color> toBottle = bottles[to];

    if (fromBottle.isEmpty || toBottle.length >= maxCapacity) {
      setState(() => selectedBottleIndex = null);
      return;
    }

    Color topColor = fromBottle.last;

    // ဖန်ခွက်အလွတ် သို့မဟုတ် အပေါ်ဆုံးအရောင်တူမှ လောင်းလို့ရမယ်
    if (toBottle.isEmpty || toBottle.last == topColor) {
      // Undo အတွက် လက်ရှိအခြေအနေကို သိမ်းထားမယ်
      history.add(bottles.map((b) => List<Color>.from(b)).toList());

      setState(() {
        while (fromBottle.isNotEmpty &&
            fromBottle.last == topColor &&
            toBottle.length < maxCapacity) {
          toBottle.add(fromBottle.removeLast());
        }
        selectedBottleIndex = null;
      });

      _checkWin();
    } else {
      // အရောင်မတူရင် ရွေးထားတာ ပြန်ဖြုတ်မယ်
      setState(() => selectedBottleIndex = null);
    }
  }

  // နိုင်/မနိုင် စစ်ဆေးခြင်း
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text('Level Complete! 🎉', textAlign: TextAlign.center),
          content: Text(
            'Level $currentLevel ကို အောင်မြင်စွာ ဖြတ်ကျော်နိုင်ပါပြီ။',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06D6A0),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  currentLevel++;
                });
                _initLevel(currentLevel);
              },
              child: const Text('Next Level', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  // နောက်ပြန်ဆုတ်ခြင်း (Undo)
  void _undo() {
    if (history.isNotEmpty) {
      setState(() {
        bottles = history.removeLast();
        selectedBottleIndex = null;
      });
    }
  }

  // ဖန်ခွက်အပို ၁ ခွက်ယူခြင်း (နောက်ပိုင်း AdMob Rewarded Ad ချိတ်မယ့်နေရာ)
  void _addExtraBottle() {
    if (extraBottleUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ဒီ Level အတွက် ဖန်ခွက်အပို ယူပြီးပါပြီ။')),
      );
      return;
    }
    setState(() {
      bottles.add([]);
      extraBottleUsed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'LEVEL $currentLevel',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart',
            onPressed: () => _initLevel(currentLevel),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // ဖန်ခွက်များ ပြသမယ့်နေရာ
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 18,
                runSpacing: 28,
                alignment: WrapAlignment.center,
                children: List.generate(bottles.length, (index) {
                  return _buildBottle(index);
                }),
              ),
            ),
          ),
          // အောက်ခြေ ခလုတ်များ (Undo & +1 Bottle)
          Padding(
            padding: const EdgeInsets.only(bottom: 36, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  icon: Icons.undo,
                  label: 'Undo',
                  onTap: _undo,
                ),
                _actionButton(
                  icon: Icons.add_circle_outline,
                  label: '+1 Bottle (Ad)',
                  onTap: _addExtraBottle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottle(int index) {
    bool isSelected = selectedBottleIndex == index;
    List<Color> colors = bottles[index];

    return GestureDetector(
      onTap: () => _onBottleTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, isSelected ? -20 : 0, 0),
        width: 56,
        height: 170,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD166) : Colors.white54,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: List.generate(colors.length, (cIndex) {
            // အပေါ်ဆုံးအရောင်ကို အပေါ်မှာပြဖို့ ပြောင်းပြန်စီမယ်
            Color color = colors[colors.length - 1 - cIndex];
            bool isBottom = (colors.length - 1 - cIndex) == 0;
            return Container(
              height: 38,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: isBottom
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      )
                    : BorderRadius.zero,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
