// Standalone unit test for injectSafetyBlock (Task #88.2).
// Run with:  node --test api/test-injection.test.mjs
// (Node 20+ ships node:test built-in, no extra deps.)
//
// Coverage:
//   - missing system field → safety becomes the only entry
//   - string system field → array [safety, client_string]
//   - array system field with cache_control → safety prepended, marker preserved
//   - unknown shape → wrapped, safety floor still applied
//   - locale 'de' / 'en' picks the right block
//
// What we deliberately do NOT test here: the full fetch handler (needs the
// Cloudflare Workers runtime + env bindings). That's verified manually via
// `wrangler dev` plus the existing curl smoke test in api/README.md.

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { injectSafetyBlock, SAFETY_BLOCK_DE, SAFETY_BLOCK_EN } from './worker.js';

describe('injectSafetyBlock - shape handling', () => {
  it('missing system field → safety block becomes the only entry', () => {
    const body = { model: 'claude-haiku-4-5', max_tokens: 100, messages: [] };
    const out = injectSafetyBlock(body, 'de');
    assert.deepEqual(out.system, [{ type: 'text', text: SAFETY_BLOCK_DE }]);
  });

  it('string system field → safety wraps + client string preserved verbatim', () => {
    const body = { system: 'Du bist Coach.', messages: [] };
    const out = injectSafetyBlock(body, 'de');
    assert.equal(out.system.length, 2);
    assert.equal(out.system[0].text, SAFETY_BLOCK_DE);
    assert.equal(out.system[1].text, 'Du bist Coach.');
    // No cache_control on the converted client text (it was a string, never cached).
    assert.equal(out.system[1].cache_control, undefined);
  });

  it('array with cache_control → safety prepended, client marker preserved', () => {
    const body = {
      system: [
        { type: 'text', text: 'Big static coach prompt', cache_control: { type: 'ephemeral' } },
      ],
      messages: [],
    };
    const out = injectSafetyBlock(body, 'en');
    assert.equal(out.system.length, 2);
    assert.equal(out.system[0].text, SAFETY_BLOCK_EN);
    assert.equal(out.system[1].text, 'Big static coach prompt');
    // The client's ephemeral cache marker survives at its new index.
    assert.deepEqual(out.system[1].cache_control, { type: 'ephemeral' });
  });

  it('multi-item array → safety prepended, all client items preserved in order', () => {
    const body = {
      system: [
        { type: 'text', text: 'A' },
        { type: 'text', text: 'B', cache_control: { type: 'ephemeral' } },
      ],
    };
    const out = injectSafetyBlock(body, 'en');
    assert.equal(out.system.length, 3);
    assert.equal(out.system[0].text, SAFETY_BLOCK_EN);
    assert.equal(out.system[1].text, 'A');
    assert.equal(out.system[2].text, 'B');
    assert.deepEqual(out.system[2].cache_control, { type: 'ephemeral' });
  });

  it('unknown shape (object) → wrapped, safety floor still in front', () => {
    const body = { system: { weird: true } };
    const out = injectSafetyBlock(body, 'en');
    assert.equal(out.system.length, 2);
    assert.equal(out.system[0].text, SAFETY_BLOCK_EN);
    assert.deepEqual(out.system[1], { weird: true });
  });
});

describe('injectSafetyBlock - locale selection', () => {
  it('de locale → German block', () => {
    const out = injectSafetyBlock({ system: '' }, 'de');
    assert.equal(out.system[0].text, SAFETY_BLOCK_DE);
    assert.match(out.system[0].text, /112/);
  });

  it('en locale → English block', () => {
    const out = injectSafetyBlock({ system: '' }, 'en');
    assert.equal(out.system[0].text, SAFETY_BLOCK_EN);
    assert.match(out.system[0].text, /emergency services/i);
  });
});

describe('injectSafetyBlock - safety content invariants', () => {
  for (const [name, text] of [['de', SAFETY_BLOCK_DE], ['en', SAFETY_BLOCK_EN]]) {
    it(`${name} block names the escalation path`, () => {
      assert.match(text, /medizinisch|medical/i);
      assert.match(text, /Hebamme|Ärztin|midwife|doctor/i);
    });
    it(`${name} block flags emergencies as non-coach`, () => {
      assert.match(text, /Notfall|emergency/i);
    });
    it(`${name} block forbids recommending blocklist items`, () => {
      assert.match(text, /Alkohol|alcohol/i);
      assert.match(text, /(NIEMALS|NEVER)/);
    });
  }
});
