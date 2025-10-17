import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../data/api/item_api_data_source.dart';
import 'stock_edit_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String? _result;
  final MobileScannerController _cameraController = MobileScannerController();
  bool _torchOn = false;
  bool _isFront = false;
  bool _isDetecting = false; // evita retornos múltiplos
  bool _isFetching = false;
  bool _isPaused = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leitor de QR')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _cameraController,
                  allowDuplicates: false,
                  onDetect: (barcode, args) async {
                    final value = barcode.rawValue;
                    if (value == null) return;
                    if (_isDetecting) return;
                    _isDetecting = true;

                    // small haptic feedback
                    try {
                      HapticFeedback.vibrate();
                    } catch (_) {}

                    setState(() => _result = value);

                    // extrai query param 'code' ou aceita o próprio valor
                    String? code;
                    final uri = Uri.tryParse(value);
                    if (uri != null && uri.queryParameters.containsKey('code')) {
                      code = uri.queryParameters['code'];
                    } else {
                      const prefix = '/items/qr?code=';
                      if (value.startsWith(prefix)) code = value.substring(prefix.length);
                      else code = value;
                    }

                    if (code == null || code.isEmpty) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR inválido')));
                      _isDetecting = false;
                      return;
                    }

                    setState(() => _isFetching = true);
                    try {
                      final api = ItemApiDataSource();
                      final item = await api.getItemByQrCode('/items/qr', code);
                      if (!mounted) return;
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockEditPage(item: item)));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar item: $e')));
                    } finally {
                      if (mounted) setState(() {
                        _isFetching = false;
                        _isDetecting = false;
                      });
                    }
                  },
                ),

                // crosshair
                Positioned(
                  width: 260,
                  height: 260,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (_isFetching)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black45,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),

          if (_result != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Resultado: $_result'),
            ),

          // controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Tocha',
                  icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                  onPressed: () async {
                    try {
                      await _cameraController.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar tocha: $e')));
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Alternar câmera',
                  icon: Icon(_isFront ? Icons.camera_front : Icons.camera_rear),
                  onPressed: () async {
                    try {
                      await _cameraController.switchCamera();
                      setState(() => _isFront = !_isFront);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar câmera: $e')));
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Pausar/retomar',
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: () async {
                    try {
                      if (_isPaused) {
                        await _cameraController.start();
                      } else {
                        await _cameraController.stop();
                      }
                      setState(() => _isPaused = !_isPaused);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar scanner: $e')));
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../data/api/item_api_data_source.dart';
import 'stock_edit_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String? _result;
  final MobileScannerController _cameraController = MobileScannerController();
  bool _torchOn = false;
  bool _isFront = false;
  bool _isDetecting = false; // evita retornos múltiplos
  bool _isFetching = false;
  bool _isPaused = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leitor de QR')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _cameraController,
                  allowDuplicates: false,
                  onDetect: (barcode, args) async {
                    final value = barcode.rawValue;
                    if (value == null) return;
                    if (_isDetecting) return;
                    _isDetecting = true;

                    // small haptic feedback
                    try {
                      HapticFeedback.vibrate();
                    } catch (_) {}

                    setState(() => _result = value);

                    // extrai query param 'code' ou aceita o próprio valor
                    String? code;
                    final uri = Uri.tryParse(value);
                    if (uri != null && uri.queryParameters.containsKey('code')) {
                      code = uri.queryParameters['code'];
                    } else {
                      const prefix = '/items/qr?code=';
                      if (value.startsWith(prefix)) code = value.substring(prefix.length);
                      else code = value;
                    }

                    if (code == null || code.isEmpty) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR inválido')));
                      _isDetecting = false;
                      return;
                    }

                    setState(() => _isFetching = true);
                    try {
                      final api = ItemApiDataSource();
                      final item = await api.getItemByQrCode('/items/qr', code);
                      if (!mounted) return;
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockEditPage(item: item)));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar item: $e')));
                    } finally {
                      if (mounted) setState(() {
                        _isFetching = false;
                        _isDetecting = false;
                      });
                    }
                  },
                ),

                // crosshair
                Positioned(
                  width: 260,
                  height: 260,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (_isFetching)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black45,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),

          if (_result != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Resultado: $_result'),
            ),

          // controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Tocha',
                  icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                  onPressed: () async {
                    try {
                      await _cameraController.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar tocha: $e')));
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Alternar câmera',
                  icon: Icon(_isFront ? Icons.camera_front : Icons.camera_rear),
                  onPressed: () async {
                    try {
                      await _cameraController.switchCamera();
                      setState(() => _isFront = !_isFront);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar câmera: $e')));
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Pausar/retomar',
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: () async {
                    try {
                      if (_isPaused) {
                        await _cameraController.start();
                      } else {
                        await _cameraController.stop();
                      }
                      setState(() => _isPaused = !_isPaused);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar scanner: $e')));
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../data/api/item_api_data_source.dart';
import 'stock_edit_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String? _result;
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:mobile_scanner/mobile_scanner.dart';

  import '../../../data/api/item_api_data_source.dart';
  import 'stock_edit_page.dart';

  class ScannerPage extends StatefulWidget {
    const ScannerPage({Key? key}) : super(key: key);

    @override
    State<ScannerPage> createState() => _ScannerPageState();
  }

  class _ScannerPageState extends State<ScannerPage> {
    String? _result;
    final MobileScannerController _cameraController = MobileScannerController();
    bool _torchOn = false;
    bool _isFront = false;
    bool _isDetecting = false; // evita retornos múltiplos
    bool _isFetching = false;
    bool _isPaused = false;

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Leitor de QR')),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _cameraController,
                    allowDuplicates: false,
                    onDetect: (barcode, args) async {
                      final value = barcode.rawValue;
                      if (value == null) return;
                      if (_isDetecting) return;
                      _isDetecting = true;

                      // small haptic feedback
                      try {
                        HapticFeedback.vibrate();
                      } catch (_) {}

                      setState(() => _result = value);

                      // extrai query param 'code' ou aceita o próprio valor
                      String? code;
                      final uri = Uri.tryParse(value);
                      if (uri != null && uri.queryParameters.containsKey('code')) {
                        code = uri.queryParameters['code'];
                      } else {
                        const prefix = '/items/qr?code=';
                        if (value.startsWith(prefix)) code = value.substring(prefix.length);
                        else code = value;
                      }

                      if (code == null || code.isEmpty) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR inválido')));
                        _isDetecting = false;
                        return;
                      }

                      setState(() => _isFetching = true);
                      try {
                        final api = ItemApiDataSource();
                        final item = await api.getItemByQrCode('/items/qr', code);
                        if (!mounted) return;
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockEditPage(item: item)));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar item: $e')));
                      } finally {
                        if (mounted) setState(() {
                          _isFetching = false;
                          _isDetecting = false;
                        });
                      }
                    },
                  ),

                  // crosshair
                  Positioned(
                    width: 260,
                    height: 260,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  if (_isFetching)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black45,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),

            if (_result != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('Resultado: $_result'),
              ),

            // controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Tocha',
                    icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                    onPressed: () async {
                      try {
                        await _cameraController.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar tocha: $e')));
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Alternar câmera',
                    icon: Icon(_isFront ? Icons.camera_front : Icons.camera_rear),
                    onPressed: () async {
                      try {
                        await _cameraController.switchCamera();
                        setState(() => _isFront = !_isFront);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar câmera: $e')));
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Pausar/retomar',
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    onPressed: () async {
                      try {
                        if (_isPaused) {
                          await _cameraController.start();
                        } else {
                          await _cameraController.stop();
                        }
                        setState(() => _isPaused = !_isPaused);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar scanner: $e')));
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    @override
    void dispose() {
      _cameraController.dispose();
      super.dispose();
    }
  }
  import '../../../data/api/item_api_data_source.dart';
  import 'stock_edit_page.dart';

  class ScannerPage extends StatefulWidget {
    const ScannerPage({Key? key}) : super(key: key);

    @override
    State<ScannerPage> createState() => _ScannerPageState();
  }

  class _ScannerPageState extends State<ScannerPage> {
    String? _result;
    final MobileScannerController _cameraController = MobileScannerController();
    bool _torchOn = false;
    bool _isFront = false;
    bool _isDetecting = false; // evita retornos múltiplos
    bool _isFetching = false;

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Leitor de QR')),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _cameraController,
                    allowDuplicates: false,
                    onDetect: (barcode, args) async {
                      final value = barcode.rawValue;
                      if (value == null) return;
                      if (_isDetecting) return;
                      _isDetecting = true;

                      // small haptic feedback
                      try {
                        HapticFeedback.vibrate();
                      } catch (_) {}

                      setState(() => _result = value);

                      // extrai query param 'code' ou aceita o próprio valor
                      String? code;
                      final uri = Uri.tryParse(value);
                      if (uri != null && uri.queryParameters.containsKey('code')) {
                        code = uri.queryParameters['code'];
                      } else {
                        const prefix = '/items/qr?code=';
                        if (value.startsWith(prefix)) code = value.substring(prefix.length);
                        else code = value;
                      }

                      if (code == null || code.isEmpty) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR inválido')));
                        _isDetecting = false;
                        return;
                      }

                      // faz a requisição ao backend usando a rota com query param
                      setState(() => _isFetching = true);
                      try {
                        final api = ItemApiDataSource();
                        final item = await api.getItemByQrCode('/items/qr', code);
                        if (!mounted) return;
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockEditPage(item: item)));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar item: $e')));
                      } finally {
                        if (mounted) setState(() {
                          _isFetching = false;
                          _isDetecting = false;
                        });
                      }
                    },
                  ),

                  // crosshair
                  Positioned(
                    width: 260,
                    height: 260,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  if (_isFetching)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black45,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),

            if (_result != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('Resultado: $_result'),
              ),

            // controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Tocha',
                    icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                    onPressed: () async {
                      try {
                        await _cameraController.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar tocha: $e')));
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Alternar câmera',
                    icon: Icon(_isFront ? Icons.camera_front : Icons.camera_rear),
                    onPressed: () async {
                      try {
                        await _cameraController.switchCamera();
                        setState(() => _isFront = !_isFront);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar câmera: $e')));
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Pausar/retomar',
                    icon: Icon(_isFetching ? Icons.hourglass_empty : Icons.pause),
                    onPressed: () async {
                      try {
                        if (_isFetching) return;
                        // toggle stop/start defensively
                        await _cameraController.stop();
                        await Future.delayed(const Duration(milliseconds: 100));
                        await _cameraController.start();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar scanner: $e')));
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    @override
    void dispose() {
      _cameraController.dispose();
      super.dispose();
    }
  }
  bool _isDetecting = false; // evita retornos múltiplos
  bool _isPaused = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leitor de QR')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  import 'package:flutter/material.dart';
                  import 'package:flutter/services.dart';
                  import 'package:mobile_scanner/mobile_scanner.dart';

                  import '../../../data/api/item_api_data_source.dart';
                  import 'stock_edit_page.dart';

                  class ScannerPage extends StatefulWidget {
                    const ScannerPage({Key? key}) : super(key: key);

                    @override
                    State<ScannerPage> createState() => _ScannerPageState();
                  }

                  class _ScannerPageState extends State<ScannerPage> {
                    String? _result;
                    final MobileScannerController _cameraController = MobileScannerController();
                    bool _torchOn = false;
                    bool _isFront = false;
                    bool _isDetecting = false; // evita retornos múltiplos
                    bool _isFetching = false;

                    @override
                    Widget build(BuildContext context) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Leitor de QR')),
                        body: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  MobileScanner(
                                    controller: _cameraController,
                                    allowDuplicates: false,
                                    onDetect: (barcode, args) async {
                                      final value = barcode.rawValue;
                                      if (value == null) return;
                                      if (_isDetecting) return;
                                      _isDetecting = true;

                                      try {
                                        HapticFeedback.vibrate();
                                      } catch (_) {}

                                      setState(() => _result = value);

                                      // Extrai query param 'code'
                                      String? code;
                                      final uri = Uri.tryParse(value);
                                      if (uri != null && uri.queryParameters.containsKey('code')) {
                                        code = uri.queryParameters['code'];
                                      } else {
                                        const prefix = '/items/qr?code=';
                                        if (value.startsWith(prefix)) code = value.substring(prefix.length);
                                        else code = value;
                                      }

                                      if (code == null || code.isEmpty) {
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR inválido')));
                                        _isDetecting = false;
                                        return;
                                      }

                                      setState(() => _isFetching = true);
                                      try {
                                        final api = ItemApiDataSource();
                                        final item = await api.getItemByQrCode('/items/qr', code);
                                        if (!mounted) return;
                                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockEditPage(item: item)));
                                      } catch (e) {
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar item: $e')));
                                      } finally {
                                        if (mounted) setState(() {
                                          _isFetching = false;
                                          _isDetecting = false;
                                        });
                                      }
                                    },
                                  ),

                                  // Crosshair
                                  Positioned(
                                    width: 260,
                                    height: 260,
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (_isFetching)
                                    const Positioned.fill(
                                      child: ColoredBox(
                                        color: Colors.black45,
                                        child: Center(child: CircularProgressIndicator()),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            if (_result != null)
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text('Resultado: $_result'),
                              ),

                            // Controls
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    tooltip: 'Tocha',
                                    icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                                    onPressed: () async {
                                      try {
                                        await _cameraController.toggleTorch();
                                        setState(() => _torchOn = !_torchOn);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar tocha: $e')));
                                      }
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Alternar câmera',
                                    icon: Icon(_isFront ? Icons.camera_front : Icons.camera_rear),
                                    onPressed: () async {
                                      try {
                                        await _cameraController.switchCamera();
                                        setState(() => _isFront = !_isFront);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar câmera: $e')));
                                      }
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Pausar/retomar',
                                    icon: Icon(_isFetching ? Icons.hourglass_empty : Icons.pause),
                                    onPressed: () async {
                                      try {
                                        if (_isFetching) return;
                                        if (_cameraController.isStarting) {
                                          await _cameraController.stop();
                                        } else {
                                          await _camera_controller.start();
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar scanner: $e')));
                                      }
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Fechar',
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    @override
                    void dispose() {
                      _cameraController.dispose();
                      super.dispose();
                    }
                  }
