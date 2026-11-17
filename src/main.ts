import './style.css';
import {
  addWine,
  deleteWine,
  updateWine,
  uploadWineImage,
  watchWines,
} from './firebase';
import { analyzeLabel, hasGeminiKey } from './gemini';
import { resizeImageToJpeg, type ResizedImage } from './image';
import { emptyWineInfo, type Wine, type WineInfo, type WineSort } from './types';

type Route =
  | { name: 'gallery' }
  | { name: 'scan' }
  | { name: 'form'; image?: ResizedImage; info?: WineInfo; existing?: Wine }
  | { name: 'detail'; wineId: string };

interface AppState {
  route: Route;
  wines: Wine[];
  loading: boolean;
  error: string | null;
  isSearching: boolean;
  query: string;
  sort: WineSort;
  scanImage: ResizedImage | null;
  isAnalyzing: boolean;
  lightboxUrl: string | null;
}

const state: AppState = {
  route: { name: 'gallery' },
  wines: [],
  loading: true,
  error: null,
  isSearching: false,
  query: '',
  sort: 'latest',
  scanImage: null,
  isAnalyzing: false,
  lightboxUrl: null,
};

const appEl = document.getElementById('app')!;

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function formatDateDot(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}.${m}.${day}`;
}

function formatDateInput(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function formatDateKo(d: Date): string {
  return `${d.getFullYear()}년 ${d.getMonth() + 1}월 ${d.getDate()}일`;
}

function renderStars(rating: number, large = false): string {
  const filled = Math.round(rating);
  const stars = Array.from({ length: 5 }, (_, i) => (i < filled ? '★' : '☆')).join('');
  return `<span class="stars${large ? ' large' : ''}">${stars}</span>`;
}

function showToast(message: string): void {
  document.querySelector('.toast')?.remove();
  const el = document.createElement('div');
  el.className = 'toast';
  el.textContent = message;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), 2600);
}

function getFilteredWines(): Wine[] {
  const q = state.query.trim().toLowerCase();
  const list = q
    ? state.wines.filter(
        (w) =>
          w.name.toLowerCase().includes(q) ||
          w.origin.toLowerCase().includes(q) ||
          w.grape.toLowerCase().includes(q) ||
          w.characteristics.toLowerCase().includes(q) ||
          (w.place?.toLowerCase().includes(q) ?? false) ||
          (w.review?.toLowerCase().includes(q) ?? false) ||
          w.foodPairing.some((f) => f.toLowerCase().includes(q)),
      )
    : [...state.wines];

  if (state.sort === 'latest') {
    list.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  } else if (state.sort === 'drankDate') {
    list.sort((a, b) => b.date.getTime() - a.date.getTime());
  } else {
    list.sort((a, b) => (b.rating ?? 0) - (a.rating ?? 0));
  }
  return list;
}

function render(): void {
  const { route } = state;
  if (route.name === 'gallery') {
    renderGallery();
  } else if (route.name === 'scan') {
    renderScan();
  } else if (route.name === 'form') {
    renderForm(route);
  } else {
    renderDetail(route.wineId);
  }

  if (state.lightboxUrl) {
    const lb = document.createElement('div');
    lb.className = 'lightbox';
    lb.innerHTML = `<img src="${escapeHtml(state.lightboxUrl)}" alt="와인 라벨 확대" />`;
    lb.addEventListener('click', () => {
      state.lightboxUrl = null;
      render();
    });
    appEl.appendChild(lb);
  }
}

function renderGallery(): void {
  const wines = getFilteredWines();

  let bodyHtml = '';
  if (state.loading) {
    bodyHtml = `<div class="center-state"><div class="spinner"></div></div>`;
  } else if (state.error) {
    bodyHtml = `<div class="center-state"><p>${escapeHtml(state.error)}</p></div>`;
  } else if (state.wines.length === 0) {
    bodyHtml = `
      <div class="center-state">
        <div class="wine-emoji">🍷</div>
        <div>첫 번째 와인을 기록해보세요</div>
        <div style="font-size:13px;margin-top:6px;">오른쪽 아래 카메라 버튼을 눌러 시작하세요</div>
      </div>
    `;
  } else if (wines.length === 0) {
    bodyHtml = `<div class="center-state"><div>검색 결과가 없습니다</div></div>`;
  } else {
    bodyHtml = `
      <div class="grid">
        ${wines
          .map(
            (w) => `
          <article class="wine-card" data-id="${escapeHtml(w.id)}">
            <div class="wine-card-img-wrap">
              ${
                w.imageUrl
                  ? `<img class="wine-card-img" src="${escapeHtml(w.imageUrl)}" alt="${escapeHtml(w.name)}" loading="lazy" />`
                  : `<span style="font-size:32px;opacity:0.35;">🍷</span>`
              }
            </div>
            <div class="wine-card-body">
              <div class="wine-card-name">${escapeHtml(w.name || '(이름 없음)')}</div>
              <div class="wine-card-date">${formatDateDot(w.date)}</div>
              ${w.rating != null ? renderStars(w.rating) : ''}
            </div>
          </article>
        `,
          )
          .join('')}
      </div>
    `;
  }

  appEl.innerHTML = `
    <div class="app-shell">
      <header class="topbar">
        ${
          state.isSearching
            ? `<input id="search-input" class="search-input" type="search" placeholder="와인명, 품종, 음식, 후기 검색..." value="${escapeHtml(state.query)}" />`
            : `<h1 class="topbar-title">WINES</h1>`
        }
        <button id="toggle-search" class="icon-btn" title="${state.isSearching ? '검색 닫기' : '검색'}">
          ${state.isSearching ? '✕' : '🔍'}
        </button>
        <select id="sort-select" class="sort-select" aria-label="정렬">
          <option value="latest" ${state.sort === 'latest' ? 'selected' : ''}>최근 등록순</option>
          <option value="drankDate" ${state.sort === 'drankDate' ? 'selected' : ''}>마신 날순</option>
          <option value="rating" ${state.sort === 'rating' ? 'selected' : ''}>평점 높은순</option>
        </select>
      </header>
      ${bodyHtml}
      <button id="fab-scan" class="fab" title="와인 스캔" aria-label="와인 스캔">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
          <circle cx="12" cy="13" r="4"/>
        </svg>
      </button>
    </div>
  `;

  if (state.isSearching) {
    const input = document.getElementById('search-input') as HTMLInputElement;
    input.focus();
    input.setSelectionRange(input.value.length, input.value.length);
    input.addEventListener('input', () => {
      state.query = input.value;
      renderGalleryGridOnly();
    });
  }

  document.getElementById('toggle-search')?.addEventListener('click', () => {
    state.isSearching = !state.isSearching;
    if (!state.isSearching) state.query = '';
    render();
  });

  document.getElementById('sort-select')?.addEventListener('change', (e) => {
    state.sort = (e.target as HTMLSelectElement).value as WineSort;
    render();
  });

  document.getElementById('fab-scan')?.addEventListener('click', () => {
    state.scanImage = null;
    state.isAnalyzing = false;
    state.route = { name: 'scan' };
    render();
  });

  bindCardClicks();
}

function renderGalleryGridOnly(): void {
  const gridEl = appEl.querySelector('.grid, .center-state');
  if (!gridEl) {
    render();
    return;
  }
  const wines = getFilteredWines();
  if (wines.length === 0) {
    gridEl.outerHTML = `<div class="center-state"><div>검색 결과가 없습니다</div></div>`;
    return;
  }
  gridEl.outerHTML = `
    <div class="grid">
      ${wines
        .map(
          (w) => `
        <article class="wine-card" data-id="${escapeHtml(w.id)}">
          <div class="wine-card-img-wrap">
            ${
              w.imageUrl
                ? `<img class="wine-card-img" src="${escapeHtml(w.imageUrl)}" alt="${escapeHtml(w.name)}" loading="lazy" />`
                : `<span style="font-size:32px;opacity:0.35;">🍷</span>`
            }
          </div>
          <div class="wine-card-body">
            <div class="wine-card-name">${escapeHtml(w.name || '(이름 없음)')}</div>
            <div class="wine-card-date">${formatDateDot(w.date)}</div>
            ${w.rating != null ? renderStars(w.rating) : ''}
          </div>
        </article>
      `,
        )
        .join('')}
    </div>
  `;
  bindCardClicks();
}

function bindCardClicks(): void {
  appEl.querySelectorAll<HTMLElement>('.wine-card').forEach((card) => {
    card.addEventListener('click', () => {
      const id = card.dataset.id;
      if (id) {
        state.route = { name: 'detail', wineId: id };
        render();
      }
    });
  });
}

function renderScan(): void {
  const img = state.scanImage;
  const aiAvailable = hasGeminiKey();

  appEl.innerHTML = `
    <div class="app-shell">
      <header class="topbar">
        <button id="back-btn" class="icon-btn" title="뒤로">←</button>
        <h1 class="topbar-title">와인 스캔</h1>
        <div style="width:40px"></div>
      </header>
      <div class="page-body">
        <div id="preview-box" class="picker-box ${img ? 'has-img' : ''}">
          ${
            img
              ? `<img src="${img.dataUrl}" alt="선택한 와인 라벨" />`
              : `<div style="font-size:36px;opacity:0.45;">📷</div>
                 <div style="color:var(--text-secondary);font-size:14px;">라벨 사진을 찍거나 선택하세요</div>`
          }
        </div>

        <div class="picker-actions">
          <label class="btn btn-outline" style="margin:0;">
            카메라
            <input id="camera-input" type="file" accept="image/*" capture="environment" hidden />
          </label>
          <label class="btn btn-outline" style="margin:0;">
            앨범에서 선택
            <input id="gallery-input" type="file" accept="image/*" hidden />
          </label>
        </div>

        ${
          state.isAnalyzing
            ? `<div class="center-state" style="min-height:120px;">
                 <div class="spinner"></div>
                 <div style="margin-top:12px;font-size:14px;">AI가 와인 라벨을 분석 중...</div>
               </div>`
            : img
              ? `
                ${
                  aiAvailable
                    ? `<button id="analyze-btn" class="btn btn-primary">✨ AI로 와인 분석하기</button>`
                    : ''
                }
                <button id="manual-btn" class="btn ${aiAvailable ? 'btn-text' : 'btn-primary'}">
                  ${aiAvailable ? 'AI 분석 없이 직접 기록하기' : '이 사진으로 기록하기'}
                </button>
              `
              : ''
        }
      </div>
    </div>
  `;

  document.getElementById('back-btn')?.addEventListener('click', () => {
    state.route = { name: 'gallery' };
    render();
  });

  const handleFile = async (file?: File) => {
    if (!file) return;
    try {
      state.scanImage = await resizeImageToJpeg(file);
      render();
    } catch (err) {
      showToast(err instanceof Error ? err.message : '이미지 처리에 실패했습니다.');
    }
  };

  document.getElementById('camera-input')?.addEventListener('change', (e) => {
    handleFile((e.target as HTMLInputElement).files?.[0]);
  });
  document.getElementById('gallery-input')?.addEventListener('change', (e) => {
    handleFile((e.target as HTMLInputElement).files?.[0]);
  });
  document.getElementById('preview-box')?.addEventListener('click', () => {
    document.getElementById('gallery-input')?.click();
  });

  document.getElementById('analyze-btn')?.addEventListener('click', async () => {
    if (!state.scanImage) return;
    state.isAnalyzing = true;
    render();
    const info = await analyzeLabel(state.scanImage.base64);
    state.isAnalyzing = false;
    if (!info) {
      showToast('AI 분석에 실패했습니다. 직접 입력해주세요.');
    }
    state.route = {
      name: 'form',
      image: state.scanImage,
      info: info ?? emptyWineInfo(),
    };
    render();
  });

  document.getElementById('manual-btn')?.addEventListener('click', () => {
    if (!state.scanImage) return;
    state.route = {
      name: 'form',
      image: state.scanImage,
      info: emptyWineInfo(),
    };
    render();
  });
}

function renderForm(route: Extract<Route, { name: 'form' }>): void {
  const existing = route.existing;
  const info = route.info ?? emptyWineInfo();
  const isEdit = Boolean(existing);

  let foodPairing = [...(existing ? existing.foodPairing : info.foodPairing)];
  let rating = existing?.rating ?? 3;
  const previewSrc = existing?.imageUrl ?? route.image?.dataUrl;

  appEl.innerHTML = `
    <div class="app-shell">
      <header class="topbar">
        <button id="back-btn" class="icon-btn" title="뒤로">←</button>
        <h1 class="topbar-title">${isEdit ? '와인 수정' : '와인 기록'}</h1>
        <div style="width:40px"></div>
      </header>
      <form id="wine-form" class="page-body">
        ${
          previewSrc
            ? `<img src="${escapeHtml(previewSrc)}" alt="라벨 미리보기" style="width:100%;height:200px;object-fit:cover;border-radius:12px;" />`
            : ''
        }

        <div class="section-label">와인 정보</div>
        <div class="field-group">
          <label class="field-label" for="f-name">와인 이름 *</label>
          <input id="f-name" class="input" required value="${escapeHtml(existing?.name ?? info.name)}" />
        </div>
        <div class="field-row">
          <div class="field-group">
            <label class="field-label" for="f-origin">원산지</label>
            <input id="f-origin" class="input" value="${escapeHtml(existing?.origin ?? info.origin)}" />
          </div>
          <div class="field-group">
            <label class="field-label" for="f-grape">포도 품종</label>
            <input id="f-grape" class="input" value="${escapeHtml(existing?.grape ?? info.grape)}" />
          </div>
        </div>
        <div class="field-group">
          <label class="field-label" for="f-char">특징</label>
          <textarea id="f-char" class="textarea" rows="2">${escapeHtml(existing?.characteristics ?? info.characteristics)}</textarea>
        </div>

        <div class="field-group">
          <label class="field-label">어울리는 음식 (페어링)</label>
          <div id="food-chips" class="chips-wrap"></div>
          <div class="chip-input-row">
            <input id="food-input" class="input" placeholder="예: 스테이크, 브리 치즈" />
            <button id="food-add-btn" type="button" class="chip-add-btn">추가</button>
          </div>
        </div>

        <div class="divider"></div>
        <div class="section-label">내 기록</div>

        <div class="field-row">
          <div class="field-group">
            <label class="field-label" for="f-date">마신 날</label>
            <input id="f-date" class="input" type="date" value="${formatDateInput(existing?.date ?? new Date())}" />
          </div>
          <div class="field-group">
            <label class="field-label" for="f-place">장소</label>
            <input id="f-place" class="input" placeholder="어디서 마셨나요?" value="${escapeHtml(existing?.place ?? '')}" />
          </div>
        </div>

        <div class="field-group">
          <label class="field-label" for="f-review">맛 · 음식 조화 메모</label>
          <textarea id="f-review" class="textarea" rows="3" placeholder="맛, 향, 음식과의 조화 등을 남겨보세요...">${escapeHtml(existing?.review ?? '')}</textarea>
        </div>

        <div class="field-group">
          <span class="field-label">평점</span>
          <div id="rating-picker"></div>
        </div>

        <button id="save-btn" type="submit" class="btn btn-primary" style="margin-top:8px;">
          ${isEdit ? '수정 완료' : '저장하기'}
        </button>
      </form>
    </div>
  `;

  const renderChips = () => {
    const wrap = document.getElementById('food-chips')!;
    wrap.innerHTML = foodPairing
      .map(
        (f, idx) => `
      <span class="chip">
        ${escapeHtml(f)}
        <button type="button" class="chip-del" data-idx="${idx}" aria-label="삭제">×</button>
      </span>
    `,
      )
      .join('');
    wrap.querySelectorAll<HTMLButtonElement>('.chip-del').forEach((btn) => {
      btn.addEventListener('click', () => {
        const idx = Number(btn.dataset.idx);
        foodPairing = foodPairing.filter((_, i) => i !== idx);
        renderChips();
      });
    });
  };

  const addFoodFromInput = () => {
    const input = document.getElementById('food-input') as HTMLInputElement;
    const items = input.value
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0 && !foodPairing.includes(s));
    if (items.length > 0) {
      foodPairing = [...foodPairing, ...items];
      input.value = '';
      renderChips();
    }
  };

  const renderRating = () => {
    const box = document.getElementById('rating-picker')!;
    box.innerHTML = Array.from({ length: 5 }, (_, i) => {
      const val = i + 1;
      return `<button type="button" class="star-btn" data-val="${val}" aria-label="${val}점">${val <= rating ? '★' : '☆'}</button>`;
    }).join('');
    box.querySelectorAll<HTMLButtonElement>('.star-btn').forEach((btn) => {
      btn.addEventListener('click', () => {
        rating = Number(btn.dataset.val);
        renderRating();
      });
    });
  };

  renderChips();
  renderRating();

  document.getElementById('food-add-btn')?.addEventListener('click', addFoodFromInput);
  document.getElementById('food-input')?.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      addFoodFromInput();
    }
  });

  document.getElementById('back-btn')?.addEventListener('click', () => {
    if (existing) {
      state.route = { name: 'detail', wineId: existing.id };
    } else {
      state.route = { name: 'scan' };
    }
    render();
  });

  document.getElementById('wine-form')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    addFoodFromInput();

    const name = (document.getElementById('f-name') as HTMLInputElement).value.trim();
    if (!name) {
      showToast('와인 이름을 입력해주세요.');
      return;
    }

    const saveBtn = document.getElementById('save-btn') as HTMLButtonElement;
    saveBtn.disabled = true;
    saveBtn.textContent = '저장 중...';

    const origin = (document.getElementById('f-origin') as HTMLInputElement).value.trim();
    const grape = (document.getElementById('f-grape') as HTMLInputElement).value.trim();
    const characteristics = (document.getElementById('f-char') as HTMLTextAreaElement).value.trim();
    const dateVal = (document.getElementById('f-date') as HTMLInputElement).value;
    const place = (document.getElementById('f-place') as HTMLInputElement).value.trim();
    const review = (document.getElementById('f-review') as HTMLTextAreaElement).value.trim();
    const date = dateVal ? new Date(`${dateVal}T12:00:00`) : new Date();

    try {
      if (existing) {
        await updateWine({
          ...existing,
          name,
          origin,
          grape,
          characteristics,
          foodPairing,
          date,
          place: place || undefined,
          review: review || undefined,
          rating,
        });
        showToast('와인 기록이 수정되었습니다 🍷');
        state.route = { name: 'detail', wineId: existing.id };
      } else {
        let imageUrl: string | undefined;
        if (route.image) {
          imageUrl = await uploadWineImage(route.image.blob);
        }
        await addWine({
          name,
          origin,
          grape,
          characteristics,
          foodPairing,
          imageUrl,
          date,
          place: place || undefined,
          review: review || undefined,
          rating,
          timestamp: new Date(),
        });
        showToast('와인이 기록되었습니다 🍷');
        state.route = { name: 'gallery' };
      }
      render();
    } catch (err) {
      saveBtn.disabled = false;
      saveBtn.textContent = isEdit ? '수정 완료' : '저장하기';
      showToast(`저장 실패: ${err instanceof Error ? err.message : '오류'}`);
    }
  });
}

function renderDetail(wineId: string): void {
  const wine = state.wines.find((w) => w.id === wineId);
  if (!wine) {
    state.route = { name: 'gallery' };
    render();
    return;
  }

  const subtitle = [wine.origin, wine.grape].filter(Boolean).join(' · ');

  appEl.innerHTML = `
    <div class="app-shell">
      <header class="topbar">
        <button id="back-btn" class="icon-btn" title="뒤로">←</button>
        <h1 class="topbar-title left">${escapeHtml(wine.name || '와인 상세')}</h1>
        <button id="edit-btn" class="icon-btn" title="수정">✎</button>
        <button id="delete-btn" class="icon-btn danger" title="삭제">🗑</button>
      </header>
      ${
        wine.imageUrl
          ? `<img id="hero-img" class="detail-hero" src="${escapeHtml(wine.imageUrl)}" alt="${escapeHtml(wine.name)}" />`
          : `<div class="detail-placeholder">🍷</div>`
      }
      <div class="page-body">
        <div>
          <h2 class="detail-title">${escapeHtml(wine.name || '(이름 없음)')}</h2>
          ${subtitle ? `<p class="detail-sub">${escapeHtml(subtitle)}</p>` : ''}
          ${wine.rating != null ? `<div style="margin-top:8px;">${renderStars(wine.rating, true)}</div>` : ''}
        </div>

        <div class="divider"></div>

        ${
          wine.characteristics
            ? `<div class="info-block"><span class="info-label">특징</span><div class="info-value">${escapeHtml(wine.characteristics)}</div></div>`
            : ''
        }

        ${
          wine.foodPairing.length > 0
            ? `<div class="info-block">
                 <span class="info-label">어울리는 음식</span>
                 <div class="chips-wrap" style="margin-top:4px;">
                   ${wine.foodPairing.map((f) => `<span class="chip">${escapeHtml(f)}</span>`).join('')}
                 </div>
               </div>`
            : ''
        }

        <div class="divider"></div>

        <div class="info-block">
          <span class="info-label">마신 날</span>
          <div class="info-value">${formatDateKo(wine.date)}</div>
        </div>

        ${
          wine.place
            ? `<div class="info-block"><span class="info-label">장소</span><div class="info-value">${escapeHtml(wine.place)}</div></div>`
            : ''
        }

        ${
          wine.review
            ? `<div class="info-block"><span class="info-label">맛 · 음식 조화 메모</span><div class="info-value">${escapeHtml(wine.review)}</div></div>`
            : ''
        }
      </div>
    </div>
  `;

  document.getElementById('back-btn')?.addEventListener('click', () => {
    state.route = { name: 'gallery' };
    render();
  });

  document.getElementById('hero-img')?.addEventListener('click', () => {
    if (wine.imageUrl) {
      state.lightboxUrl = wine.imageUrl;
      render();
    }
  });

  document.getElementById('edit-btn')?.addEventListener('click', () => {
    state.route = { name: 'form', existing: wine };
    render();
  });

  document.getElementById('delete-btn')?.addEventListener('click', async () => {
    if (!window.confirm('이 와인 기록을 삭제하시겠습니까?')) return;
    try {
      await deleteWine(wine);
      showToast('삭제되었습니다.');
      state.route = { name: 'gallery' };
      render();
    } catch (err) {
      showToast(`삭제 실패: ${err instanceof Error ? err.message : '오류'}`);
    }
  });
}

// Subscribe once to Firestore stream
watchWines(
  (wines) => {
    state.wines = wines;
    state.loading = false;
    state.error = null;
    render();
  },
  () => {
    state.loading = false;
    state.error = '와인 목록을 불러오지 못했습니다. 네트워크 연결을 확인해주세요.';
    render();
  },
);

render();
