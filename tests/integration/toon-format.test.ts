import { describe, it, expect } from 'vitest';
import {
  encodeTOON,
  decodeTOON,
  autoDecode,
  convertJSONToTOON,
  convertTOONToJSON
} from '../../src/utils/toon';

const integrationSample = {
  id: 'IMPL-3.2',
  title: 'TOON-first rollout playbook',
  status: 'active',
  meta: {
    agent: 'code-developer',
    owner: 'codex',
    priority: 'p0'
  },
  context: {
    requirements: ['TOON 编解码', '自动检测', '命令兼容'],
    focus_paths: ['src/utils/toon.ts', 'tests/integration', 'scripts/toon-wrapper.sh'],
    acceptance: [
      'TOON 自动检测通过 autoDecode()',
      '安装脚本切换到 TOON 工具',
      'README 记录 token 节省'
    ]
  },
  flow_control: {
    pre_analysis: { owner: 'architect', state: 'complete' },
    implementation_approach: { owner: 'codex', state: 'ready' },
    verification: { owner: 'tester', state: 'pending' }
  }
};

describe('Integration • TOON format utilities', () => {
  it('preserves workflow data through encode/decode pipeline', () => {
    const toon = encodeTOON(integrationSample);
    const decoded = decodeTOON(toon);
    expect(decoded).toEqual(integrationSample);
  });

  it('achieves at least 30% token savings versus pretty JSON', () => {
    const jsonText = JSON.stringify(integrationSample, null, 2);
    const toonText = encodeTOON(integrationSample);
    const savingsRatio = 1 - toonText.length / jsonText.length;

    expect(savingsRatio).toBeGreaterThan(0.3);
    expect(savingsRatio).toBeLessThan(0.7); // realistic bound to catch regressions
  });

  it('auto-detects both JSON and TOON payloads for backward compatibility', () => {
    const jsonPayload = JSON.stringify(integrationSample, null, 2);
    const toonPayload = encodeTOON(integrationSample);

    expect(autoDecode(jsonPayload)).toEqual(integrationSample);
    expect(autoDecode(toonPayload)).toEqual(integrationSample);
  });

  it('converts between JSON and TOON using helper utilities', () => {
    const jsonPayload = JSON.stringify(integrationSample);
    const toonPayload = convertJSONToTOON(jsonPayload);
    const backToJson = convertTOONToJSON(toonPayload);

    expect(JSON.parse(backToJson)).toEqual(integrationSample);
  });
});
