import 'package:flutter/material.dart';
import '../models/anime.dart';
import '../models/watchlist.dart';
import '../services/image_service.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final Watchlist? watchlist;
  final VoidCallback onTap;

  const AnimeCard({
    super.key,
    required this.anime,
    this.watchlist,
    required this.onTap,
  });

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case Watchlist.statusPlanned:
        return Colors.blue;
      case Watchlist.statusWatching:
        return Colors.orange;
      case Watchlist.statusCompleted:
        return Colors.green;
      case Watchlist.statusDropped:
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Build schedule string
    String schedule = '';
    if (anime.releaseDay != null && anime.releaseDay!.isNotEmpty) {
      schedule = anime.releaseDay!;
    }
    if (anime.releaseTime != null && anime.releaseTime!.isNotEmpty) {
      schedule = schedule.isEmpty
          ? anime.releaseTime!
          : '$schedule • ${anime.releaseTime}';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Image
            SizedBox(
              width: 90,
              height: 125,
              child: ImageService.instance.buildImage(
                imagePath: anime.imagePath,
                width: 90,
                height: 125,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Release Schedule
                    if (schedule.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              schedule,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Platform
                    if (anime.platform != null && anime.platform!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.tv,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              anime.platform!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    // Watchlist Status badge if in watchlist
                    if (watchlist != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(watchlist!.status, theme.colorScheme)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getStatusColor(watchlist!.status, theme.colorScheme)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          watchlist!.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(
                              watchlist!.status,
                              theme.colorScheme,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
