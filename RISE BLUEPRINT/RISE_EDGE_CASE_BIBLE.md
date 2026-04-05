# ============================================================
# RISE — AI ALARM CLOCK
# THE COMPLETE EDGE CASE & FAILSAFE BIBLE
# Version 1.0 — Required reading before Parts 3–12
# ============================================================
# COMMAND TO AI CODING AGENT:
# Read this document IN FULL before implementing any service
# in Parts 3 through 12. Every numbered edge case here has a
# defined RISE Response. When you encounter the relevant code
# location, implement the response exactly as specified.
# This document is LAW for the project.
# ============================================================

---

# CATEGORY 1: AUDIO ROUTING — THE EARPIECE PROBLEM

## EC-1.1: User sleeps with wired earphones plugged in
SCENARIO: User listens to music to fall asleep. Falls asleep mid-podcast.
Earphones may be: (a) in ears — risk of ear damage at full alarm volume,
(b) dangling off pillow — alarm barely audible, (c) pulled phone to floor.

RISE RESPONSE:
- At alarm fire: query AudioManager for current output route
- If wired device detected: CAP earphone/aux volume at 40% (ear safety)
- SIMULTANEOUSLY activate phone speaker at full alarm volume via
  AudioManager.STREAM_ALARM (separate from media stream, not affected by wired device)
- On iOS: AVAudioSession.overrideOutputAudioPort(.speaker) forces speaker
  regardless of wired device state
- Display on-screen: "Earphones detected — alarm playing on speaker too"
- Log event for analytics: audio_route_override: wired

IMPLEMENT IN: alarm_service.dart (Part 3), audio_route_manager.dart (Part 3)

---

## EC-1.2: Bluetooth earphones connected but physically out of ears
SCENARIO: AirPods/Galaxy Buds paired. They fell out during sleep.
Alarm routes entirely to Bluetooth device sitting on the nightstand
or lost in the sheets. Volume is muffled/inaudible.

RISE RESPONSE:
- At alarm fire: check if audio output is Bluetooth (A2DP or HFP profile)
- Force override to phone speaker using STREAM_ALARM on Android (this
  stream DOES override Bluetooth routing when used with FLAG_FROM_SYSTEM)
- On iOS: same AVAudioSession.overrideOutputAudioPort(.speaker) call
- This is NON-NEGOTIABLE — Bluetooth earphones NEVER receive the alarm
  stream without also having the speaker active simultaneously
- Log event: audio_route_override: bluetooth_earphone

IMPLEMENT IN: alarm_service.dart (Part 3)

---

## EC-1.3: Bluetooth earphones die mid-sleep (battery depleted)
SCENARIO: User sleeps with 15% battery Buds. They die at 2am.
iOS may silently stop audio playback. Android typically reroutes,
but behavior is inconsistent across manufacturers.

RISE RESPONSE:
- The foreground alarm service monitors AudioManager.getDevices()
  every 10 seconds while alarm is actively firing
- If BT device DISCONNECTS while alarm is playing: immediately
  re-initialize audio session on speaker, restart audio from
  beginning of alarm sound, increase volume by 10%
- This is a background thread in the alarm foreground service

IMPLEMENT IN: alarm_service.dart (Part 3)

---

## EC-1.4: Phone connected to Bluetooth speaker in another room
SCENARIO: User had music on a living room Bluetooth speaker.
Falls asleep. Alarm fires through the speaker downstairs.
Nobody in the bedroom hears it.

RISE RESPONSE:
- Same Bluetooth override logic as EC-1.2
- Alarm ALWAYS plays through phone speaker regardless of BT device type
- At alarm setup time, if BT device is connected: toast advisory
  "Your audio is routed to [Device Name]. RISE will play the
  alarm through your phone speaker when it fires."

IMPLEMENT IN: alarm_setup_screen.dart (Part 3), alarm_service.dart (Part 3)

---

## EC-1.5: Phone connected to car Bluetooth (parked in driveway)
SCENARIO: Phone auto-reconnects to car BT every morning.
Alarm fires through car speakers. User cannot hear from bedroom.

RISE RESPONSE:
- Detect BT device name for common car identifiers at alarm set time
  (keywords: car, auto, honda, toyota, bmw, ford, audio, vehicle)
- If car BT detected: advisory the night before the alarm
- Same speaker override at alarm fire time
- Car BT detection is informational only — the override is universal

IMPLEMENT IN: alarm_service.dart (Part 3)

---

## EC-1.6: User has Bluetooth hearing aids
SCENARIO: User requires hearing aids to hear. Hearing aids are BT-paired.
The speaker override would route alarm away from their only hearing device.

RISE RESPONSE:
- Accessibility settings: "I use hearing aids" toggle
- When this is ON: DO NOT override BT routing — hearing aids ARE the speaker
- Instead: maximize vibration AND activate smart lights as primary wake channels
- Never forcibly route away from hearing aids

IMPLEMENT IN: accessibility_settings.dart (Part 11), alarm_service.dart (Part 3)

---

## EC-1.7: Phone connected to TV/soundbar via AirPlay or Chromecast
SCENARIO: User was casting audio before bed. Alarm fires through TV.
If TV is in living room, bedroom user cannot hear it.

RISE RESPONSE:
- AirPlay/Chromecast casting sessions are treated identically to BT speakers
- STREAM_ALARM on Android always uses the onboard speaker
- AVAudioSession.overrideOutputAudioPort(.speaker) on iOS handles this
- No special detection needed — the override is universal

IMPLEMENT IN: alarm_service.dart (Part 3)

---

## EC-1.8: Phone volume is set to zero (user always uses earphones)
SCENARIO: User's media/ringtone volume is at zero. Alarm fires silently.
This is the most common silent alarm failure that users never know happened.

RISE RESPONSE:
- CRITICAL: STREAM_ALARM volume is INDEPENDENT of media/ringtone volume
- At alarm service init: set STREAM_ALARM to min(userSetting, 50%) at minimum
  — we guarantee at least 50% alarm stream volume even if user set it lower
- At alarm fire: set STREAM_ALARM to AppConstants.alarmInitialVolumePercent (40%)
  — this OVERRIDES whatever the user set for alarm volume in system settings
- On iOS: Critical Alerts bypass silent switch AND volume controls
- Pre-bedtime check: if system volume is 0 AND alarm stream is also 0:
  show advisory "Your phone is fully muted. RISE will still play at 40%
  volume when your alarm fires — alarm volume is separate from phone volume."

IMPLEMENT IN: alarm_service.dart (Part 3), alarm_setup_screen.dart (Part 3)

---

# CATEGORY 2: PHYSICAL PHONE POSITION DURING SLEEP

## EC-2.1: Phone face-down on nightstand
No special handling needed. Alarm fires normally.
Screen interaction requires user to flip phone — acceptable UX.

---

## EC-2.2: Phone slides under pillow
SCENARIO: User puts phone under pillow to feel vibration.
Risks: (a) overheating potential fire hazard, (b) muffled audio,
(c) blocked camera for PPG.

RISE RESPONSE:
- Temperature monitoring at alarm fire time:
  Android: PowerManager.thermalStatus — if THERMAL_STATUS_SEVERE or higher:
    show red warning "Your phone is dangerously hot. Move it off your pillow."
  iOS: ProcessInfo.thermalState — if .critical: same warning
- Audio: volume escalation naturally compensates for muffling
- PPG: signal quality check handles blocked camera gracefully (EC-3.5)
- Bedtime advisory (if ambient light is near-zero but accelerometer
  shows phone was moved/adjusted at bedtime): "Sleeping with your phone
  under a pillow can cause overheating. Place it on the nightstand."
  — show ONCE, never repeatedly

IMPLEMENT IN: alarm_service.dart (Part 3), sleep_detection_service.dart (Part 5)

---

## EC-2.3: Phone falls off nightstand during sleep
SCENARIO: Phone tumbles to floor. Audio muffled by carpet.
User is a heavy sleeper.

RISE RESPONSE:
- Fall detection: accelerometer spike (>15 m/s²) followed by sustained
  stillness at a different orientation = likely dropped
- If fall detected AFTER sleep onset but BEFORE alarm: log event,
  increase this session's maximum volume ceiling by 15% as compensation
- Cannot fully solve audio muffling on carpet — haptics is the backup channel
- Fall event logged in sleep session for product analytics

IMPLEMENT IN: sleep_detection_service.dart (Part 5)

---

## EC-2.4: Phone is in another room (charging in kitchen)
SCENARIO: User leaves phone far from bedroom. Sleep detected (phone still)
but user not near phone when alarm fires.

RISE RESPONSE:
- Sleep onset requires: screen dark + phone still + alarm was previously
  set — NOT just stillness alone
- If phone hasn't been touched for >3 minutes after alarm fires → escalate
  immediately (don't wait 15 min) to full volume + buddy
- We cannot force proximity — but we can document in setup:
  "For RISE to work, keep your phone within arm's reach while sleeping."
- First-time setup tip shown once in onboarding

IMPLEMENT IN: alarm_service.dart (Part 3)

---

## EC-2.5: Phone battery low when alarm is about to fire
SCENARIO: User forgot to charge. Battery at 15% at 5am. Alarm at 6am.

RISE RESPONSE:
- Foreground service monitors battery level continuously
- At 20%: persistent notification "Battery at 20%. Plug in RISE to
  guarantee your alarm fires tonight."
- At 10%: urgent notification "Battery critical. Alarm may not fire."
- At 5% AND alarm is within 4 hours:
  → Fire a PRE-ALARM warning NOW: "Your battery is dying and your
    [6:00 AM] alarm is in 4 hours. Do you want RISE to wake you now
    instead?" — user can confirm or dismiss
  → Log battery level at every alarm fire for diagnostics

IMPLEMENT IN: alarm_service.dart (Part 3), battery_monitor.dart (Part 3)

---

## EC-2.6: Pet interacts with phone (dog, cat)
SCENARIO: Pet picks up or paws at phone. Motion + accidental screen taps.

RISE RESPONSE:
- Wake dismissal REQUIRES: screen on + meaningful touch interaction
  (tap a specific game element, not random screen touch)
- Random taps anywhere on screen do NOT dismiss alarm
- Motion alone never equals dismissal — interaction must be intentional
- Sleep session continues until meaningful interaction detected

IMPLEMENT IN: alarm_screen.dart (Part 7), all wake_games (Part 6)

---

# CATEGORY 3: BIOMETRIC EDGE CASES

## EC-3.1: User has a fever
SCENARIO: HR elevated 10-20 BPM above enrolled baseline. PPG mismatch.
RISE should not aggressively accuse sick person of being someone else.

RISE RESPONSE:
- After 2 consecutive failed PPG verifications: auto-switch to PIN fallback
- Message: "Heart rate doesn't match your profile — this can happen if
  you're not feeling well. Enter your PIN instead."
- NEVER show aggressive "Wrong person detected" language
- Log event: biometric_fallback_reason: hr_mismatch (for analytics)

IMPLEMENT IN: biometric_service.dart (Part 4)

---

## EC-3.2: User exercised before sleep (elevated HR)
Same response as EC-3.1. Additionally:
- Morning HR tolerance is ±18 BPM (wider than day tolerance of ±12 BPM)
- Sleep HR is naturally lower; post-exercise HR recovers over hours
- 2-failure PIN fallback handles edge cases where HR hasn't normalized

IMPLEMENT IN: biometric_service.dart (Part 4), app_constants.dart (Part 1, update)

---

## EC-3.3: User on beta-blockers or HR-altering medication
SCENARIO: Beta-blockers reduce resting HR significantly (60→45 BPM).
Enrolled profile becomes stale after medication starts.

RISE RESPONSE:
- Health settings: "I take medication that affects heart rate" toggle
- This activates Wide Tolerance Mode: ±25 BPM instead of ±12 BPM
- Monthly reminder to re-enroll if profile is >3 months old
- If failed verifications exceed 3 in one week: "Your heart rate profile
  may need updating. Re-enroll for best accuracy." — with re-enroll CTA

IMPLEMENT IN: biometric_service.dart (Part 4), settings_screen.dart (Part 11)

---

## EC-3.4: User has atrial fibrillation (irregular heartbeat)
SCENARIO: AFib produces "irregularly irregular" intervals.
Standard HR matching using BPM average is unreliable.

RISE RESPONSE:
- PPG signal analysis: compute inter-beat interval (IBI) variance
- If IBI variance score exceeds arrhythmia threshold: skip BPM matching,
  fall back to waveform pattern similarity instead
- Accessibility setting: "I have an irregular heartbeat" — permanently
  disables HR matching, uses PIN-only mode
- Never attempt to diagnose — RISE detects irregularity but does NOT
  display "possible AFib" to the user (medical liability)

IMPLEMENT IN: ppg_service.dart (Part 4)

---

## EC-3.5: User has poor circulation / Raynaud's disease
SCENARIO: Cold fingers with weak blood perfusion. PPG signal extremely
weak or nonexistent.

RISE RESPONSE:
- Compute PPG signal quality score (signal-to-noise ratio) alongside reading
- If SNR < 40% after 8 seconds: show gentle message
  "Signal too weak — try warming your hands, or enter your PIN instead"
- Offer PIN fallback immediately — no penalty, no accusation
- This is the same path as EC-3.1 / EC-3.2 — unified graceful fallback

IMPLEMENT IN: ppg_service.dart (Part 4)

---

## EC-3.6: User has darker skin tone (PPG bias)
SCENARIO: Documented bias — melanin absorbs red light differently.
Single-channel red PPG can be significantly less accurate.

RISE RESPONSE:
- Use BOTH red AND green channels from camera for PPG processing
  (green channel less affected by melanin — better cross-skin accuracy)
- Tolerance window is PER-USER calibrated from enrollment variance
  (not a hardcoded global threshold)
- If enrollment shows high reading variance: tolerance auto-expands
- No race or skin tone data is ever collected — algorithm self-calibrates
  from the user's own enrollment data

IMPLEMENT IN: ppg_service.dart (Part 4)

---

## EC-3.7: User has artificial nails, bandage, or cast on hand
SCENARIO: Usual finger unavailable. Different finger has different
waveform pattern. PPG fails.

RISE RESPONSE:
- During enrollment: "RISE recommends enrolling your index finger,
  but you can also add a backup finger."
- Enrollment supports up to 2 finger profiles per user
- At alarm time: if first profile fails → show "Try a different finger"
- After 2 profile attempts: PIN fallback
- Log: biometric_fallback_reason: profile_mismatch

IMPLEMENT IN: ppg_service.dart (Part 4), biometric_enrollment.dart (Part 11)

---

## EC-3.8: User has tremors (Parkinson's, essential tremor)
SCENARIO: Cannot hold finger still for 8 seconds.
Cannot complete trace game reliably.

RISE RESPONSE (BIOMETRIC):
- Extended capture window: up to 15 seconds (vs. standard 8)
- Motion averaging filter: smooth out high-frequency tremor noise
  from the PPG signal — use a low-pass filter at 2Hz cutoff
- If signal quality is still insufficient: 3-attempt limit then PIN

RISE RESPONSE (WAKE GAMES):
- Accessibility setting: "I have a movement condition"
- Effect: trace game PERMANENTLY removed from rotation
- Game timers doubled in duration
- Touch targets enlarged to 2× standard size
- Word unscramble uses drag-and-drop with large tiles

IMPLEMENT IN: ppg_service.dart (Part 4), wake_games (Part 6), settings (Part 11)

---

## EC-3.9: User is deaf or hard of hearing
SCENARIO: Alarm sound is useless as wake mechanism.
Must rely entirely on non-audio channels.

RISE RESPONSE:
- Accessibility setting: "I am deaf / hard of hearing"
- Alarm behavior changes:
  → Maximum vibration (continuous alternating pattern, not single buzz)
  → Screen flashes: full brightness white → dark, 1Hz rate (NOT rapid strobe)
  → Smart lights: immediate full brightness activation
  → Buddy auto-notified at alarm fire (no delay — this IS their sound)
- Volume setting in alarm setup is hidden for this accessibility mode
- Note: rapid screen strobe (>3Hz) is disabled due to photosensitivity risk

IMPLEMENT IN: alarm_service.dart (Part 3), alarm_screen.dart (Part 7)

---

## EC-3.10: User has photosensitive epilepsy
SCENARIO: ANY flashing could trigger a seizure.
This is a life-safety issue.

RISE RESPONSE:
- Accessibility setting: "I have photosensitive epilepsy" (separate from deaf mode)
- When enabled: ALL screen flashing / strobing disabled universally
- Smart lights: steady brightness only (no flash pattern)
- Wake game: no flashing animations on correct/incorrect answers
- This setting OVERRIDES all other animation settings in the app
- If BOTH "deaf" AND "photosensitive epilepsy" are set: vibration +
  steady bright screen + steady lights + immediate buddy notification only

IMPLEMENT IN: alarm_screen.dart (Part 7), wake_games (Part 6), app_theme.dart (Part 1 update)

---

## EC-3.11: User has cognitive disability
SCENARIO: Cannot complete math, word, or memory games reliably.

RISE RESPONSE:
- Accessibility setting: "Simple wake confirmation"
- Wake challenge replaced with: tap 5 large numbered buttons in
  sequence (1→2→3→4→5), each >60px touch target
- No timer
- No wrong-answer penalty
- High contrast colors, no animations
- Clear audio instruction: "Tap 1, then 2, then 3..." (TTS)

IMPLEMENT IN: wake_games (Part 6), settings (Part 11)

---

# CATEGORY 4: SLEEP DETECTION FAILURES

## EC-4.1: User sleeping in moving vehicle (train, plane, car)
SCENARIO: Constant rhythmic motion from vehicle. Accelerometer never reads
"still." Sleep onset never logged. Journey crosses midnight.

RISE RESPONSE:
- Pattern discrimination: vehicle motion = regular sinusoidal oscillation
  at 0.5–2Hz with consistent amplitude
- Tossing/turning motion = irregular, variable amplitude, non-periodic
- If vehicle motion pattern detected for >10 minutes:
  → Switch to SCREEN-BASED sleep detection only (screen-off = sleep proxy)
  → Display: "Looks like you're moving — RISE switched to travel mode."
- Alarm fires normally regardless of sleep detection accuracy
- Vehicle motion is NOT logged as "awake" — it's logged as "motion_travel"

IMPLEMENT IN: sleep_detection_service.dart (Part 5)

---

## EC-4.2: Baby or partner's motion detected as user's motion
SCENARIO: Baby in same room/bed grabs phone or moves near it.
Accelerometer detects motion but user is still asleep.

RISE RESPONSE:
- Brief motion events (<15 seconds) during established sleep window
  are NOT sleep-ending events — they are logged as "micro-waking"
- Only SUSTAINED interaction (screen on + app open for >3 minutes)
  triggers end of sleep session
- A baby touching the phone's screen does not unlock it and cannot
  interact with the app meaningfully

IMPLEMENT IN: sleep_detection_service.dart (Part 5)

---

## EC-4.3: User on washing machine / dryer vibration
SCENARIO: Phone placed on or near vibrating appliance.
Consistent mechanical vibration reads as motion.

RISE RESPONSE:
- Same rhythmic vibration detection as EC-4.1
- High-frequency mechanical vibration (>5Hz, consistent amplitude)
  is filtered out as "ambient vibration" — does NOT prevent sleep detection

IMPLEMENT IN: sleep_detection_service.dart (Part 5)

---

## EC-4.4: User wakes at 3am to use bathroom, checks phone, goes back to sleep
SCENARIO: Brief phone interaction mid-sleep. Should NOT end sleep session.
Should NOT reset sleep onset timestamp.

RISE RESPONSE:
- Phone interactions <5 minutes during sleep window: logged as "night waking"
  micro-event — does NOT end the sleep session
- Sleep session continues after brief interaction
- Night waking events are tracked as sleep quality metric
  (frequency of night wakings correlates inversely with sleep quality)
- Only alarm dismissal OR sustained use >5 minutes ends sleep session

IMPLEMENT IN: sleep_detection_service.dart (Part 5)

---

## EC-4.5: User pulls an all-nighter (never sleeps)
SCENARIO: No sleep onset detected. But alarm is set for 8am.

RISE RESPONSE:
- If no sleep onset logged by alarm fire time:
  → Fire alarm normally with NO sleep verification requirement
  → No biometric match needed (no sleep = no "did they sleep?" check)
  → Wake game still required (this is the anti-circumvention layer)
- Do not show "You didn't sleep" message — unnecessary guilt
- Log session as "no_sleep_detected" for analytics only

IMPLEMENT IN: alarm_service.dart (Part 3), sleep_detection_service.dart (Part 5)

---

## EC-4.6: Shift worker — sleeps at 8am, wakes at 4pm
SCENARIO: Standard night=sleep assumption is wrong for shift workers.

RISE RESPONSE:
- Sleep detection is PURELY behavior-based (screen off + still)
  — NOT time-of-day based
- Works correctly for any sleep schedule without special configuration
- Alarm timing: user sets alarm time regardless of AM/PM convention
- Sleep window: looks for sleep onset in the 12 hours BEFORE any alarm

IMPLEMENT IN: sleep_detection_service.dart (Part 5)

---

## EC-4.7: User naps during the day
SCENARIO: 30-minute nap alarm. Should RISE run full biometric + wake game?

RISE RESPONSE:
- Alarm type selector in setup: "Regular Alarm" vs. "Nap"
- Nap mode behavior:
  → Gentle volume ramp (starts at 20%, not 40%)
  → Maximum 1 snooze allowed
  → NO biometric check
  → Simple "I'm Up" single-tap dismissal (no full wake game)
  → No buddy notification
  → Sleep logged as "nap" with separate quality metrics

IMPLEMENT IN: alarm_model.dart (Part 2 update), alarm_service.dart (Part 3),
             alarm_screen.dart (Part 7)

---

## EC-4.8: User is already awake when alarm fires (woke up early)
SCENARIO: User is making coffee when alarm fires. They're not groggy.
The wake game feels annoying and pointless.

RISE RESPONSE:
- "Early Start" button available 30 minutes before any scheduled alarm
- Shows in app home screen: "Your alarm is in 23 minutes — already up?"
  with "Dismiss Early" button
- Tapping "Dismiss Early" requires ONE easy question (1 math problem or
  1 general knowledge question) — confirms intentional dismissal
- No snooze count recorded. No buddy notification.
- Sleep session ends and is logged normally.

IMPLEMENT IN: home_screen.dart (Part 3 update), alarm_service.dart (Part 3)

---

## EC-4.9: User dismisses alarm then lies down and falls back asleep
SCENARIO: Dismisses 6am alarm. Brain reboots from game. Lies back "for a
minute." Falls asleep for 3 hours. No backup alarm.

RISE RESPONSE (the most important sleep behavior edge case):
- "Post-dismissal watchdog": after alarm dismissed, monitor for 15 minutes
- If phone goes dark AND motion stops within 8 minutes of dismissal:
  → Start a soft countdown: "RISE thinks you may have lain back down."
  → After 3 more minutes of inactivity: fire a secondary "backup alert"
    — gentle chime + notification: "Hey — you just woke up. Stay up?"
  → Tapping notification: simple single-tap dismissal
  → No tap within 5 minutes: escalate to full alarm again
- User can DISABLE this in settings: "Post-alarm watchdog: OFF"
- Default: ON

IMPLEMENT IN: alarm_service.dart (Part 3)

---

## EC-4.10: Insomnia — user is awake all night but phone shows stillness
SCENARIO: User lying awake in the dark. Phone shows "sleep" based on
screen-off + stillness. Misleading sleep data.

RISE RESPONSE (honesty policy):
- In sleep log and analytics: "Sleep estimated from screen-off time.
  For accurate tracking, use a connected wearable or enable optional
  microphone sleep detection."
- RISE never claims to definitively know if someone slept
- All sleep metrics are clearly labeled "estimated"
- This is a documented product limitation communicated transparently

IMPLEMENT IN: sleep_tracker_screen.dart (Part 5)

---

# CATEGORY 5: ALARM DISMISSAL SCENARIOS

## EC-5.1: User is in the shower when alarm fires
SCENARIO: Can hear alarm but cannot reach phone. Alarm escalates.

RISE RESPONSE:
- This is INTENTIONAL product behavior — alarm should escalate
- Buddy notification delay for "shower scenario":
  Standard: notify buddy after 15 minutes of no dismissal
  Adjust: after ANY dismissal attempt (even if game not completed),
  reset buddy timer — user is clearly awake and trying
- Cannot detect showering — just rely on natural alarm escalation

---

## EC-5.2: User is driving when alarm fires
SCENARIO: Forgot to disable overnight alarm. Now driving. Should not
interact with phone at all.

RISE RESPONSE:
- Driving detection: check if phone is connected to car BT AND
  if speed data is available (via GPS, >15 km/h)
- If driving detected: auto-dismiss alarm with log: "dismissed_driving"
- On-screen message: "Safe driving mode — alarm dismissed."
- No wake game required
- No snooze count recorded
- iOS CarPlay: detect CarPlay session, same behavior
- Setting: "Auto-dismiss when driving" — ON by default

IMPLEMENT IN: alarm_service.dart (Part 3), driving_detector.dart (Part 3)

---

## EC-5.3: Daylight Saving Time — alarm fires at wrong clock time
SCENARIO: Clocks spring forward or fall back. Scheduled alarm fires
1 hour early or late.

RISE RESPONSE (CRITICAL — timezone handling):
- ALL alarm scheduling uses tz.TZDateTime (established in Part 1)
- Android AlarmManager: always converts local time → UTC using
  the timezone library — DST-aware
- 24 hours before DST change: push notification
  "Tonight is Daylight Saving Time. Your alarms have been
  automatically adjusted to fire at the correct local time."
- After any DST change: verify all scheduled alarms on next app open
  → Compare expected fire time vs. scheduled UTC time
  → If discrepancy detected: auto-correct and notify user

IMPLEMENT IN: alarm_service.dart (Part 3), timezone_manager.dart (Part 3)

---

## EC-5.4: User crosses timezone mid-sleep (flight)
SCENARIO: Set alarm for 8am. Phone's timezone auto-updates mid-flight.
Alarm could fire at wrong time.

RISE RESPONSE:
- Timezone change detection: compare timezone string at sleep onset
  vs. timezone string at alarm fire time
- If timezone changed WHILE sleep window is active:
  → Do NOT auto-reschedule active alarm — let it fire as scheduled
    (rescheduling a firing alarm mid-sleep is worse than a slight offset)
  → After dismissal: "Your timezone changed while you slept.
    Check your alarms for tomorrow." — with single-tap shortcut to alarms
- Setting per alarm: "Local time" (adjusts to timezone) vs.
  "Absolute time" (fires at set UTC time regardless of timezone)

IMPLEMENT IN: alarm_service.dart (Part 3), timezone_manager.dart (Part 3)

---

## EC-5.5: System update (Android/iOS) overnight causing phone restart
SCENARIO: OS update installs at 3am. Phone reboots. All scheduled
alarms are cleared from AlarmManager.

RISE RESPONSE (3-layer defense):
LAYER 1: Boot receiver (BOOT_COMPLETED) — reschedules ALL enabled alarms
         from Hive database immediately on boot
LAYER 2: flutter_local_notifications system notifications are re-registered
         on boot via the boot receiver
LAYER 3: Next app open — verify all alarms are scheduled, show warning
         if any alarms were lost: "Your phone restarted. RISE has
         rescheduled all your alarms." — with verification list

IMPLEMENT IN: boot_receiver.dart (Part 3), alarm_service.dart (Part 3)

---

## EC-5.6: App is force-stopped by user or OS
SCENARIO: User swipes app from recents. On aggressive manufacturers
(Xiaomi, Samsung), this may kill the foreground service.

RISE RESPONSE (3-layer defense):
LAYER 1: Foreground service with FOREGROUND_SERVICE_TYPE declaration
         — survives most force-stops on stock Android
LAYER 2: AlarmManager.setExactAndAllowWhileIdle() fires an Intent that
         RELAUNCHES the app even if it was killed — this is OS-level
LAYER 3: flutter_local_notifications scheduled notification is a
         SYSTEM-LEVEL alarm that doesn't depend on app process being alive
— Even if all 3 fail (rooted device with system-level kill):
  Show permanent advisory at alarm setup: "Your device may restrict
  background alarms. Review battery settings to ensure reliability."

IMPLEMENT IN: alarm_service.dart (Part 3), boot_receiver.dart (Part 3)

---

## EC-5.7: Do Not Disturb or Focus Mode silences alarm
SCENARIO: User has DND scheduled from 11pm-7am. RISE alarm at 6:30am.
Silenced — user never wakes up.

RISE RESPONSE:
- Android: STREAM_ALARM is DND-exempt by default UNLESS user explicitly
  configured DND to block alarms — detect this and warn
- iOS: Critical Alerts BYPASS DND and Silent Switch entirely
  (this is the core reason we request Critical Alerts entitlement)
- At alarm setup: check if DND is active AND covers alarm time
  → If alarm is blocked by DND: red warning
    "Do Not Disturb is blocking this alarm. Tap to fix."
  → Direct deep-link to DND settings
  → This warning is shown EVERY TIME they set the alarm while DND blocks it

IMPLEMENT IN: alarm_setup_screen.dart (Part 3), dnd_checker.dart (Part 3)

---

## EC-5.8: Multiple alarms — dismissed first, fell back asleep before second
SCENARIO: 6:00am alarm dismissed (brain rebooted). 6:30am backup alarm.
User falls back asleep in between. Second alarm fires.

RISE RESPONSE:
- Each alarm is independent — second alarm fires normally
- HOWEVER: global snooze tracking is PER-SESSION not per-alarm
  If user already snoozed 2× on the 6am alarm: the 6:30am alarm
  starts on difficulty level 2 (not level 1) — escalating difficulty
  recognizes the user has been fighting waking up
- Post-dismissal watchdog (EC-4.9) also applies between alarms

IMPLEMENT IN: alarm_service.dart (Part 3), alarm_model.dart (Part 2 update)

---

## EC-5.9: Medical emergency — user cannot dismiss alarm
SCENARIO: User had a medical event. Phone is alarming for 30 minutes.

RISE RESPONSE (the most important safety feature):
- 15 minutes: Buddy gets WhatsApp message:
  "[Name]'s RISE alarm has been going for 15 minutes without response.
  They may have overslept — give them a nudge!"
- 30 minutes: Buddy gets escalated message:
  "⚠️ [Name]'s alarm has been going for 30 minutes with no response.
  Please check on them — they may need help."
- 45 minutes: Emergency contact (separate from buddy) gets same escalated message
- RISE does NOT auto-call emergency services (too many false positives,
  liability, varies by jurisdiction) — the 30/45-minute buddy messages
  ARE the emergency pathway
- In alarm setup: "Emergency contact" field (separate from buddy)
  — documented as "the person RISE calls first if you can't wake up"

IMPLEMENT IN: alarm_service.dart (Part 3), buddy_notification_service.dart (Part 3)

---

# CATEGORY 6: SYSTEM & OS INTERFERENCE

## EC-6.1: Android root detected
SCENARIO: Rooted device can bypass foreground service, manipulate system
clock, kill processes at kernel level.

RISE RESPONSE:
- Detect root using RootBeer library or equivalent at app launch
- If rooted: show one-time advisory in settings:
  "Rooted devices may have reduced alarm reliability. RISE cannot
  guarantee full alarm protection on rooted hardware."
- Do NOT block functionality — just inform
- Log root status to analytics (anonymized) for product decisions

IMPLEMENT IN: main.dart (Part 1 update), device_capability_service.dart (Part 2)

---

## EC-6.2: System clock manipulation
SCENARIO: User (or malware) changes system time to trigger alarm early
then dismiss it — skipping the intended wake time.

RISE RESPONSE:
- Alarms also use ELAPSED_REALTIME_WAKEUP (time since boot) in addition
  to RTC (wall clock time) — elapsed time cannot be faked without root
- On alarm fire: compare expected fire time vs. actual fire time
  → Discrepancy > 5 minutes: log "irregular_dismissal" flag
  → This is logged for analytics, not used to punish user

IMPLEMENT IN: alarm_service.dart (Part 3)

---

## EC-6.3: Phone storage completely full
SCENARIO: Hive cannot write. Sleep data lost. App may crash on launch.

RISE RESPONSE:
- Critical alarm config (next fire time, alarm settings) is ALSO stored
  in SharedPreferences as a lightweight backup — SP rarely fails even
  under extreme storage pressure
- Storage check at every app launch: if available storage < 50MB, show warning
- If Hive write fails: catch exception, log to Crashlytics,
  fall back to SharedPreferences config, retry Hive write every 5 minutes
- Never crash on storage failure — always degrade gracefully

IMPLEMENT IN: main.dart (Part 1 update), alarm_service.dart (Part 3)

---

## EC-6.4: Low Power Mode throttles background services
SCENARIO: Android Doze mode or iOS Low Power Mode restricts background
execution. Alarm service is delayed or killed.

RISE RESPONSE:
- Android: FOREGROUND SERVICE is Doze-exempt — this is the entire reason
  RISE uses a foreground service instead of a background service
- AlarmManager.setExactAndAllowWhileIdle() is also Doze-exempt
- iOS: UNUserNotificationCenter scheduled notifications are Low Power Mode-exempt
- At onboarding: request battery optimization exemption (Part 2 manufacturer
  restrictions) — this is the most important single permission
- No additional handling needed if architecture is correct

IMPLEMENT IN: alarm_service.dart (Part 3)

---

## EC-6.5: Another alarm app conflict (duplicate alarms)
SCENARIO: User has stock clock AND RISE set for same time. Both fire.
Or stock clock fires and user dismisses it thinking it was RISE.

RISE RESPONSE:
- Cannot detect other alarm apps
- Onboarding tip (shown once): "For best results, disable alarms in your
  phone's stock clock app. RISE handles everything."
- Cannot be enforced — user education only

IMPLEMENT IN: onboarding.dart (Part 11)

---

# CATEGORY 7: NETWORK & EXTERNAL SERVICE FAILURES

## EC-7.1: No internet when alarm fires
RISE RESPONSE:
- CORE ALARM: 100% offline. Zero network dependency. Non-negotiable.
- Buddy WhatsApp: queue message, send when network returns
  — add "[Delayed]" to message: "[Delayed] [Name]'s alarm fired
  at 6:00 AM — just FYI!"
- Firebase sync: queued, synced on next connection
- Calorie tracker: manual entry works offline; search/barcode fails gracefully
  "No internet — enter food details manually."
- RevenueCat: use cached subscription status (7-day offline grace period)

IMPLEMENT IN: alarm_service.dart (Part 3), buddy_notification_service.dart (Part 3)

---

## EC-7.2: RevenueCat outage / unavailable
SCENARIO: RC server down. Cannot validate subscription.
User should not lose Pro access due to a third-party outage.

RISE RESPONSE:
- Cache last known subscription status with timestamp in SharedPreferences
- If RC unreachable: use cached status for up to 7 days without challenge
- After 7 days offline: downgrade gracefully to Lite
  → Show notification: "We couldn't verify your RISE Pro subscription.
    Connect to the internet and tap 'Restore Purchases' to reactivate."
- NEVER silently remove Pro features mid-session during an outage

IMPLEMENT IN: subscription_provider.dart (Part 2 update), subscription_service.dart (Part 9)

---

## EC-7.3: WhatsApp not installed on user's device
RISE RESPONSE:
- canLaunchUrl() check before displaying WhatsApp buddy option
- If WhatsApp not installed: only show "In-app notification" option
- Never show a non-functional button

IMPLEMENT IN: buddy_notification_service.dart (Part 3)

---

# CATEGORY 8: ANTI-CIRCUMVENTION

## EC-8.1: User enrolled sleeping partner's biometric during setup
SCENARIO: Devious setup — enrolled someone else's finger/heartbeat
so that person can dismiss the alarm every morning.

RISE RESPONSE:
- Enrollment requires FIVE sessions spaced MINIMUM 12 hours apart
  across AT LEAST 3 different calendar days
- Each session requires 10 minutes of normal phone use immediately before
  (screen interaction history check) — impossible to hold a sleeping person's
  finger to a phone for 10 minutes of "use"
- This pattern makes it impractical to enroll someone else's biometrics

IMPLEMENT IN: biometric_service.dart (Part 4), biometric_enrollment.dart (Part 11)

---

## EC-8.2: User leaves phone perfectly still to fake "sleeping"
SCENARIO: Places phone under book. Phone shows stillness. User goes out.

RISE RESPONSE:
- Sleep verification is only ONE layer — the wake game is the true
  anti-circumvention tool and it fires regardless of sleep detection accuracy
- GPS/WiFi positioning: if phone is stationary but location shows movement
  (WiFi network changes, cell tower changes): flag session as "unverified"
- No sleep credit for unverified sessions (streaks, challenges not awarded)

IMPLEMENT IN: sleep_detection_service.dart (Part 5)

---

## EC-8.3: User shared PIN with partner to dismiss alarm
SCENARIO: Social circumvention — partner solves game every morning.

RISE RESPONSE:
- This is a social agreement we cannot technically prevent
- The General Knowledge game is the primary defense: dynamic questions
  that require actual conscious engagement
- Making your partner solve 5 math problems every morning is
  inherently unsustainable — behavioral deterrence
- Accept this as an inherent limitation of any non-implanted system

---

# CATEGORY 9: SPECIAL USER POPULATIONS

## EC-9.1: User in a mental health crisis
SCENARIO: User is in distress overnight. Alarm goes undismissed not
because they overslept, but because they cannot or will not respond.

RISE RESPONSE:
- 30-minute buddy alert message is explicitly phrased as a WELLNESS CHECK:
  "⚠️ [Name]'s alarm has been going for 30 minutes with no response.
  Please check on them — they may need help."
- 45-minute emergency contact escalation (separate from buddy)
- In settings: separate fields for "Accountability Buddy" and
  "Emergency Contact" with explicit label:
  "The person RISE contacts first if you cannot be reached"

IMPLEMENT IN: buddy_notification_service.dart (Part 3), settings (Part 11)

---

## EC-9.2: Elderly users unfamiliar with biometrics
RISE RESPONSE:
- Onboarding has 3 modes: Quick / Standard / Assisted
- Assisted mode: large text, slow animations, step-by-step voice-over
  style instructions with visual guides
- PPG enrollment shows real-time heartbeat animation confirming it's working
- "Try again" language always gentle — never "Failed"
- Assisted mode auto-suggested if device accessibility settings
  (large text, display size) indicate accessibility preferences are active

IMPLEMENT IN: onboarding.dart (Part 11)

---

## EC-9.3: Child profile (Guardian plan)
SCENARIO: Parent sets alarm for child. Child tries to dismiss by killing app.

RISE RESPONSE:
- Guardian tier: parent is admin for child profile
- Child profile cannot: disable alarms, delete alarms, change game difficulty
- Parent receives: push notification when child's alarm fires, when dismissed
- Parent can see child's wake game results in Guardian dashboard
- Child's alarm escalation also notifies parent directly (not just buddy)

IMPLEMENT IN: guardian_service.dart (Part 9), guardian_dashboard.dart (Part 9)

---

# THE DEFINITIVE FAILSAFE HIERARCHY

When everything else fails, RISE falls back through this chain.
Every level is independently implemented and does not depend on the
levels above it. The alarm WILL fire through at least one of these.

```
LEVEL 1: ✅ Foreground Service fires alarm with full PPG biometric + wake game
         → Requires: service alive + camera + permissions
           ↓ [flash failed / PPG quality too low]

LEVEL 2: ✅ Foreground Service fires alarm with PIN verification + wake game
         → Requires: service alive + permissions
           ↓ [service killed by aggressive manufacturer]

LEVEL 3: ✅ AlarmManager.setExactAndAllowWhileIdle() Intent relaunches app
         → Requires: AlarmManager permission + BOOT_COMPLETED receiver
         → This RESURRECTS the app from a killed state
           ↓ [AlarmManager permission denied — Android 12+]

LEVEL 4: ✅ flutter_local_notifications system alarm notification fires
         → This is a SYSTEM-LEVEL notification, independent of app process
         → Requires: notification permission
           ↓ [notification permission denied]

LEVEL 5: ❌ No alarm can fire on this device
         → Show PERMANENT RED WARNING at alarm setup time:
           "⛔ This alarm CANNOT fire — notification permission is required."
         → Cannot save alarm without granting notification permission
         → This is the only hard block in RISE

PARALLEL AT ALL LEVELS (async, non-blocking):
  → 15 min no dismissal: buddy WhatsApp message (queued if offline)
  → 30 min no dismissal: escalated buddy wellness check
  → 45 min no dismissal: emergency contact notification
```

---

# SETTINGS & FEATURES REQUIRED BY THIS EDGE CASE ANALYSIS

The following settings MUST exist in the app (implemented in Part 11):
These are non-optional — each one is required by the edge cases above.

ACCESSIBILITY SETTINGS (no paywall — accessibility is always free):
[ ] I use hearing aids (EC-1.6)
[ ] I am deaf / hard of hearing (EC-3.9)
[ ] I have photosensitive epilepsy (EC-3.10)
[ ] I have a movement condition (EC-3.8)
[ ] Simple wake confirmation (EC-3.11)
[ ] I have an irregular heartbeat (EC-3.4)
[ ] I take medication that affects heart rate (EC-3.3)

ALARM SETTINGS (per alarm):
[ ] Alarm type: Regular / Nap (EC-4.7)
[ ] Auto-dismiss when driving: ON/OFF (EC-5.2)
[ ] Post-alarm watchdog: ON/OFF (EC-4.9)
[ ] Early Start button: always shown 30 min before alarm (EC-4.8)

SAFETY SETTINGS:
[ ] Accountability Buddy (name + WhatsApp number)
[ ] Emergency Contact (separate person — wellness check recipient)
[ ] Buddy notify after: [X] snoozes (configurable 1-5)
[ ] Emergency alert after: [X] minutes of no dismissal (default 30)

AUDIO SETTINGS:
[ ] Route alarm to hearing aid (EC-1.6): ON/OFF
[ ] Post-DST notification: always ON (EC-5.3)

SLEEP SETTINGS:
[ ] Sleep detection method: Motion / Screen / Both
[ ] Microphone sleep detection: OFF by default, opt-in (EC-1.8 reference)
[ ] Nap mode settings (separate from main alarm)

---

# MESSAGES LIBRARY — All User-Facing Messages From Edge Cases

These strings must be added to app_strings.dart (Part 1 update):

// Audio routing
static const String earphoneDetected = 'Earphones detected — alarm also playing on speaker';
static const String btOverridden = 'Bluetooth audio overridden — alarm playing on speaker';
static const String volumeAutoSet = 'Alarm volume set to minimum 50% for reliability';

// Biometric fallbacks
static const String ppgSignalWeak = 'Signal too weak — warm your hands or enter your PIN';
static const String ppgHrMismatch = 'Heart rate doesn\'t match your profile. Not feeling well? Enter your PIN instead.';
static const String ppgFallbackPin = 'Switching to PIN verification';
static const String ppgTryOtherFinger = 'Try a different finger';
static const String biometricReenrollPrompt = 'Your biometric profile may need updating. Re-enroll for best accuracy.';

// Sleep detection
static const String travelModeActive = 'Looks like you\'re moving — RISE switched to travel mode.';
static const String estimatedSleepDisclaimer = 'Sleep estimated from screen-off time. For accuracy, enable microphone detection or connect a wearable.';
static const String postAlarmWatchdog = 'Hey — you just woke up. Stay up?';
static const String timezoneChanged = 'Your timezone changed while you slept. Check your alarms for tomorrow.';

// Safety
static const String buddy15MinMessage = '[Name]\'s RISE alarm has been going for 15 minutes without response. They may have overslept — give them a nudge!';
static const String buddy30MinMessage = '⚠️ [Name]\'s alarm has been going for 30 minutes with no response. Please check on them — they may need help.';
static const String emergencyContactMessage = '⚠️ [Name]\'s alarm has been going for 45 minutes. This is an automated wellness check — please contact them.';

// System
static const String alarmsRescheduledAfterBoot = 'Your phone restarted. RISE has rescheduled all your alarms.';
static const String dndBlockingAlarm = 'Do Not Disturb is blocking this alarm.';
static const String batteryLow20 = 'Battery at 20%. Plug in to guarantee your alarm fires.';
static const String batteryCritical10 = 'Battery critical. Your alarm may not fire.';
static const String batteryPreAlarm = 'Battery dying before your alarm. Wake up now?';
static const String noAlarmWithoutNotification = '⛔ This alarm cannot fire — notification permission is required.';
static const String drivingModeDismissed = 'Safe driving mode — alarm dismissed.';

---
## END OF EDGE CASE BIBLE
## 10 categories | 65+ edge cases | All with defined RISE Responses
## This document is referenced by Parts 3–12 of the blueprint.
```
