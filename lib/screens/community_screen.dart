import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Tip', 'Question', 'Success'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final p = context.read<AppProvider>();
      if (p.posts.isEmpty) p.fetchCommunityPosts();
    });
  }

  List<dynamic> _filtered(List<dynamic> posts) {
    if (_selectedFilter == 'All') return posts;
    return posts
        .where((p) =>
            (p['category'] ?? '').toString().toLowerCase() ==
            _selectedFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final posts = _filtered(provider.posts);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppTheme.primaryGreen,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Community',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          'Grow together with fellow farmers',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_square, color: Colors.white),
                tooltip: 'New Post',
                onPressed: () => _showNewPostSheet(context),
              ),
            ],
          ),

          // ── Filter Chips ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: _filters.map((f) {
                  final sel = f == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow:
                            sel ? AppTheme.elevatedShadow : AppTheme.cardShadow,
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Posts ────────────────────────────────────────────────────────
          if (provider.posts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            )
          else if (posts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No posts in this category',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == posts.length) return const SizedBox(height: 100);
                  return _PostCard(
                    post: posts[i],
                    onLike: () =>
                        provider.togglePostLike(posts[i]['id'] as int),
                  );
                },
                childCount: posts.length + 1,
              ),
            ),
        ],
      ),
    );
  }

  void _showNewPostSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String category = 'tip';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Share with the Community',
                    style: AppTheme.heading1),
                const SizedBox(height: 16),

                // Category
                const Text('Category', style: AppTheme.bodySmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final c in ['tip', 'question', 'success'])
                      GestureDetector(
                        onTap: () => setModal(() => category = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: category == c
                                ? _catColor(c)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c[0].toUpperCase() + c.substring(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: category == c
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(hintText: 'Post title'),
                ),
                const SizedBox(height: 12),

                // Content
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      hintText: 'Share your tip, question or success story...'),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Post submitted! (Firebase coming soon)'),
                          backgroundColor: AppTheme.primaryGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Publish Post'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'tip': return AppTheme.primaryGreen;
      case 'question': return AppTheme.infoBlue;
      case 'success': return AppTheme.accentOrange;
      default: return AppTheme.primaryGreen;
    }
  }
}

class _PostCard extends StatelessWidget {
  final dynamic post;
  final VoidCallback onLike;
  const _PostCard({required this.post, required this.onLike});

  Color _catColor(String cat) {
    switch (cat) {
      case 'tip': return AppTheme.primaryGreen;
      case 'question': return AppTheme.infoBlue;
      case 'success': return AppTheme.accentOrange;
      default: return AppTheme.textMuted;
    }
  }

  Color _catBg(String cat) {
    switch (cat) {
      case 'tip': return const Color(0xFFE3F5EB);
      case 'question': return const Color(0xFFEBF3FF);
      case 'success': return const Color(0xFFFFF4E0);
      default: return const Color(0xFFF2F2F2);
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'tip': return Icons.lightbulb_outline_rounded;
      case 'question': return Icons.help_outline_rounded;
      case 'success': return Icons.emoji_events_outlined;
      default: return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = post['category'] ?? 'tip';
    final liked = post['liked'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _catColor(cat).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      post['author_avatar'] ?? '??',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _catColor(cat),
                          fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['author'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textPrimary)),
                      Text(post['time'] ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _catBg(cat),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_catIcon(cat), size: 12, color: _catColor(cat)),
                      const SizedBox(width: 4),
                      Text(
                        cat[0].toUpperCase() + cat.substring(1),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _catColor(cat)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(post['title'] ?? '',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),

            // Content
            Text(
              post['content'] ?? '',
              style: AppTheme.bodyLarge,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // Footer actions
            const Divider(color: AppTheme.dividerColor, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                // Like
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(liked),
                          size: 20,
                          color: liked ? AppTheme.errorRed : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post['likes']}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: liked
                              ? AppTheme.errorRed
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Comments
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 18, color: AppTheme.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      '${post['comments_count']} comments',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                // Share
                Row(
                  children: const [
                    Icon(Icons.share_outlined,
                        size: 18, color: AppTheme.textMuted),
                    SizedBox(width: 4),
                    Text('Share',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}