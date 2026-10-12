import React from 'react';
import { Text } from 'react-native';
import { C } from '../theme';

// اسم المنصة «MTC-iPTv» — نص واحد باتجاه LTR ثابت، لا ينقلب مهما كان الجهاز عربيًا.
// نص واحد (Text واحد مع أبناء) لا يُعاد ترتيبه في وضع RTL.
export default function Wordmark({ size = 30 }) {
  return (
    <Text style={{ fontSize: size, fontWeight: '900', letterSpacing: 0.3, writingDirection: 'ltr', textAlign: 'left' }}>
      <Text style={{ color: C.txt }}>MTC</Text>
      <Text style={{ color: C.ac }}>-iPTv</Text>
    </Text>
  );
}
