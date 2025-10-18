import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/standartScreen.dart';
import '../../../data/api/item_api_data_source.dart';
import '../../../data/api/supplier_api_data_source.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../data/api/item_type_api_data_source.dart';
import '../../components/navBar.dart';

class StockDetailPage extends StatefulWidget {
  final String? itemId;
  final Map<String, dynamic>? itemData;
  const StockDetailPage({super.key, this.itemId, this.itemData});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _item;
  bool _loading = true;
  String? _error;
  String? _supplierName;
  String? _itemTypeName;
  final SecureStorageService _storageService = SecureStorageService();

  @override
  void initState() {
    super.initState();
    if (widget.itemData != null) {
      _item = widget.itemData;
      _loading = false;
      _fetchAdditionalData();
    } else {
      _fetchItem();
    }
  }

  Future<void> _fetchAdditionalData() async {
    if (_item == null) return;

    String? supplierName;
    if (_item!['supplierId'] != null) {
      try {
        final supplierApi = SupplierApiDataSource();
        final supplier = await supplierApi.getSupplierById(
          _item!['supplierId'].toString(),
        );
        supplierName = supplier['name'];
      } catch (e) {
        print('Erro ao buscar fornecedor: $e');
        supplierName = 'Fornecedor não encontrado';
      }
    }

    String? itemTypeName;
    if (_item!['itemTypeId'] != null) {
      try {
        final itemTypeApi = ItemTypeApiDataSource();
        final itemType = await itemTypeApi.getItemTypeById(
          _item!['itemTypeId'].toString(),
        );
        itemTypeName = itemType['name'];
      } catch (e) {
        print('Erro ao buscar tipo de item: $e');
        itemTypeName = 'Tipo não encontrado';
      }
    }

    setState(() {
      _supplierName = supplierName;
      _itemTypeName = itemTypeName;
    });
  }

  Future<void> _fetchItem() async {
    if (widget.itemId == null || widget.itemId!.isEmpty) {
      setState(() {
        _error = 'ID do item não fornecido';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Buscar dados do item
      final api = ItemApiDataSource();
      final data = await api.getItemById(widget.itemId!);

      // Buscar nome do fornecedor se houver supplierId
      String? supplierName;
      if (data['supplierId'] != null) {
        try {
          final supplierApi = SupplierApiDataSource();
          final supplier = await supplierApi.getSupplierById(
            data['supplierId'].toString(),
          );
          supplierName = supplier['name'];
        } catch (e) {
          print('Erro ao buscar fornecedor: $e');
          supplierName = 'Fornecedor não encontrado';
        }
      }

      // Buscar nome do tipo de item se houver itemTypeId
      String? itemTypeName;
      if (data['itemTypeId'] != null) {
        try {
          final itemTypeApi = ItemTypeApiDataSource();
          final itemType = await itemTypeApi.getItemTypeById(
            data['itemTypeId'].toString(),
          );
          itemTypeName = itemType['name'];
        } catch (e) {
          print('Erro ao buscar tipo de item: $e');
          itemTypeName = 'Tipo não encontrado';
        }
      }

      setState(() {
        _item = data;
        _supplierName = supplierName;
        _itemTypeName = itemTypeName;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: StandardScreen(
        title: 'Detalhes do Produto',
        showBackButton: true, // Adicione o botão voltar
        child: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Carregando detalhes...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : _error != null
            ? Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ops! Algo deu errado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Erro ao carregar: $_error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _fetchItem,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.infoLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _item == null
            ? Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.search_off,
                          color: Colors.orange,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Item não encontrado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'O produto que você procura não existe ou foi removido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com imagem/ícone e informações principais
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.infoLight.withValues(alpha: 0.8),
                            AppColors.infoLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.infoLight.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _item?['name']?.toString() ?? 'Sem nome',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _supplierName ??
                                          _item?['supplierName']?.toString() ??
                                          'Fornecedor não informado',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Status do estoque
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _stockStatusCard(
                                    'Estoque Atual',
                                    _item?['currentStock']?.toString() ?? '0',
                                    Icons.inventory,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _stockStatusCard(
                                    'Unidade',
                                    _item?['measure']?.toString() ?? '-',
                                    Icons.straighten,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Informações técnicas
                    _sectionCard(
                      title: 'Informações do Produto',
                      icon: Icons.info_outline,
                      children: [
                        // Tornar o código clicável para abrir o popup com QR
                        InkWell(
                          onTap: () => _showQrDialog(context),
                          child: _modernInfoRow(
                            'Código',
                            _item?['id']?.toString() ?? '-',
                            Icons.qr_code,
                          ),
                        ),
                        _modernInfoRow(
                          'Validade',
                          _formatDate(_item?['expirationDate']?.toString()),
                          Icons.event,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Controle de estoque
                    _sectionCard(
                      title: 'Controle de Estoque',
                      icon: Icons.inventory_2,
                      children: [
                        _modernInfoRow(
                          'Fornecedor',
                          _supplierName ??
                              _item?['supplierName']?.toString() ??
                              'Não informado',
                          Icons.business,
                        ),
                        _modernInfoRow(
                          'Estoque Mínimo',
                          _item?['minimumStock']?.toString() ??
                              _item?['minStock']?.toString() ??
                              _item?['minimum_stock']?.toString() ??
                              'Não informado',
                          Icons.warning_amber,
                        ),
                        _modernInfoRow(
                          'Estoque Máximo',
                          _item?['maximumStock']?.toString() ??
                              _item?['maxStock']?.toString() ??
                              _item?['maximum_stock']?.toString() ??
                              'Não informado',
                          Icons.check_circle_outline,
                        ),
                        _modernInfoRow(
                          'Tipo do Item',
                          _itemTypeName ??
                              _item?['itemType']?.toString() ??
                              'Não informado',
                          Icons.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Descrição se houver
                    if ((_item?['description']?.toString().isNotEmpty ?? false))
                      _sectionCard(
                        title: 'Descrição',
                        icon: Icons.description,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              _item?['description']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // Botões de ação ocultados a pedido: Editar e Movimentar
                    const SizedBox.shrink(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _stockStatusCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.infoLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.infoLight, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _modernInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (statusColor ?? AppColors.infoLight).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: statusColor ?? AppColors.infoLight,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: statusColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == '-') {
      return 'Não informado';
    }

    try {
      // Tenta diferentes formatos de data
      DateTime date;
      if (dateString.contains('T')) {
        date = DateTime.parse(dateString);
      } else if (dateString.contains('-')) {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          return dateString;
        }
      } else {
        return dateString;
      }

      // Formata para dd/MM/yyyy
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _showQrDialog(BuildContext context) async {
    final encryptedId = _item?['qrCode']?.toString() ?? '-';
    // Construir a rota completa que o backend espera
    final code = '/items/qr?code=$encryptedId';
    final name = _item?['name']?.toString() ?? 'Sem nome';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: SizedBox(
            width: 300,
            child: Builder(
              builder: (context) {
                // Constrói o widget do QR de forma síncrona para evitar que LayoutBuilder
                // seja executado durante cálculos intrínsecos do AlertDialog.
                Widget qrChild;
                try {
                  qrChild = QrImageView(
                    data: code,
                    size: 160.0,
                  );
                } catch (e) {
                  print('[StockDetail] Erro ao gerar QR: $e');
                  qrChild = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      const Text('Não foi possível gerar o QR.'),
                      const SizedBox(height: 8),
                      Text('Detalhes: $e', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    qrChild,
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _shareQr(code, name),
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar'),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _printQrAsPdf(code, name);
              },
              icon: const Icon(Icons.print),
              label: const Text('Imprimir'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareQr(String code, String name) async {
    try {
      await Share.share('Produto: $name');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao compartilhar')),
      );
    }
  }

  Future<void> _printQrAsPdf(String code, String name) async {
    try {
      // Gera um PDF simples com o QR usando o pacote printing/pdf
      await Printing.layoutPdf(onLayout: (format) async {
        final doc = pw.Document();

        // Renderiza o QR em bytes
  final qrPainter = QrPainter(data: code, version: QrVersions.auto, gapless: false);
        final byteData = await qrPainter.toImageData(300);
        final bytes = byteData!.buffer.asUint8List();

        final image = pw.MemoryImage(bytes);

        doc.addPage(pw.Page(build: (context) {
          return pw.Column(children: [
            pw.Text(name, style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 12),
            pw.Image(image, width: 200, height: 200),
          ]);
        }));

        return doc.save();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao imprimir: $e')),
      );
    }
  }
}
