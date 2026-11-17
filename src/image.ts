export interface ResizedImage {
  blob: Blob;
  dataUrl: string;
  base64: string;
}

/**
 * Resizes an image file to fit within maxDim x maxDim and encodes as JPEG.
 * Keeps Gemini Vision tile count low and minimizes Firebase Storage usage.
 */
export async function resizeImageToJpeg(
  file: File,
  maxDim = 800,
  quality = 0.8,
): Promise<ResizedImage> {
  const dataUrl = await new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(new Error('이미지를 읽을 수 없습니다.'));
    reader.readAsDataURL(file);
  });

  const img = await new Promise<HTMLImageElement>((resolve, reject) => {
    const el = new Image();
    el.onload = () => resolve(el);
    el.onerror = () => reject(new Error('이미지 로드에 실패했습니다.'));
    el.src = dataUrl;
  });

  let { width, height } = img;
  if (width > maxDim || height > maxDim) {
    const scale = Math.min(maxDim / width, maxDim / height);
    width = Math.round(width * scale);
    height = Math.round(height * scale);
  }

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Canvas를 초기화할 수 없습니다.');
  ctx.drawImage(img, 0, 0, width, height);

  const outDataUrl = canvas.toDataURL('image/jpeg', quality);
  const blob = await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (b) => (b ? resolve(b) : reject(new Error('이미지 변환에 실패했습니다.'))),
      'image/jpeg',
      quality,
    );
  });

  const base64 = outDataUrl.split(',')[1] ?? '';
  return { blob, dataUrl: outDataUrl, base64 };
}
