import type { WineInfo } from './types';

const GEMINI_API_KEY = import.meta.env.VITE_GEMINI_API_KEY ?? '';
const GEMINI_ENDPOINT =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

const LABEL_PROMPT = `이 와인 라벨을 분석하고 아래 JSON 형식으로만 응답하세요 (코드 블록 없이 순수 JSON):
{"name":"와인 전체 이름","origin":"원산지(국가, 지역)","grape":"포도 품종","characteristics":"특징(한 문장, 한국어)","foodPairing":["음식1","음식2","음식3"]}
확인 불가 시 "알 수 없음"으로 표시하세요.`;

export function hasGeminiKey(): boolean {
  return GEMINI_API_KEY.trim().length > 0 && GEMINI_API_KEY !== 'YOUR_GEMINI_API_KEY';
}

export async function analyzeLabel(base64Jpeg: string): Promise<WineInfo | null> {
  if (!hasGeminiKey()) return null;

  try {
    const res = await fetch(`${GEMINI_ENDPOINT}?key=${encodeURIComponent(GEMINI_API_KEY)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                inlineData: {
                  mimeType: 'image/jpeg',
                  data: base64Jpeg,
                },
              },
              { text: LABEL_PROMPT },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: 'application/json',
        },
      }),
    });

    if (!res.ok) return null;

    const payload = (await res.json()) as {
      candidates?: Array<{
        content?: { parts?: Array<{ text?: string }> };
      }>;
    };

    const rawText = payload.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!rawText) return null;

    const jsonStr = rawText.replace(/```json|```/g, '').trim();
    const parsed = JSON.parse(jsonStr) as Record<string, unknown>;

    return {
      name: typeof parsed.name === 'string' ? parsed.name : '알 수 없음',
      origin: typeof parsed.origin === 'string' ? parsed.origin : '알 수 없음',
      grape: typeof parsed.grape === 'string' ? parsed.grape : '알 수 없음',
      characteristics:
        typeof parsed.characteristics === 'string' ? parsed.characteristics : '',
      foodPairing: Array.isArray(parsed.foodPairing)
        ? parsed.foodPairing.filter((x): x is string => typeof x === 'string')
        : [],
    };
  } catch {
    return null;
  }
}
