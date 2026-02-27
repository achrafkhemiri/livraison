import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:frontend/data/models/models.dart';
import 'package:frontend/providers/order_provider.dart';
import 'package:frontend/providers/livreur_provider.dart';
import 'package:frontend/ui/screens/gerant/order_list_screen.dart';

// ── Mock OrderProvider ────────────────────────────────────────
class MockOrderProvider extends ChangeNotifier implements OrderProvider {
  List<Order> _paginatedOrders;
  int _currentPage;
  int _totalElements;
  int _totalPages;
  bool _isFirstPage;
  bool _isLastPage;
  bool _isLoadingPage;
  String? _errorMessage;

  MockOrderProvider({
    List<Order>? paginatedOrders,
    int currentPage = 0,
    int totalElements = 0,
    int totalPages = 1,
    bool isFirstPage = true,
    bool isLastPage = true,
    bool isLoadingPage = false,
    String? errorMessage,
  })  : _paginatedOrders = paginatedOrders ?? [],
        _currentPage = currentPage,
        _totalElements = totalElements,
        _totalPages = totalPages,
        _isFirstPage = isFirstPage,
        _isLastPage = isLastPage,
        _isLoadingPage = isLoadingPage,
        _errorMessage = errorMessage;

  @override
  List<Order> get paginatedOrders => _paginatedOrders;
  @override
  int get currentPage => _currentPage;
  @override
  int get totalElements => _totalElements;
  @override
  int get totalPages => _totalPages;
  @override
  bool get isFirstPage => _isFirstPage;
  @override
  bool get isLastPage => _isLastPage;
  @override
  bool get isLoadingPage => _isLoadingPage;
  @override
  String? get errorMessage => _errorMessage;

  // Track method calls for verification
  int searchOrdersCalled = 0;
  int? lastSearchPage;
  String? lastSearchStatus;
  String? lastSearchQuery;
  DateTime? lastSearchDateFrom;
  DateTime? lastSearchDateTo;

  int nextPageCalled = 0;
  int previousPageCalled = 0;
  int goToPageCalled = 0;
  int? lastGoToPage;
  int refreshCalled = 0;

  @override
  Future<void> searchOrders({
    int page = 0,
    int? size = 10,
    String? search,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    searchOrdersCalled++;
    lastSearchPage = page;
    lastSearchStatus = status;
    lastSearchQuery = search;
    lastSearchDateFrom = dateFrom;
    lastSearchDateTo = dateTo;
    notifyListeners();
  }

  @override
  Future<void> nextPage() async {
    nextPageCalled++;
    notifyListeners();
  }

  @override
  Future<void> previousPage() async {
    previousPageCalled++;
    notifyListeners();
  }

  @override
  Future<void> goToPage(int page) async {
    goToPageCalled++;
    lastGoToPage = page;
    notifyListeners();
  }

  @override
  Future<void> refreshCurrentPage() async {
    refreshCalled++;
    notifyListeners();
  }

  @override
  Future<bool> updateOrderStatus(int id, String status) async => true;

  @override
  Future<bool> assignOrderToLivreur(int orderId, int livreurId) async => true;

  @override
  Future<List<Map<String, dynamic>>> getRecommendedLivreurs(int orderId) async => [];

  @override
  Future<bool> createOrder(Order order) async => true;

  @override
  Future<void> loadProductsStock() async {}

  @override
  List<Map<String, dynamic>> get productsStock => [];

  // Stubs for remaining OrderProvider interface
  @override
  List<Order> get orders => [];
  @override
  List<Order> get pendingOrders => [];
  @override
  List<Order> get myOrders => [];
  @override
  List<Order> get proposedOrders => [];
  @override
  Order? get selectedOrder => null;
  @override
  bool get isLoading => false;
  @override
  Map<String, dynamic>? get mapData => null;
  @override
  Map<String, dynamic>? get collectionPlan => null;
  @override
  int get pageSize => 10;
  @override
  String? get searchQuery => null;
  @override
  String? get statusFilter => null;
  @override
  DateTime? get dateFrom => null;
  @override
  DateTime? get dateTo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Mock LivreurProvider ──────────────────────────────────────
class MockLivreurProvider extends ChangeNotifier implements LivreurProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Test Helpers ──────────────────────────────────────────────
List<Order> _createTestOrders(int count) {
  return List.generate(count, (i) => Order(
    id: i + 1,
    numero: 'CMD-${1000 + i}',
    clientId: 100 + i,
    clientNom: 'Client ${i + 1}',
    livreurId: i % 3 == 0 ? null : 200 + i,
    livreurNom: i % 3 == 0 ? null : 'Livreur ${i + 1}',
    status: ['pending', 'processing', 'shipped', 'delivered'][i % 4],
    montantTTC: 50.0 + i * 10,
    dateCommande: DateTime(2024, 6, 15, 10 + i, 30),
    adresseLivraison: 'Adresse ${i + 1}, Tunis',
  ));
}

Widget _buildTestWidget(MockOrderProvider mockProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<OrderProvider>.value(value: mockProvider),
      ChangeNotifierProvider<LivreurProvider>.value(value: MockLivreurProvider()),
    ],
    child: const MaterialApp(
      home: OrderListScreen(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────
void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_FR');
  });
  group('OrderListScreen', () {
    testWidgets('shows loading indicator when isLoadingPage is true', (tester) async {
      final mock = MockOrderProvider(isLoadingPage: true);
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement...'), findsOneWidget);
    });

    testWidgets('shows empty state when no orders', (tester) async {
      final mock = MockOrderProvider(paginatedOrders: [], totalElements: 0);
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      expect(find.text('Aucune commande'), findsOneWidget);
      expect(find.text('Les commandes apparaîtront ici'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      final mock = MockOrderProvider(errorMessage: 'Erreur réseau');
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      expect(find.text('Erreur de chargement'), findsOneWidget);
      expect(find.text('Erreur réseau'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('displays order cards with correct info', (tester) async {
      final orders = _createTestOrders(3);
      final mock = MockOrderProvider(
        paginatedOrders: orders,
        totalElements: 3,
        totalPages: 1,
      );
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      // Verify order numbers (visible items may be limited in test viewport)
      expect(find.text('#CMD-1000'), findsOneWidget);
      expect(find.text('#CMD-1001'), findsOneWidget);

      // Verify client names
      expect(find.text('Client 1'), findsOneWidget);
      expect(find.text('Client 2'), findsOneWidget);

      // Verify amounts
      expect(find.text('50.00 TND'), findsOneWidget);
      expect(find.text('60.00 TND'), findsOneWidget);
    });

    testWidgets('displays header with correct total count', (tester) async {
      final orders = _createTestOrders(5);
      final mock = MockOrderProvider(
        paginatedOrders: orders,
        totalElements: 25,
        totalPages: 3,
      );
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      // Header should show total
      expect(find.text('25 commandes'), findsOneWidget);
      expect(find.text('Commandes'), findsOneWidget);
    });

    testWidgets('shows search bar with placeholder text', (tester) async {
      final mock = MockOrderProvider();
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Rechercher par n°, client, livreur...'), findsOneWidget);
    });

    testWidgets('calls searchOrders on init', (tester) async {
      final mock = MockOrderProvider();
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      // Should call searchOrders during init
      expect(mock.searchOrdersCalled, greaterThanOrEqualTo(1));
      expect(mock.lastSearchPage, 0);
    });

    testWidgets('shows status filter chips', (tester) async {
      final mock = MockOrderProvider();
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      // All status labels should be visible (scrollable list)
      expect(find.text('Toutes'), findsOneWidget);
      expect(find.text('En attente'), findsAtLeast(1));
    });

    testWidgets('tapping status chip triggers search with status filter', (tester) async {
      final mock = MockOrderProvider();
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      final initialCalls = mock.searchOrdersCalled;

      // Tap "En attente" chip
      await tester.tap(find.text('En attente').first);
      await tester.pump();

      expect(mock.searchOrdersCalled, greaterThan(initialCalls));
      expect(mock.lastSearchStatus, 'pending');
    });

    testWidgets('shows pagination controls when totalPages > 1', (tester) async {
      final orders = _createTestOrders(5);
      final mock = MockOrderProvider(
        paginatedOrders: orders,
        totalElements: 25,
        totalPages: 3,
        currentPage: 0,
        isFirstPage: true,
        isLastPage: false,
      );
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      // Pagination bar should show page info
      expect(find.text('Page 1/3'), findsOneWidget);

      // Should show chevron icons
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('hides pagination controls when totalPages <= 1', (tester) async {
      final orders = _createTestOrders(3);
      final mock = MockOrderProvider(
        paginatedOrders: orders,
        totalElements: 3,
        totalPages: 1,
      );
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('shows filter toggle button in header', (tester) async {
      final mock = MockOrderProvider();
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
    });

    testWidgets('tapping filter button reveals date filter panel', (tester) async {
      final mock = MockOrderProvider();
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      // Initially date filter should NOT be visible
      expect(find.text('Filtrer par date'), findsNothing);

      // Tap filter icon
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pump();

      // Date filter should now be visible
      expect(find.text('Filtrer par date'), findsOneWidget);
      expect(find.text('Du'), findsOneWidget);
      expect(find.text('Au'), findsOneWidget);
    });

    testWidgets('shows results count text', (tester) async {
      final orders = _createTestOrders(2);
      final mock = MockOrderProvider(
        paginatedOrders: orders,
        totalElements: 15,
        totalPages: 2,
      );
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      expect(find.text('15 résultats'), findsOneWidget);
    });

    testWidgets('shows actions popup menu on order card', (tester) async {
      final orders = [Order(
        id: 1,
        numero: 'CMD-001',
        clientId: 1,
        clientNom: 'Test Client',
        status: 'pending',
        montantTTC: 100.0,
        dateCommande: DateTime(2024, 6, 15),
      )];
      final mock = MockOrderProvider(
        paginatedOrders: orders,
        totalElements: 1,
        totalPages: 1,
      );
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      // Actions button should be visible
      expect(find.text('Actions'), findsOneWidget);
    });

    testWidgets('shows FAB for creating orders', (tester) async {
      final mock = MockOrderProvider();
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays status badge on order cards', (tester) async {
      final orders = [
        Order(id: 1, numero: 'CMD-P', clientId: 1, status: 'pending',
            montantTTC: 50, dateCommande: DateTime(2024, 1, 1)),
        Order(id: 2, numero: 'CMD-D', clientId: 2, status: 'delivered',
            montantTTC: 75, dateCommande: DateTime(2024, 1, 2)),
      ];
      final mock = MockOrderProvider(
        paginatedOrders: orders,
        totalElements: 2,
        totalPages: 1,
      );
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      // Status labels should appear as badges
      expect(find.text('En attente'), findsAtLeast(1));
      expect(find.text('Livrée'), findsAtLeast(1));
    });

    testWidgets('shows "Non assigné" for orders without livreur', (tester) async {
      final orders = [Order(
        id: 1,
        numero: 'CMD-NA',
        clientId: 1,
        clientNom: 'Client',
        livreurId: null,
        livreurNom: null,
        status: 'pending',
        montantTTC: 100.0,
        dateCommande: DateTime(2024, 6, 1),
      )];
      final mock = MockOrderProvider(
        paginatedOrders: orders,
        totalElements: 1,
        totalPages: 1,
      );
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      expect(find.text('Non assigné'), findsOneWidget);
    });

    testWidgets('shows "Aucun résultat trouvé" with active filters and empty list', (tester) async {
      final mock = MockOrderProvider(
        paginatedOrders: [],
        totalElements: 0,
      );
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      // Activate a filter by tapping a status chip
      await tester.tap(find.text('En attente').first);
      await tester.pump();

      // Now empty state should show filtered message
      expect(find.text('Aucun résultat trouvé'), findsOneWidget);
      expect(find.text('Essayez de modifier vos filtres'), findsOneWidget);
      expect(find.text('Effacer les filtres'), findsOneWidget);
    });

    testWidgets('retry button triggers reload on error', (tester) async {
      final mock = MockOrderProvider(errorMessage: 'Erreur test');
      await tester.pumpWidget(_buildTestWidget(mock));
      await tester.pump();

      final callsBefore = mock.searchOrdersCalled;

      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      expect(mock.searchOrdersCalled, greaterThan(callsBefore));
    });
  });
}
