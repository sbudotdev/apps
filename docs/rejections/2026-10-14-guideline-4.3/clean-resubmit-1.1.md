# Sbu Clean 1.1: messaggio nel Resolution Center al reinvio (23/10)

Da incollare nel thread del rifiuto, dopo l'invio della 1.1 (build 7).

---

Hello,

Thank you for your answer of 22 October. Following your advice to submit an app with distinct content and functionality, I have not argued the 1.0 again: I changed the app, and resubmitted it as version 1.1 (build 7). I would be grateful if the reviewer could read this note together with the build.

What changed since the rejected 1.0 (build 3)

1. Blurry photos: every photo's sharpness is measured on the device; shaken, out-of-focus and pocket shots are gathered in one list to review. Favourites and screenshots are never included.
2. Chat photos: images saved by WhatsApp, Telegram and other chat apps, found through the albums those apps keep in Photos, in one grid.
3. Similar videos: a frame of every video is compared on the device with Vision, so copies and retakes of the same scene are grouped, each playable before choosing.
4. "On this day" calendar: a month view marking every day that has photos from past years, each day opening its own review queue.
5. Duplicate contacts: people saved twice (same number in any format, same email or same name) are merged into one contact on request. Contacts access is asked only when the user opens this screen, and before every merge the original contacts are saved as a vCard file in the Files app, so nothing can be lost.

The binary changed accordingly: about 1,900 lines of the app's own code were added since 1.0, which now has about 7,300 lines of its own. Swiping was rebuilt to preload and decode the next photos, the screenshots were remade on real photos, and the description now opens with what the app does.

Updated answers where they changed

- Testing: builds 5, 6 and 7 went through TestFlight on my own iPhone, and every screen is driven by UI tests with an accessibility audit on the iPhone 16e and 17 Pro Max simulators. Still internal only, no external testers. Fixed during this beta: swiping stuttered on the iPhone because each photo loaded only when it reached the top of the stack; a tall screenshot's hidden edge caught taps meant for the "Select all" button; some text was clipped at large sizes.
- Suite: Sbu Clean is still the only app on my account that scans the whole Photos library or uses Contacts. My other apps do unrelated things: a habit tracker, a QR scanner, a subscription tracker, a Bluetooth finder for lost headphones. None could host these features.
- Shared code: the shared package, SbuKit, is my own design system (about 4,000 lines: colours, type, buttons, the large-number component and the Settings screen). It holds no photo, contact, Vision or storage logic. Nothing is shared with any third party, and no template or generation service was used.

I build these apps myself as free alternatives to paid utilities: Sbu Clean has no subscription, no in-app purchase, no limit per day and no ads, and analyses everything on the device. If anything still looks too close to another app, I would really appreciate knowing which part, so I can change it.

Thank you for your time.

Matteo Giuditta
