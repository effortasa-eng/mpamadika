import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';

const colN = ['Mena', 'Manga', 'Maitso', 'Mavo'];
const colC = [Color(0xFFDC2626), Color(0xFF2563EB), Color(0xFF15803D), Color(0xFFA16207)];
const svc = 'mg.mpamadika';

void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
    darkTheme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true, brightness: Brightness.dark),
    home: const Home()));

// ---------- Lojika (ao amin'ny telefaona hôte ihany) ----------
class Kard {
  final int c, n;
  Kard(this.c, this.n);
  Map<String, dynamic> toJson() => {'c': c, 'n': n};
}

class Sus {
  final Kard k;
  final bool t;
  bool r = false;
  Sus(this.k, this.t);
}

class Game {
  int mission = 1, thr = 9, T = 1, f = 0, b = 3, t = 0, end = 0;
  String msg = 'Natomboka ny iraka.';
  List<Sus> sus = [];
  List<List<Kard>> hands = [];
  List<Kard> qg = [];

  Game(this.mission, int p) {
    final r = Random();
    final s = 4 + (mission - 1) ~/ 4;
    T = 1 + (mission - 1) ~/ 7;
    thr = 8 + r.nextInt(4);
    b = T + 2;
    final d = <Kard>[for (var c = 0; c < 4; c++) for (var n = 2; n <= 15; n++) Kard(c, n)]..shuffle(r);
    final hi = d.where((x) => x.n >= thr).take(T);
    final lo = d.where((x) => x.n < thr).take(s - T);
    sus = [...hi.map((x) => Sus(x, true)), ...lo.map((x) => Sus(x, false))]..shuffle(r);
    final used = sus.map((e) => e.k).toSet();
    final rest = d.where((x) => !used.contains(x)).toList();
    hands = [for (var i = 0; i < p; i++) rest.sublist(i * 5, i * 5 + 5)];
    qg = rest.sublist(p * 5);
  }

  void _over(int e, String why) {
    end = e;
    for (final s in sus) s.r = true;
    msg = '$msg\n$why';
  }

  bool act(int p, Map<String, dynamic> m) {
    if (end != 0 || p != t) return false;
    final pl = 'Mpilalao ${p + 1}';
    if (m['a'] == 'ask') {
      final i = m['i'] as int, ty = m['ty'] as int;
      if (i < 0 || i >= hands[p].length) return false;
      final x = hands[p].removeAt(i);
      final n = sus.where((s) => ty == 1 ? s.k.n >= x.n : s.k.c == x.c).length;
      msg = '$pl : ${colN[x.c]} ${x.n} → misy $n ahiahiana ${ty == 1 ? 'manana isa ≥ ${x.n}' : colN[x.c]}.';
      if (qg.isEmpty) {
        _over(2, 'Lany ny karatra ao amin’ny Foibe.');
        return true;
      }
      hands[p].add(qg.removeLast());
    } else if (m['a'] == 'fire') {
      final i = m['i'] as int;
      if (i < 0 || i >= sus.length || sus[i].r) return false;
      final s = sus[i];
      s.r = true;
      if (s.t) {
        f++;
        msg = '$pl : nitifitra #${i + 1} → mpamadika!';
      } else {
        b--;
        msg = '$pl : nitifitra #${i + 1} → tsy meloka.';
      }
      if (f >= T) {
        _over(1, 'Hita ny mpamadika rehetra!');
        return true;
      }
      if (b <= 0) {
        _over(2, 'Lany ny bala.');
        return true;
      }
    } else {
      return false;
    }
    t = (t + 1) % hands.length;
    return true;
  }

  Map<String, dynamic> view(int p) => {
        'you': p, 'turn': t, 'm': mission, 'thr': thr, 'T': T, 'f': f, 'b': b,
        'qg': qg.length, 'msg': msg, 'end': end,
        'sus': [for (final s in sus) s.r ? {'c': s.k.c, 'n': s.k.n, 't': s.t} : null],
        'hand': [for (final x in hands[p]) x.toJson()],
      };
}

// ---------- Fifandraisana + UI ----------
class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final nearby = Nearby();
  final nameC = TextEditingController(text: 'Mpilalao');
  final order = <String>[];
  final names = <String, String>{};
  final found = <String, String>{};
  Game? g;
  Map<String, dynamic>? v;
  bool host = false, lobby = false;
  String? hostId;
  String st = '';
  int mission = 1;
  int? sel;
  List<int> marks = List.filled(8, 0);

  Future<void> perms() async {
    await nearby.askLocationPermission();
    await nearby.askBluetoothPermission();
    try {
      await nearby.askNearbyWifiDevicesPermission();
    } catch (_) {}
  }

  void note(String s) => setState(() => st = s);
  Uint8List enc(Object o) => Uint8List.fromList(utf8.encode(jsonEncode(o)));

  void recv(String id, Payload p) {
    if (p.type != PayloadType.BYTES || p.bytes == null) return;
    final m = jsonDecode(utf8.decode(p.bytes!)) as Map<String, dynamic>;
    if (host) {
      final i = order.indexOf(id) + 1;
      if (i == 0 || g == null) return;
      if (g!.act(i, m)) push();
    } else {
      setState(() {
        if (v != null && v!['end'] != 0 && m['end'] == 0) marks = List.filled(8, 0);
        v = m;
        sel = null;
      });
    }
  }

  void conn(String id, ConnectionInfo info) {
    names[id] = info.endpointName;
    nearby.acceptConnection(id, onPayLoadRecieved: recv, onPayloadTransferUpdate: (a, b) {});
  }

  Future<void> create() async {
    await perms();
    setState(() {
      host = true;
      lobby = true;
      order.clear();
      st = 'Miandry mpilalao...';
    });
    await nearby.startAdvertising(nameC.text, Strategy.P2P_STAR,
        onConnectionInitiated: conn,
        onConnectionResult: (id, s) {
          if (s == Status.CONNECTED) setState(() => order.add(id));
        },
        onDisconnected: (id) => note('Nisy niala : ${names[id]}'),
        serviceId: svc);
  }

  Future<void> join() async {
    await perms();
    setState(() {
      host = false;
      lobby = true;
      found.clear();
      st = 'Mikaroka lalao...';
    });
    await nearby.startDiscovery(nameC.text, Strategy.P2P_STAR,
        onEndpointFound: (id, n, s) => setState(() => found[id] = n),
        onEndpointLost: (id) => setState(() => found.remove(id)),
        serviceId: svc);
  }

  void go(String id) {
    nearby.requestConnection(nameC.text, id,
        onConnectionInitiated: conn,
        onConnectionResult: (i, s) {
          if (s == Status.CONNECTED) {
            hostId = i;
            nearby.stopDiscovery();
            note('Tafiditra! Miandry ny fanombohan’ny hôte...');
          } else {
            note('Tsy tafiditra. Andramo indray.');
          }
        },
        onDisconnected: (i) => note('Nahena ny fifandraisana.'));
  }

  void newRound() {
    marks = List.filled(8, 0);
    g = Game(mission, order.length + 1);
    push();
  }

  void start() {
    nearby.stopAdvertising();
    newRound();
  }

  void push() {
    for (var i = 0; i < order.length; i++) {
      nearby.sendBytesPayload(order[i], enc(g!.view(i + 1)));
    }
    setState(() {
      v = g!.view(0);
      sel = null;
    });
  }

  void act(Map<String, dynamic> m) {
    if (host) {
      if (g!.act(0, m)) push();
    } else if (hostId != null) {
      nearby.sendBytesPayload(hostId!, enc(m));
    }
  }

  Widget kard(Map x, {bool sl = false}) => Container(
        width: 56, height: 70, margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: colC[x['c']], borderRadius: BorderRadius.circular(10),
            border: sl ? Border.all(width: 3) : null),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${x['n']}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(colN[x['c']], style: const TextStyle(color: Colors.white, fontSize: 9)),
        ]),
      );

  Widget menu() => Column(children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Anaranao')),
        const SizedBox(height: 14),
        FilledButton(onPressed: create, child: const Text('Mamorona lalao (hôte)')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: join, child: const Text('Hiditra amin’ny lalao')),
      ]);

  Widget lobbyW() => Column(children: [
        Text(st),
        if (host) ...[
          Text('Mpilalao : ${order.length + 1} (2 ka hatramin’ny 5)'),
          ...order.map((id) => Text('• ${names[id] ?? id}')),
          DropdownButton<int>(
              value: mission,
              items: [for (var i = 1; i <= 20; i++) DropdownMenuItem(value: i, child: Text('Iraka $i'))],
              onChanged: (x) => setState(() => mission = x!)),
          FilledButton(
              onPressed: order.isNotEmpty && order.length <= 4 ? start : null,
              child: const Text('Atombohy')),
        ] else
          ...found.entries.map((e) => ListTile(
              title: Text(e.value), trailing: const Icon(Icons.login), onTap: () => go(e.key))),
      ]);

  Widget game() {
    final m = v!;
    final sus = m['sus'] as List;
    final hand = m['hand'] as List;
    final mine = m['turn'] == m['you'];
    final end = m['end'] as int;
    return Column(children: [
      Text('Iraka ${m['m']} · Mpamadika = ahiahiana manana isa ≥ ${m['thr']}'),
      Text('Mpamadika sisa: ${m['T'] - m['f']} · Bala: ${m['b']} · Foibe: ${m['qg']}'),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.center, children: [
        for (var i = 0; i < sus.length; i++)
          sus[i] != null
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(children: [
                    kard(sus[i]),
                    Text(sus[i]['t'] ? '🔴 Mpamadika' : '✅ Tsy meloka', style: const TextStyle(fontSize: 11)),
                  ]))
              : InkWell(
                  onTap: () => setState(() => marks[i] = (marks[i] + 1) % 3),
                  child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(children: [
                        Container(
                            width: 56, height: 70, margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: const Text('?', style: TextStyle(color: Colors.white, fontSize: 24))),
                        Text('${['❓', '✅', '🔴'][marks[i]]} #${i + 1}'),
                      ]))),
      ]),
      const Text('Kitiho ny ahiahiana hanamarika ny eritreritrao.', style: TextStyle(fontSize: 11)),
      const Divider(),
      Text('${m['msg']}', textAlign: TextAlign.center),
      const Divider(),
      const Text('Ny karatrao'),
      Wrap(children: [
        for (var i = 0; i < hand.length; i++)
          GestureDetector(onTap: () => setState(() => sel = i), child: kard(hand[i], sl: i == sel)),
      ]),
      if (end != 0) ...[
        Text(end == 1 ? '🎉 Nahomby!' : '💥 Tsy nahomby', style: const TextStyle(fontSize: 26)),
        if (host)
          FilledButton(
              onPressed: () {
                if (end == 1 && mission < 20) mission++;
                newRound();
              },
              child: Text(end == 1 ? 'Iraka manaraka' : 'Averina'))
        else
          const Text('Miandry ny hôte...'),
      ] else if (mine) ...[
        const Text('Anjaranao!', style: TextStyle(fontWeight: FontWeight.bold)),
        if (sel != null) ...[
          FilledButton(
              onPressed: () => act({'a': 'ask', 'i': sel, 'ty': 0}),
              child: Text('Firy ny ahiahiana ${colN[hand[sel!]['c']]}?')),
          FilledButton(
              onPressed: () => act({'a': 'ask', 'i': sel, 'ty': 1}),
              child: Text('Firy ny ahiahiana manana isa ≥ ${hand[sel!]['n']}?')),
        ] else
          const Text('Safidio ny karatra hampiasaina hanontaniana.'),
        const Text('Na mitifira :'),
        Wrap(children: [
          for (var i = 0; i < sus.length; i++)
            if (sus[i] == null)
              Padding(
                  padding: const EdgeInsets.all(3),
                  child: OutlinedButton(
                      onPressed: () => act({'a': 'fire', 'i': i}), child: Text('🔫 #${i + 1}'))),
        ]),
      ] else
        Text('Miandry an’i Mpilalao ${m['turn'] + 1}...'),
    ]);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('🕵️ Mpamadika')),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: SingleChildScrollView(child: v != null ? game() : (lobby ? lobbyW() : menu())))),
      );
}
