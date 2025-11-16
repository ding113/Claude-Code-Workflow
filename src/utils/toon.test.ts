import { describe, it, expect } from 'vitest';
import {
  encodeTOON,
  decodeTOON,
  detectFormat,
  autoDecode,
  convertJSONToTOON,
  convertTOONToJSON
} from './toon';

describe('TOON Utilities', () => {
  describe('encodeTOON', () => {
    it('should encode simple objects', () => {
      const data = { id: 1, name: 'Alice', active: true };
      const toon = encodeTOON(data);
      expect(toon).toContain('id: 1');
      expect(toon).toContain('name: Alice');
      expect(toon).toContain('active: true');
    });

    it('should encode arrays of objects in tabular format', () => {
      const data = {
        users: [
          { id: 1, name: 'Alice', role: 'admin' },
          { id: 2, name: 'Bob', role: 'user' }
        ]
      };
      const toon = encodeTOON(data);
      expect(toon).toContain('users[2]{id,name,role}:');
      expect(toon).toContain('1,Alice,admin');
      expect(toon).toContain('2,Bob,user');
    });

    it('should use custom delimiter', () => {
      const data = { tags: ['a', 'b', 'c'] };
      const toon = encodeTOON(data, { delimiter: '\t' });
      expect(toon).toContain('tags[3');
      expect(toon).toContain('\t');
    });
  });

  describe('decodeTOON', () => {
    it('should decode simple TOON to object', () => {
      const toon = 'id: 1\nname: Alice\nactive: true';
      const result = decodeTOON(toon);
      expect(result).toEqual({ id: 1, name: 'Alice', active: true });
    });

    it('should decode tabular arrays', () => {
      const toon = 'users[2]{id,name,role}:\n  1,Alice,admin\n  2,Bob,user';
      const result = decodeTOON(toon) as any;
      expect(result.users).toHaveLength(2);
      expect(result.users[0]).toEqual({ id: 1, name: 'Alice', role: 'admin' });
      expect(result.users[1]).toEqual({ id: 2, name: 'Bob', role: 'user' });
    });
  });

  describe('detectFormat', () => {
    it('should detect JSON format', () => {
      const json = '{"id": 1, "name": "Alice"}';
      expect(detectFormat(json)).toBe('json');
    });

    it('should detect JSON arrays', () => {
      const json = '[1, 2, 3]';
      expect(detectFormat(json)).toBe('json');
    });

    it('should detect TOON format with array length', () => {
      const toon = 'items[3]: a,b,c';
      expect(detectFormat(toon)).toBe('toon');
    });

    it('should detect TOON format with tabular notation', () => {
      const toon = 'users[2]{id,name}:\n  1,Alice\n  2,Bob';
      expect(detectFormat(toon)).toBe('toon');
    });

    it('should detect TOON format with simple key-value', () => {
      const toon = 'name: Alice\nage: 30';
      expect(detectFormat(toon)).toBe('toon');
    });

    it('should return unknown for empty string', () => {
      expect(detectFormat('')).toBe('unknown');
    });
  });

  describe('autoDecode', () => {
    it('should auto-detect and decode JSON', () => {
      const json = '{"id": 1, "name": "Alice"}';
      const result = autoDecode(json);
      expect(result).toEqual({ id: 1, name: 'Alice' });
    });

    it('should auto-detect and decode TOON', () => {
      const toon = 'id: 1\nname: Alice';
      const result = autoDecode(toon);
      expect(result).toEqual({ id: 1, name: 'Alice' });
    });

    it('should fallback to TOON for unknown format', () => {
      const toon = 'items[2]: a,b';
      const result = autoDecode(toon) as any;
      expect(result.items).toEqual(['a', 'b']);
    });
  });

  describe('convertJSONToTOON', () => {
    it('should convert JSON string to TOON', () => {
      const json = '{"users":[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]}';
      const toon = convertJSONToTOON(json);
      expect(toon).toContain('users[2]{id,name}:');
      expect(toon).toContain('1,Alice');
      expect(toon).toContain('2,Bob');
    });
  });

  describe('convertTOONToJSON', () => {
    it('should convert TOON string to JSON', () => {
      const toon = 'id: 1\nname: Alice';
      const json = convertTOONToJSON(toon);
      const parsed = JSON.parse(json);
      expect(parsed).toEqual({ id: 1, name: 'Alice' });
    });

    it('should use custom indentation', () => {
      const toon = 'id: 1\nname: Alice';
      const json = convertTOONToJSON(toon, { indent: 4 });
      expect(json).toContain('    '); // 4 spaces
    });
  });

  describe('round-trip conversion', () => {
    it('should preserve data through JSON -> TOON -> JSON', () => {
      const original = {
        id: 123,
        name: 'Test',
        items: [
          { sku: 'A1', qty: 2 },
          { sku: 'B2', qty: 5 }
        ]
      };

      const toon = encodeTOON(original);
      const decoded = decodeTOON(toon);

      expect(decoded).toEqual(original);
    });

    it('should preserve data through TOON -> JSON -> TOON', () => {
      const originalTOON = 'id: 1\nname: Alice\nitems[2]{id,qty}:\n  1,5\n  2,3';
      const json = convertTOONToJSON(originalTOON);
      const backToTOON = convertJSONToTOON(json);
      const final = decodeTOON(backToTOON);
      const expected = decodeTOON(originalTOON);

      expect(final).toEqual(expected);
    });
  });
});
