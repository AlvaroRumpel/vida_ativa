import 'dart:ui_web' as ui_web;

/// Returns true when the iOS install banner should be shown.
/// Uses dart:ui_web BrowserDetection (no dart:js needed).
/// On iOS Safari, returns true. Once installed as PWA, the app
/// opens in standalone mode (not Safari) so this never fires.
bool isIosInstallBannerNeeded() {
  return ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs;
}
