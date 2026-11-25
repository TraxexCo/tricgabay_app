# UI polish and motion — design

Date: 2026-11-21. Direction approved in conversation: **polish the current look** (Philippine-flag
palette, Poppins), plus motion throughout, including a logo-to-login launch animation and
micro-interactions such as loading buttons and an animated slide-to-confirm.

## Goals

- Every screen feels like one app: the same button sizes, corner radii, spacing, input style,
  sheets, dialogs and page transitions.
- Motion explains what happened. Loading shows on the control that was pressed, success is
  confirmed visually, and content enters in a calm stagger instead of popping in.
- Launch is seamless: the phone's splash screen matches Flutter's first frame, then the logo
  shrinks up and the login form glides in.

## Non-goals and anti-goals

- No new colour palette, font or brand.
- No Lottie or Rive. Built-in Flutter animation covers everything here.
- Motion that slows people down is a failure: nothing blocks input for longer than about 400 ms.
- Ignoring the OS "remove animations" setting is a failure: every animation must respect
  `MediaQuery.disableAnimations` and show the final state immediately.

## Approach (decided)

1. **Theme first.** Add the missing component themes (FilledButton, which 44 call sites use
   unthemed, plus IconButton, SegmentedButton, ListTile, BottomSheet, ProgressIndicator,
   Switch, NavigationBar and FAB) and page transitions (FadeForwards on Android, Cupertino on
   iOS). One change polishes every screen.
2. **Motion kit** in `lib/core/motion/`:
   - Tokens for durations and curves, plus a reduced-motion check.
   - `FadeSlideIn` and a staggered list helper.
   - `PressableScale` for tappable cards.
   - `AnimatedCheck` success mark.
   - `SkeletonBox` shimmer for loading placeholders.
   - `AnimatedCount` for money and counters.
3. **Micro-interactions:**
   - AppButton cross-fades between its label and a spinner and shrinks slightly when pressed.
   - The booking-detail action buttons show a spinner instead of the word "Saving".
   - Slide-to-confirm gets a shimmer hint, springs back when released early, fills green with
     an animated check and a haptic tap on success, and shakes on failure.
4. **Launch:**
   - `flutter_native_splash` sets the native splash to the same background and logo.
   - The splash screen keeps the logo in the same place while the session restores.
   - Signed-out returning users: the logo flies (Hero) into a smaller logo at the top of login,
     whose fields and buttons enter in a stagger.
   - First-time users still see onboarding.
5. **Screen pass:** entrance stagger and pressable cards on list, dashboard and detail screens;
   animated success on booking confirmation and payment confirmation; skeletons where lists
   load.

## Left to the builder

Exact durations within the tokens, which lists get stagger, and per-screen spacing fixes found
while previewing.
