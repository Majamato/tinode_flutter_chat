# tinode_flutter_chat

A drop-in Flutter chat UI for the [Tinode](https://github.com/tinode/chat) chat server, built on
[`tinode_dart_client`](../tinode_dart_client).

## Features

- Connects, logs in with a built-in form or with credentials you pass, and keeps the session for as
  long as the widget lives. The login screen also signs new users up (confirming their email
  with a mailed code where the server asks for one) and resets forgotten passwords with a code
  sent by email.
- A profile screen, from the settings (or the chat list's menu without the tab bar), edits the
  user's name and photo. An account screen, next to it, changes the password (typed twice; the
  login stays), logs out and deletes the account.
- A chat's info screen, from its title, lists a group's members and removes them, and deletes a
  chat or a group, or leaves a group. Chats deleted elsewhere, or that the user was removed from,
  leave the list.
- Shows the chat list from `me`, newest first, with unread counts that follow new messages and reads
  from other devices.
- Opens direct chats, groups and channels. Channel followers get a read-only view.
- Loads history, pages older messages in on scroll, and merges live messages as they arrive.
- Sends plain text and marks what the user sees as read.
- Sends and shows images, videos and files: an attach button offers Photos (Gallery on Android)
  for a photo or a video, Camera (an in-app camera that takes either, and saves what it takes to
  the device's photos) and File, then a preview with a caption. Photos and videos are compressed
  on the device before they go, and a video must fit 20 MiB once compressed (see
  `TinodeAttachmentLimits`). Their bubble shows at once, with the compression's and then the
  upload's progress in numbers; both carry on when the user leaves the chat, and wait in the
  outbox like any message. Images show in the chat and open full screen; videos show their poster
  and length, and play full screen; files show their name and size, and a tap downloads and opens
  them with the system's viewer. Profile photos given by reference show too.
- In groups, names the sender of each run of messages and shows their avatar. Shows who is
  typing, under the chat's name and as a bubble with bouncing dots. The user's own messages get
  delivered and read ticks, and a "Read by" list in groups.
- Bubbles in the chat's design: a tail on the last of each run, the time inline after the
  last line, a date above each day, a flat wallpaper, and floating glass for the app bar and
  the composer, the messages scrolling under both. A sent message pops in. Wrap or replace bubbles with `bubbleBuilder`:

  ```dart
  TinodeChat(
    config: config,
    bubbleBuilder: (context, bubble, defaultBubble) => bubble.kind ==
            TinodeBubbleKind.call
        ? MyCallBubble(bubble)
        : defaultBubble,
  )
  ```
- Every screen with an app bar, from the chat list to the login's password reset, shares one
  glass `TinodeAppBar`, and every screen that can go back one `TinodeBackButton`, which names
  the screen it goes back to. Wrap the bar or bring your own with `appBarBuilder`; the content
  scrolls under whatever bar you return and starts below its preferred height:

  ```dart
  TinodeChat(
    config: config,
    appBarBuilder: (context, screen, defaultAppBar) => switch (screen) {
      TinodeChatScreen(:final topic) => MyChatBar(topic: topic),
      TinodeSettingsScreen() => const TinodeAppBar(title: Text('Me')),
      _ => defaultAppBar,
    },
  )
  ```
- Finds people and groups by login, email, phone or tag, opens 1:1 chats with them, and creates
  groups with members. This needs the network.
- Voice messages: the mic in the send button records (`record`), a second tap sends, and Cancel
  or a swipe drops it. They show as a waveform bubble that plays in place (`just_audio`), one at
  a time, and go as Tinode's `AU` entity (AAC, with the duration and a loudness preview), so
  TinodeWeb and Tindroid play them too. Turn recording off with
  `TinodeChatFeatures(voiceMessages: false)`.
- 1:1 voice and video calls with `flutter_webrtc`: call buttons in direct chats, a ringing screen
  over any route, mute, camera on/off, front/back camera and speaker. Calls show in the chat with
  how they went. They need a server with ICE (STUN/TURN) servers.
- Calls use the phone's own call screens, CallKit on iOS and a self-managed Telecom connection
  on Android: they ring over the lock screen, can be answered and hung up from there, and keep
  the microphone and camera with the app in the background. With `TinodeCalls.handlePush` in your
  push handler, a call rings even while the app is closed.
- Push notifications without a push dependency: pass the token from your push service (e.g.
  `firebase_messaging`) and it is registered for whoever logs in, and removed on log out. Read
  the pushes with `TinodePush.tryParse`, and open the tapped chat with
  `TinodeChatController.openChat`.
- Message search within a chat, from the search button in its app bar, over the messages kept
  on the device and ignoring accents. A result goes back to the chat scrolled to the message,
  highlighted for a moment. Tinode has no server-side message search, so it works offline too.
  The chat list's search button finds people and groups.
- Keeps the cache small: each chat keeps its newest 1000 messages and the downloaded files
  stay under 200 MiB, both adjustable with `TinodeCacheLimits`.
- A floating tab bar with the chats, the calls history and the settings (turn it off with
  `TinodeChat(tabBar: false)`), and an Appearance screen where the user picks one of your
  palettes and light, dark or system (`TinodeAppearance`).
- Speaks English, Spanish and French, following the app's locale (see [Languages](#languages)).
- Restyle it with a `TinodeChatTheme` theme extension, translate or reword it with
  `TinodeChatStrings`, and swap its [Phosphor](https://phosphoricons.com) icons for your own
  with `TinodeChatIcons` (e.g. `TinodeChat(icons: const TinodeChatIcons(send: Icons.send))`).
- Needs no `ProviderScope` or other setup in your app.

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

void main() => runApp(
  MaterialApp(
    home: TinodeChat(
      config: TinodeConfig(
        server: Uri.parse('wss://chat.example.com'),
        apiKey: '<your API key>',
        userAgent: 'MyApp/1.0',
      ),
      // Optional: skip the login form. Keep the token from onLoggedIn.
      // credentials: TinodeCredentials.token(savedToken),
      onLoggedIn: (login) => saveToken(login.token),
    ),
  ),
);
```

### Appearance

Offer your palettes and let the user pick one, with light, dark or system, on the settings'
Appearance screen. Load the choice before `runApp` and build your themes from it; it is saved on
the device:

```dart
final appearance = await TinodeAppearance.load(
  palettes: [
    TinodeAppearancePalette(id: 'slate', label: 'Slate', colors: TinodeChatPalette.neutral),
    TinodeAppearancePalette(id: 'plum', label: 'Plum', colors: plumPalette),
  ],
);
runApp(
  ListenableBuilder(
    listenable: appearance,
    builder: (context, _) => MaterialApp(
      theme: TinodeChatTheme.materialTheme(palette: appearance.palette.colors),
      darkTheme: TinodeChatTheme.materialTheme(
        palette: appearance.palette.colors,
        brightness: Brightness.dark,
      ),
      themeMode: appearance.themeMode,
      home: TinodeChat(config: config, appearance: appearance),
    ),
  ),
);
```

`TinodeChat.appearanceExtra` adds a widget of your own to that screen, e.g. a look setting of
your app's own such as its text size.


### Login screen

The login is plain: a title and the form, on the theme's background. `loginHeader` puts your logo
above it. To draw the screen yourself, pass `loginBuilder`: it gets the working form, and you
place it. The form logs in, signs up, resets passwords and asks for mailed codes on its own, in
your theme.

```dart
TinodeChat(
  config: config,
  loginBuilder: (context, login, defaultLogin) => Stack(
    children: [
      const MyBackground(),
      Center(
        child: MyCard(
          child: Column(
            children: [
              if (login.signUpOffered)
                MyModeSwitch(mode: login.mode, onChanged: login.onModeChanged),
              login.form,
            ],
          ),
        ),
      ),
    ],
  ),
)
```

The result is the body of the screen's `Scaffold`, and `loginHeader` shows only in the default
screen. `defaultLogin` is that default, to wrap instead. Keep the form above the keyboard as you
see fit (a scroll view reversed to its bottom does it), and put no `Navigator` around it: it opens
its screens on the chat's own. Resetting a password and confirming an email stay plain screens in
your theme. `BubbleTail` and `SlidingSegments` are exported for your own design.

## Languages

The chat's texts are built in for English, Spanish and French, and follow the app's locale. For
the app's locale to resolve to Spanish or French, and for dates and Material's own texts to be
translated too, add `flutter_localizations` to your app:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

```dart
MaterialApp(
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: TinodeChatStrings.supportedLocales, // or your own list
  home: TinodeChat(config: config),
)
```

Without them Flutter resolves the locale to English, and so does the chat. The phone's call
screens, which the system shows, follow the phone's language.

To force a language, or reword some texts, pass `strings`:

```dart
TinodeChat(
  config: config,
  strings: const TinodeChatStrings.es(chatListTitle: 'Mis chats'),
)
```

`TinodeChatStrings()` is English, `.es()` Spanish and `.fr()` French; any text you leave out
keeps that language's default. Pass the same `strings` to `TinodeCalls.handlePush`, which
otherwise uses the phone's language.

## Accounts: what the server decides

Some account features depend on how the server is set up, and the chat adapts to it:

- **Email at sign-up.** A server that sends email usually requires one; the official Docker image
  does as soon as it has an SMTP server. The sign-up form then requires the email and asks for
  the code the server mails. Elsewhere the email is optional and nothing needs confirming. Only
  the server can change this.
- **Password reset** needs the server to send email, since the code goes by email. By default the
  login screen offers it only where the server requires an email (Tinode v0.25 also fails on resets
  where email is optional).
- **Changing the password**, editing the profile and deleting the account work on any server.

Switch features off for a server that doesn't offer them, or force the reset on for one you know
sends email:

```dart
TinodeChat(
  config: config,
  features: const TinodeChatFeatures(
    signUp: false, // e.g. accounts made by an admin
    passwordReset: PasswordResetMode.always,
    videoCalls: false, // voice calls only
  ),
)
```

A kind of call that is off has no button and doesn't ring in this app; pass the same features to
`TinodeCalls.handlePush(push, config: config, features: features)` so it doesn't ring from a
push either.

**Presence** (who is online, and when they were last seen) has two switches:

- **What the app shows**: `TinodeChatFeatures(presence: false)` shows no one's presence. It is
  not only hidden: the chat drops `online`, last seen and `pres on` / `off` as they arrive, and
  keeps none of it in memory or in the cache. The server still sends it.
- **What others see of me**: each user's "Show my online status" in the settings, on by default.
  Off, their profile carries `"x-presence": "hidden"`, and apps built on this package don't show
  them online or with a last seen; on again, `"x-presence": "shown"`. It follows the account to every device. It is a request,
  not a guarantee: the server still sends their presence, and other Tinode apps may show it.
  Tinode can only truly hide a user who never attaches `me`, which would stop the chat list's
  live updates.

Rules such as the shortest login or password, or how long codes last, are the server's
(`tinode.conf`); the chat shows its refusals.

The chat has its own design, in a neutral slate blue by default. Brand it with a
`TinodeChatPalette` and your fonts (bundled by your app), light and dark:

```dart
const brand = TinodeChatPalette(
  primary: Color(0xFF5B1A8C), // own messages, primary buttons; white text on it
  night: Color(0xFF6E29A8), // primary in dark mode
  bright: Color(0xFF8A3FD1), // decoration only
  accent: Color(0xFFFF9A3D), // small pops
  soft: Color(0xFFF1E5FA), // light chat wallpaper
  ink: Color(0xFF42106A), // links on light backgrounds
  onDark: Color(0xFFC08BFF), // links on dark backgrounds
  deep: Color(0xFF1A0730), // behind voice calls
  scene: Color(0xFF28133D), // in place of the remote video
);

MaterialApp(
  theme: TinodeChatTheme.materialTheme(palette: brand, fontFamily: 'Inter'),
  darkTheme: TinodeChatTheme.materialTheme(
    palette: brand,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
  ),
)
```

Change any part with `copyWith`, on the `ThemeData` or on its `TinodeChatTheme` extension. An
app theme without the extension still works: the chat derives one from its color scheme. See
[`docs/design.md`](docs/design.md) for the design.

See [`example/`](example/lib/main.dart) for a runnable app. To try it locally, start the server
from `../tinode-tests` (`docker compose up -d`) and log in as `alice` / `alice123`.

## Calls: platform setup

Calls use the microphone and camera, so the host app must declare them.

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-feature android:name="android.hardware.camera" android:required="false"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

For release builds, keep WebRTC from R8: `-keep class org.webrtc.** { *; }` in
`proguard-rules.pro`.

**iOS** (`ios/Runner/Info.plist`): `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
and `UIBackgroundModes` with `audio` so a call keeps its sound when the screen locks. The Podfile
needs `platform :ios, '13.0'` or later.

The OS asks the user for access when the first call starts. See [`example/`](example/) for a
complete setup, and [Background calls](#background-calls-platform-setup) for the phone's own
call screens, which need a little more.

## Attachments: platform setup

Picking photos, videos and files uses `image_picker` and `file_picker`; the Camera entry is
`camerawesome`; compressing uses `v_video_compressor` and `flutter_image_compress`; saving the
camera's captures to the photos uses `gal`; playing videos uses `video_player`; opening received
files uses `open_filex`. The package runs on Android, iOS and desktop; the web is not supported
yet (its cache uses `dart:io`).

- **iOS** (`ios/Runner/Info.plist`): `NSPhotoLibraryUsageDescription` (photos and videos to
  send), `NSPhotoLibraryAddUsageDescription` (saving what the camera takes),
  `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` (already there for calls) for the
  Camera entry, which records sound with its videos.
- **Android:** photos and videos open the system photo picker, a sheet over the app; the
  package turns it on itself. `MainActivity` must not be `android:launchMode="singleInstance"`:
  Android then opens every picker (photos and files) as a separate app and answers "cancelled"
  before anything is picked. Use `singleTask` (see Calls below). For saving the camera's captures on Android
  10 and older, `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
  android:maxSdkVersion="29" tools:replace="android:maxSdkVersion"/>` (with
  `xmlns:tools="http://schemas.android.com/tools"` on `<manifest>`: `v_video_compressor` declares
  it up to Android 9). See `file_picker`'s notes for older Android versions.
- **macOS:** the `com.apple.security.files.user-selected.read-only` entitlement (in
  `DebugProfile.entitlements` and `Release.entitlements`), next to `network.client`.
- **Linux:** `file_picker` needs `zenity` or `kdialog` installed.
- **Desktop:** there is no Camera entry, and photos and videos go up as they are (there are no
  encoders there). Every file is still capped by the server's `maxFileUploadSize`.

## Voice messages: platform setup

Recording uses the microphone, which calls declare already:

- **Android:** `<uses-permission android:name="android.permission.RECORD_AUDIO"/>`.
- **iOS:** `NSMicrophoneUsageDescription` in `Info.plist`; say it is for voice messages too
  (e.g. "… uses the microphone for calls and voice messages.").
- **macOS:** `NSMicrophoneUsageDescription` and the `com.apple.security.device.audio-input`
  entitlement.

The OS asks the user for access the first time they record. iOS can't play the WebM recordings
TinodeWeb makes in Chrome; such a message says it can't be played.

Downloaded files live in the OS's cache folder, which the OS may clear; files waiting to be sent
are kept in the app's support folder until the server has them. Voice messages, sent and
received, are kept in the support folder too, until their message or chat is deleted. Logging out
deletes all of them.

## Offline

Each user's chats are kept on the device, so they open without waiting for the server:

- the chat list and the messages already seen show at once, even in airplane mode;
- back online, only what changed is fetched: new messages, deletions, updated chats;
- messages sent offline wait in an outbox with a clock, and go out once the link is back,
  never twice. One the server refuses shows an error mark; a long press retries or discards it;
- a long press on a message deletes it for the user, or for everyone where they may.

Pass the token of the user who last logged in as `TinodeCredentials.token`, and the app opens
their chats even with no network, logging in once the server answers. Logging out, from the chat
list's menu or with a `TinodeChatController`, deletes the user's cache. Their call history stays
on the device, in a file of its own, for their next login; deleting the account deletes it:

```dart
final chat = TinodeChatController();

TinodeChat(
  config: config,
  credentials: savedToken == null ? null : TinodeCredentials.token(savedToken),
  controller: chat,
  onLoggedIn: (login) => saveToken(login.token),
  onLoggedOut: deleteSavedToken, // also when the server refuses the token
);

// From the host's own settings screen:
await chat.logOut();
```

### Cache limits

The cache is pruned once each time a user's chats open: each chat keeps its newest messages,
older ones go and load from the server again when the user scrolls back to them, and the
downloaded files used longest ago go until the rest fit. Messages of chats that left the list,
and files left behind by a message that was never sent, go too.

```dart
TinodeChat(
  config: config,
  cacheLimits: const TinodeCacheLimits(
    messagesPerChat: 5000, // default 1000
    fileCacheBytes: 500 * 1024 * 1024, // default 200 MiB
  ),
)
```

Message search finds only what the cache keeps, so `messagesPerChat` is also how far back it
reaches. Files waiting to be sent never count and are never pruned.

Photos and videos shrink before they are sent, and a video must fit a size limit once compressed:

```dart
TinodeChat(
  config: config,
  attachmentLimits: const TinodeAttachmentLimits(
    maxVideoBytes: 20 * 1024 * 1024, // the default; the server's limit wins when lower
    videoBitrate: 1500000, // bits per second, at about 720p
    maxPhotoSide: 2048, // pixels, JPEG at photoQuality 85
  ),
)
```

The server must accept files that large too (`max_file_upload_size` in `tinode.conf`).

The calls history is built from the cache too. Each time the calls tab shows, it fetches the
newest messages of the direct chats the cache is behind on (at most 30, three at a time), so
calls made while the app was closed show up; older calls show once their chat has been
scrolled back to.

## Push: platform setup

The package depends on no push service. The host app sets one up, typically `firebase_messaging`
with its platform setup (`google-services.json`, APNs key), and passes the device token in:

```dart
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _chat = TinodeChatController();
  final _messaging = FirebaseMessaging.instance;
  String? _pushToken;

  @override
  void initState() {
    super.initState();
    unawaited(_messaging.requestPermission());
    _messaging.getToken().then(_setToken);
    _messaging.onTokenRefresh.listen(_setToken);
    // A tapped notification opens its chat, also when it started the app.
    _messaging.getInitialMessage().then(_open);
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
  }

  void _setToken(String? token) => setState(() => _pushToken = token);

  void _open(RemoteMessage? message) {
    if (TinodePush.tryParse(message?.data ?? {}) case final push?) {
      _chat.openChat(push.topic);
    }
  }

  /// Drops the old token at the push service, then takes a new one for the
  /// next user.
  Future<void> _renewToken() async {
    _setToken(null);
    await _messaging.deleteToken();
    _setToken(await _messaging.getToken());
  }

  @override
  Widget build(BuildContext context) => TinodeChat(
    config: config,
    controller: _chat,
    pushToken: _pushToken,
    onLoggedOut: () => unawaited(_renewToken()),
  );
}
```

- **The token** is registered for whoever logs in, sent again when it changes and after each
  reconnect, and removed from the server on log out, before the socket closes. A log out while
  offline can't reach the server, hence the new token in `onLoggedOut`: the push service drops
  the old one, so the server's copy goes nowhere.
- **The platform** (`TinodeConfig.platform`) is this device's, Android, iOS or web, unless you set
  one.
- **Showing notifications** is the host's job, e.g. with `flutter_local_notifications` from the
  background handler. `TinodePush.tryParse(message.data)` reads a push; skip `silent` ones, which
  have nothing to show, after handing it to `TinodeCalls.handlePush` (call pushes are all
  silent; see [Background calls](#background-calls-platform-setup)). A `ReadPush` means the user
  read the chat on another device: its notifications can go. While the app is open, the chat
  shows new messages and rings for calls itself.
- **The server** sends pushes only with its push adapter set up (`push` in `tinode.conf`), for FCM
  with a service account of the same Firebase project as the app.
- **Calls** ring from pushes through `TinodeCalls.handlePush`: see below.

## Background calls: platform setup

Every call goes through the phone's own call screens (`flutter_callkit_incoming`): CallKit on iOS,
a self-managed Telecom connection on Android, which also runs a foreground service that keeps the
microphone and camera while a call goes on. For calls to ring while the app is in the background
or closed, hand each push from your background handler to `TinodeCalls.handlePush` first:

```dart
@pragma('vm:entry-point')
Future<void> onBackgroundPush(RemoteMessage message) async {
  final push = TinodePush.tryParse(message.data);
  if (push == null) return;
  final token = (await SharedPreferences.getInstance()).getString('token');
  if (await TinodeCalls.handlePush(push, config: config, token: token)) {
    return; // a call: it rings, or stops ringing
  }
  if (!push.silent) await showNotification(push);
}

// In main(): FirebaseMessaging.onBackgroundMessage(onBackgroundPush);
```

- **The caller's name** comes from the chats kept on the device for the user who last logged in
  to `config`'s server. A chat that isn't there yet rings as `TinodeChatStrings.unknownCaller`.
- **Accepting** opens the app straight into the call: pass the saved token as
  `TinodeCredentials.token`, as for an offline start, and the call joins once connected.
- **Declining while the app is closed** hangs up for the caller at once when you pass `token`
  (Android). The token stays with the ringing call until it ends. Without it, the caller hears it
  ring until the server's call timeout.
- **While the app is open** the chat rings by itself; leave call pushes from `onMessage` alone.
- **Permissions:** call `TinodeCalls.requestPermissions()` at a good moment, e.g. after login:
  notifications (Android 13+) and full screen notifications (Android 14+, which opens the
  system's settings). iOS asks nothing for CallKit.

**Android:** the plugin declares its permissions, services and the Telecom connection itself.
Set `android:launchMode="singleTask"` on `MainActivity`, so a call opens the app you have rather
than a second one. Not `singleInstance`, as the plugin's own README says: with it, the photo and
file pickers open as a separate app and come back empty. Keep the plugin from R8:
`-keep class com.hiennv.flutter_callkit_incoming.** { *; }` in `proguard-rules.pro`. Google Play
allows full screen notifications (`USE_FULL_SCREEN_INTENT`) for calling apps; declare it in the
Play Console.

**iOS:** CallKit owns the audio session, so WebRTC has to wait for it. In `AppDelegate.swift`
(see [`example/`](example/ios/Runner/AppDelegate.swift)):

```swift
import WebRTC
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, CallkitIncomingAppDelegate {
  override func application(...) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    RTCAudioSession.sharedInstance().useManualAudio = true
    RTCAudioSession.sharedInstance().isAudioEnabled = false
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func onAccept(_ call: Call, _ action: CXAnswerCallAction) { action.fulfill() }
  func onDecline(_ call: Call, _ action: CXEndCallAction) { action.fulfill() }
  func onEnd(_ call: Call, _ action: CXEndCallAction) { action.fulfill() }
  func onTimeOut(_ call: Call) {}
  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = true
  }
  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = false
  }
  func providerDidReset() {}
}
```

`UIBackgroundModes` needs `audio` (above) and, for call pushes, `remote-notification`.

**What iOS can't do:** Tinode sends no VoIP (PushKit) pushes, only a regular background push for
a call. iOS may hold those back, and never wakes an app the user swiped away, so on iOS a call
rings from a push only while the app is suspended in the background. Calls in the app, and in the
background while the session is open, always ring through CallKit.

**Turning it off:** `TinodeChatFeatures(systemCalls: false)` keeps calls inside the app, e.g.
for the App Store in China, which doesn't allow CallKit. Leave out the AppDelegate's
`useManualAudio` then, or calls have no sound. On Android, calls then lose the foreground
service.

## Roadmap

Built so far: the happy path, reconnection, calls, offline, finding people and starting chats,
group chat essentials, attachments, account and profile, push notifications, background calls,
message search and cache upkeep.
Still to come. Each feature lands in [`tinode_dart_client`](../tinode_dart_client) first
where it needs the protocol:

1. ~~**Find people and start chats**~~: done (search, 1:1 chats, new groups with members).
2. ~~**Group chat essentials**~~: done (sender names and avatars in groups, typing indicators,
   delivered and read ticks, a "Read by" list).
3. ~~**Attachments**~~: done (send and show images and files, photos given by reference).
   Rich Drafty rendering (bold, links, mentions) is still to come: messages show their plain
   text.
4. ~~**Account and profile**~~: done (sign up with email confirmation, password reset by email, edit name and
   photo, change the password, log out, delete the account, delete or leave chats, remove group
   members).
5. ~~**Push**~~: done (the host's push token registered for whoever logs in and removed on log
   out, `TinodePush` to read pushes, `openChat` for tapped notifications).
6. ~~**Background calls**~~: done (CallKit and a self-managed Telecom connection, ringing from a
   push with `TinodeCalls.handlePush`, a foreground service for the microphone and camera on
   Android). On iOS a call rings from a push only while the app is suspended: Tinode sends no
   VoIP pushes. Later still: switching between voice and video during a call.
7. ~~**Message search and cache upkeep**~~: done (search a chat's cached messages and jump to a
   result; prune each chat to its newest messages and the file cache to a size, both set with
   `TinodeCacheLimits`).
8. ~~**Design**~~: done ([`docs/design.md`](docs/design.md): the palette, the theme's tokens
   and `TinodeChatTheme.materialTheme`; the chat screen with bubble tails, runs, date chips,
   the wallpaper, the glass app bar and composer, the send button's morph and the bubble
   builder; online presence and last seen; the chat list; the call screens
   and the call bar; the app shell with the floating tab bar, the calls history, the settings
   and the Appearance screen; and voice messages).

## Development

Start with [`docs/`](docs/README.md): architecture, Riverpod usage, widget rules and testing.

## License

MIT. Tinode's server is GPL-3.0; this package only talks to it over the network.
