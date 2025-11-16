/**
 * TOON Format Utilities
 *
 * Provides utilities for encoding/decoding between JSON and TOON format
 * with automatic format detection and dual-format support for backward compatibility.
 */

import { encode, decode } from '@toon-format/toon';

/**
 * Encode data to TOON format
 * @param data - Any JSON-serializable value
 * @param options - Encoding options (delimiter, indent, keyFolding)
 * @returns TOON-formatted string
 */
export function encodeTOON(data: unknown, options?: {
  delimiter?: ',' | '\t' | '|';
  indent?: number;
  keyFolding?: 'off' | 'safe';
}): string {
  return encode(data, options);
}

/**
 * Decode TOON format to data
 * @param input - TOON-formatted string
 * @param options - Decoding options (strict, expandPaths)
 * @returns Decoded data
 */
export function decodeTOON(input: string, options?: {
  strict?: boolean;
  expandPaths?: 'off' | 'safe';
}): unknown {
  return decode(input, options);
}

/**
 * Detect if a string is TOON format vs JSON
 * @param input - Input string to analyze
 * @returns 'toon' | 'json' | 'unknown'
 */
export function detectFormat(input: string): 'toon' | 'json' | 'unknown' {
  const trimmed = input.trim();

  if (!trimmed) return 'unknown';

  // JSON detection: starts with { or [
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      JSON.parse(trimmed);
      return 'json';
    } catch {
      // Might be malformed JSON or TOON
    }
  }

  // TOON detection heuristics:
  // 1. Contains array length notation: [N]
  // 2. Contains tabular field notation: {field1,field2}
  // 3. Contains key: value without surrounding braces
  // 4. Uses indentation-based structure

  const toonPatterns = [
    /\[\d+\]:/,                    // Array length: items[5]:
    /\[\d+\]\{[\w,]+\}:/,          // Tabular: items[2]{id,name}:
    /^\w+:/m,                      // Key-value without braces
    /^  \w+:/m                     // Indented key (2 spaces)
  ];

  const hasToonPattern = toonPatterns.some(pattern => pattern.test(trimmed));

  if (hasToonPattern) {
    return 'toon';
  }

  return 'unknown';
}

/**
 * Auto-decode: Detect format and decode appropriately
 * Supports both JSON and TOON for backward compatibility
 * @param input - JSON or TOON formatted string
 * @param options - Decoding options
 * @returns Decoded data
 */
export function autoDecode(input: string, options?: {
  strict?: boolean;
  expandPaths?: 'off' | 'safe';
}): unknown {
  const format = detectFormat(input);

  if (format === 'json') {
    return JSON.parse(input);
  } else if (format === 'toon') {
    return decodeTOON(input, options);
  } else {
    // Fallback: try JSON first, then TOON
    try {
      return JSON.parse(input);
    } catch {
      return decodeTOON(input, options);
    }
  }
}

/**
 * Convert JSON file content to TOON format
 * @param jsonContent - JSON string content
 * @param options - Encoding options
 * @returns TOON formatted string
 */
export function convertJSONToTOON(jsonContent: string, options?: {
  delimiter?: ',' | '\t' | '|';
  indent?: number;
  keyFolding?: 'off' | 'safe';
}): string {
  const data = JSON.parse(jsonContent);
  return encodeTOON(data, options);
}

/**
 * Convert TOON file content to JSON format
 * @param toonContent - TOON string content
 * @param options - Decoding and JSON options
 * @returns JSON formatted string
 */
export function convertTOONToJSON(toonContent: string, options?: {
  strict?: boolean;
  expandPaths?: 'off' | 'safe';
  indent?: number;
}): string {
  const data = decodeTOON(toonContent, {
    strict: options?.strict,
    expandPaths: options?.expandPaths
  });
  return JSON.stringify(data, null, options?.indent ?? 2);
}
