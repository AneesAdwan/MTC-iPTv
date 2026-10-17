# mtc_update

تحديث ذاتي آمن لبرنامج **MTC-iPTv SuperAdmin** على ويندوز — Dart صافي (بدون Flutter).
Secure self-update for the **MTC-iPTv SuperAdmin** Windows program — pure Dart (no Flutter).

خطة المرجع: `mtc_iptv/docs/plans/admin-rebuild-2026-10.md` القسم 9.5، وقرار ق-12 (بدون شهادة Authenticode مدفوعة).
Reference: plan section 9.5 and decision Q-12 (no paid Authenticode certificate).

> هاد الباكج **ما بيلمس** مسار تحديث تطبيق المشاهدين الحالي (DSA / WinSparkle).
> This package does **not** touch the viewer app's existing DSA / WinSparkle update path.

---

## 1. نموذج التهديد · Threat model

**العربي**

- **الثقة بالتوقيع، مش بالمكان.** المستودع الخاص، رمز GitHub، رابط التحميل، HTTPS — كلها *نقل* بس. إذا حدا سرق رمز المستودع أو استبدل ملف بالإصدار، البرنامج بيرفض لأنه ما معه المفتاح الخاص.
- المفتاح العام (32 بايت) **مدموج بالبرنامج**. المفتاح الخاص **ما بيدخل المستودع أبدًا** — بيعيش بـ `%USERPROFILE%\.mtc-iptv\superadmin_ed25519.key` على جهاز المالك + نسخة احتياطية أوفلاين.
- البيان (manifest) موقّع Ed25519، وفيه بصمة SHA-256 وحجم الملف ← أي تعديل بالملف أو بالبيان بيترفض.
- **منع الرجوع:** أي إصدار ≤ المثبّت بيترفض، إلا «بيان رجوع» موقّع مخصوص لإصدار محدد ومن إصدار محدد (ما بينعاد استعماله).
- **الحد الأدنى المسموح:** الإصدارات تحت `min_allowed_version` محظورة (ثغرات). إذا المثبّت تحته، التحديث إجباري. والبرنامج بيحفظ أعلى حد شافه (`blockedBelow`) فما بينضحك عليه ببيان قديم.
- **بدون Authenticode (ق-12):** ويندوز بيحذّر بأول تثبيت بس («More info» ← «Run anyway»). كل التحديثات بعدها بتتحقق بتوقيعنا.
- **شو ما بيحمي منه:** سرقة المفتاح الخاص نفسه (احميه!)، أو جهاز المدير مخترق أصلًا.

**English**

- **Trust the signature, not the location.** The private repo, the GitHub token, the download URL and HTTPS are transport only. A stolen repo token or a swapped release asset is rejected because the attacker cannot produce an Ed25519 signature.
- The 32-byte public key is **embedded in the app**. The private key **never enters the repo**; it lives at `%USERPROFILE%\.mtc-iptv\superadmin_ed25519.key` on the owner's machine plus an offline backup.
- The manifest is Ed25519-signed and pins the artifact's SHA-256 and size, so any change to the file or the manifest is rejected.
- **Anti-rollback:** any version ≤ installed is refused, except a specially signed rollback manifest bound to an exact target *and* an exact installed version (`rollback_to` + `rollback_from`), so it cannot be replayed later.
- **min_allowed_version:** versions below it are blocked; an installed version below it makes the update mandatory. The app persists the highest minimum it has seen (`blockedBelow`) so an old, validly signed manifest cannot lower it.
- **No Authenticode (Q-12):** Windows SmartScreen warns on the first install only; every later update is verified by our signature.
- **Out of scope:** theft of the private key itself, or an already-compromised admin machine.

### ليش `package:cryptography`؟ · Why `package:cryptography`

- Ed25519 بـ Dart صافي (بيشتغل بـ `dart test` وبـ Flutter Windows بدون مكتبات أصلية)، مُصان ومستعمل كتير، وهو أصلًا تبعية بـ `mtc_core` (ما في تبعية جديدة على المشروع).
- Pure-Dart Ed25519 (RFC 8032) that works in plain `dart test` and in Flutter Windows without native code; widely used and maintained; already a dependency of `mtc_core`, so no new supply-chain surface. `package:crypto` (dart-lang) is used for streaming SHA-256. A test pins the RFC 8032 test vector 1 to prove the implementation.

---

## 2. إنشاء المفتاح مرة وحدة · Generate the key once

```powershell
$env:PATH = "$HOME\scoop\apps\flutter\current\bin;$HOME\scoop\shims;$env:PATH"
cd mtc_iptv\packages\mtc_update
dart pub get
dart run bin/keygen.dart            # default: %USERPROFILE%\.mtc-iptv\superadmin_ed25519.key
```

- بيكتب المفتاح الخاص + `superadmin_ed25519.key.pub`، وبيقصر صلاحيات الملف على مستخدمك (icacls).
- بيرفض يكتب فوق مفتاح موجود، وبيرفض أي مكان جوّا مستودع git.
- بيطبع سطر `TrustedKey(...)` — حطّه بقائمة المفاتيح بالبرنامج.
- **خزّن نسخة احتياطية أوفلاين** (USB مشفّر / مدير كلمات سر). إذا ضاع المفتاح، ما في تحديث موقّع إلا بإصدار جديد بمفتاح جديد يتثبّت يدويًا.

It writes the private key and `<key>.pub`, restricts the key's ACL to your user, refuses to overwrite and refuses any location inside a git repo, and prints the `TrustedKey(...)` line to embed. **Back it up offline.**

```dart
// in the SuperAdmin app
const superAdminUpdateKeys = [
  TrustedKey(id: 'superadmin-2026', publicKeyBase64: '<printed by keygen>'),
];
```

**تدوير المفتاح · Key rotation:** اعمل مفتاح جديد، حطّ الاتنين بالقائمة بإصدار (موقّع بالقديم)، بعدها وقّع بالجديد، وشيل القديم بالإصدار اللي بعده. / Ship a release (signed with the old key) that trusts both keys, then sign with the new key, then drop the old key one release later.

---

## 3. توقيع إصدار · Sign a release

```powershell
dart run bin/sign_release.dart --artifact dist\mtc-superadmin-1.2.0-windows.zip `
    --version 1.2.0 --min-allowed 1.0.0 [--channel stable] [--key PATH] [--out DIR]
```

بيحسب SHA-256 والحجم، بيكتب `manifest.json` (البايتات القانونية) و`manifest.sig` (توقيع base64)، وبيتأكد من التوقيع قبل ما يخلص. ارفع الملفات التلاتة سوا.
Computes SHA-256 + size, writes `manifest.json` (canonical bytes) and `manifest.sig` (base64 signature), self-verifies. Upload all three files together.

**بيان رجوع موقّع · Signed rollback** (رجّع الأجهزة اللي عليها 1.2.0 لـ 1.1.0):

```powershell
dart run bin/sign_release.dart --artifact dist\mtc-superadmin-1.1.0-windows.zip `
    --version 1.1.0 --min-allowed 1.0.0 --rollback-from 1.2.0
```

### صيغة البيان · Manifest format

```json
{"app":"mtc-superadmin","channel":"stable","file":"mtc-superadmin-1.2.0-windows.zip","min_allowed_version":"1.0.0","published_at":"2026-10-17T12:00:00Z","schema":1,"sha256":"<64 hex>","size":12345678,"version":"1.2.0"}
```

مفاتيح مرتبة، بدون فراغات، UTF-8. حقول الرجوع (`rollback_to`, `rollback_from`) بس ببيان الرجوع. البرنامج بيرفض أي بايتات مش مطابقة حرفيًا للشكل القانوني (حقول غريبة، مفاتيح مكررة، فراغات).
Sorted keys, compact, UTF-8; rollback fields only on rollback manifests. The verifier refuses bytes that are not byte-identical to the canonical encoding (unknown fields, duplicate keys, whitespace).

---

## 4. كيف البرنامج بيتحقق · How the app verifies

```dart
final verifier = UpdateVerifier(trustedKeys: superAdminUpdateKeys, channel: 'stable');

// 1) before downloading the big file
final vm = await verifier.verifyManifest(
  installed: Version.parse(appVersion),
  manifestBytes: manifestJsonBytes,
  signatureText: manifestSigText,
  blockedBelow: persistedMinAllowed, // highest min_allowed_version seen so far
);
if (vm.isMandatory) { /* installed build is blocked: update now, no "later" */ }

// 2) after download
final update = await verifier.verifyArtifact(vm, File(downloadedZipPath));
await installer.stage(update);           // extracts next to the running version
persist(max(persistedMinAllowed, update.manifest.minAllowedVersion));
// restart through the launcher
```

الترتيب: التوقيع أولًا (ما في شي بالبيان موثوق قبله) ← البنية ← app/channel ← قواعد الإصدار ← الحجم والبصمة. وقت الـ `stage` بينحسب SHA-256 مرة تانية على نفس البايتات اللي رح تنفك (ضد تبديل الملف بعد الفحص).
Order: signature first, then structure, app/channel, version policy, size + SHA-256. `stage()` re-hashes the very bytes it extracts (defeats a swap after verification).

كل رفض إله سبب من `UpdateRejection` · Every rejection carries an `UpdateRejection`:

| reason | meaning |
|---|---|
| `noTrustedKeys` | empty key list (programming error) |
| `signatureMalformed` | `manifest.sig` not base64 of 64 bytes |
| `signatureInvalid` | tampered manifest, wrong / unknown / retired key |
| `manifestMalformed` | signed but invalid, unknown field, non-canonical |
| `wrongApp` / `wrongChannel` | not `mtc-superadmin` / not our channel |
| `versionNotNewer` | version ≤ installed (anti-rollback) |
| `rollbackNotAllowed` | bad rollback: `rollback_to` ≠ version, `rollback_from` ≠ installed, or target not older |
| `versionBlocked` | target below `min_allowed_version` or below the persisted minimum |
| `fileNameMismatch` / `fileSizeMismatch` / `fileHashMismatch` | artifact does not match manifest |

---

## 5. التثبيت جنب بعض والاستعادة · Side-by-side install & automatic restore

```
%LOCALAPPDATA%\MTC-iPTv-SuperAdmin\
  launcher.exe            tiny, never auto-updated
  state.json              current / previous / pending + history + last_revert
  state.json.bak          last good copy
  versions\
    1.2.0\  (current, has .mtc_confirmed)
    1.1.0\  (previous, kept until the next successful update)
    1.3.0\  (pending, on trial)
```

**الخطوات · Flow**

1. `stage(update)` — بيفك الـ zip بمجلد مؤقت ← `versions\<ver>\` ← `pending = ver`. النسخة الشغالة ما بتنلمس. / extract to a temp folder, rename to `versions\<ver>\`, mark pending; the running version is untouched.
2. اللانشر بينادي `beginLaunch()` — إذا في pending بيعدّ محاولة تشغيل؛ إذا خلصت المحاولات (`maxBootAttempts`، افتراضي 2) بيرجع تلقائيًا قبل التشغيل. / counts a boot attempt for the pending version; once attempts are exhausted it reverts before starting.
3. البرنامج الجديد بيعمل فحص التشغيل (بيفتح، بيوصل للخادم، بيقرأ `admin_status`) وبعدين بينادي `confirmHealthy(version)` ← بيصير current، والقديم previous، واللي قبله بينحذف. / the new app runs its health check, then calls `confirmHealthy()`: it becomes current, the old current becomes previous, older folders are deleted.
4. إذا وقع أو طلع قبل التأكيد، أو ما أكّد خلال `healthTimeout` (افتراضي 90 ث) ← اللانشر بيسكّره، `revertPending(reason)`، وبيشغّل الإصدار السابق. السبب بينحفظ بـ `last_revert` و`history`، والبرنامج بيعرضه للمدير بالتشغيل الجاي. / crash / early exit / no confirmation within the timeout: the launcher kills it, reverts with the reason recorded in `last_revert` and `history`, and starts the previous version.

**ملف الحالة خربان · Corrupted state file:** `state.json` بينكتب بشكل ذرّي (tmp ← rename) مع `.bak`. إذا خرب: منرجع للـ `.bak`؛ إذا الاتنين خربانين: منبني الحالة من علامات `.mtc_confirmed` (أعلى إصدار مؤكد = current، اللي بعده = previous، بدون pending — يعني الإصدار غير المؤكد ما بيشتغل). / Atomic writes plus `.bak`; if both are unreadable the state is rebuilt from `.mtc_confirmed` markers (highest confirmed = current, next = previous, never a pending one).

### تصميم اللانشر · Launcher design

برنامج صغير (`launcher.exe`، Dart AOT: `dart compile exe`) بيعمل شي واحد:
A tiny program (`launcher.exe`, Dart AOT via `dart compile exe`) that does exactly one thing:

```dart
import 'dart:io';
import 'package:mtc_update/mtc_update.dart';

Future<void> main() async {
  final root = Directory(File(Platform.resolvedExecutable).parent.path);
  await superviseLaunch(
    installer: SideBySideInstaller(root, maxBootAttempts: 2),
    spawn: ioProcessSpawner('mtc_superadmin.exe'),
    healthTimeout: const Duration(seconds: 90),
  );
}
```

- اختصار سطح المكتب بيأشّر على `launcher.exe`، مش على إصدار محدد. / Shortcuts point at `launcher.exe`, never at a version folder.
- اللانشر نفسه ما بيتحدّث تلقائيًا (بيتغيّر بس مع المثبّت الكامل) — هيك عطل بالتحديث ما بيكسر طريق الرجوع. / The launcher is not self-updated (only by a full installer), so a bad update can never break the way back.
- التشغيل العادي: `detached` واللانشر بيطلع فورًا. التشغيل التجريبي: بيضل يراقب لحد التأكيد أو المهلة، وبيمرّق `--mtc-update-trial` للبرنامج. / Normal start: detached, launcher exits immediately. Trial start: supervised until confirmation or timeout; the app receives `--mtc-update-trial`.
- عداد المحاولات بينزاد **قبل** التشغيل، فلو انطفى الجهاز أو اللانشر نفسه وقع، التشغيل الجاي بيعرف وبيرجع بعد `maxBootAttempts`. / The boot counter is incremented *before* starting, so power loss or a launcher crash still leads to a revert after `maxBootAttempts`.
- البرنامج لازم ينادي `confirmHealthy` بس بعد ما يتأكد إنه هو سليم. إذا الخادم مش واصل بسبب الشبكة (مش بسبب البرنامج)، القرار للبرنامج: الأفضل يأكّد بعد ما يفتح الواجهة ويتأكد إن الخلل بالشبكة، كي ما يرجع إصدار سليم لأنه الإنترنت مقطوع. / Call `confirmHealthy` only once the app knows *it* is fine; if the server is unreachable for network reasons, prefer confirming once the UI is up so an offline admin does not revert a good build.

### الرجوع اليدوي الموقّع · Signed rollback

بيان رجوع (`--rollback-from`) بيمرق نفس المسار: `verify` ← `stage` ← تجربة ← `confirmHealthy`. إذا الهدف هو نفسه الـ previous، بينفك من جديد من الملف الموقّع (ما منثق بالمجلد القديم).
A rollback manifest goes through the same path (verify → stage → trial → confirm). If the target equals the kept previous version it is re-extracted from the signed artifact.

---

## 6. التطوير · Development

```powershell
dart analyze
dart test
```

الاختبارات بتعمل مفاتيح مؤقتة بمجلدات temp بس — ما في مفتاح حقيقي، وما بتكتب شي بـ `%USERPROFILE%\.mtc-iptv`. ملفات `*.key` و`manifest.sig` مستثناة بـ `.gitignore`.
Tests create throw-away keys in temp folders only; nothing is written to `%USERPROFILE%\.mtc-iptv`. `*.key` and `manifest.sig` are git-ignored.
