import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(AhjuApp());

class AhjuApp extends StatefulWidget {
  @override
  _AhjuAppState createState() => _AhjuAppState();
}

class _AhjuAppState extends State<AhjuApp> {
  bool isDarkMode = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: FyrePlanLoplik(
        isDark: isDarkMode, 
        onThemeChanged: (val) => setState(() => isDarkMode = val)
      ),
    );
  }
}

class FyrePlanLoplik extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChanged;
  FyrePlanLoplik({required this.isDark, required this.onThemeChanged});
  @override
  _FyrePlanLoplikState createState() => _FyrePlanLoplikState();
}

class _FyrePlanLoplikState extends State<FyrePlanLoplik> {
  // Kõik kontrollerid on tagasi
  final pindalaCtrl = TextEditingController(text: "100");
  final korgusCtrl = TextEditingController(text: "2.5");
  final seinM2Ctrl = TextEditingController(text: "120");
  final villaMmCtrl = TextEditingController(text: "200");
  final akenM2Ctrl = TextEditingController(text: "15");
  final uksM2Ctrl = TextEditingController(text: "4");

  final hindPunaneCtrl = TextEditingController(text: "1.15");
  final hindSamottCtrl = TextEditingController(text: "3.40");
  final hindSeguCtrl = TextEditingController(text: "16.00");

  String seinMaterjal = 'Puitkarkass';
  String aknaTuup = '3-kordne pakett';
  String ventTuup = 'Loomulik';
  
  double soojakaduW = 0;
  int kokkuTellised = 0;
  bool naita = false;

  double ahjuLaius = 0.85; 
  double ahjuSyga = 0.85;
  double ahjuKorgus = 2.10;

  void arvuta() {
    setState(() {
      double pindala = double.tryParse(pindalaCtrl.text.replaceAll(',', '.')) ?? 0;
      double korgus = double.tryParse(korgusCtrl.text.replaceAll(',', '.')) ?? 2.5;
      double seinad = double.tryParse(seinM2Ctrl.text.replaceAll(',', '.')) ?? 0;
      double villa = double.tryParse(villaMmCtrl.text.replaceAll(',', '.')) ?? 0;
      double aknad = double.tryParse(akenM2Ctrl.text.replaceAll(',', '.')) ?? 0;
      double uksed = double.tryParse(uksM2Ctrl.text.replaceAll(',', '.')) ?? 0;

      const double dT = 42.0;
      
      // Seinad
      double uSein = (seinMaterjal == 'Palk') ? 0.55 : (seinMaterjal == 'Kivimaja' ? ((villa < 10) ? 1.5 : 45 / (villa + 5)) : 40 / (villa + 1));
      // Aknad
      double uAken = (aknaTuup == '3-kordne pakett') ? 0.8 : 1.4;
      
      double kaduSein = (seinad - aknad - uksed) * uSein * dT;
      double kaduAken = aknad * uAken * dT;
      double kaduUks = uksed * 1.6 * dT;
      double kaduLagi = pindala * 0.15 * dT;
      double kaduPorand = pindala * 0.14 * dT;
      
      double ventKordaja = (ventTuup == 'Loomulik') ? 0.33 : 0.07;
      double kaduVent = ventKordaja * (pindala * korgus) * dT;

      soojakaduW = kaduSein + kaduAken + kaduUks + kaduLagi + kaduPorand + kaduVent;
      kokkuTellised = (soojakaduW / 1000 * 195).toInt(); 

      double mahtM3 = kokkuTellised / 450; 
      ahjuLaius = 0.85;
      ahjuKorgus = 2.1;
      ahjuSyga = mahtM3 / (ahjuLaius * ahjuKorgus);
      if (ahjuSyga < 0.6) ahjuSyga = 0.60;
      
      naita = true;
    });
  }

  void kopeeri(double kw, double hind, int p, int s, int m) {
    String tekst = "Ahju pakkumine:\n"
        "Vajalik võimsus: ${kw.toStringAsFixed(2)} kW\n"
        "Materjalid:\n - Punane tellis: $p tk\n - Šamott: $s tk\n - Segu: $m kotti\n"
        "Eelarve: ${hind.toStringAsFixed(2)} €";
    Clipboard.setData(ClipboardData(text: tekst));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kopeeritud!")));
  }

  @override
  Widget build(BuildContext context) {
    double voimsusKW = soojakaduW / 1000;
    int punane = (kokkuTellised * 0.75).toInt();
    int samott = (kokkuTellised * 0.25).toInt();
    int segud = (kokkuTellised / 45).ceil();
    
    double pHind = double.tryParse(hindPunaneCtrl.text) ?? 0;
    double sHind = double.tryParse(hindSamottCtrl.text) ?? 0;
    double mHind = double.tryParse(hindSeguCtrl.text) ?? 0;
    double summa = (punane * pHind) + (samott * sHind) + (segud * mHind);

    return Scaffold(
      appBar: AppBar(title: Text("FyrePlan Pro"), backgroundColor: Colors.orange[900]),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Text("MAJA ANDMED", style: TextStyle(fontWeight: FontWeight.bold)),
                      rida("Pindala (m2)", pindalaCtrl),
                      rida("Seinte pind (m2)", seinM2Ctrl),
                      rida("Seina kõrgus (m)", korgusCtrl),
                      rida("Aknad (m2)", akenM2Ctrl),
                      rida("Uksed (m2)", uksM2Ctrl),
                      
                      DropdownButtonFormField<String>(
                        value: seinMaterjal,
                        items: ['Puitkarkass', 'Palk', 'Kivimaja'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => seinMaterjal = v!),
                        decoration: InputDecoration(labelText: "Seina tüüp"),
                      ),
                      if (seinMaterjal != 'Palk') rida("Villa paksus (mm)", villaMmCtrl),
                      
                      DropdownButtonFormField<String>(
                        value: aknaTuup,
                        items: ['2-kordne pakett', '3-kordne pakett'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => aknaTuup = v!),
                        decoration: InputDecoration(labelText: "Akna tüüp"),
                      ),
                      DropdownButtonFormField<String>(
                        value: ventTuup,
                        items: ['Loomulik', 'Soojatagastusega'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => ventTuup = v!),
                        decoration: InputDecoration(labelText: "Ventilatsioon"),
                      ),
                      
                      Divider(height: 30),
                      Text("MATERJALIDE HINNAD (€)", style: TextStyle(fontWeight: FontWeight.bold)),
                      rida("Punane tellis (tk)", hindPunaneCtrl),
                      rida("Šamott (tk)", hindSamottCtrl),
                      rida("Segu (kott)", hindSeguCtrl),
                      
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: arvuta,
                        child: Text("ARVUTA JA JOONISTA"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[900], foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50)),
                      ),
                    ],
                  ),
                ),
              ),
              if (naita) ...[
                SizedBox(height: 20),
                Text("AHJU JOONIS (Ridade arv: ${(ahjuKorgus / 0.075).round()})", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                AhjuJoonis(laius: ahjuLaius, korgus: ahjuKorgus),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(border: Border.all(color: Colors.orange), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      tulemusRida("Vajalik võimsus:", "${voimsusKW.toStringAsFixed(2)} kW"),
                      tulemusRida("Punane tellis:", "$punane tk"),
                      tulemusRida("Šamott-tellis:", "$samott tk"),
                      tulemusRida("Segu (25kg):", "$segud tk"),
                      tulemusRida("Mõõdud (cm):", "${(ahjuLaius*100).toInt()}x${(ahjuSyga*100).toInt()}"),
                      Divider(),
                      Text("KOKKU: ${summa.toStringAsFixed(2)} €", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                      TextButton.icon(
                        onPressed: () => kopeeri(voimsusKW, summa, punane, samott, segud),
                        icon: Icon(Icons.copy), label: Text("Kopeeri pakkumine")
                      )
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget rida(String s, TextEditingController c) => Padding(padding: EdgeInsets.symmetric(vertical: 4), child: TextField(controller: c, decoration: InputDecoration(labelText: s, border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true)));
  Widget tulemusRida(String s, String v) => Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(s), Text(v, style: TextStyle(fontWeight: FontWeight.bold))]));
}

class AhjuJoonis extends StatelessWidget {
  final double laius;
  final double korgus;
  AhjuJoonis({required this.laius, required this.korgus});

  @override
  Widget build(BuildContext context) {
    int ridadeArv = (korgus / 0.075).round();
    double scale = 2.0; 
    double drawWidth = laius * 100 * scale;
    double rowHeight = 7.5 * scale;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Column(
          children: List.generate(ridadeArv, (index) {
            bool isShifted = index % 2 == 0;
            return Container(
              height: rowHeight,
              width: drawWidth,
              decoration: BoxDecoration(
                color: Colors.orange[800],
                border: Border(bottom: BorderSide(color: Colors.orange[900]!, width: 0.5)),
              ),
              child: CustomPaint(
                painter: MuuriPainter(isShifted: isShifted, scale: scale),
              ),
            );
          }).reversed.toList(),
        ),
        Positioned(
          bottom: rowHeight * 4, 
          child: Container(
            width: drawWidth * 0.5,
            height: rowHeight * 6,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border.all(color: Colors.black, width: 3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Container(
                width: drawWidth * 0.4,
                height: rowHeight * 4,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
                child: Icon(Icons.fireplace, color: Colors.orange[900], size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MuuriPainter extends CustomPainter {
  final bool isShifted;
  final double scale;
  MuuriPainter({required this.isShifted, required this.scale});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.orange[900]!..strokeWidth = 1.0;
    double brickWidth = 25.0 * scale; 
    double startX = isShifted ? (brickWidth / 2) : 0;
    for (double x = startX; x < size.width; x += brickWidth) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}