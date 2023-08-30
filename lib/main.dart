import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dynamic_island_manager.dart';
import 'dynamic_island_stopwatch_data_model.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

void main() {
  runApp(const TimerScreen(
    taskName: 'Task',
  ));
}

class TimerScreen extends StatefulWidget {
  final String taskName;

  const TimerScreen({Key? key, required this.taskName}) : super(key: key);

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late Duration _duration = Duration.zero;
  bool _isPaused = false;
  bool _isStarted = false;
  double _percentComplete = 0.0;
  Timer? _timer;
  Duration _elapsedDuration = Duration.zero;
  Duration _pausedDuration = Duration.zero;

  final DynamicIslandManager diManager = DynamicIslandManager(channelKey: 'DI');
  bool _isLiveActivityRunning = false;
  Timer? _liveActivityTimer;
  int _liveActivitySeconds = 0;

  void _startLiveActivity() {
    setState(() {
      _isLiveActivityRunning = true;
    });

    diManager.startLiveActivity(
      jsonData: DynamicIslandStopwatchDataModel(elapsedSeconds: 0).toMap(),
    );

    _liveActivityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _liveActivitySeconds++;
      });

      diManager.updateLiveActivity(
        jsonData: DynamicIslandStopwatchDataModel(
          elapsedSeconds: _liveActivitySeconds,
        ).toMap(),
      );
    });
  }

  void _stopLiveActivity() {
    _liveActivityTimer?.cancel();
    setState(() {
      _liveActivitySeconds = 0;
      _isLiveActivityRunning = false;
    });

    diManager.stopLiveActivity();
  }

  void _pauseTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _pausedDuration = _elapsedDuration;
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
    _startTimerFromPaused();
  }

  void _startTimerFromPaused() {
    final pausedSeconds = _pausedDuration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if ((_elapsedDuration + Duration(seconds: pausedSeconds)).inSeconds >=
            _duration.inSeconds) {
          timer.cancel();
          _isStarted = false;
        } else {
          _elapsedDuration = _elapsedDuration + const Duration(seconds: 1);

          if (!_isPaused) {
            _percentComplete = (_elapsedDuration.inSeconds + pausedSeconds) /
                _duration.inSeconds;
          }

          if (!_isLiveActivityRunning) {
            _startLiveActivity();
          }
        }
      });
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_elapsedDuration.inSeconds >= _duration.inSeconds) {
          timer.cancel();
          _isStarted = false;
        } else {
          _elapsedDuration = Duration(seconds: _elapsedDuration.inSeconds + 1);
          _percentComplete = _elapsedDuration.inSeconds / _duration.inSeconds;

          if (!_isLiveActivityRunning) {
            _startLiveActivity();
          }
        }
      });
    });
  }

  void _stopTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    setState(() {
      _isPaused = false;
      _isStarted = false;
      _duration = const Duration();
      _percentComplete = 0.0;
      _stopLiveActivity();
    });
  }

  void _setTimer(Duration duration) {
    if (duration.inSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No time has been set.'),
        ),
      );
    } else {
      setState(() {
        _duration = duration;
        _isStarted = true;
        _isPaused = false;
        _elapsedDuration = const Duration();
        _percentComplete = 0.0;
      });
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      CupertinoIcons.back,
                      size: 28,
                    ),
                  ),
                  const SizedBox(
                      height: 10), // Spacer between Back Button and Timer Text
                  const Text(
                    'Timer', // Your Timer Text here
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: CupertinoButton(
                onPressed: () {
                  // Add your action here for the timer icon click
                },
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  CupertinoIcons.timer,
                  size: 28,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.taskName,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  !_isStarted
                      ? CupertinoTimerPicker(
                          mode: CupertinoTimerPickerMode.hms,
                          onTimerDurationChanged: (duration) {
                            setState(() {
                              _duration = duration;
                            });
                          },
                        )
                      : CircularPercentIndicator(
                          radius: MediaQuery.of(context).size.width * 0.6,
                          lineWidth: 10.0,
                          percent: _percentComplete,
                          center: Text(
                            '${_elapsedDuration.inHours.toString().padLeft(2, '0')}:${(_elapsedDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsedDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 40),
                          ),
                          progressColor: Colors.pink,
                        ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _isStarted && !_isPaused
                          ? ElevatedButton(
                              onPressed: _pauseTimer,
                              style: ElevatedButton.styleFrom(
                                primary: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(120, 48),
                              ),
                              child: const Text(
                                'Pause',
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isPaused
                                  ? _resumeTimer
                                  : () => _setTimer(_duration),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(120, 48),
                              ),
                              child: Text(
                                _isPaused ? 'Resume' : 'Start',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                      ElevatedButton(
                        onPressed: _isStarted ? _stopTimer : null,
                        style: ElevatedButton.styleFrom(
                          primary: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          minimumSize: const Size(120, 48),
                        ),
                        child: const Text(
                          'Stop',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
