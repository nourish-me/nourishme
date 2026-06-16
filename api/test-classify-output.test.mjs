// Standalone unit test for the Worker's output post-check (Task #88.4).
// Run with:  node --test api/test-classify-output.test.mjs
//
// Covers:
//   - blocklist + recommendation phrase in same sentence -> blocked
//   - blocklist mentioned in a warning sentence -> NOT blocked
//   - rec phrase about a different (non-blocklist) item -> NOT blocked
//   - mixed-language model output still trips check
//   - locale fallback (unknown locale -> EN responses)
//   - keyword list integrity (non-empty, frozen)
//   - returns 'normal' for empty / null / non-string inputs

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  classifyOutput,
  BLOCKLIST_KEYWORDS,
  RECOMMENDATION_PHRASES_DE,
  RECOMMENDATION_PHRASES_EN,
  BLOCKED_RESPONSES,
} from './worker.js';

describe('classifyOutput - blocking cases', () => {
  it('DE: "Tatar ist okay" -> blocked', () => {
    const r = classifyOutput('Tatar ist okay wenn frisch.', 'de');
    assert.equal(r.classification, 'blocked');
    assert.match(r.ruleId, /tatar/);
    assert.match(r.ruleId, /ist okay/);
    assert.equal(r.response, BLOCKED_RESPONSES.de);
  });

  it('DE: "ein Glas Wein ist vertretbar" -> blocked', () => {
    const r = classifyOutput(
      'Ein Glas Wein ist vertretbar in dieser Phase.',
      'de',
    );
    assert.equal(r.classification, 'blocked');
    assert.match(r.ruleId, /wein/);
    assert.match(r.ruleId, /vertretbar/);
  });

  it('EN: "tuna is safe in pregnancy" -> blocked', () => {
    const r = classifyOutput(
      'Tuna is safe in pregnancy as long as portions stay small.',
      'en',
    );
    assert.equal(r.classification, 'blocked');
    assert.match(r.ruleId, /tuna/);
    assert.match(r.ruleId, /is safe/);
    assert.equal(r.response, BLOCKED_RESPONSES.en);
  });

  it('EN: "feel free to have brie" -> blocked', () => {
    const r = classifyOutput(
      'Feel free to have brie if it is pasteurised.',
      'en',
    );
    assert.equal(r.classification, 'blocked');
    assert.match(r.ruleId, /brie/);
    assert.match(r.ruleId, /feel free to/);
  });

  it('mixed-language: DE prompt but EN rec phrase still trips', () => {
    // Model occasionally slips into English even when locale is DE.
    const r = classifyOutput('Camembert is fine in pregnancy.', 'de');
    assert.equal(r.classification, 'blocked');
  });
});

describe('classifyOutput - non-blocking cases (warning sentences must pass)', () => {
  it('"vermeide Tatar in der Schwangerschaft" passes', () => {
    const r = classifyOutput(
      'Vermeide Tatar in der Schwangerschaft (Listerien-Risiko).',
      'de',
    );
    assert.equal(r.classification, 'normal');
  });

  it('"avoid raw tuna" passes', () => {
    const r = classifyOutput('Avoid raw tuna during pregnancy.', 'en');
    assert.equal(r.classification, 'normal');
  });

  it('blocklist hit in one sentence + rec phrase in a different sentence passes',
      () => {
    // The model warns about Tatar in sentence 1 and recommends grilled
    // salmon ("ist okay") in sentence 2. Different sentences -> no block.
    const r = classifyOutput(
      'Vermeide Tatar in der Schwangerschaft. Gegrillter Lachs ist okay.',
      'de',
    );
    assert.equal(r.classification, 'normal');
  });

  it('rec phrase about a non-blocklist item passes', () => {
    const r = classifyOutput('Apfel ist okay in jeder Phase.', 'de');
    assert.equal(r.classification, 'normal');
  });

  it('empty / null / non-string input returns normal', () => {
    assert.equal(classifyOutput('', 'de').classification, 'normal');
    assert.equal(classifyOutput(null, 'de').classification, 'normal');
    assert.equal(classifyOutput(undefined, 'de').classification, 'normal');
    assert.equal(classifyOutput(42, 'de').classification, 'normal');
  });

  it('unknown locale falls back to EN responses on a hit', () => {
    const r = classifyOutput('Tuna is safe in pregnancy.', 'fr');
    assert.equal(r.classification, 'blocked');
    assert.equal(r.response, BLOCKED_RESPONSES.en);
  });
});

describe('classifyOutput - keyword + phrase list integrity', () => {
  it('BLOCKLIST_KEYWORDS is non-empty and frozen', () => {
    assert.ok(BLOCKLIST_KEYWORDS.length > 0);
    assert.throws(() => {
      BLOCKLIST_KEYWORDS.push('foo');
    });
  });

  it('rec phrase lists are non-empty and frozen', () => {
    assert.ok(RECOMMENDATION_PHRASES_DE.length > 0);
    assert.ok(RECOMMENDATION_PHRASES_EN.length > 0);
    assert.throws(() => {
      RECOMMENDATION_PHRASES_EN.push('foo');
    });
  });

  it('BLOCKED_RESPONSES exist for both locales and route to a human', () => {
    assert.ok(BLOCKED_RESPONSES.de.length > 0);
    assert.ok(BLOCKED_RESPONSES.en.length > 0);
    assert.match(BLOCKED_RESPONSES.de, /Hebamme|Ärztin/);
    assert.match(BLOCKED_RESPONSES.en, /midwife|doctor/i);
  });
});
