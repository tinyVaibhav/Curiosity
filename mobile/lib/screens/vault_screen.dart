import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/models/feed_models.dart';
import '../core/state/feed_provider.dart';
import '../core/theme/geist_theme.dart';
import '../services/vault_service.dart';
import '../widgets/vault_history_card.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<VaultHistoryItem> _historyItems = [];
  bool _isLoading = true;
  String? _loadingDate;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await VaultService.instance.fetchVaultHistory();
      if (mounted) {
        setState(() {
          _historyItems = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load archive timeline.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleTimeTravel(String packDate) async {
    HapticFeedback.lightImpact();
    setState(() {
      _loadingDate = packDate;
    });

    final feedProvider = context.read<FeedProvider>();
    await feedProvider.loadArchivePack(packDate);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? GeistColors.darkBackground : GeistColors.lightBackground;
    final borderColor = isDark ? GeistColors.darkBorder : GeistColors.lightBorder;
    final primaryTextColor = isDark ? GeistColors.darkTextPrimary : GeistColors.lightTextPrimary;
    final secondaryTextColor = isDark ? GeistColors.darkTextSecondary : GeistColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: SafeArea(
          child: Container(
            height: 60.0,
            padding: const EdgeInsets.symmetric(horizontal: GeistSpacing.sm),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
            ),
            child: Row(
              children: [
                // Back Button
                Semantics(
                  button: true,
                  label: 'Back, return to previous screen',
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(GeistSpacing.radiusMd),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GeistSpacing.sm,
                          vertical: GeistSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 14.0,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(width: GeistSpacing.xs),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Centered Screen Title
                Semantics(
                  header: true,
                  child: Text(
                    'The Vault (Past 30 Days)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: primaryTextColor,
                    ),
                  ),
                ),
                const Spacer(),
                // Balance empty space for true center
                const SizedBox(width: 60.0),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 24.0,
                height: 24.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: primaryTextColor,
                ),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 36.0, color: secondaryTextColor),
                      const SizedBox(height: GeistSpacing.sm),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: GeistSpacing.md),
                      OutlinedButton(
                        onPressed: _fetchHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _historyItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 36.0, color: secondaryTextColor),
                          const SizedBox(height: GeistSpacing.sm),
                          Text(
                            'No past editions available yet.',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: primaryTextColor,
                      backgroundColor: isDark ? GeistColors.darkSurface : GeistColors.lightSurface,
                      onRefresh: _fetchHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(GeistSpacing.md),
                        itemCount: _historyItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: GeistSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = _historyItems[index];
                          final isCardLoading = _loadingDate == item.packDate;

                          return VaultHistoryCard(
                            item: item,
                            isLoading: isCardLoading,
                            onTap: () => _handleTimeTravel(item.packDate),
                          );
                        },
                      ),
                    ),
    );
  }
}
