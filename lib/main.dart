import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SalesTrackerApp());
}

class SalesTrackerApp extends StatelessWidget {
  const SalesTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class Entry {
  final String type;
  final String name;
  final double amount;
  final DateTime date;

  Entry({
    required this.type,
    required this.name,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
    type: json['type'],
    name: json['name'],
    amount: json['amount'],
    date: DateTime.parse(json['date']),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('entries');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        _entries = decoded.map((e) => Entry.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'entries',
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  double get totalSalesToday => _entries
      .where((e) => e.type == 'sale' && _isToday(e.date))
      .fold(0, (a, e) => a + e.amount);
  double get totalExpensesToday => _entries
      .where((e) => e.type == 'expense' && _isToday(e.date))
      .fold(0, (a, e) => a + e.amount);
  double get netProfitToday => totalSalesToday - totalExpensesToday;

  void _addEntry(Entry entry) {
    setState(() {
      _entries.add(entry);
      _currentIndex = 0;
    });
    _saveEntries();
  }

  void _deleteEntry(Entry entry) {
    setState(() {
      _entries.remove(entry);
    });
    _saveEntries();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        totalSales: totalSalesToday,
        totalExpenses: totalExpensesToday,
        netProfit: netProfitToday,
        entries: _entries.where((e) => _isToday(e.date)).toList(),
        onDelete: _deleteEntry,
      ),
      AddSaleScreen(onAdd: _addEntry),
      AddExpenseScreen(onAdd: _addEntry),
      HistoryScreen(entries: _entries, onDelete: _deleteEntry),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1D9E75),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Sale'),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_circle),
            label: 'Expense',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final double totalSales, totalExpenses, netProfit;
  final List<Entry> entries;
  final Function(Entry) onDelete;

  const DashboardScreen({
    super.key,
    required this.totalSales,
    required this.totalExpenses,
    required this.netProfit,
    required this.entries,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        title: const Text(
          'Sales Tracker 🇪🇹',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                final url = Uri.parse(
                  'https://my-latest-portfolio-alpha.vercel.app/',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Developed by',
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                  Text(
                    'Hailemeskel Girum',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _StatCard(
                  label: 'Total Sales',
                  value: 'ETB ${totalSales.toStringAsFixed(0)}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Expenses',
                  value: 'ETB ${totalExpenses.toStringAsFixed(0)}',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: netProfit >= 0
                    ? const Color(0xFFEAF3DE)
                    : const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Net Profit Today',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ETB ${netProfit.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: netProfit >= 0
                          ? const Color(0xFF1D9E75)
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TODAY\'S ENTRIES',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No entries yet today',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[entries.length - 1 - i];
                        return _EntryCard(entry: e, onDelete: onDelete);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final Entry entry;
  final Function(Entry) onDelete;

  const _EntryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('${entry.date.toIso8601String()}_${entry.name}_${entry.amount}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        onDelete(entry);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: entry.type == 'sale'
                ? const Color(0xFFEAF3DE)
                : const Color(0xFFFCEBEB),
            child: Icon(
              entry.type == 'sale' ? Icons.arrow_upward : Icons.arrow_downward,
              color: entry.type == 'sale'
                  ? const Color(0xFF1D9E75)
                  : Colors.red,
              size: 18,
            ),
          ),
          title: Text(
            entry.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            entry.type == 'sale' ? 'Sale' : 'Expense',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            '${entry.type == 'sale' ? '+' : '-'}ETB ${entry.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: entry.type == 'sale'
                  ? const Color(0xFF1D9E75)
                  : Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddSaleScreen extends StatefulWidget {
  final Function(Entry) onAdd;
  const AddSaleScreen({super.key, required this.onAdd});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        title: const Text('Record Sale', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Name (optional)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Sugar, Bread...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Amount (ETB)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: 'ETB ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final amount = double.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                      ),
                    );
                    return;
                  }
                  widget.onAdd(
                    Entry(
                      type: 'sale',
                      name: _nameController.text.isEmpty
                          ? 'Sale'
                          : _nameController.text,
                      amount: amount,
                      date: DateTime.now(),
                    ),
                  );
                  _nameController.clear();
                  _amountController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Sale saved!'),
                      backgroundColor: Color(0xFF1D9E75),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Save Sale', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  final Function(Entry) onAdd;
  const AddExpenseScreen({super.key, required this.onAdd});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Stock purchase';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Record Expense',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                'Stock purchase',
                'Rent',
                'Transport',
                'Other',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 20),
            const Text(
              'Note (optional)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'e.g. Flour 50kg...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Amount (ETB)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: 'ETB ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final amount = double.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                      ),
                    );
                    return;
                  }
                  final name = _noteController.text.isEmpty
                      ? _category
                      : '$_category - ${_noteController.text}';
                  widget.onAdd(
                    Entry(
                      type: 'expense',
                      name: name,
                      amount: amount,
                      date: DateTime.now(),
                    ),
                  );
                  _noteController.clear();
                  _amountController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Expense saved!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text(
                  'Save Expense',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  final List<Entry> entries;
  final Function(Entry) onDelete;
  const HistoryScreen({
    super.key,
    required this.entries,
    required this.onDelete,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Today';

  List<Entry> get _filtered {
    final now = DateTime.now();
    return widget.entries.where((e) {
      if (_filter == 'Today')
        return e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day;
      if (_filter == 'Week')
        return e.date.isAfter(now.subtract(const Duration(days: 7)));
      if (_filter == 'Month')
        return e.date.year == now.year && e.date.month == now.month;
      return true;
    }).toList();
  }

  double get _filteredSales =>
      _filtered.where((e) => e.type == 'sale').fold(0, (a, e) => a + e.amount);
  double get _filteredExpenses => _filtered
      .where((e) => e.type == 'expense')
      .fold(0, (a, e) => a + e.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D9E75),
        title: const Text('History', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF5F5F5),
            child: Row(
              children: ['Today', 'Week', 'Month', 'All'].map((f) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _filter == f
                            ? const Color(0xFF1D9E75)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1D9E75)),
                      ),
                      child: Text(
                        f,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _filter == f
                              ? Colors.white
                              : const Color(0xFF1D9E75),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatCard(
                  label: 'Sales',
                  value: 'ETB ${_filteredSales.toStringAsFixed(0)}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: 'Expenses',
                  value: 'ETB ${_filteredExpenses.toStringAsFixed(0)}',
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                _StatCard(
                  label: 'Profit',
                  value:
                      'ETB ${(_filteredSales - _filteredExpenses).toStringAsFixed(0)}',
                  color: const Color(0xFF1D9E75),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No entries found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final e = _filtered[_filtered.length - 1 - i];
                      return _EntryCard(entry: e, onDelete: widget.onDelete);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
