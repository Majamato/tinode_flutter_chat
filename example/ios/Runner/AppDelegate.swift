import AVFAudio
import CallKit
import Flutter
import UIKit
import WebRTC
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, CallkitIncomingAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Calls go through CallKit, which owns the audio session: WebRTC plays
    // audio only once CallKit has activated it (below).
    RTCAudioSession.sharedInstance().useManualAudio = true
    RTCAudioSession.sharedInstance().isAudioEnabled = false
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // The chat drives the call itself: CallKit's actions are done at once.
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
