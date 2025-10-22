import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/api/item_api_data_source.dart';
import 'stock/stock_edit_page.dart';

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
                  onDetect: (capture) async {
                    // mobile_scanner 3.x fornece BarcodeCapture com lista de barcodes
                    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
                    final value = barcode?.rawValue;
                    if (value == null) return;
                    if (_isDetecting) return;
                    _isDetecting = true;

                    // small haptic feedback
                    try {
                      HapticFeedback.vibrate();
                    } catch (_) {}

                    setState(() => _result = value);

                    final scanned = value.trim();
                    // O backend fornece o campo qrCode já no formato de rota (ex: "/items?code=xxx").
                    // Usamos exatamente o conteúdo lido para buscar o item.
                    if (!scanned.contains('code=')) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR inválido')));
                      _isDetecting = false;
                      return;
                    }

                    final uriString = scanned; // usar exatamente o valor do QR

                    setState(() => _isFetching = true);
                    try {
                      final api = ItemApiDataSource();
                      print('[ScannerPage] Scanned QR -> $uriString');
                      final item = await api.getItemByQrCode(uriString);
                      if (!mounted) return;
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockEditPage(item: item)));
                    } catch (e) {
                      // Log detalhado para depuração
                      print('[ScannerPage] Erro ao buscar item por QR ($uriString): $e');
                      String userMsg = 'Erro ao recuperar item';
                      try {
                        final msg = e.toString();
                        if (msg.contains('Item não encontrado')) {
                          userMsg = 'Item não encontrado';
                        } else if (msg.isNotEmpty) {
                          // Mostra a mensagem sem o prefixo Exception: para o usuário
                          userMsg = msg.replaceFirst('Exception: ', '');
                        }
                      } catch (_) {}
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userMsg')));
                    } finally {
                      if (mounted) {
                        setState(() {
                        _isFetching = false;
                        _isDetecting = false;
                      });
                      }
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

          // controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Lanterna',
                  icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                  onPressed: () async {
                    try {
                      await _cameraController.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao alternar lanterna: $e')));
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
