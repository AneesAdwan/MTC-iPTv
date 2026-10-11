// عميل Supabase للتطبيق — نفس قاعدة بيانات الويب. قراءة فقط عبر الواجهات العامة.
import 'react-native-url-polyfill/auto';
import { createClient } from '@supabase/supabase-js';
import { SUPABASE_URL, SUPABASE_ANON_KEY } from '../config';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false },          // التطبيق للمشاهدة فقط، بلا تسجيل دخول
  global: { headers: { 'x-client-info': 'mtc-iptv-app' } },
});
