import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../data/api/pharmacy_api_data_source.dart';
import '../../../logic/cubit/pharmacy_cubit.dart';
import '../../../core/utils/secure_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../components/standartScreen.dart';

class ExpiryScreen extends StatelessWidget {
  const ExpiryScreen({Key? key}) : super(key: key);

  Future<void> _checkUserAccess() async {
    final storage = SecureStorageService();
    final user = await storage.getUser();
    print('[ExpiryScreen] Dados do usuário: ID=${user?.id}, Nome=${user?.name}, Role=${user?.role}, SessionId=${user?.sessionId}');
    print('[ExpiryScreen] Verificando permissões de acesso à Farmácia...');
  }

  Dio _createDio() {
    print('[ExpiryScreen] Criando instância do Dio');
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8080',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final storage = SecureStorageService();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('[ExpiryScreen] Interceptor: Buscando token...');
          final token = await storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('[ExpiryScreen] Interceptor: Token adicionado ao header');
            print('[ExpiryScreen] Interceptor: Token = ${token.substring(0, 20)}...');
          } else {
            print('[ExpiryScreen] Interceptor: AVISO - Token não encontrado!');
          }
          print('[ExpiryScreen] Interceptor: URL = ${options.uri}');
          print('[ExpiryScreen] Interceptor: Headers = ${options.headers}');
          handler.next(options);
        },
        onError: (error, handler) {
          print('[ExpiryScreen] Interceptor: ERRO na requisição');
          print('[ExpiryScreen] Interceptor: Status Code = ${error.response?.statusCode}');
          print('[ExpiryScreen] Interceptor: Mensagem = ${error.message}');
          print('[ExpiryScreen] Interceptor: Response Data = ${error.response?.data}');
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  @override
  Widget build(BuildContext context) {
    _checkUserAccess();
    return BlocProvider(
      create: (context) => PharmacyCubit(PharmacyApiDataSource(_createDio()))
        ..fetchExpiryData(365), // Usa 365 dias para pegar todos os itens a vencer
      child: const ExpiryScreenContent(),
    );
  }
}

class ExpiryScreenContent extends StatefulWidget {
  const ExpiryScreenContent({Key? key}) : super(key: key);

  @override
  State<ExpiryScreenContent> createState() => _ExpiryScreenContentState();
}

class _ExpiryScreenContentState extends State<ExpiryScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Controle de Validade',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () {
            context.read<PharmacyCubit>().fetchExpiryData(365);
          },
          tooltip: 'Atualizar dados',
        ),
      ],
      child: BlocBuilder<PharmacyCubit, PharmacyState>(
        builder: (context, state) {
          if (state is PharmacyLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Carregando dados...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (state is PharmacyError) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: AppColors.errorLight),
                    const SizedBox(height: 16),
                    const Text(
                      'Ops! Algo deu errado',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<PharmacyCubit>().refresh(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is PharmacyLoaded) {
            print('[ExpiryScreen] Renderizando PharmacyLoaded:');
            print('  - Vencidos: ${state.expiredItems.length} itens');
            print('  - A Vencer: ${state.expiringSoonItems.length} itens');
            print('  - Filtro: ${state.selectedDays} dias');
            
            return Column(
              children: [
                const SizedBox(height: 20),
                _buildSummaryCards(state),
                _buildTabBar(),
                _buildItemsList(state),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryCards(PharmacyLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Vencidos',
              count: state.summary.expiredCount,
              icon: Icons.warning_rounded,
              gradient: [Colors.red.shade400, Colors.red.shade600],
              iconColor: Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'A Vencer',
              count: state.summary.expiringSoonCount,
              icon: Icons.schedule_rounded,
              gradient: [Colors.orange.shade400, Colors.orange.shade600],
              iconColor: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required List<Color> gradient,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.secondaryLight],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(
            icon: Icon(Icons.warning_rounded, size: 20),
            text: 'Vencidos',
          ),
          Tab(
            icon: Icon(Icons.schedule_rounded, size: 20),
            text: 'A Vencer',
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(PharmacyLoaded state) {
    print('[ExpiryScreen] _buildItemsList chamado:');
    print('  - state.expiredItems: ${state.expiredItems.length}');
    print('  - state.expiringSoonItems: ${state.expiringSoonItems.length}');
    
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildItemList(
            items: state.expiredItems,
            hasMore: state.hasMoreExpired,
            isLoadingMore: state.isLoadingMore,
            onLoadMore: () => context.read<PharmacyCubit>().loadMoreExpired(),
          ),
          _buildItemList(
            items: state.expiringSoonItems,
            hasMore: state.hasMoreExpiringSoon,
            isLoadingMore: state.isLoadingMore,
            onLoadMore: () => context.read<PharmacyCubit>().loadMoreExpiringSoon(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList({
    required List<dynamic> items,
    required bool hasMore,
    required bool isLoadingMore,
    required VoidCallback onLoadMore,
  }) {
    print('[ExpiryScreen] _buildItemList: ${items.length} itens, hasMore=$hasMore');
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum item encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // Detecta quando o usuário está próximo do final da lista
        if (!isLoadingMore &&
            hasMore &&
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: items.length + (hasMore ? 1 : 0), // +1 para o indicador de loading
        itemBuilder: (context, index) {
          // Mostra o indicador de loading no final
          if (index == items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                ),
              ),
            );
          }

          final item = items[index];
          return _buildItemCard(item);
        },
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final isExpired = item.expireDate != null && item.expireDate!.isBefore(DateTime.now());
    final statusColor = isExpired ? Colors.red : Colors.orange;
    
    // Calcula os dias restantes
    String statusText;
    if (isExpired) {
      final daysExpired = DateTime.now().difference(item.expireDate!).inDays;
      statusText = daysExpired == 0 ? 'VENCIDO HOJE' : 'VENCIDO HÁ ${daysExpired}d';
    } else if (item.expireDate != null) {
      final daysRemaining = item.expireDate!.difference(DateTime.now()).inDays;
      statusText = daysRemaining == 0 ? 'VENCE HOJE' : 'VENCE EM ${daysRemaining}d';
    } else {
      statusText = 'SEM DATA';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: AppColors.primaryLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.itemTypeName} - ${item.sectionTitle}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Validade',
                      value: item.expireDate != null ? _formatDate(item.expireDate!) : 'N/A',
                      color: statusColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.inventory_2_rounded,
                      label: 'Estoque',
                      value: '${item.currentStock.toStringAsFixed(2)} ${item.measure}',
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
