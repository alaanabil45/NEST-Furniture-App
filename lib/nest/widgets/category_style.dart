import 'package:flutter/material.dart';

import '../core/nest_theme.dart';
import '../data/product.dart';

extension ProductCategoryStyle on ProductCategory {
  IconData get icon => switch (this) {
    ProductCategory.seating => Icons.weekend_outlined,
    ProductCategory.tables => Icons.table_restaurant_outlined,
    ProductCategory.storage => Icons.inventory_2_outlined,
    ProductCategory.lighting => Icons.lightbulb_outline,
    ProductCategory.decor => Icons.local_florist_outlined,
    ProductCategory.bedroom => Icons.bed_rounded,
    ProductCategory.nightstands => Icons.bedroom_child_outlined,
    ProductCategory.vanity => Icons.bathroom_outlined,
  };

  Color get background => switch (this) {
    ProductCategory.seating => NestColors.butter,
    ProductCategory.tables => NestColors.coral,
    ProductCategory.storage => NestColors.softGreen,
    ProductCategory.lighting => NestColors.cobalt,
    ProductCategory.decor => NestColors.creamDeep,
    ProductCategory.bedroom => NestColors.softGreen,
    ProductCategory.nightstands => NestColors.coral,
    ProductCategory.vanity => NestColors.creamDeep,
  };

  Color get foreground => switch (this) {
    ProductCategory.lighting => NestColors.cream,
    ProductCategory.bedroom => NestColors.charcoal,
    ProductCategory.nightstands => NestColors.charcoal,
    ProductCategory.vanity => NestColors.charcoal,
    _ => NestColors.charcoal,
  };
}
