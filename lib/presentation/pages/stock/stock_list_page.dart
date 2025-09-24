import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/navBar.dart';
import '../../components/standartScreen.dart';
import '../../../data/api/item_api_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<Map<String, dynamic>> _displayedItems = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _hasLoadedData = false;
  final int _itemsPerLoad = 20;
  String _searchQuery = '';
  String? _selectedSupplier = 'Todos';
  String? _selectedSection = ''; 
  String? _userRole;
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
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('user_role');
    
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
      final itemSupplier = item['supplierName']?.toString() ?? '';
      
      final matchesSearch = _searchQuery.isEmpty || itemName.contains(_searchQuery);
      final matchesSupplier = _selectedSupplier == null || 
          _selectedSupplier == 'Todos' || 
          itemSupplier == _selectedSupplier;
      
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final sectionId = prefs.getString('session_id') ?? '';
      final api = ItemApiDataSource();
      
      String? effectiveSectionId;
      if (_userRole == 'ADMIN') {
        if (_selectedSection != null && _selectedSection!.isNotEmpty) {
          effectiveSectionId = _selectedSection;
        }
      } else {
        effectiveSectionId = sectionId;
      }
      
      print('[StockList] Role: $_userRole, Seção selecionada: $_selectedSection, SectionId efetivo: $effectiveSectionId');
      
      _allItems = await api.getItems(token, sectionId: effectiveSectionId, userRole: _userRole);
      _hasLoadedData = true;
      
      print('Carregados ${_allItems.length} itens do backend');
      
      final supplierSet = <String>{'Todos'}; 
      for (final item in _allItems) {
        final supplier = item['supplierName']?.toString();
        if (supplier != null && supplier.isNotEmpty && supplier != 'Todos') {
          supplierSet.add(supplier);
        }
      }
      _suppliers = supplierSet.toList()..sort();
      
      if (_suppliers.contains('Todos')) {
        _suppliers.remove('Todos');
        _suppliers.insert(0, 'Todos');
      }
      
      if (_selectedSupplier == null || !_suppliers.contains(_selectedSupplier)) {
        _selectedSupplier = 'Todos';
      }
      
      print('Fornecedores encontrados: $_suppliers');
      
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

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/menu');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/product_register');
          _refreshItems();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Produto', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.infoLight,
      ),
      backgroundColor: Colors.transparent,
      bottomNavigationBar: CustomNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
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
              child: Row(
                children: [
                  // Ícone de filtro
                  Icon(
                    Icons.filter_list,
                    color: AppColors.infoLight,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  
                  // Campo de pesquisa compacto
                  Expanded(
                    flex: 3,
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
                          hintText: 'Buscar...',
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
                  
                  const SizedBox(width: 8),
                  
                  // Dropdown Fornecedor compacto
                  if (_suppliers.isNotEmpty)
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedSupplier != 'Todos' 
                                ? AppColors.infoLight.withValues(alpha: 0.3)
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _getValidSupplierValue(),
                            hint: Text(
                              'Fornecedor',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
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
                            items: _suppliers.map((supplier) {
                              return DropdownMenuItem(
                                value: supplier,
                                child: Text(
                                  supplier,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSupplier = value;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  
                  // Dropdown Seção para ADMIN
                  if (_userRole == 'ADMIN') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
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
                            value: _getValidSectionValue(),
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
                              });
                              _loadAllItems();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(width: 8),
                  
                  // Contador de resultados e limpar
                  if (_hasLoadedData) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredItems.length}',
                        style: TextStyle(
                          color: AppColors.infoLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty || 
                        _selectedSupplier != 'Todos' || 
                        (_userRole == 'ADMIN' && _selectedSection != '')) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchController.clear();
                            _selectedSupplier = 'Todos';
                            _selectedSection = '';
                            _searchQuery = '';
                          });
                          _loadAllItems();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.clear_all,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshItems,
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.grey[50]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        // Tenta diferentes chaves possíveis de ID
                                        String? id;
                                        for (final key in ['id', 'itemId', 'productId', 'code', 'uuid']) {
                                          final v = item[key];
                                          if (v != null && v.toString().isNotEmpty) {
                                            id = v.toString();
                                            break;
                                          }
                                        }

                                        // Se ID válido, navega com id; se não, envia os dados completos
                                        Navigator.pushNamed(
                                          context,
                                          '/stock_detail',
                                          arguments: id != null
                                              ? {'id': id, 'data': item}
                                              : {'data': item},
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            // Ícone do produto com container estilizado
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    AppColors.infoLight.withValues(alpha: 0.8),
                                                    AppColors.infoLight,
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.infoLight.withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.inventory_2_outlined,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Informações do produto
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Nome do produto
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
                                                  // Informações secundárias
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.infoLight.withValues(alpha: 0.1),
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
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange.withValues(alpha: 0.1),
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
                                                  // Fornecedor
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.business,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          item['supplierName']?.toString() ?? 'Fornecedor não informado',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.grey[600],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Seta indicando que é clicável
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withValues(alpha: 0.1),
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
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
