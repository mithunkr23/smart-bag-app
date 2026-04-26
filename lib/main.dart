import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/* -----------------------------
   MAIN
----------------------------- */

void main() {
  runApp(SmartBagApp());
}

class SmartBagApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bag',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

/* -----------------------------
   DATA
----------------------------- */

final Map<String, String> bookMap = {
  "8904304780960": "ML",
  "8904304525271": "CC",
  "9102995996175": "BCT",
};

final Map<String, List<String>> timetable = {
  "Monday": ["CC", "BCT"],
  "Tuesday": ["ML", "CC"],
  "Wednesday": ["ML", "CC", "BCT"],
  "Thursday": ["CC", "BCT"],
  "Friday": ["CC", "ML"],
  "Saturday": ["BCT","ML"],
  "Sunday": ["ML","CC"],
};

/* -----------------------------
   TWILIO SMS FUNCTION
----------------------------- */

Future<void> sendSMS(String message) async {
  final accountSid = "YOUR_ACCOUNT_SID";
  final authToken = "YOUR_AUTH_TOKEN";
  final fromNumber = "+xxxxxxxxx";
  final toNumber = "+91XXXXXXXXXX";

  final url = Uri.parse(
      "https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json");

  final auth = base64Encode(utf8.encode('$accountSid:$authToken'));

  await http.post(
    url,
    headers: {
      "Authorization": "Basic $auth",
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body: {
      "From": fromNumber,
      "To": toNumber,
      "Body": message,
    },
  );
}

/* -----------------------------
   HOME SCREEN
----------------------------- */

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smart Bag")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ScannerScreen()),
            );

            if (result != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Detected: ${result['detected'].join(", ")}\n\n"
                    "Missing: ${result['missing'].isEmpty ? "None" : result['missing'].join(", ")}",
                  ),
                ),
              );
            }
          },
          child: Text("Scan Barcode"),
        ),
      ),
    );
  }
}

/* -----------------------------
   SCANNER SCREEN
----------------------------- */

class ScannerScreen extends StatefulWidget {
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  Set<String> detectedSubjects = {};
  bool isFinished = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 10), () {
      if (mounted && !isFinished) {
        finishScanning();
      }
    });
  }

  String getDayName() {
    return [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday"
    ][DateTime.now().weekday % 7];
  }

  // FIXED FUNCTION
  void processCode(String code) {
    if (!bookMap.containsKey(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ Unknown barcode detected"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String subject = bookMap[code]!;

    if (!detectedSubjects.contains(subject)) {
      setState(() {
        detectedSubjects.add(subject);
      });
    }

    String today = getDayName();
    List<String> todaySubjects = timetable[today] ?? [];

    if (todaySubjects.every((sub) => detectedSubjects.contains(sub))) {
      finishScanning();
    }
  }

  void finishScanning() async {
    if (isFinished) return;
    isFinished = true;

    String today = getDayName();
    List<String> todaySubjects = timetable[today] ?? [];

    List<String> missing = todaySubjects
        .where((sub) => !detectedSubjects.contains(sub))
        .toList();

    String message =
    "📚 Detected: ${detectedSubjects.isEmpty ? "None" : detectedSubjects.join(", ")}\n\n"
    "❌ Missing: ${missing.isEmpty ? "None" : missing.join(", ")}";

    await sendSMS(message);

    Navigator.pop(context, {
      "detected": detectedSubjects.toList(),
      "missing": missing,
    });
  }

  @override
  Widget build(BuildContext context) {
    String today = getDayName();
    List<String> todaySubjects = timetable[today] ?? [];

    List<String> missing = todaySubjects
        .where((sub) => !detectedSubjects.contains(sub))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Scan Books (10 sec)")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: (barcodeCapture) {
                if (isFinished) return;

                for (final barcode in barcodeCapture.barcodes) {
                  final code = barcode.rawValue;
                  if (code != null) {
                    processCode(code);
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(12),
              width: double.infinity,
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📅 Today: $today",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  SizedBox(height: 8),

                  Text("✅ Detected:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(detectedSubjects.isEmpty
                      ? "None"
                      : detectedSubjects.join(", ")),

                  SizedBox(height: 10),

                  Text("❌ Missing:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(missing.isEmpty ? "None" : missing.join(", ")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}