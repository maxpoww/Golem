// Focus -> Visibility bridge.
//
// Facebook/Messenger only post a *system* notification when the page reports
// document.visibilityState === "hidden". On Windows/macOS Chromium marks a
// window "occluded" (hidden) when it's covered/unfocused; on Linux/Wayland
// Chromium does NO occlusion tracking, so an unfocused or off-workspace window
// stays "visible" forever and those sites never notify (they only ding).
//
// Chromium *does* report window focus/blur on Linux, though (that's why
// WhatsApp Web — which gates on focus — works). So we bridge the gap: report
// the page as "hidden" whenever the browser window is not focused, and
// "visible" when it is. Net effect: FB/Messenger behave like WhatsApp — notify
// while you're looking elsewhere, stay quiet while you're reading them.
//
// Runs in the MAIN world at document_start so the override is in place before
// the page's own scripts read visibilityState.
(() => {
  "use strict";

  // Seed from the real focus state; a freshly-opened background tab counts as
  // hidden too (respect the genuine hidden state when the tab isn't foreground).
  let hidden = document.visibilityState === "hidden" || !document.hasFocus();

  const redefine = (name, getter) => {
    try {
      Object.defineProperty(document, name, { configurable: true, get: getter });
    } catch (_) {
      /* another instance already defined it; ignore */
    }
  };

  redefine("hidden", () => hidden);
  redefine("visibilityState", () => (hidden ? "hidden" : "visible"));
  // webkitHidden/webkitVisibilityState are still read by some older paths.
  redefine("webkitHidden", () => hidden);
  redefine("webkitVisibilityState", () => (hidden ? "hidden" : "visible"));

  const setHidden = (next) => {
    if (next === hidden) return;
    hidden = next;
    // Notify the page's own listeners so it re-evaluates (mark-as-read,
    // notification gating, etc.) exactly as if the tab were shown/hidden.
    document.dispatchEvent(new Event("visibilitychange"));
    document.dispatchEvent(new Event("webkitvisibilitychange"));
  };

  // Window focus/blur is what Chromium DOES report reliably on Linux.
  window.addEventListener("blur", () => setHidden(true), true);
  window.addEventListener("focus", () => setHidden(false), true);

  // If the tab is genuinely backgrounded/minimized, Chromium fires the native
  // visibilitychange with document actually hidden — honor that too. We read
  // our own override, so detect the real state via hasFocus at that moment.
  document.addEventListener(
    "visibilitychange",
    () => {
      // Only react to the *native* transition to visible while focused; the
      // hidden direction is already covered by blur.
      if (document.hasFocus()) setHidden(false);
    },
    true
  );
})();
