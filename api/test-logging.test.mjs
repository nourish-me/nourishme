// Standalone unit test for the audit-log helpers (Task #88.7).
// Run with:  node --test api/test-logging.test.mjs
//
// Covers what's safe to verify without the Cloudflare runtime:
//   - pseudonymizeUser hashes deterministically with the same secret
//   - different installs produce different hashes (no collisions on realistic inputs)
//   - same install + different secrets produce different hashes (salt does its job)
//   - empty install-id or secret yields 'anon' (defensive default)
//   - hash is hex, fixed 16-char length
//   - AUDIT_EVENT enum has the four expected names

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { pseudonymizeUser, AUDIT_EVENT } from './worker.js';

const SECRET = 'test-secret-do-not-use-in-prod';

describe('pseudonymizeUser', () => {
  it('returns 16-char lowercase hex for a normal input', async () => {
    const h = await pseudonymizeUser('install-abc-123', SECRET);
    assert.equal(h.length, 16);
    assert.match(h, /^[0-9a-f]{16}$/);
  });

  it('is deterministic for the same (install, secret) pair', async () => {
    const a = await pseudonymizeUser('install-abc', SECRET);
    const b = await pseudonymizeUser('install-abc', SECRET);
    assert.equal(a, b);
  });

  it('produces different hashes for different install-ids', async () => {
    const a = await pseudonymizeUser('install-A', SECRET);
    const b = await pseudonymizeUser('install-B', SECRET);
    assert.notEqual(a, b);
  });

  it('produces different hashes when the secret (salt) changes', async () => {
    const a = await pseudonymizeUser('install-A', 'secret-one');
    const b = await pseudonymizeUser('install-A', 'secret-two');
    assert.notEqual(a, b);
  });

  it("returns 'anon' for missing install-id", async () => {
    assert.equal(await pseudonymizeUser('', SECRET), 'anon');
    assert.equal(await pseudonymizeUser(null, SECRET), 'anon');
    assert.equal(await pseudonymizeUser(undefined, SECRET), 'anon');
  });

  it("returns 'anon' for missing secret (Worker mis-config defence)", async () => {
    assert.equal(await pseudonymizeUser('install-A', ''), 'anon');
    assert.equal(await pseudonymizeUser('install-A', null), 'anon');
  });
});

describe('AUDIT_EVENT enum', () => {
  it('exposes the four audit-event constants', () => {
    assert.equal(AUDIT_EVENT.EMERGENCY, 'audit_emergency');
    assert.equal(AUDIT_EVENT.ESCALATION, 'audit_escalation');
    assert.equal(AUDIT_EVENT.BLOCKED_OUTPUT, 'audit_blocked');
    assert.equal(AUDIT_EVENT.API_CALL, 'api_call');
  });

  it('is frozen (no accidental mutation by emit sites)', () => {
    assert.throws(() => {
      AUDIT_EVENT.EMERGENCY = 'something_else';
    });
  });
});
