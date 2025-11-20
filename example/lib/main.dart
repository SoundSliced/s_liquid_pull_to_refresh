import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:s_liquid_pull_to_refresh/s_liquid_pull_to_refresh.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLiquidPullToRefresh Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      scrollBehavior: MaterialScrollBehavior().copyWith(
        physics: BouncingScrollPhysics(),
        scrollbars: true,
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
          PointerDeviceKind.trackpad
        },
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ExamplesListPage(),
    );
  }
}

/// Main page showing different example variations
class ExamplesListPage extends StatelessWidget {
  const ExamplesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SLiquidPullToRefresh Examples'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ExampleCard(
            title: 'Basic Example',
            description: 'Simple pull-to-refresh with default settings',
            icon: Icons.refresh,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BasicExamplePage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ExampleCard(
            title: 'Custom Colors',
            description: 'Customized colors and styling',
            icon: Icons.palette,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomColorsExamplePage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ExampleCard(
            title: 'Fast Animation',
            description: 'Faster animation with custom speed',
            icon: Icons.speed,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FastAnimationExamplePage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ExampleCard(
            title: 'Programmatic Trigger',
            description: 'Trigger refresh with a button',
            icon: Icons.touch_app,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProgrammaticExamplePage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ExampleCard(
            title: 'GridView Example',
            description: 'Using with GridView scrollable',
            icon: Icons.grid_view,
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GridViewExamplePage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Basic example with default settings
class BasicExamplePage extends StatefulWidget {
  const BasicExamplePage({super.key});

  @override
  State<BasicExamplePage> createState() => _BasicExamplePageState();
}

class _BasicExamplePageState extends State<BasicExamplePage> {
  final List<int> _items = List.generate(20, (index) => index);
  int _refreshCount = 0;

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _refreshCount++;
      _items.insert(0, _refreshCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Example'),
      ),
      body: SLiquidPullToRefresh(
        onRefresh: _handleRefresh,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(child: Text('${_items[index]}')),
                title: Text('Item ${_items[index]}'),
                subtitle: Text('Pull down to refresh • Count: $_refreshCount'),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Example with custom colors
class CustomColorsExamplePage extends StatefulWidget {
  const CustomColorsExamplePage({super.key});

  @override
  State<CustomColorsExamplePage> createState() =>
      _CustomColorsExamplePageState();
}

class _CustomColorsExamplePageState extends State<CustomColorsExamplePage> {
  final List<String> _items = List.generate(15, (i) => 'Message ${i + 1}');

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _items.insert(0, 'New Message ${_items.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Colors'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SLiquidPullToRefresh(
        onRefresh: _handleRefresh,
        height: 150,
        color: Colors.deepPurple,
        backgroundColor: Colors.white,
        borderWidth: 4.0,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade100, Colors.purple.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _items[index],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Example with fast animation
class FastAnimationExamplePage extends StatefulWidget {
  const FastAnimationExamplePage({super.key});

  @override
  State<FastAnimationExamplePage> createState() =>
      _FastAnimationExamplePageState();
}

class _FastAnimationExamplePageState extends State<FastAnimationExamplePage> {
  final List<String> _news = List.generate(
    10,
    (i) => 'News Article ${i + 1}',
  );

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _news.insert(0, 'Breaking News ${_news.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fast Animation')),
      body: SLiquidPullToRefresh(
        onRefresh: _handleRefresh,
        animSpeedFactor: 2.0,
        springAnimationDurationInMilliseconds: 600,
        height: 100,
        color: Colors.orange,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _news.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.article, color: Colors.orange),
              title: Text(_news[index]),
              subtitle: Text(DateTime.now().toString().split('.')[0]),
              trailing: const Icon(Icons.chevron_right),
            );
          },
        ),
      ),
    );
  }
}

/// Example with programmatic trigger
class ProgrammaticExamplePage extends StatefulWidget {
  const ProgrammaticExamplePage({super.key});

  @override
  State<ProgrammaticExamplePage> createState() =>
      _ProgrammaticExamplePageState();
}

class _ProgrammaticExamplePageState extends State<ProgrammaticExamplePage> {
  final _refreshKey = GlobalKey<SLiquidPullToRefreshState>();
  final List<String> _tasks = List.generate(12, (i) => 'Task ${i + 1}');
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _tasks.insert(0, 'New Task ${_tasks.length + 1}');
      _isRefreshing = false;
    });
  }

  void _triggerRefresh() {
    _refreshKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programmatic Trigger')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tap the button to trigger refresh programmatically',
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : _triggerRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SLiquidPullToRefresh(
              key: _refreshKey,
              onRefresh: _handleRefresh,
              color: Colors.green,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    value: false,
                    onChanged: (_) {},
                    title: Text(_tasks[index]),
                    secondary: const Icon(Icons.task_alt),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Example with GridView
class GridViewExamplePage extends StatefulWidget {
  const GridViewExamplePage({super.key});

  @override
  State<GridViewExamplePage> createState() => _GridViewExamplePageState();
}

class _GridViewExamplePageState extends State<GridViewExamplePage> {
  List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _colors = [
        Colors.primaries[_colors.length % Colors.primaries.length],
        ..._colors,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GridView Example')),
      body: SLiquidPullToRefresh(
        onRefresh: _handleRefresh,
        color: Colors.teal,
        showChildOpacityTransition: false,
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _colors.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: _colors[index],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _colors[index].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
