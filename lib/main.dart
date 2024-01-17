import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

enum DotColor { Blue, Red, Brown }

class MovingDot {
  late Offset position;
  late Offset direction;

  MovingDot(double x, double y) {
    position = Offset(x, y);
    direction = getRandomDirection();
    // 添加定時器，每100毫秒更新一次方向
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      direction = getRandomDirection();
    });
  }

  Offset getRandomDirection() {
    double randomAngle = Random().nextDouble() * 2 * pi;
    return Offset.fromDirection(randomAngle, 15.0);
  }

  void updatePosition(double screenWidth, double screenHeight) {
    position += direction;

    if (position.dx < 0 || position.dx > screenWidth - 10) {
      direction = Offset(-direction.dx, direction.dy);
    }
    if (position.dy < 0 || position.dy > screenHeight - 10) {
      direction = Offset(direction.dx, -direction.dy);
    }

    // 確保點在合法的範圍內
    position = Offset(
      position.dx.clamp(0.0, screenWidth - 10),
      position.dy.clamp(0.0, screenHeight - 10),
    );
  }
}

class ColoredDot {
  late DotColor color;
  late MovingDot movingDot;

  ColoredDot(double x, double y, DotColor dotColor) {
    color = dotColor;
    movingDot = MovingDot(x, y);
  }

  void updateMovingDotPosition(BuildContext context) {
    movingDot.updatePosition(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );

    // 確保點在合法的範圍內
    movingDot.position = Offset(
      movingDot.position.dx.clamp(0.0, MediaQuery.of(context).size.width - 10),
      movingDot.position.dy.clamp(0.0, MediaQuery.of(context).size.height - 10),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SpriteHuntGame(),
    );
  }
}

class SpriteHuntGame extends StatefulWidget {
  @override
  _SpriteHuntGameState createState() => _SpriteHuntGameState();
}

class _SpriteHuntGameState extends State<SpriteHuntGame> {
  bool gameOver = false;
  bool win = false;
  Random random = Random();
  late Offset position;
  int score = 0;
  List<Offset> greenDots = [];
  List<ColoredDot> coloredDots = [];
  bool initialized = false;

  void checkWinCondition() {
    // 判斷是否所有綠點都已經被吃掉
    if (greenDots.isEmpty && !gameOver && !win) {
      setState(() {
        win = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    position = Offset(50, 150);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: []);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (!initialized) {
        initialized = true;
        generateGreenDots();
        generateColoredDots();
        startAnimation();
        startAutoMove();
      }
    });
  }

  void startAutoMove() {
    // 在遊戲結束後不再更新紅、棕、藍點的方向
    if (!gameOver) {
      // 定時器，每100毫秒更新一次紅、藍、棕點的方向
      Timer.periodic(Duration(milliseconds: 100), (timer) {
        updateColoredDotsPosition();
      });
    }
  }

  void updateColoredDotsPosition() {
    if (!gameOver && !win) {
      setState(() {
        for (var dot in coloredDots) {
          dot.updateMovingDotPosition(context); // 更新藍、紅、棕圓形的位置
        }
      });
    }
  }

  void generateGreenDots() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < 20; i++) {
      double x = random.nextDouble() * (screenWidth - 20) + 10; // 調整 x 的範圍
      double y = random.nextDouble() * (screenHeight - 20) + 10; // 調整 y 的範圍
      greenDots.add(Offset(x, y));
    }
  }

  void generateColoredDots() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < 3; i++) {
      double x = random.nextDouble() * (screenWidth - 60) + 30; // 調整 x 的範圍
      double y = random.nextDouble() * (screenHeight - 60) + 30; // 調整 y 的範圍
      DotColor color = DotColor.values[i];
      coloredDots.add(ColoredDot(x, y, color));
    }
  }

  void updateColoredDots() {
    setState(() {
      for (var dot in coloredDots) {
        dot.updateMovingDotPosition(context); // 更新藍、紅、棕圓形的位置
      }
    });
  }

  void updateYellowDot({bool isKeyboardEvent = false}) {
    // 在遊戲結束後不再更新黃色點的位置
    if (!gameOver) {
      if (isKeyboardEvent) {
        setState(() {
          position += Offset(2.0, 2.0);
        });
      }
    }
  }

  void updateAllDots() {
    setState(() {
      updateColoredDots();
      updateYellowDot(); // 更新黃色點的位置
    });

    checkCollisions();
    checkWinCondition(); // 檢查是否達到勝利條件
  }

  void startAnimation() {
    // 定期更新動畫，此處每100毫秒更新一次
    Duration duration = Duration(milliseconds: 100);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      updateAllDots(); // 更新所有點的位置
      updateColoredDotsPosition(); // 更新藍、紅、棕圓形的位置
      Future.delayed(duration, () => startAnimation());
    });
  }

  void handleArrowKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent && !gameOver && !win) {
      setState(() {
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          position = Offset(position.dx, max(position.dy - 10, 0));
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          position = Offset(position.dx,
              min(position.dy + 10, MediaQuery.of(context).size.height - 30));
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          position = Offset(position.dx - 10, max(position.dy, 0));
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          position = Offset(
              min(position.dx + 10, MediaQuery.of(context).size.width - 30),
              position.dy);
        }

        // 更新 coloredDots 的位置
        updateColoredDots();

        checkCollisions();

        // 更新黃色點的位置，傳遞 true 表示是由鍵盤事件觸發的
        updateYellowDot(isKeyboardEvent: true);
      });
    }
  }

  void checkCollisions() {
    List<Offset> collidedDots = [];
    double spriteCenterX = position.dx + 12.5;
    double spriteCenterY = position.dy + 12.5;

    for (var dot in coloredDots) {
      double spriteCenterX = position.dx + 12.5;
      double spriteCenterY = position.dy + 12.5;
      double dotCenterX = dot.movingDot.position.dx + 20; // 假設圓形的半徑為20
      double dotCenterY = dot.movingDot.position.dy + 20; // 假設圓形的半徑為20
      double radiusSum = 12.5 + 20; // 半徑和

      if ((spriteCenterX - dotCenterX).abs() < radiusSum &&
          (spriteCenterY - dotCenterY).abs() < radiusSum) {
        setState(() {
          // Handle collision with colored dot here
          // For now, let's just reset the colored dot's position and direction
          dot.movingDot.position = Offset(
            random.nextDouble() * (MediaQuery.of(context).size.width - 100) +
                50,
            random.nextDouble() * (MediaQuery.of(context).size.height - 100) +
                50,
          );
          dot.movingDot.direction = dot.movingDot.getRandomDirection();

          // 碰到紅、棕、藍點，設置遊戲為結束
          gameOver = true;
          win = false;
        });
      }
    }

    for (int i = 0; i < greenDots.length; i++) {
      double dotCenterX = greenDots[i].dx + 5;
      double dotCenterY = greenDots[i].dy + 5;
      double radiusSum = 12.5 + 5; // 半徑和

      if ((spriteCenterX - dotCenterX).abs() < radiusSum &&
          (spriteCenterY - dotCenterY).abs() < radiusSum) {
        setState(() {
          score += 10;
          collidedDots.add(greenDots[i]);
        });
      }
    }

    for (var dot in collidedDots) {
      greenDots.remove(dot);
    }

    if (greenDots.isEmpty && !gameOver) {
      setState(() {
        win = true;
        gameOver = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('小精靈'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '分數: $score',
              style: TextStyle(fontSize: 20),
            ),
          ),
          Expanded(
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: handleArrowKey,
              child: Stack(
                children: [
                  Container(
                    color: (gameOver || win)
                        ? Colors.grey.withOpacity(0.7)
                        : Colors.white,
                  ),
                  ...greenDots.map((dot) => Positioned(
                        left: dot.dx,
                        top: dot.dy,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )),
                  ...coloredDots.map((dot) => Positioned(
                        left: dot.movingDot.position.dx,
                        top: dot.movingDot.position.dy,
                        child: Container(
                          width: (dot.color == DotColor.Blue ||
                                  dot.color == DotColor.Red ||
                                  dot.color == DotColor.Brown)
                              ? 40
                              : 10,
                          height: (dot.color == DotColor.Blue ||
                                  dot.color == DotColor.Red ||
                                  dot.color == DotColor.Brown)
                              ? 40
                              : 10,
                          decoration: BoxDecoration(
                            color: getColor(dot.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )),
                  Positioned(
                    left: position.dx - 12.5,
                    top: position.dy - 12.5,
                    child: CustomSprite(),
                  ),
                  if (gameOver)
                    Center(
                      child: Text(
                        'Game Over',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  if (win)
                    Center(
                      child: Text(
                        'Congratulation!\n  You Win',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getColor(DotColor color) {
    switch (color) {
      case DotColor.Blue:
        return const Color.fromARGB(255, 4, 71, 125);
      case DotColor.Red:
        return Colors.red;
      case DotColor.Brown:
        return Colors.brown;
    }
  }
}

class CustomSprite extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: 25,
        height: 25,
        color: Colors.yellow.shade300,
      ),
    );
  }
}
