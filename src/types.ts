export interface WineInfo {
  name: string;
  origin: string;
  grape: string;
  characteristics: string;
  foodPairing: string[];
}

export interface Wine {
  id: string;
  name: string;
  origin: string;
  grape: string;
  characteristics: string;
  foodPairing: string[];
  imageUrl?: string;
  date: Date;
  place?: string;
  review?: string;
  rating?: number;
  timestamp: Date;
}

export type WineSort = 'latest' | 'drankDate' | 'rating';

export function emptyWineInfo(): WineInfo {
  return {
    name: '',
    origin: '',
    grape: '',
    characteristics: '',
    foodPairing: [],
  };
}
