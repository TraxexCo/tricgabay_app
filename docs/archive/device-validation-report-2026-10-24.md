# Tric-Gabay Batch 4A device validation report

**Opened:** 2026-10-24 (Asia/Manila)  
**Branch / baseline commit:** `master` / `be032162bdbbd740292bca29444fe4e52978ec08`  
**Current status:** **BLOCKED — no authorized physical Android device is connected**

## Scope and safety

This report distinguishes physical-device evidence from code inspection and
automated desktop tests. No APK was installed, no application data was cleared,
no device setting was changed, no remote Supabase project was modified, and no
PayMongo, email, or push-notification request was performed.

All pre-existing uncommitted work remains preserved. No reset, clean, stash,
discard, commit, push, merge, migration deployment, or Edge Function deployment
was performed.

## Device and tool inventory

| Item | Result |
|---|---|
| ADB | **PASS** — Android Debug Bridge 1.0.41, platform-tools 37.0.0 |
| ADB server | **PASS** — started successfully on the Windows host |
| Connected physical devices | **BLOCKED** — `adb devices -l` returned no devices |
| Authorized installation target | **BLOCKED** — no device identity is available to authorize |
| Second physical device | **BLOCKED** — none detected |
| Existing debug APK | **PASS (build artifact only)** — version `1.0.0+1`, package `com.tricgabay.app` |

Because no device is connected, device model, Android version, API level,
screen size, predictive-Back support, installed app version, and existing app
data cannot yet be recorded.

## Pre-installation code inspection

| Area | Result | Evidence type |
|---|---|---|
| Predictive Back manifest opt-in | **PASS** | Code inspection: `android:enableOnBackInvokedCallback="true"` |
| Shell Back handling | **PASS (automated only)** | Existing `PopScope` implementation and prior widget regressions; not physical evidence |
| Fine/coarse location declarations | **PASS** | Manifest inspection |
| Location foreground-service declarations | **PASS** | Manifest inspection |
| Driver foreground location notification | **PASS** | Code inspection of `ActiveTripTrackingService` |
| Authoritative active-trip reload | **PASS (design inspection only)** | Session restore followed by remote synchronization |
| Offline command safety | **PASS (automated/design only)** | Only idempotent notification-read commands may be replayed |
| Tracking stop on completion/cancellation/logout | **PASS (code inspection only)** | Remote sync and session cleanup call tracking stop |
| Notification/deep-link Back parent | **PASS (design inspection only)** | Validated notification routes are pushed rather than replacing history |
| Local-only backend target | **BLOCKED** | Default debug configuration points to a hosted Supabase project |

The normal debug build must not be installed for this batch without an
explicitly isolated backend configuration. A physical test build should use an
approved local endpoint (for example through ADB reverse) or another explicitly
approved non-production test backend. The hosted default is not authorized by
Batch 4A.

## Physical scenarios

| Scenario | Status | Reason |
|---|---|---|
| Back from child page | **BLOCKED** | No physical device |
| Back dismisses dialog/sheet | **BLOCKED** | No physical device |
| Tab-history Back | **BLOCKED** | No physical device |
| Notification/deep-link Back | **BLOCKED** | No physical device and external push delivery is outside scope |
| Tourist/driver/admin Back consistency | **BLOCKED** | No physical device |
| Predictive-Back gesture | **BLOCKED** | No supported physical Android device identified |
| Controlled process termination and relaunch | **BLOCKED** | No physical device |
| Authentication and active-trip recovery | **BLOCKED** | No physical device and no authorized isolated backend connection |
| Offline restart and safe recovery | **BLOCKED** | No physical device |
| Logout/account-switch residue | **BLOCKED** | No physical device |
| Permission allow/deny/change | **BLOCKED** | No physical device |
| Approximate versus precise location | **BLOCKED** | No physical device |
| Foreground/background/screen-lock tracking | **BLOCKED** | No physical device |
| Process/device-restart tracking behavior | **BLOCKED** | No physical device |
| Network loss and reconnection | **BLOCKED** | No physical device |
| Tracking stops after terminal state/logout | **BLOCKED** | No physical device |
| Full tourist/driver two-device trip | **BLOCKED** | No devices detected; two are required |
| Device accessibility/UI resilience | **BLOCKED** | No physical device |

No physical scenario is reported as passed based on emulator, desktop widget
tests, mocks, or source inspection.

## Required continuation setup

1. Connect one, preferably two, Android phones by USB.
2. Enable Developer options and USB debugging on each phone.
3. Accept the computer RSA authorization prompt on each phone.
4. Explicitly authorize the detected device serial number(s) as Batch 4A test
   targets and authorize installation of `com.tricgabay.app` without clearing
   existing application data.
5. Keep the phones unlocked for the initial permission and predictive-Back
   checks.
6. Before installation, configure an isolated backend path. Do not use the
   hosted project implicitly.

## Stop condition

Batch 4A is not complete and the Android workflows are not yet evidenced as
ready for Batch 4B. Work must resume only after at least one physical device is
connected and explicitly authorized. Two-device workflow validation requires
two authorized physical devices.
