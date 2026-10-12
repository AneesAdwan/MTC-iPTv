import { Dimensions, Platform, PixelRatio } from 'react-native';

// نظام تجاوب: يكيّف المقاسات حسب نوع الشاشة (جوال / لوحي / تلفاز).
const { width, height } = Dimensions.get('window');
export const SW = width, SH = height;
export const isTV = Platform.isTV === true;

// نوع الجهاز حسب أصغر بُعد
const minDim = Math.min(width, height);
export const device = isTV ? 'tv' : minDim >= 600 ? 'tablet' : 'phone';
export const isBig = device !== 'phone'; // لوحي أو تلفاز

// معامل تكبير لطيف للنصوص والمقاسات على الشاشات الكبيرة
export const scale = isTV ? 1.35 : device === 'tablet' ? 1.18 : 1;
export const rs = (n) => Math.round(n * scale);

// أعمدة الشبكة حسب عرض الشاشة
export const gridCols = isTV ? 6 : width >= 1000 ? 6 : width >= 820 ? 5 : width >= 640 ? 4 : 3;

// عرض بطاقة القناة في الصفوف الأفقية
export const cardW = isTV ? 250 : device === 'tablet' ? 200 : Math.min(160, (width - 40) / 2.4);

// ارتفاع مسرح الفيديو: 16:9 لكن لا يتجاوز نصف ارتفاع الشاشة (للوحي والتلفاز)
export const videoH = Math.min(Math.round(width * 9 / 16), Math.round(height * (isBig ? 0.62 : 0.5)));
