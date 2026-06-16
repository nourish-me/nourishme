// Standalone unit test for the Worker's input pre-classifier (Task #88.3).
// Run with:  node --test api/test-classify-input.test.mjs
//
// Covers:
//   - emergency keywords (de/en) match and synthesise the right response
//   - escalation keywords (de/en) match and synthesise the right response
//   - emergency wins when both stages would match
//   - normal text returns normal classification with no response
//   - body shape extraction: string content, array content (text-only),
//     array content (mixed text + image), last-user-message picking
//   - empty / missing messages return normal

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  classifyInput,
  EMERGENCY_KEYWORDS,
  ESCALATION_KEYWORDS,
  EMERGENCY_RESPONSES,
  ESCALATION_RESPONSES,
} from './worker.js';

// Helpers to build minimal Anthropic-shaped bodies.
const stringMsg = (text, role = 'user') => ({ role, content: text });
const textArrayMsg = (text, role = 'user') => ({
  role,
  content: [{ type: 'text', text }],
});
const photoTextArrayMsg = (text, role = 'user') => ({
  role,
  content: [
    { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: 'xxx' } },
    { type: 'text', text },
  ],
});

describe('classifyInput - emergency stage', () => {
  it('DE: starke Blutung matches, returns emergency + canned response', () => {
    const body = { messages: [stringMsg('Ich habe seit heute morgen eine starke Blutung')] };
    const r = classifyInput(body, 'de');
    assert.equal(r.classification, 'emergency');
    assert.equal(r.ruleId, 'starke blutung');
    assert.equal(r.response, EMERGENCY_RESPONSES.de);
  });

  it('EN: heavy bleeding matches', () => {
    const body = { messages: [stringMsg("I've had heavy bleeding since this morning")] };
    const r = classifyInput(body, 'en');
    assert.equal(r.classification, 'emergency');
    assert.equal(r.ruleId, 'heavy bleeding');
    assert.equal(r.response, EMERGENCY_RESPONSES.en);
  });

  it('case-insensitive', () => {
    const body = { messages: [stringMsg('PRETERM LABOUR what to do')] };
    const r = classifyInput(body, 'en');
    assert.equal(r.classification, 'emergency');
  });

  it('matches across array text content (parse-meal style)', () => {
    const body = { messages: [textArrayMsg('habe vorzeitige Wehen')] };
    const r = classifyInput(body, 'de');
    assert.equal(r.classification, 'emergency');
  });

  it('matches across mixed image+text content (photo-parse style)', () => {
    const body = { messages: [photoTextArrayMsg('baby is not moving today')] };
    const r = classifyInput(body, 'en');
    assert.equal(r.classification, 'emergency');
  });
});

describe('classifyInput - escalation stage', () => {
  it('DE: Medikament matches', () => {
    const body = { messages: [stringMsg('ich nehme ein Medikament, was darf ich essen')] };
    const r = classifyInput(body, 'de');
    assert.equal(r.classification, 'escalation');
    assert.equal(r.ruleId, 'medikament');
    assert.equal(r.response, ESCALATION_RESPONSES.de);
  });

  it('EN: gestational diabetes matches', () => {
    const body = { messages: [stringMsg('I have gestational diabetes, what diet should I follow?')] };
    const r = classifyInput(body, 'en');
    assert.equal(r.classification, 'escalation');
    assert.equal(r.response, ESCALATION_RESPONSES.en);
  });

  it('DE: Mastitis matches', () => {
    const body = { messages: [stringMsg('habe seit gestern Mastitis')] };
    const r = classifyInput(body, 'de');
    assert.equal(r.classification, 'escalation');
  });
});

describe('classifyInput - precedence and last-message picking', () => {
  it('emergency wins when both stages would match in the same message', () => {
    // "starke blutung" + "medikament" in one message - emergency must surface.
    const body = {
      messages: [stringMsg('starke Blutung und ich nehme ein Medikament')],
    };
    const r = classifyInput(body, 'de');
    assert.equal(r.classification, 'emergency');
  });

  it('only the LATEST user message is classified, not the history', () => {
    // Earlier turn mentions a hot keyword; latest user turn is benign.
    // Without "last-only" semantics the bot would re-fire forever on
    // a chat history that once contained the keyword.
    const body = {
      messages: [
        stringMsg('I had heavy bleeding last week'),
        { role: 'assistant', content: 'Please call your midwife.' },
        stringMsg('today I had apples and yogurt for breakfast'),
      ],
    };
    const r = classifyInput(body, 'en');
    assert.equal(r.classification, 'normal');
  });

  it('skips non-user roles when picking the latest user message', () => {
    const body = {
      messages: [
        stringMsg('benign breakfast'),
        { role: 'assistant', content: 'Sounds great!' },
        stringMsg('habe Mastitis'),
      ],
    };
    const r = classifyInput(body, 'de');
    assert.equal(r.classification, 'escalation');
  });
});

describe('classifyInput - normal / defensive shapes', () => {
  it('normal text returns normal, no ruleId, no response', () => {
    const body = { messages: [stringMsg('apple and yogurt for breakfast')] };
    const r = classifyInput(body, 'en');
    assert.equal(r.classification, 'normal');
    assert.equal(r.ruleId, undefined);
    assert.equal(r.response, undefined);
  });

  it('empty messages array returns normal', () => {
    const r = classifyInput({ messages: [] }, 'en');
    assert.equal(r.classification, 'normal');
  });

  it('missing messages field returns normal (does not throw)', () => {
    const r = classifyInput({}, 'en');
    assert.equal(r.classification, 'normal');
  });

  it('non-string content shape returns normal (does not throw)', () => {
    const r = classifyInput({ messages: [{ role: 'user', content: null }] }, 'en');
    assert.equal(r.classification, 'normal');
  });

  it('unknown locale falls back to en keyword list', () => {
    const body = { messages: [stringMsg('heavy bleeding now')] };
    const r = classifyInput(body, 'fr');
    assert.equal(r.classification, 'emergency');
  });
});

describe('classifyInput - keyword list integrity', () => {
  it('emergency DE + EN lists are non-empty and frozen', () => {
    assert.ok(EMERGENCY_KEYWORDS.de.length > 0);
    assert.ok(EMERGENCY_KEYWORDS.en.length > 0);
    assert.throws(() => {
      EMERGENCY_KEYWORDS.de = [];
    });
  });

  it('escalation DE + EN lists are non-empty and frozen', () => {
    assert.ok(ESCALATION_KEYWORDS.de.length > 0);
    assert.ok(ESCALATION_KEYWORDS.en.length > 0);
    assert.throws(() => {
      ESCALATION_KEYWORDS.en = [];
    });
  });

  it('responses exist for both locales and stages', () => {
    assert.ok(EMERGENCY_RESPONSES.de.length > 0);
    assert.ok(EMERGENCY_RESPONSES.en.length > 0);
    assert.ok(ESCALATION_RESPONSES.de.length > 0);
    assert.ok(ESCALATION_RESPONSES.en.length > 0);
    // Emergency response must mention emergency-care channel.
    assert.match(EMERGENCY_RESPONSES.de, /112|Notfall/);
    assert.match(EMERGENCY_RESPONSES.en, /emergency/i);
    // Escalation response must direct to a real person.
    assert.match(ESCALATION_RESPONSES.de, /Hebamme|Ärztin/);
    assert.match(ESCALATION_RESPONSES.en, /midwife|doctor/i);
  });
});
