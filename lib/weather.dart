import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

/// Clima pela Open-Meteo (sem chave). Só a cidade escolhida é enviada.
class WeatherError implements Exception {
  final String message;
  const WeatherError(this.message);
  @override
  String toString() => message;
}

class CityResult {
  final String name;
  final String detail;
  final double lat;
  final double lon;
  const CityResult(this.name, this.detail, this.lat, this.lon);
}

Future<Map<String, dynamic>> _getJson(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(uri);
    final res = await req.close().timeout(const Duration(seconds: 15));
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) throw const WeatherError('Não foi possível atualizar o clima agora.');
    return Map<String, dynamic>.from(jsonDecode(body) as Map);
  } on WeatherError {
    rethrow;
  } on SocketException {
    throw const WeatherError('Sem internet.');
  } on TimeoutException {
    throw const WeatherError('Sem internet.');
  } catch (_) {
    throw const WeatherError('Não foi possível atualizar o clima agora.');
  } finally {
    client.close(force: true);
  }
}

Future<List<CityResult>> searchCities(String q) async {
  final j = await _getJson(Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
    'name': q.trim(),
    'count': '8',
    'language': 'pt',
    'format': 'json',
  }));
  final out = <CityResult>[];
  for (final r in (j['results'] as List?) ?? const []) {
    final m = Map<String, dynamic>.from(r as Map);
    final detail = [m['admin1'], m['country']].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    out.add(CityResult(
      m['name'] as String,
      detail,
      (m['latitude'] as num).toDouble(),
      (m['longitude'] as num).toDouble(),
    ));
  }
  return out;
}

/// Busca o clima da cidade salva e guarda no store.
Future<void> refreshWeather() async {
  final w = store.weather;
  if (w == null) return;
  final j = await _getJson(Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '${w.lat}',
    'longitude': '${w.lon}',
    'current': 'temperature_2m,weather_code',
    'daily': 'temperature_2m_max,temperature_2m_min,precipitation_probability_max',
    'timezone': 'auto',
    'forecast_days': '1',
  }));
  final cur = Map<String, dynamic>.from((j['current'] as Map?) ?? const {});
  final daily = Map<String, dynamic>.from((j['daily'] as Map?) ?? const {});
  num? first(String k) {
    final l = daily[k];
    return l is List && l.isNotEmpty ? l.first as num? : null;
  }

  // A cidade pode ter mudado enquanto buscava.
  if (store.weather?.city != w.city) return;
  store.setWeather(WeatherData(
    city: w.city,
    lat: w.lat,
    lon: w.lon,
    temp: (cur['temperature_2m'] as num?)?.toDouble(),
    code: (cur['weather_code'] as num?)?.toInt(),
    max: first('temperature_2m_max')?.toDouble(),
    min: first('temperature_2m_min')?.toDouble(),
    rain: first('precipitation_probability_max')?.toInt(),
    at: DateTime.now().millisecondsSinceEpoch,
  ));
}

/// Ícone e descrição curta do código WMO.
(IconData, String) weatherLook(int? code) {
  final c = code ?? -1;
  if (c == 0) return (Icons.wb_sunny_outlined, 'Céu limpo');
  if (c >= 1 && c <= 2) return (Icons.wb_cloudy_outlined, 'Poucas nuvens');
  if (c == 3) return (Icons.cloud_outlined, 'Nublado');
  if (c == 45 || c == 48) return (Icons.cloud_outlined, 'Neblina');
  if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return (Icons.water_drop_outlined, 'Chuva');
  if ((c >= 71 && c <= 77) || c == 85 || c == 86) return (Icons.ac_unit_rounded, 'Neve');
  if (c >= 95) return (Icons.thunderstorm_outlined, 'Tempestade');
  return (Icons.wb_cloudy_outlined, '');
}

String fmtTemp(double? t) => t == null ? '–' : '${t.round()}°';

// ============================================================== Interface
/// Faixa compacta do clima no Início.
class WeatherStrip extends StatefulWidget {
  const WeatherStrip({super.key});
  @override
  State<WeatherStrip> createState() => _WeatherStripState();
}

class _WeatherStripState extends State<WeatherStrip> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final w = store.weather;
    final age = w?.at == null ? null : DateTime.now().millisecondsSinceEpoch - w!.at!;
    if (w != null && (age == null || age > 30 * 60 * 1000)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    if (_loading || store.weather == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await refreshWeather();
    } on WeatherError catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = store.weather;
    if (w == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => showCitySheet(context),
          icon: const Icon(Icons.wb_cloudy_outlined, size: 18),
          label: const Text('Definir cidade do clima'),
          style: TextButton.styleFrom(foregroundColor: C.text2, padding: EdgeInsets.zero),
        ),
      );
    }
    final (icon, desc) = weatherLook(w.code);
    const sub = TextStyle(fontSize: 13, color: C.text2);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _refresh,
      onLongPress: () => showCitySheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: C.primaryDark),
            const SizedBox(width: 8),
            Text(fmtTemp(w.temp), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error ?? (w.hasData ? [w.city, if (desc.isNotEmpty) desc].join(' · ') : w.city),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sub,
              ),
            ),
            if (_loading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            else if (w.hasData) ...[
              Text('${fmtTemp(w.min)} / ${fmtTemp(w.max)}', style: sub),
              if (w.rain != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.water_drop_outlined, size: 16, color: C.info),
                Text('${w.rain}%', style: sub),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showCitySheet(BuildContext context) => showAppSheet(context, (_) => const CitySheet());

class CitySheet extends StatefulWidget {
  const CitySheet({super.key});
  @override
  State<CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<CitySheet> {
  final _q = TextEditingController();
  List<CityResult>? _results;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_q.text.trim().length < 2) {
      setState(() => _error = 'Digite o nome da cidade.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await searchCities(_q.text);
      _results = r;
      if (r.isEmpty) _error = 'Nenhuma cidade encontrada.';
    } on WeatherError catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _choose(CityResult c) async {
    store.setWeather(WeatherData(city: c.name, lat: c.lat, lon: c.lon));
    Navigator.pop(context);
    try {
      await refreshWeather();
    } on WeatherError {
      // A faixa do Início mostra o erro ao tocar para atualizar.
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = store.weather;
    return SheetFrame(
      title: 'Cidade do clima',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _q,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Cidade',
              hintText: cur?.city ?? 'Ex.: Belo Horizonte',
              errorText: _error,
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(tooltip: 'Buscar', onPressed: _search, icon: const Icon(Icons.search_rounded)),
            ),
          ),
          const SizedBox(height: 8),
          for (final c in _results ?? const <CityResult>[])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(c.name),
              subtitle: c.detail.isEmpty ? null : Text(c.detail),
              onTap: () => _choose(c),
            ),
          if (cur != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                store.setWeather(null);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Desligar clima'),
              style: TextButton.styleFrom(foregroundColor: C.danger),
            ),
          ],
        ],
      ),
    );
  }
}
