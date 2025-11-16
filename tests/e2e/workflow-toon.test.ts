import { describe, it, expect } from 'vitest';
import {
  encodeTOON,
  decodeTOON,
  detectFormat,
  autoDecode,
  convertTOONToJSON,
  convertJSONToTOON
} from '../../src/utils/toon';

const workflowSession = {
  session: 'workflow-toon-rollout',
  phases: [
    { id: 'brainstorm', owner: 'gemini', depth: 3 },
    { id: 'plan', owner: 'codex', depth: 2 },
    { id: 'execute', owner: 'codex', depth: 4 },
    { id: 'test', owner: 'tester', depth: 3 }
  ],
  tasks: [
    { id: 'IMPL-001', title: 'TOON schema draft', status: 'complete', effort: 5 },
    { id: 'IMPL-002', title: 'Memory alignment', status: 'complete', effort: 8 },
    { id: 'IMPL-003', title: 'CLI tooling', status: 'complete', effort: 3 },
    { id: 'IMPL-004', title: 'Docs + tests rollout', status: 'ready', effort: 13 }
  ],
  checkpoints: {
    last_verified: '2025-01-04T08:30:12Z',
    coverage: { unit: 0.92, integration: 0.81, e2e: 0.74 },
    blockers: []
  },
  timeline: [
    { ts: '2025-01-03T02:00:00Z', event: 'Initial migration plan drafted' },
    { ts: '2025-01-03T04:10:00Z', event: 'TOON utilities merged' },
    { ts: '2025-01-03T10:45:00Z', event: 'Docs synced with TOON-first messaging' }
  ]
};

describe('E2E • Workflow TOON adoption', () => {
  it('keeps the full workflow session stable across encode/decode boundaries', () => {
    const toonPayload = encodeTOON(workflowSession);
    const decoded = decodeTOON(toonPayload);
    expect(decoded).toEqual(workflowSession);
  });

  it('allows TOON payloads to be exported as JSON for legacy consumers', () => {
    const toonPayload = encodeTOON(workflowSession);
    const jsonText = convertTOONToJSON(toonPayload, { indent: 0 });
    const parsed = JSON.parse(jsonText);

    expect(parsed.tasks.filter((task: any) => task.status === 'complete')).toHaveLength(3);
    expect(parsed.checkpoints.coverage.integration).toBeCloseTo(0.81);
  });

  it('auto-detects TOON payloads while continuing to read legacy JSON tasks', () => {
    const toonPayload = encodeTOON(workflowSession);
    const legacyJson = JSON.stringify({ id: 'IMPL-999', status: 'pending', agent: 'code-developer' });

    expect(detectFormat(toonPayload)).toBe('toon');
    expect(autoDecode(toonPayload)).toEqual(workflowSession);
    expect(autoDecode(legacyJson)).toEqual({ id: 'IMPL-999', status: 'pending', agent: 'code-developer' });
  });

  it('supports E2E conversion pipelines (JSON → TOON → JSON) for workflow payloads', () => {
    const jsonText = JSON.stringify(workflowSession, null, 2);
    const toonPayload = convertJSONToTOON(jsonText);
    const roundTripJson = convertTOONToJSON(toonPayload);

    expect(JSON.parse(roundTripJson)).toEqual(workflowSession);
  });
});
