import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

// 导入你的页面文件
import 'pages/home_page.dart';
import 'pages/favorite_page.dart';
import 'pages/downloads_page.dart';
import 'pages/settings_page.dart';
import 'pages/search_page.dart';

void main() {
  runApp(const MyApp());
}

// 1. 定义导航状态模型
class NavigationState {
  final int index;
  final String? query;

  NavigationState({required this.index, this.query});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationState && index == other.index && query == other.query;

  @override
  int get hashCode => index.hashCode ^ query.hashCode;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Music',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // 保持你原有的种子颜色
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MyMainPage(),
    );
  }
}

class MyMainPage extends StatefulWidget {
  const MyMainPage({super.key});

  @override
  State<MyMainPage> createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MyMainPage> {
  // --- 导航核心状态 ---
  int _selectedIndex = 0;
  String? _submittedQuery;
  bool _isReversed = false;

  // 历史栈与重做栈
  final List<NavigationState> _history = [];
  final List<NavigationState> _redoStack = [];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // 计算当前状态对象
  NavigationState get _currentState =>
      NavigationState(index: _selectedIndex, query: _submittedQuery);

  bool get _isSearching => _submittedQuery != null;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --- 核心逻辑：记录并跳转 ---
  void _recordAndGo(NavigationState newState) {
    if (newState == _currentState) return;

    setState(() {
      _history.add(_currentState);
      _redoStack.clear();
      if (_history.length > 50) _history.removeAt(0);

      _selectedIndex = newState.index;
      _submittedQuery = newState.query;
    });
  }

  // --- 核心逻辑：Undo (后退) ---
  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      final previous = _history.removeLast();
      _redoStack.add(_currentState);
      _isReversed = previous.index < _selectedIndex;
      _selectedIndex = previous.index;
      _submittedQuery = previous.query;
      _searchController.text = previous.query ?? "";
    });
    _searchFocusNode.unfocus();
  }

  // --- 核心逻辑：Redo (前进) ---
  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      final next = _redoStack.removeLast();
      _history.add(_currentState);
      _isReversed = next.index > _selectedIndex;
      _selectedIndex = next.index;
      _submittedQuery = next.query;
      _searchController.text = next.query ?? "";
    });
  }

  // --- UI 触发动作 ---
  void _handleSearch(String value) {
    if (value.trim().isEmpty) return;
    _recordAndGo(NavigationState(index: _selectedIndex, query: value.trim()));
    _searchFocusNode.unfocus();
  }

  void _onNavItemSelected(int index) {
    _recordAndGo(NavigationState(index: index, query: null));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _history.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _undo();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            // 1. TopBar (保留 Padding)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildTopBar(),
            ),

            // 2. 中间区域 (Sidebar + Content)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Sidebar
                    _buildNavigationSideBar(),

                    const SizedBox(width: 8),

                    // Content
                    Expanded(
                      child: PageTransitionSwitcher(
                        duration: const Duration(milliseconds: 300),
                        reverse: _isReversed,
                        transitionBuilder: (child, anim, secAnim) {
                          return SharedAxisTransition(
                            animation: anim,
                            secondaryAnimation: secAnim,
                            transitionType: SharedAxisTransitionType.vertical,
                            child: child,
                          );
                        },
                        child: Container(
                          key: ValueKey(
                            '${_selectedIndex}_${_submittedQuery ?? "none"}',
                          ),
                          child: _isSearching
                              ? SearchPage(
                                  query: _submittedQuery!,
                                  onBack: _undo,
                                )
                              : _buildTabContent(_selectedIndex),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. BottomBar (新样式，全宽)
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // --- 你的原始 Sidebar 样式 (完全复原) ---
  Widget _buildNavigationSideBar() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryFixed,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: _isSearching ? null : _selectedIndex,
              onDestinationSelected: _onNavItemSelected,
              backgroundColor: Colors.transparent,
              indicatorColor: Theme.of(context).colorScheme.primaryFixedDim,
              indicatorShape: const CircleBorder(),
              minWidth: 56,
              labelType: NavigationRailLabelType.none,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text("Home"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.music_note_outlined),
                  selectedIcon: Icon(Icons.music_note),
                  label: Text("Favorite"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: Text("Downloads"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text("Settings"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 新的 BottomBar 样式 ---
  Widget _buildBottomBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 84,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        // 顶部添加极细的分割线
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Column(
        children: [
          // 1. 顶部进度条
          LinearProgressIndicator(
            value: 0.35,
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: colorScheme.primary,
          ),

          // 2. 主体控制区
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  // --- 左侧：歌曲信息 (30%) ---
                  Expanded(flex: 3, child: _buildNowPlayingInfo(colorScheme)),

                  // --- 中间：播放控制 (40%) ---
                  Expanded(flex: 4, child: _buildPlayerControls(colorScheme)),

                  // --- 右侧：辅助工具 (30%) ---
                  Expanded(flex: 3, child: _buildTrailingTools(colorScheme)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 左侧：封面与文字
  Widget _buildNowPlayingInfo(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 专辑封面
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: colorScheme.primaryContainer,
            // 模拟封面图
            image: const DecorationImage(
              image: NetworkImage(
                "https://p2.music.126.net/yubdvc1O67Mc-R6278JGkQ==/109951170780656355.jpg",
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 歌名与歌手
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "We are condemned to be free(cn)",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "Fontainebleau",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 中间：播放控制按钮
  Widget _buildPlayerControls(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite),
          color: Colors.blueAccent,
          tooltip: "Like",
          iconSize: 22,
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 28,
          tooltip: "Previous",
        ),
        const SizedBox(width: 16),
        // 播放按钮
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.onSurface,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded),
            color: colorScheme.surface,
            iconSize: 32,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 28,
          tooltip: "Next",
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.lyrics_outlined),
          iconSize: 22,
          tooltip: "Lyrics",
        ),
      ],
    );
  }

  // 右侧：辅助工具
  Widget _buildTrailingTools(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.queue_music_rounded),
          tooltip: "Playlist",
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.repeat_rounded),
          tooltip: "Repeat",
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.shuffle_rounded),
          tooltip: "Shuffle",
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.volume_up_rounded),
          tooltip: "Volume",
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
          tooltip: "Expand",
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: _history.isNotEmpty ? _undo : null,
          tooltip: "后退",
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward, size: 20),
          onPressed: _redoStack.isNotEmpty ? _redo : null,
          tooltip: "前进",
        ),
        const Spacer(),
        ListenableBuilder(
          listenable: Listenable.merge([_searchFocusNode, _searchController]),
          builder: (context, _) {
            bool isExpanded =
                _searchFocusNode.hasFocus || _searchController.text.isNotEmpty;
            return AnimatedContainer(
              curve: Easing.emphasizedDecelerate,
              duration: const Duration(milliseconds: 200),
              width: isExpanded ? 256 : 112,
              child: SearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onSubmitted: _handleSearch,
                hintText: "搜索",
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.secondaryContainer,
                ),
                constraints: const BoxConstraints(maxHeight: 32, minHeight: 32),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12),
                ),
                leading: const Icon(Icons.search, size: 18),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        if (_isSearching) _undo();
                      },
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
      ],
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const FavoritePage();
      case 2:
        return const DownloadsPage();
      case 3:
        return const SettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }
}
