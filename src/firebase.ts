import { initializeApp } from 'firebase/app';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getFirestore,
  onSnapshot,
  orderBy,
  query,
  Timestamp,
  updateDoc,
  type DocumentData,
  type QueryDocumentSnapshot,
} from 'firebase/firestore';
import {
  deleteObject,
  getDownloadURL,
  getStorage,
  ref,
  uploadBytes,
} from 'firebase/storage';
import type { Wine } from './types';

const firebaseConfig = {
  apiKey: 'AIzaSyAXfpkFcFH-HXOGqNEmMiUeV4SIMCWOiDE',
  authDomain: 'wines-96a55.firebaseapp.com',
  projectId: 'wines-96a55',
  storageBucket: 'wines-96a55.firebasestorage.app',
  messagingSenderId: '739128263714',
  appId: '1:739128263714:web:a1547555fed9a5d632b67b',
  measurementId: 'G-RSDSF8Q7Y5',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const storage = getStorage(app);

const WINES_COL = 'wines';

function toDate(value: unknown): Date {
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  return new Date();
}

function fromDoc(snap: QueryDocumentSnapshot<DocumentData>): Wine {
  const d = snap.data();
  return {
    id: snap.id,
    name: typeof d.name === 'string' ? d.name : '',
    origin: typeof d.origin === 'string' ? d.origin : '',
    grape: typeof d.grape === 'string' ? d.grape : '',
    characteristics: typeof d.characteristics === 'string' ? d.characteristics : '',
    foodPairing: Array.isArray(d.foodPairing)
      ? d.foodPairing.filter((x): x is string => typeof x === 'string')
      : [],
    imageUrl: typeof d.imageUrl === 'string' ? d.imageUrl : undefined,
    date: toDate(d.date),
    place: typeof d.place === 'string' ? d.place : undefined,
    review: typeof d.review === 'string' ? d.review : undefined,
    rating: typeof d.rating === 'number' ? d.rating : undefined,
    timestamp: toDate(d.timestamp),
  };
}

function toFirestore(wine: Omit<Wine, 'id'>): Record<string, unknown> {
  return {
    name: wine.name,
    origin: wine.origin,
    grape: wine.grape,
    characteristics: wine.characteristics,
    foodPairing: wine.foodPairing,
    imageUrl: wine.imageUrl ?? null,
    date: Timestamp.fromDate(wine.date),
    place: wine.place ?? null,
    review: wine.review ?? null,
    rating: wine.rating ?? null,
    timestamp: Timestamp.fromDate(wine.timestamp),
  };
}

export function watchWines(
  onData: (wines: Wine[]) => void,
  onError: (err: Error) => void,
): () => void {
  const q = query(collection(db, WINES_COL), orderBy('timestamp', 'desc'));
  return onSnapshot(
    q,
    (snap) => onData(snap.docs.map(fromDoc)),
    (err) => onError(err),
  );
}

export async function addWine(wine: Omit<Wine, 'id'>): Promise<string> {
  const docRef = await addDoc(collection(db, WINES_COL), toFirestore(wine));
  return docRef.id;
}

export async function updateWine(wine: Wine): Promise<void> {
  const { id, ...rest } = wine;
  await updateDoc(doc(db, WINES_COL, id), toFirestore(rest));
}

export async function deleteWine(wine: Wine): Promise<void> {
  await deleteDoc(doc(db, WINES_COL, wine.id));
  if (wine.imageUrl) {
    await deleteImage(wine.imageUrl);
  }
}

export async function uploadWineImage(blob: Blob): Promise<string> {
  const id = crypto.randomUUID();
  const storageRef = ref(storage, `wines/${id}.jpg`);
  await uploadBytes(storageRef, blob, { contentType: 'image/jpeg' });
  return getDownloadURL(storageRef);
}

export async function deleteImage(url: string): Promise<void> {
  try {
    await deleteObject(ref(storage, url));
  } catch {
    // Ignore already-deleted or unreachable storage objects
  }
}
