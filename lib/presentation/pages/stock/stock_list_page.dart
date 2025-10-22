import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/navBar.dart';
import '../../components/standartScreen.dart';
import '../../../data/api/item_api_data_source.dart';
import 'stock_detail_page.dart';


import '../../../core/utils/secure_storage_service.dart';
import '../../../core/utils/diacritics_utils.dart';


class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  int _selectedIndex = 0;
  
  final SecureStorageService _storageService = SecureStorageService();
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<Map<String, dynamic>> _displayedItems = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _hasLoadedData = false;
  final int _itemsPerLoad = 20;
  String _searchQuery = '';
  // Removido filtro por fornecedor
  String? _selectedSupplier;
  String? _selectedSection = ''; 
  String? _userRole;
  // Removido: lista de fornecedores
  List<String> _suppliers = []; 
  final List<Map<String, String>> _sections = [
    {'id': '', 'name': 'Todas'},
    {'id': '1', 'name': 'Almoxarifado'},
    {'id': '2', 'name': 'Farmácia'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
    _loadUserRoleAndItems();
  }

  Future<void> _loadUserRoleAndItems() async {
    final user = await _storageService.getUser();
    _userRole = user?.role;
    _selectedSupplier ??= 'Todos';
    _selectedSection ??= '';
    
    print('[StockList] Role do usuário: $_userRole');
    await _loadAllItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.toLowerCase();
    if (_searchQuery != newQuery) {
      setState(() {
        _searchQuery = newQuery;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    print('Aplicando filtros - Query: "$_searchQuery", Supplier: "$_selectedSupplier"');
    print('Total de itens: ${_allItems.length}');
    
    _filteredItems = _allItems.where((item) {
    final itemName = item['name']?.toString().toLowerCase() ?? '';
  // Removido: filtro por fornecedor
  final itemSupplier = '';
    // Busca ignorando acentos
    final matchesSearch = _searchQuery.isEmpty ||
      removeDiacriticsCustom(itemName).contains(removeDiacriticsCustom(_searchQuery));
    final matchesSupplier = true;
    return matchesSearch && matchesSupplier;
    }).toList();
    
    print('Itens filtrados: ${_filteredItems.length}');
    

    _displayedItems.clear();
    _isLoading = false;
    
    if (_filteredItems.isNotEmpty) {
      final endIndex = _itemsPerLoad.clamp(0, _filteredItems.length);
      _displayedItems.addAll(_filteredItems.sublist(0, endIndex));
      print('Exibindo inicialmente ${_displayedItems.length} itens');
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = 200;
      
      if (currentScroll >= maxScroll - threshold && !_isLoading) {
        print('Scroll trigger: carregando mais itens...');
        _loadMoreItems();
      }
    }
  }

  String _getValidSectionValue() {
    final validIds = _sections.map((s) => s['id']).toList();
    final isValid = validIds.contains(_selectedSection);
    print('[DEBUG] Section - Selected: $_selectedSection, Valid IDs: $validIds, Is Valid: $isValid');
    return isValid ? _selectedSection! : '';
  }

  String _getValidSupplierValue() {
    final isValid = _suppliers.contains(_selectedSupplier);
    print('[DEBUG] Supplier - Selected: $_selectedSupplier, Suppliers: $_suppliers, Is Valid: $isValid');
    return isValid ? _selectedSupplier! : 'Todos';
  }

  Future<void> _loadAllItems() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _storageService.getUser();
      final token = await _storageService.getToken();
      final sectionId = user?.sessionId ?? '';  // Corrigido: session_id, não section_id
      final api = ItemApiDataSource();

      print('[StockList] Token: ${token != null  ? "${token.substring(0, 10)}..." : "VAZIO"}');
      print('[StockList] SectionId da sessão: "$sectionId"');
      print('[StockList] Role do usuário: $_userRole');
      
      String? effectiveSectionId;
      if (_userRole == 'ADMIN') {
        // Para ADMIN: se selecionou uma seção específica, usa ela; senão, null para ver todos
        if (_selectedSection != null && _selectedSection!.isNotEmpty) {
          effectiveSectionId = _selectedSection;
          print('[StockList] ADMIN - Filtrando por seção selecionada: $_selectedSection');
        } else {
          effectiveSectionId = null;  // null = todos os itens para ADMIN
          print('[StockList] ADMIN - Buscando todos os itens (sem filtro de seção)');
        }
      } else {
        // Para não-ADMIN: sempre usa a seção do usuário
        effectiveSectionId = sectionId;
        print('[StockList] Usuário $_userRole - Filtrando por seção: $sectionId');
      }
      
      print('[StockList] Role: $_userRole, Seção selecionada: $_selectedSection, SectionId efetivo: $effectiveSectionId');
      
      _allItems = await api.getItems(sectionId: effectiveSectionId, userRole: _userRole);
      _hasLoadedData = true;
      
  // Removido: enriquecimento com nomes de fornecedores
      
      print('Carregados ${_allItems.length} itens do backend');
      
      // Removido: construção de filtro de fornecedores
      
      _filteredItems = List.from(_allItems);
      _displayedItems.clear();
      
      if (_filteredItems.isNotEmpty) {
        final endIndex = _itemsPerLoad.clamp(0, _filteredItems.length);
        _displayedItems.addAll(_filteredItems.sublist(0, endIndex));
        print('Carregamento inicial: ${_displayedItems.length} itens');
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar itens: $e')),
        );
      }
    }
  }

  // Removido: rotina de busca de nomes de fornecedores

  void _loadMoreItems() {
    if (!_hasLoadedData || _displayedItems.length >= _filteredItems.length || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          final startIndex = _displayedItems.length;
          final endIndex = (startIndex + _itemsPerLoad).clamp(0, _filteredItems.length);
          _displayedItems.addAll(_filteredItems.sublist(startIndex, endIndex));
          _isLoading = false;
          
          print('Carregados ${_displayedItems.length} de ${_filteredItems.length} itens filtrados');
        });
      }
    });
  }

  Future<void> _refreshItems() async {
    setState(() {
      _allItems.clear();
      _filteredItems.clear();
      _displayedItems.clear();
      _hasLoadedData = false;
      _suppliers.clear();
      _selectedSupplier = 'Todos';
      _selectedSection = '';
      _searchController.clear();
      _searchQuery = '';
    });
    await _loadAllItems();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/register_product');
          _refreshItems();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Produto', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.infoLight,
      ),
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
        title: 'Estoque',
        child: Column(
          children: [
            // Filtros Compactos
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primeira linha: Campo de busca e contador
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícone de filtro
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Icon(
                          Icons.filter_list,
                          color: AppColors.infoLight,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Campo de pesquisa
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _searchQuery.isNotEmpty 
                                  ? AppColors.infoLight.withValues(alpha: 0.3)
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar produtos...',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[400],
                                size: 18,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () => _searchController.clear(),
                                      child: Icon(
                                        Icons.clear,
                                        color: Colors.grey[400],
                                        size: 16,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, 
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Contador de resultados
                      if (_hasLoadedData) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.infoLight,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_filteredItems.length}',
                                style: TextStyle(
                                  color: AppColors.infoLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Segunda linha: Dropdowns de filtros
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Removido: filtro por fornecedor
                      // Dropdown Seção para ADMIN
                      if (_userRole == 'ADMIN') ...[
                        Expanded(
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedSection != '' 
                                    ? AppColors.infoLight.withValues(alpha: 0.3)
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _sections.any((s) => s['id'] == _selectedSection) ? _selectedSection : '',
                                hint: Text(
                                  'Selecione a seção',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                                isExpanded: true,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                                items: _sections.map((section) {
                                  return DropdownMenuItem(
                                    value: section['id'],
                                    child: Text(
                                      section['name']!,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSection = value;
                                    _selectedSupplier = 'Todos';
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                  _loadAllItems();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Botão limpar filtros
                      if (_searchQuery.isNotEmpty || 
                          _selectedSupplier != 'Todos' || 
                          (_userRole == 'ADMIN' && _selectedSection != '')) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                              _selectedSupplier = 'Todos';
                              _selectedSection = '';
                            });
                            _applyFilters();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.clear, color: Colors.grey[500], size: 16),
                                const SizedBox(width: 4),
                                const Text('Limpar', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Lista ou loading
            Expanded(
              child: _isLoading && _displayedItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Carregando produtos...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _displayedItems.isEmpty && _hasLoadedData
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(32),
                            padding: const EdgeInsets.all(32),
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
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Nenhum produto encontrado',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tente ajustar os filtros ou adicionar novos produtos.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          itemCount: _displayedItems.length + (_displayedItems.length < _filteredItems.length ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _displayedItems.length) {
                              return Container(
                                margin: const EdgeInsets.all(16.0),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.infoLight),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Carregando mais produtos...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final item = _displayedItems[index];
                              return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StockDetailPage(
                                        itemId: item['id']?.toString(),
                                        itemData: item,
                                      ),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _refreshItems();
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Ícone
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.infoLight.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.white.withOpacity(1),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Informações do produto
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name']?.toString() ?? 'Sem nome',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.infoLight.withOpacity(0.10),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.inventory,
                                                        size: 14,
                                                        color: AppColors.infoLight,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${item['currentStock'] ?? '0'}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.infoLight,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.withOpacity(0.10),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.straighten,
                                                        size: 14,
                                                        color: Colors.orange,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        item['measure']?.toString() ?? '-',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.orange,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            const SizedBox.shrink(),
                                          ],
                                        ),
                                      ),
                                      // Seta indicando que é clicável
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.10),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
