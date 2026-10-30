import 'package:flutter/painting.dart';

import '../state/custom_pieces_controller.dart';

import 'product.dart';

abstract final class Catalog {
  static const String _dir = 'assets/images/nest';
  static const String heroImage = '$_dir/hero.jpg';

  static const List<Product> all = [
    Product(
      id: 'oslo-sofa',
      name: 'Oslo Sofa',
      description: 'Designed for slow mornings and long evenings, the Oslo Sofa brings together generous proportions, softly rounded arms, and tactile boucle upholstery. Its understated silhouette makes it an inviting centerpiece for contemporary living spaces, pairing beautifully with natural wood, layered textiles, and warm neutral tones. A timeless piece that makes everyday comfort feel considered.',
      category: ProductCategory.seating,
      price: 1290,
      imageAsset: '$_dir/oslo-sofa.jpg',
      tone: Color(0xFFF7E3AE),
    ),
    Product(
      id: 'miro-chair',
      name: 'Miro Lounge Chair',
      description: 'A sculptural accent chair that turns an ordinary corner into a design moment. The Miro Lounge Chair features a low, generous seat and a beautifully curved back, creating a relaxed silhouette with a confident personality. Style it beside a reading lamp, next to a statement side table, or on its own as an expressive focal point.',
      category: ProductCategory.seating,
      price: 540,
      imageAsset: '$_dir/miro-chair.jpg',
      tone: Color(0xFFF6B9A5),
      isNew: true,
    ),
    Product(
      id: 'pilar-table',
      name: 'Pilar Coffee Table',
      description: 'The Pilar Coffee Table celebrates the beauty of simplicity through a rounded profile, natural oak character, and softly tapered legs. Its balanced proportions bring warmth to the center of your living room without overwhelming the space. Perfect for displaying your favorite books, a ceramic vase, or the small everyday objects that make a house feel personal.',
      category: ProductCategory.tables,
      price: 420,
      imageAsset: '$_dir/pilar-table.jpg',
      tone: Color(0xFFC9D8C3),
    ),
    Product(
      id: 'dune-table',
      name: 'Dune Dining Table',
      description: 'Made for conversations that last a little longer, the Dune Dining Table combines a smooth oval top with the quiet warmth of light ash. Its six-seat layout encourages an easy, welcoming flow around the table, while the natural finish complements both minimal interiors and more expressive dining spaces. A thoughtful foundation for shared meals, celebrations, and everyday rituals.',
      category: ProductCategory.tables,
      price: 980,
      imageAsset: '$_dir/dune-table.jpg',
      tone: Color(0xFFEDE3CC),
    ),
    Product(
      id: 'arc-lamp',
      name: 'Arc Floor Lamp',
      description: 'Bring a softer glow to your favorite corner with the Arc Floor Lamp. Its sweeping silhouette and linen shade create an elegant balance between sculptural form and everyday function. Designed to complement reading nooks, quiet living rooms, and cozy bedside spaces, it adds a layer of warmth that transforms the mood of a room as the day winds down.',
      category: ProductCategory.lighting,
      price: 260,
      imageAsset: '$_dir/arc-lamp.jpg',
      tone: Color(0xFFB9C7F2),
      isNew: true,
    ),
    Product(
      id: 'haven-sideboard',
      name: 'Haven Sideboard',
      description: 'Quietly elegant and thoughtfully understated, the Haven Sideboard brings a sense of order to beautifully lived-in spaces. Its low profile, sliding doors, and fluted walnut-inspired finish create visual texture while keeping everyday essentials out of sight. Place it in a dining room, hallway, or living area to combine practical storage with a refined furniture statement.',
      category: ProductCategory.storage,
      price: 760,
      imageAsset: '$_dir/haven-sideboard.jpg',
      tone: Color(0xFFF7E3AE),
    ),
    Product(
      id: 'terra-vase',
      name: 'Terra Vase',
      description: 'Small in scale, rich in character, the Terra Vase brings an artisanal touch to shelves, consoles, and dining tables. Its sculptural presence and warm terracotta-inspired finish make it beautiful on its own or styled with seasonal branches and fresh stems. Pair it with natural wood, soft linens, and earthy ceramics for a layered, collected look.',
      category: ProductCategory.decor,
      price: 68,
      imageAsset: '$_dir/terra-vase.jpg',
      tone: Color(0xFFF6B9A5),
    ),
    Product(
      id: 'bloom-rug',
      name: 'Bloom Rug',
      description: 'Inspired by the irregular beauty of nature, the Bloom Rug introduces movement, depth, and softness beneath your feet. Its organic floral pattern brings together a relaxed artistic feel and the tactile appeal of wool, making it a natural anchor for living rooms, reading corners, and creative spaces. Let its flowing silhouette contrast with clean-lined furniture for a room that feels curated rather than overly arranged.',
      category: ProductCategory.decor,
      price: 340,
      imageAsset: '$_dir/bloom-rug.jpg',
      tone: Color(0xFFC9D8C3),
      isNew: true,
    ),

    Product(
      id: 'sculpted-chair',
      name: 'Sculpted Accent Chair',
      description: 'A statement chair where expressive curves meet refined craftsmanship. Its sculptural silhouette and contrasting materials bring an artistic presence to living rooms, reading corners, and curated interiors. Pair it with warm wood and soft lighting for a thoughtful, gallery-inspired look.',
      category: ProductCategory.seating,
      price: 620,
      imageAsset: '$_dir/chair-2.jpg',
      tone: Color(0xFFE8D8CC),
      isNew: true,
    ),
    Product(
      id: 'organic-dining-table',
      name: 'Organic Dining Table',
      description: 'Inspired by the natural movement of wood, this dining table makes every gathering feel special. Its expressive form and warm finish create a distinctive focal point, balancing sculptural character with the everyday purpose of a shared dining space.',
      category: ProductCategory.tables,
      price: 1150,
      imageAsset: '$_dir/dunetable-2.jpg',
      tone: Color(0xFFD5B89A),
      isNew: true,
    ),
    Product(
      id: 'sculptural-mirror',
      name: 'Sculptural Wall Mirror',
      description: 'More than a reflective surface, this sculptural mirror brings personality to your walls. Its organic outline softens architectural lines and adds an artistic touch to entryways, bedrooms, and dressing spaces. Style it above a console for a beautifully composed interior moment.',
      category: ProductCategory.decor,
      price: 290,
      imageAsset: '$_dir/mirror.jpg',
      tone: Color(0xFFE8DFD2),
    ),
    Product(
      id: 'abstract-rug',
      name: 'Abstract Statement Rug',
      description: 'Layered organic shapes and rich earthy tones give this statement rug a distinctive artistic character. It anchors a seating area, introduces depth beneath furniture, and connects contrasting colors throughout the room. Ideal for interiors that celebrate expressive shapes and thoughtful design.',
      category: ProductCategory.decor,
      price: 390,
      imageAsset: '$_dir/rug-2.jpg',
      tone: Color(0xFFB8B09D),
      isNew: true,
    ),
    Product(
      id: 'contemporary-sideboard',
      name: 'Contemporary Sideboard',
      description: 'A considered storage piece designed to bring calm and character to your home. Its clean horizontal profile makes it easy to style with artwork, ceramics, and table lamps, while its understated presence complements modern dining rooms and living spaces.',
      category: ProductCategory.storage,
      price: 820,
      imageAsset: '$_dir/sideboard-2.jpg',
      tone: Color(0xFFD9C6AD),
    ),
    Product(
      id: 'artistic-cabinet',
      name: 'Artistic Storage Cabinet',
      description: 'Designed for interiors that appreciate the unexpected, this storage piece combines functional furniture with a bold artistic silhouette. Use it to create a focal point in an entryway or living room, and style the surrounding space with simple accessories to let its form stand out.',
      category: ProductCategory.storage,
      price: 890,
      imageAsset: '$_dir/sideboard-3.jpg',
      tone: Color(0xFFE4D8C8),
      isNew: true,
    ),
    Product(
      id: 'velvet-sofa',
      name: 'Velvet Curve Sofa',
      description: 'Make a confident design statement with a sofa defined by soft curves and rich velvet character. Its expressive profile brings a sense of intimacy and sophistication to the living room, working beautifully with neutral walls, sculptural side tables, and understated accents.',
      category: ProductCategory.seating,
      price: 1490,
      imageAsset: '$_dir/sofa-2.jpg',
      tone: Color(0xFF6F302D),
      isNew: true,
    ),
    Product(
      id: 'organic-lounge-sofa',
      name: 'Cloud Lounge Sofa',
      description: 'Generous rounded forms give this lounge sofa a relaxed, contemporary personality. Its soft-looking silhouette creates an inviting place to unwind, while its distinctive shape adds visual interest without relying on excessive decoration. A natural fit for modern, comfort-focused interiors.',
      category: ProductCategory.seating,
      price: 1580,
      imageAsset: '$_dir/sofa-3.jpg',
      tone: Color(0xFFD8E0DF),
    ),
    Product(
      id: 'sculptural-side-table',
      name: 'Pebble Side Table',
      description: 'Inspired by smooth stones and natural forms, the Pebble Side Table turns a functional surface into a sculptural accent. Its stacked, rounded base creates a sense of movement, while the tabletop offers a convenient place for a book, a cup, or a favorite decorative object.',
      category: ProductCategory.tables,
      price: 360,
      imageAsset: '$_dir/table-2.jpg',
      tone: Color(0xFFD3B89B),
      isNew: true,
    ),

    // BEDROOM — 5 beds
    Product(
      id: 'bed-sculptural-cream',
      name: 'Sculptural Cream Bed',
      description: 'A sculptural upholstered bed featuring playful rounded details, a soft neutral palette, and an artistic silhouette. Designed to become the centerpiece of a contemporary bedroom.',
      category: ProductCategory.bedroom,
      price: 1890,
      imageAsset: '$_dir/bed-1.jpg',
      tone: Color(0xFFD9CFC2),
      isNew: true,
    ),
    Product(
      id: 'bed-cloud-tufted',
      name: 'Cloud Tufted Bed',
      description: 'A generously upholstered bed with a plush, rounded silhouette and a warm taupe finish. Its soft textures create a calm and inviting bedroom atmosphere.',
      category: ProductCategory.bedroom,
      price: 1750,
      imageAsset: '$_dir/bed-2.jpg',
      tone: Color(0xFFB49A84),
      isNew: true,
    ),
    Product(
      id: 'bed-wave-modern',
      name: 'Wave Modern Bed',
      description: 'A contemporary bed featuring a distinctive flowing headboard and coordinated bedside surfaces. A refined choice for modern interiors with sculptural details.',
      category: ProductCategory.bedroom,
      price: 1950,
      imageAsset: '$_dir/bed-3.jpg',
      tone: Color(0xFFB6ADA5),
    ),
    Product(
      id: 'bed-arch-rose',
      name: 'Rose Arch Bed',
      description: 'A romantic upholstered bed with layered arch-shaped headboard panels and a muted rose finish. Its soft curves bring warmth and character to the bedroom.',
      category: ProductCategory.bedroom,
      price: 1680,
      imageAsset: '$_dir/bed-4.jpg',
      tone: Color(0xFFC5A3A0),
      isNew: true,
    ),
    Product(
      id: 'bed-ribbed-sculpture',
      name: 'Ribbed Sculptural Bed',
      description: 'A statement bed with a tall sculptural headboard, subtle ribbed forms, and a sophisticated neutral palette. Designed for bedrooms with a bold contemporary aesthetic.',
      category: ProductCategory.bedroom,
      price: 1820,
      imageAsset: '$_dir/bed-5.jpg',
      tone: Color(0xFFBEBBB5),
    ),

    // SEATING — 2 pieces
    Product(
      id: 'chair-striped-boucle',
      name: 'Monochrome Accent Chair',
      description: 'A bold accent chair upholstered in contrasting black and ivory stripes, balanced by a warm wooden frame. An expressive statement piece for reading corners and living spaces.',
      category: ProductCategory.seating,
      price: 590,
      imageAsset: '$_dir/chair-3.jpg',
      tone: Color(0xFFD4C7B4),
      isNew: true,
    ),
    Product(
      id: 'sofa-curve-stripe',
      name: 'Curved Stripe Sofa',
      description: 'A curved sofa with striking vertical stripes and a rich, warm color palette. Its distinctive profile creates a dramatic focal point in contemporary living rooms.',
      category: ProductCategory.seating,
      price: 2190,
      imageAsset: '$_dir/sofa-4.jpg',
      tone: Color(0xFF804B37),
      isNew: true,
    ),

    // NIGHTSTANDS — 2 pieces
    Product(
      id: 'nightstand-rounded',
      name: 'Rounded Bedside Cabinet',
      description: 'A contemporary bedside cabinet with a rounded silhouette, contrasting finishes, and practical drawer storage. A refined addition to a modern bedroom.',
      category: ProductCategory.nightstands,
      price: 420,
      imageAsset: '$_dir/comod-2.jpg',
      tone: Color(0xFFC7B7A4),
    ),
    Product(
      id: 'nightstand-orbit',
      name: 'Orbit Nightstand',
      description: 'A sculptural bedside table combining smooth rounded forms with a warm wood finish. Its compact design makes it an elegant companion for contemporary beds.',
      category: ProductCategory.nightstands,
      price: 460,
      imageAsset: '$_dir/komod-1.jpg',
      tone: Color(0xFF9C7B60),
      isNew: true,
    ),

    // TABLES — 2 pieces
    Product(
      id: 'table-ruby-pedestal',
      name: 'Ruby Pedestal Table',
      description: 'A glossy red pedestal table with a sculptural base and expressive striped tabletop. Designed to add a confident pop of color to curated interiors.',
      category: ProductCategory.tables,
      price: 380,
      imageAsset: '$_dir/dunetable-3.jpg',
      tone: Color(0xFF9C2925),
      isNew: true,
    ),
    Product(
      id: 'table-red-sculptural',
      name: 'Red Sculptural Side Table',
      description: 'A striking side table with a vibrant red finish and rounded architectural form. Its distinctive silhouette brings an artistic accent to a living room or reading nook.',
      category: ProductCategory.tables,
      price: 340,
      imageAsset: '$_dir/table-3.jpg',
      tone: Color(0xFFB21F24),
      isNew: true,
    ),

    // LIGHTING — 3 pieces
    Product(
      id: 'lamp-organic-floor',
      name: 'Organic Arc Floor Lamp',
      description: 'A sculptural floor lamp with a flowing dark silhouette and a warm woven shade. Its ambient light and organic shape create a calm, sophisticated atmosphere.',
      category: ProductCategory.lighting,
      price: 520,
      imageAsset: '$_dir/lamp-2.jpg',
      tone: Color(0xFF8E7963),
      isNew: true,
    ),
    Product(
      id: 'lamp-bloom-trio',
      name: 'Bloom Floor Lights',
      description: 'A collection of slender floor lights topped with delicate, fan-shaped shades. Their warm glow creates an artistic lighting arrangement for spacious living areas.',
      category: ProductCategory.lighting,
      price: 680,
      imageAsset: '$_dir/lamp-3.jpg',
      tone: Color(0xFFC1A17B),
    ),
    Product(
      id: 'lamp-orb-sculpture',
      name: 'Orb Sculpture Lamp',
      description: 'An expressive sculptural lamp featuring luminous spherical forms held by a dramatic dark figure. A conversation-starting accent for design-led interiors.',
      category: ProductCategory.lighting,
      price: 740,
      imageAsset: '$_dir/lamp-4.jpg',
      tone: Color(0xFF514743),
      isNew: true,
    ),

    // DECOR — 2 mirrors
    Product(
      id: 'mirror-liquid-gold',
      name: 'Liquid Gold Mirror',
      description: 'A full-length mirror framed by an irregular, flowing gold-toned silhouette. Its reflective sculptural frame transforms a functional object into a statement piece.',
      category: ProductCategory.decor,
      price: 560,
      imageAsset: '$_dir/mirror-2.jpg',
      tone: Color(0xFFB18A42),
      isNew: true,
    ),
    Product(
      id: 'mirror-sculpted-burgundy',
      name: 'Burgundy Sculptural Mirror',
      description: 'A bold organic mirror with a deep burgundy sculptural frame. Its fluid shape adds color, depth, and artistic character to contemporary interiors.',
      category: ProductCategory.decor,
      price: 490,
      imageAsset: '$_dir/mirror-3.jpg',
      tone: Color(0xFF672A3D),
      isNew: true,
    ),

    // VANITY & DRESSING — 2 pieces
    Product(
      id: 'vanity-floating-modern',
      name: 'Floating Modern Vanity',
      description: 'A contemporary dressing table with rounded drawers, a contrasting wood finish, and an illuminated mirror. Designed to bring elegance and practical organization to a dressing area.',
      category: ProductCategory.vanity,
      price: 980,
      imageAsset: '$_dir/vanitytable-1.jpg',
      tone: Color(0xFFB3A092),
      isNew: true,
    ),
    Product(
      id: 'vanity-oval-glow',
      name: 'Oval Glow Dressing Table',
      description: 'A refined dressing table paired with a softly illuminated oval mirror and warm wood details. A sophisticated combination of storage, ambient lighting, and understated design.',
      category: ProductCategory.vanity,
      price: 1120,
      imageAsset: '$_dir/vanitytable-2.jpg',
      tone: Color(0xFFC2AA95),
      isNew: true,
    ),
  ];

  static const List<String> _curatedIds = [
    'miro-chair',
    'arc-lamp',
    'pilar-table',
    'terra-vase',
  ];

  static Product byId(String id) {
    final custom = customPieces.productFor(id);
    if (custom != null) return custom;
    return all.firstWhere((p) => p.id == id);
  }

  static bool exists(String id) =>
      customPieces.productFor(id) != null || all.any((p) => p.id == id);

  static List<Product> get curated => [for (final id in _curatedIds) byId(id)];

  static int countIn(ProductCategory category) =>
      all.where((product) => product.category == category).length;

  /// Highest price rounded up to the next 50.
  /// Used by the price slider.
  static int get priceCeiling {
    final top = all
        .map((product) => product.price)
        .reduce((a, b) => a > b ? a : b);

    return (top / 50).ceil() * 50;
  }
}
