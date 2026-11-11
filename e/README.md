# نجوم الملعب · Saha Stars

لعبة كرة قدم خماسية في ملف HTML واحد، تشتغل في المتصفح وعلى الجوال، ومعها تطبيق أندرويد.

An original 5-a-side football game in a single HTML file, for browser and phone, with an Android app wrapper.

## المميزات · Features

- **المباراة:** تحكم باللمس أو بالكيبورد، وتمريرات وتسديدات وكرات ساقطة وعرضيات ورأسيات ومهارات.
- **الكرات الثابتة:** ركنيات وضربات حرة بحائط وتقويس، وضربات جزاء، وبطاقات صفراء وحمراء.
- **اللياقة والتشكيل:** لياقة للاعبين وتبديلات، وأربع تشكيلات، وثلاثة أساليب لعب.
- **المسيرة:** دوري من 6 فرق مع صعود وهبوط، وسوق انتقالات، وتدريب.
- **التعليق:** حماسي بالعربي والإنجليزي والتركي، ويُقرأ بصوت الجهاز. وتقدر تسجّل صوتك كمعلّق من تبويب «النادي».
- **بعد الهدف:** إعادة بالتصوير البطيء، واحتفال خاص لكل لاعب.

## التشغيل · Run

افتح `njoom-almalab.html` في أي متصفح حديث.

Open `njoom-almalab.html` in any modern browser.

## تطبيق أندرويد · Android app

متطلبات البناء:

- JDK 17 أو أحدث
- Android SDK فيه platform وbuild-tools، ومساره في `ANDROID_HOME`

Requirements: JDK 17+ and the Android SDK (a platform and build-tools), with `ANDROID_HOME` set.

```powershell
powershell -ExecutionPolicy Bypass -File android\build.ps1
```

السكربت يبني ملف `njoom-almalab.apk` بدون Gradle، وينشئ مفتاح توقيع في `android/` أول مرة تشغّله. احتفظ بالمفتاح ولا ترفعه للمستودع.

The script builds `njoom-almalab.apk` without Gradle and creates a signing key in `android/` on first run. Keep that key private.

## صوتك كمعلّق داخل اللعبة · Built-in voice clips

1. حط ملفات الصوت في مجلد `voice/`.
2. اكتب أسماءها في `VBUILT` داخل `njoom-almalab.html`.

مثال:

```js
const VBUILT={goal:['voice/goal1.mp4'],shot:['voice/shot1.mp4']};
```

مجلد `voice/` مستثنى من المستودع.

Put audio files in `voice/` and list them in `VBUILT` in `njoom-almalab.html`. The `voice/` folder is git-ignored.
