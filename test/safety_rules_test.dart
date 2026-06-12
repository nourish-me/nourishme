import 'package:flutter_test/flutter_test.dart';
import 'package:nurturetrack/services/safety_rules.dart';

// Pins the deterministic caffeine rule (docs/safety-rules-reference.md, rule 1).
// This is the safety layer that must NOT depend on the model remembering to
// warn: known caffeine sources trigger the 200 mg/day limit, phase-gated.
void main() {
  const pregnant = SafetyPhase(isPregnant: true, trimester: 2);
  const pregnantT1 = SafetyPhase(isPregnant: true, trimester: 1);
  const pregnantNoTri = SafetyPhase(isPregnant: true);
  const lactating = SafetyPhase(isLactating: true);
  const neither = SafetyPhase();

  group('caffeine rule — triggers', () {
    test('pregnant + coffee → German warning', () {
      final w = SafetyRules.caffeine('Großer Kaffee', pregnant, locale: 'de');
      expect(w, isNotNull);
      expect(w, contains('200 mg'));
      expect(w, startsWith('Koffein'));
    });

    test('lactating + espresso → English warning', () {
      final w = SafetyRules.caffeine('double espresso', lactating, locale: 'en');
      expect(w, isNotNull);
      expect(w, contains('200 mg'));
      expect(w, startsWith('Caffeine'));
    });

    test('detection is case-insensitive', () {
      expect(
        SafetyRules.caffeine('ENERGY drink', pregnant, locale: 'en'),
        isNotNull,
      );
    });

    test('matcha and cola are recognised caffeine sources', () {
      expect(SafetyRules.caffeine('Matcha Latte', pregnant), isNotNull);
      expect(SafetyRules.caffeine('Cola', lactating), isNotNull);
    });
  });

  group('caffeine rule — no warning', () {
    test('phase not relevant (neither pregnant nor lactating) → null', () {
      expect(SafetyRules.caffeine('Espresso', neither, locale: 'de'), isNull);
    });

    test('no caffeine source in product → null', () {
      expect(SafetyRules.caffeine('Apfel mit Quark', pregnant), isNull);
    });

    test('herbal tea is not flagged (bare "Tee" is intentionally not a trigger)',
        () {
      expect(SafetyRules.caffeine('Kamillentee', pregnant), isNull);
    });

    test('substring trap: "Tomate" must NOT match the "mate" keyword', () {
      expect(SafetyRules.caffeine('Tomate mit Mozzarella', pregnant), isNull);
    });

    test('but a real "Mate" drink IS flagged', () {
      expect(SafetyRules.caffeine('Club Mate', pregnant), isNotNull);
    });
  });

  group('caffeine rule — energy drink special case (DGE)', () {
    test('pregnant + Red Bull → strict "avoid entirely" wording, not the '
        'standard 200 mg limit (DGE specifically scopes energy drinks: '
        'taurine, inositol, unclear interactions)', () {
      final w = SafetyRules.caffeine('Red Bull', pregnant, locale: 'de');
      expect(w, isNotNull);
      expect(w!.toLowerCase(), contains('komplett meiden'));
      expect(w.toLowerCase(), contains('taurin'));
    });

    test('lactating + Red Bull → falls back to the regular 200 mg limit '
        'message (DGE energy-drink rule scopes to pregnancy)', () {
      final w = SafetyRules.caffeine('Red Bull', lactating, locale: 'de');
      expect(w, isNotNull);
      expect(w!.toLowerCase(), contains('tagesgrenze'));
    });

    test('Monster Energy / Rockstar Energy / bare "energy drink" all fire '
        'the strict pregnancy wording (the "energy" token in the input is '
        'what carries the caffeine-keyword match - bare brand names like '
        '"Rockstar" alone need the "energy" companion word for the rule '
        'to engage)', () {
      for (final p in ['Monster Energy', 'Rockstar Energy', 'energy drink']) {
        final w = SafetyRules.caffeine(p, pregnant, locale: 'de');
        expect(w, isNotNull, reason: '$p should fire caffeine in pregnancy');
        expect(w!.toLowerCase(), contains('komplett meiden'),
            reason: '$p should get the strict energy-drink wording');
      }
    });
  });

  group('alcohol rule — phase-specific message', () {
    test('pregnant → "avoid completely" message (German)', () {
      final w = SafetyRules.alcohol('Rotwein', pregnant, locale: 'de');
      expect(w, isNotNull);
      expect(w, contains('ganz meiden'));
    });

    test('lactating → "avoid while producing milk" message (English). Was '
        'the wait-time formula; DGE position paper now scopes to full '
        'abstinence and BfR mirrors that.', () {
      final w = SafetyRules.alcohol('a glass of wine', lactating, locale: 'en');
      expect(w, isNotNull);
      expect(w!.toLowerCase(), contains('avoid'));
      expect(w.toLowerCase(), contains('producing milk'));
    });

    test('German compound "Glühwein" is recognised', () {
      expect(SafetyRules.alcohol('Glühwein', pregnant), isNotNull);
    });

    test('English "beer" is recognised', () {
      expect(SafetyRules.alcohol('cold beer', lactating), isNotNull);
    });
  });

  group('alcohol rule — no warning', () {
    test('phase not relevant → null', () {
      expect(SafetyRules.alcohol('Rotwein', neither), isNull);
    });

    test('compound trap: "Schweinebraten" must NOT match "wein"', () {
      expect(SafetyRules.alcohol('Schweinebraten', pregnant), isNull);
    });

    test('short-word traps: "Rumpsteak" / "Ingwer Shot" do not match rum/gin',
        () {
      expect(SafetyRules.alcohol('Rumpsteak', pregnant), isNull);
      expect(SafetyRules.alcohol('Ingwer Shot', pregnant), isNull);
    });

    test('alcohol-free variant is never flagged', () {
      expect(SafetyRules.alcohol('alkoholfreies Bier', pregnant), isNull);
    });
  });

  group('raw animal products rule — pregnancy only', () {
    test('pregnant + sushi → warning', () {
      final w = SafetyRules.rawAnimalProducts('Sushi Platte', pregnant, locale: 'de');
      expect(w, isNotNull);
      expect(w, contains('Listerien'));
    });

    test('pregnant + Räucherlachs / Rohmilchkäse / Tiramisu → warning', () {
      expect(SafetyRules.rawAnimalProducts('Räucherlachs', pregnant), isNotNull);
      expect(SafetyRules.rawAnimalProducts('Rohmilchkäse', pregnant), isNotNull);
      expect(SafetyRules.rawAnimalProducts('Tiramisu', pregnant), isNotNull);
    });

    test('LACTATING + sushi → null (this risk is pregnancy-specific)', () {
      expect(SafetyRules.rawAnimalProducts('Sushi', lactating), isNull);
    });

    test('neither phase → null', () {
      expect(SafetyRules.rawAnimalProducts('Sushi', neither), isNull);
    });
  });

  group('raw animal products rule — no false positives', () {
    test('"Omelett" must not match "mett"', () {
      expect(SafetyRules.rawAnimalProducts('Omelett', pregnant), isNull);
    });

    test('"Brioche" must not match "brie"', () {
      expect(SafetyRules.rawAnimalProducts('Brioche', pregnant), isNull);
    });

    test('"Tatarensauce" must not match "tatar"', () {
      expect(SafetyRules.rawAnimalProducts('Tatarensauce', pregnant), isNull);
    });

    test('cooked salmon is fine (bare "Lachs" is not a trigger)', () {
      expect(SafetyRules.rawAnimalProducts('gekochter Lachs', pregnant), isNull);
    });

    test('"Parmesan" alone is NOT a keyword (industrial grated parmesan in '
        'Germany is pasteurised) - only "Parmigiano Reggiano" triggers', () {
      expect(SafetyRules.rawAnimalProducts('Parmesan', pregnant), isNull);
      expect(SafetyRules.rawAnimalProducts('Parmigiano Reggiano', pregnant),
          isNotNull);
    });

    test('"Mozzarella" alone is NOT a keyword (supermarket mozzarella is '
        'pasteurised); the raw-milk Italian fresh cheeses live with the '
        'LLM via the prompt rule, not the deterministic list', () {
      expect(SafetyRules.rawAnimalProducts('Mozzarella', pregnant), isNull);
    });

    test('Emmentaler alone is NOT a keyword (modern supermarket Emmentaler '
        'is pasteurised - only the listed traditional raw-milk hard cheeses '
        'fire deterministically)', () {
      expect(SafetyRules.rawAnimalProducts('Emmentaler', pregnant), isNull);
    });
  });

  group('raw animal products rule — added beta-feedback keywords', () {
    test('Appenzeller in pregnancy → warning (the Brötchen mit Appenzeller '
        'incident that triggered this expansion: a beta tester logged the '
        'cheese and got a false "ist pasteurisiert" reply from the LLM; '
        'Appenzeller is classically raw-milk)', () {
      expect(SafetyRules.rawAnimalProducts(
          'Brötchen mit Appenzeller Käse', pregnant), isNotNull);
    });

    test('Other raw-milk hard cheeses fire: Gruyère, Comté, Pecorino, '
        'Manchego, Beaufort, Bergkäse', () {
      for (final cheese in [
        'Gruyère', 'Gruyere', 'Comté', 'Pecorino',
        'Manchego', 'Beaufort', 'Bergkäse',
      ]) {
        expect(SafetyRules.rawAnimalProducts(cheese, pregnant), isNotNull,
            reason: '$cheese should fire the raw-animal rule in pregnancy');
      }
    });

    test('Wash-rind / smear-rind cheeses (highest structural listeria '
        'risk, independent of milk treatment): Munster, Limburger, '
        'Reblochon, Vacherin, Romadur, Handkäse', () {
      for (final cheese in [
        'Munster', 'Limburger', 'Reblochon',
        'Vacherin Mont d\'Or', 'Romadur', 'Handkäse',
      ]) {
        expect(SafetyRules.rawAnimalProducts(cheese, pregnant), isNotNull,
            reason: '$cheese should fire the raw-animal rule in pregnancy');
      }
    });

    test('Air-cured ham family (always raw, never heated): Parmaschinken, '
        'Serrano, Bresaola, Bündnerfleisch, Coppa', () {
      for (final meat in [
        'Parmaschinken', 'Serrano-Schinken', 'Bresaola',
        'Bündnerfleisch', 'Coppa', 'Rohschinken', 'Lachsschinken',
      ]) {
        expect(SafetyRules.rawAnimalProducts(meat, pregnant), isNotNull,
            reason: '$meat should fire the raw-animal rule in pregnancy');
      }
    });

    test('Wild / game (toxoplasma): Reh, Hirsch, Wildschwein, Wildbraten', () {
      for (final game in ['Reh', 'Rehbraten', 'Hirsch', 'Wildschwein',
        'Wildbraten']) {
        expect(SafetyRules.rawAnimalProducts(game, pregnant), isNotNull,
            reason: '$game should fire the raw-animal rule in pregnancy');
      }
    });

    test('Cold-cured / pickled fish: Matjes, Bismarckhering, Rollmops, '
        'Bückling', () {
      for (final fish in ['Matjes', 'Bismarckhering', 'Rollmops', 'Bückling']) {
        expect(SafetyRules.rawAnimalProducts(fish, pregnant), isNotNull,
            reason: '$fish should fire the raw-animal rule in pregnancy');
      }
    });

    test('Raw molluscs (norovirus + listeria): Austern / oysters', () {
      expect(SafetyRules.rawAnimalProducts('Austern', pregnant), isNotNull);
      expect(SafetyRules.rawAnimalProducts('raw oysters', pregnant), isNotNull);
    });

    test('Raw-egg sauces: Hollandaise, Béarnaise', () {
      expect(SafetyRules.rawAnimalProducts(
          'Sauce Hollandaise', pregnant), isNotNull);
      expect(SafetyRules.rawAnimalProducts('Béarnaise', pregnant), isNotNull);
    });

    test('Sprouts (salmonella): Sprossen, Bohnensprossen, Alfalfa', () {
      for (final s in ['Sprossen', 'Bohnensprossen', 'Alfalfa', 'Mungo']) {
        expect(SafetyRules.rawAnimalProducts(s, pregnant), isNotNull,
            reason: '$s should fire the raw-animal rule in pregnancy');
      }
    });

    test('Vorzugsmilch / Hofmilch (legally-sold German unpasteurised milk)', () {
      expect(SafetyRules.rawAnimalProducts('Vorzugsmilch', pregnant), isNotNull);
      expect(SafetyRules.rawAnimalProducts('Hofmilch frisch vom Bauern',
          pregnant), isNotNull);
    });
  });

  group('mercury fish rule — phase-specific message', () {
    test('pregnant → "avoid" message', () {
      final w = SafetyRules.mercuryFish('Thunfisch', pregnant, locale: 'de');
      expect(w, isNotNull);
      expect(w, contains('meiden'));
    });

    test('lactating → "limit" message', () {
      final w = SafetyRules.mercuryFish('tuna steak', lactating, locale: 'en');
      expect(w, isNotNull);
      expect(w, contains('limit'));
    });

    test('German compound "Thunfischsalat" is caught', () {
      expect(SafetyRules.mercuryFish('Thunfischsalat', pregnant), isNotNull);
    });

    test('shark / swordfish / pike are caught', () {
      expect(SafetyRules.mercuryFish('Haifischsteak', pregnant), isNotNull);
      expect(SafetyRules.mercuryFish('Schwertfisch', pregnant), isNotNull);
      expect(SafetyRules.mercuryFish('Hechtsuppe', pregnant), isNotNull);
    });
  });

  group('mercury fish rule — no false positives', () {
    test('regular "Makrele" is NOT flagged (only Königsmakrele is)', () {
      expect(SafetyRules.mercuryFish('geräucherte Makrele', pregnant), isNull);
      expect(SafetyRules.mercuryFish('Königsmakrele', pregnant), isNotNull);
    });

    test('low-mercury fish (Lachs, Forelle, Kabeljau) are fine', () {
      expect(SafetyRules.mercuryFish('Lachs', pregnant), isNull);
      expect(SafetyRules.mercuryFish('Forelle', pregnant), isNull);
      expect(SafetyRules.mercuryFish('Kabeljau', pregnant), isNull);
    });

    test('phase not relevant → null', () {
      expect(SafetyRules.mercuryFish('Thunfisch', neither), isNull);
    });
  });

  group('liver / vitamin A rule — first trimester only', () {
    test('pregnant T1 + Leber → warning', () {
      final w = SafetyRules.liverVitaminA('Leber', pregnantT1, locale: 'de');
      expect(w, isNotNull);
      expect(w, contains('1. Trimester'));
    });

    test('compounds Kalbsleber / Leberwurst / foie gras are caught', () {
      expect(SafetyRules.liverVitaminA('Kalbsleber', pregnantT1), isNotNull);
      expect(SafetyRules.liverVitaminA('Leberwurst', pregnantT1), isNotNull);
      expect(SafetyRules.liverVitaminA('foie gras', pregnantT1), isNotNull);
    });

    test('unknown trimester defaults to 1 (warns)', () {
      expect(SafetyRules.liverVitaminA('Leber', pregnantNoTri), isNotNull);
    });

    test('T2/T3 now DO warn (softer wording). BfR explicitly recommends '
        'avoiding liver of all species across the whole pregnancy due to '
        'inconsistently high retinol content; the prior "T1 only" carve-out '
        'was not strict enough vs. the German guideline state.', () {
      final t2 = SafetyRules.liverVitaminA('Leber', pregnant, locale: 'de'); // T2
      expect(t2, isNotNull);
      expect(t2!.toLowerCase(), contains('zurückhaltend'));
      final t3 = SafetyRules.liverVitaminA('Leber',
          const SafetyPhase(isPregnant: true, trimester: 3),
          locale: 'de');
      expect(t3, isNotNull);
      expect(t3!.toLowerCase(), contains('zurückhaltend'));
    });
  });

  group('liver / vitamin A rule — no false positives', () {
    test('"Leberkäse" has no liver and must NOT trigger', () {
      expect(SafetyRules.liverVitaminA('Leberkäse', pregnantT1), isNull);
      expect(SafetyRules.liverVitaminA('Leberkässemmel', pregnantT1), isNull);
    });

    test('lactating only → null (this is a pregnancy concern)', () {
      expect(SafetyRules.liverVitaminA('Leber', lactating), isNull);
    });
  });

  group('lactation herbs rule — soft, large-amount only', () {
    test('everyday cup of sage tea is NOT flagged (no over-warning)', () {
      // The whole point: weak evidence, so a normal tea must stay silent.
      expect(SafetyRules.lactationHerbs('Salbeitee', lactating), isNull);
      expect(SafetyRules.lactationHerbs('eine Tasse Pfefferminztee', lactating),
          isNull);
    });

    test('large/medicinal amount → gentle note (not a warning)', () {
      final w =
          SafetyRules.lactationHerbs('Abstilltee mit Salbei', lactating, locale: 'de');
      expect(w, isNotNull);
      expect(w, startsWith('Hinweis'));
      expect(w, contains('Alltagsmengen sind unkritisch'));
    });

    test('sage concentrate / peppermint oil are flagged', () {
      expect(SafetyRules.lactationHerbs('Salbei-Konzentrat', lactating),
          isNotNull);
      expect(SafetyRules.lactationHerbs('Pfefferminzöl Kapseln', lactating),
          isNotNull);
    });

    test('olive-oil trap: "Salbeibutter mit Olivenöl" must not trigger', () {
      expect(
        SafetyRules.lactationHerbs('Salbeibutter mit Olivenöl', lactating),
        isNull,
      );
    });

    test('not lactating → null even for a concentrate', () {
      expect(SafetyRules.lactationHerbs('Salbei-Konzentrat', pregnantT1), isNull);
    });
  });

  group('algae / seaweed rule — pregnancy only (DGE)', () {
    test('pregnant + Nori-Sushi → warning (iodine swings + arsenic per DGE)',
        () {
      final w = SafetyRules.algae('Sushi mit Nori', pregnant, locale: 'de');
      expect(w, isNotNull);
      expect(w, contains('Jod'));
    });

    test('all the named seaweeds fire: Algen-Smoothie, Algensalat, Wakame, '
        'Kombu, Kelp, Dulse, Spirulina, Chlorella', () {
      for (final p in [
        'Algen-Smoothie',
        'Algensalat',
        'Algenprodukte vom Markt',
        'Wakame Suppe',
        'Kombu Brühe',
        'kelp tablets',
        'dulse flakes',
        'Spirulina Pulver',
        'Chlorella Tabletten',
      ]) {
        expect(SafetyRules.algae(p, pregnant), isNotNull,
            reason: '$p should fire the algae rule in pregnancy');
      }
    });

    test('LACTATING → null (DGE scopes the recommendation to pregnancy)', () {
      expect(SafetyRules.algae('Algensalat', lactating), isNull);
      expect(SafetyRules.algae('Nori', lactating), isNull);
    });

    test('neither phase → null', () {
      expect(SafetyRules.algae('Spirulina', neither), isNull);
    });
  });

  group('wild boar offal rule — BfR (PFAS / dioxin / PCB)', () {
    test('pregnant + Wildschweinleber → second warning beyond the regular '
        'game/raw-animal hit (PFAS, Dioxine, PCB per BfR)', () {
      final w = SafetyRules.boarOffal('Wildschweinleber', pregnant, locale: 'de');
      expect(w, isNotNull);
      expect(w!.toLowerCase(), contains('pfas'));
    });

    test('lactating ALSO triggers (BfR scopes to childbearing-age + pregnant '
        '+ lactating)', () {
      expect(SafetyRules.boarOffal('Wildschwein-Innereien', lactating),
          isNotNull);
    });

    test('neither phase → null', () {
      expect(SafetyRules.boarOffal('Wildschweinleber', neither), isNull);
    });

    test('plain Wildschweinbraten (no offal) → NOT this rule (the regular '
        'game keyword still fires the raw-animal rule though)', () {
      expect(SafetyRules.boarOffal('Wildschweinbraten', pregnant), isNull);
    });
  });

  group('quinine rule — BfR pregnancy', () {
    test('pregnant + Tonic Water → warning, mentions BfR', () {
      final w = SafetyRules.quinine('Tonic Water', pregnant, locale: 'de');
      expect(w, isNotNull);
      expect(w, contains('BfR'));
    });

    test('Bitter Lemon + Gin Tonic + bare "Chinin" all fire', () {
      for (final p in ['Bitter Lemon', 'Gin Tonic', 'Chinin Sirup']) {
        expect(SafetyRules.quinine(p, pregnant), isNotNull,
            reason: '$p should fire the quinine rule in pregnancy');
      }
    });

    test('LACTATING → null (BfR scopes to pregnancy)', () {
      expect(SafetyRules.quinine('Tonic Water', lactating), isNull);
    });

    test('neither phase → null', () {
      expect(SafetyRules.quinine('Tonic Water', neither), isNull);
    });
  });

  group('algae rule — no false positives', () {
    test('"Algerien" / "algerische Küche" must NOT trip "algen" (substring '
        'guard: we list "algen" plural, not bare "alge", so the geo word '
        'is safe)', () {
      expect(SafetyRules.algae('Algerien-Reise', pregnant), isNull);
      expect(SafetyRules.algae('algerische Küche', pregnant), isNull);
    });
  });

  group('allWarnings — runs every rule', () {
    test('a product hitting two categories returns both, in rule order', () {
      final w = SafetyRules.allWarnings('Espresso mit Thunfisch', pregnant);
      expect(w.length, 2);
      expect(w.first.toLowerCase(), contains('caffeine')); // default locale en
      expect(w[1].toLowerCase(), contains('mercury'));
    });

    test('nothing relevant → empty list', () {
      expect(SafetyRules.allWarnings('Apfel', pregnant), isEmpty);
    });

    test('phase gating still applies inside allWarnings', () {
      // Sushi is pregnancy-only; for a lactating user it must not appear.
      expect(SafetyRules.allWarnings('Sushi', lactating), isEmpty);
    });
  });

  group('mergeWarnings — deterministic floor + model extras', () {
    test('deterministic first, then model extras', () {
      expect(SafetyRules.mergeWarnings(['A', 'B'], ['C']), ['A', 'B', 'C']);
    });

    test('exact duplicates from the model are dropped', () {
      expect(SafetyRules.mergeWarnings(['A'], ['A', 'B']), ['A', 'B']);
    });

    test('deterministic warnings survive an empty model result', () {
      expect(SafetyRules.mergeWarnings(['A'], const []), ['A']);
    });

    test('empty deterministic + model extras keeps the extras', () {
      expect(SafetyRules.mergeWarnings(const [], ['X']), ['X']);
    });
  });
}
