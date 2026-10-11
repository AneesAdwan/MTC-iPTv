import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { C } from '../theme';

// اسم المنصة بأسلوب الموقع: MTC بالأبيض و-iPTv بلون الهوية.
export default function Wordmark({ size = 30 }) {
  return (
    <View style={s.row}>
      <Text style={[s.t, { fontSize: size, color: C.txt }]}>MTC</Text>
      <Text style={[s.t, { fontSize: size, color: C.ac }]}>-iPTv</Text>
    </View>
  );
}
const s = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'baseline' },
  t: { fontWeight: '900', letterSpacing: 0.3 },
});
