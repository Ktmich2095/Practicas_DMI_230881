import 'package:flutter/material.dart';

import '../../../domain/entities/season.dart';
import '../../../config/branding/brand_assets.dart';

class TokTikLogo extends StatelessWidget {
  final Season season;
  final double size;
  final bool decorated;
  const TokTikLogo({
    super.key,
    required this.season,
    this.size = 72,
    this.decorated = true,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logotipo TokTik · ${season.label}',
    image: true,
    child: Image.asset(
      BrandAssets.logo(season, decorated: decorated),
      key: ValueKey('logo-${season.name}'),
      width: size,
      height: size,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    ),
  );
}
