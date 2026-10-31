/// Why a voice message could not be recorded or played.
enum VoiceFailure {
  /// The user, or the OS, refused the microphone.
  microphoneDenied,

  /// A call has the microphone.
  duringCall,

  /// The recording was shorter than `VoiceNote.minDuration`.
  tooShort,

  /// The recorder could not start or save.
  recorderFailed,

  /// The recording could not be fetched or decoded, e.g. a format this
  /// device can't play.
  cannotPlay,
}
