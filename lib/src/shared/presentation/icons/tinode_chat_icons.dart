import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons_scope.dart';

/// Every icon `TinodeChat` shows, from [Phosphor](https://phosphoricons.com)
/// by default: Regular, with Fill for the current tab and Bold for the
/// small ticks.
///
/// Pass your own to `TinodeChat.icons` to change some or all of them:
///
/// ```dart
/// TinodeChat(
///   config: config,
///   icons: const TinodeChatIcons(send: Icons.send_rounded),
/// )
/// ```
///
/// Any `IconData` works: Material's `Icons`, `CupertinoIcons`, another icon
/// package or your own icon font. Sets that only ship SVGs have to be turned
/// into an icon font first (e.g. with fluttericon.com). Icons are drawn
/// 24 px unless noted; pairs like [chatsTab] and [chatsTabSelected] let a
/// set show an outline and its filled twin.
@immutable
class TinodeChatIcons {
  /// Creates the icons; any left out keep their Phosphor default.
  const TinodeChatIcons({
    this.chatsTab = PhosphorIconsRegular.chatCircle,
    this.chatsTabSelected = PhosphorIconsFill.chatCircle,
    this.callsTab = PhosphorIconsRegular.phone,
    this.callsTabSelected = PhosphorIconsFill.phone,
    this.settingsTab = PhosphorIconsRegular.gearSix,
    this.settingsTabSelected = PhosphorIconsFill.gearSix,
    this.back = PhosphorIconsRegular.caretLeft,
    this.forward = PhosphorIconsRegular.arrowRight,
    this.disclosure = PhosphorIconsRegular.caretRight,
    this.close = PhosphorIconsRegular.x,
    this.search = PhosphorIconsRegular.magnifyingGlass,
    this.account = PhosphorIconsRegular.userCircle,
    this.avatarPlaceholder = PhosphorIconsFill.user,
    this.newChat = PhosphorIconsRegular.plus,
    this.newGroup = PhosphorIconsRegular.usersThree,
    this.openChat = PhosphorIconsRegular.chatCircle,
    this.muted = PhosphorIconsRegular.bellSlash,
    this.attach = PhosphorIconsRegular.paperclip,
    this.photo = PhosphorIconsRegular.image,
    this.camera = PhosphorIconsRegular.camera,
    this.file = PhosphorIconsRegular.file,
    this.audioFile = PhosphorIconsRegular.fileAudio,
    this.videoFile = PhosphorIconsRegular.fileVideo,
    this.imageFile = PhosphorIconsRegular.fileImage,
    this.pdfFile = PhosphorIconsRegular.filePdf,
    this.send = PhosphorIconsBold.arrowUp,
    this.microphone = PhosphorIconsRegular.microphone,
    this.microphoneOff = PhosphorIconsRegular.microphoneSlash,
    this.play = PhosphorIconsFill.play,
    this.pause = PhosphorIconsFill.pause,
    this.sending = PhosphorIconsBold.clock,
    this.sent = PhosphorIconsBold.check,
    this.delivered = PhosphorIconsBold.checks,
    this.read = PhosphorIconsBold.checks,
    this.failed = PhosphorIconsRegular.warningCircle,
    this.readBy = PhosphorIconsRegular.checks,
    this.retry = PhosphorIconsRegular.arrowClockwise,
    this.delete = PhosphorIconsRegular.trashSimple,
    this.deleteForever = PhosphorIconsRegular.trash,
    this.leaveChat = PhosphorIconsRegular.signOut,
    this.removeMember = PhosphorIconsRegular.userMinus,
    this.voiceCall = PhosphorIconsRegular.phone,
    this.videoCall = PhosphorIconsRegular.videoCamera,
    this.outgoingCall = PhosphorIconsRegular.phoneOutgoing,
    this.incomingCall = PhosphorIconsRegular.phoneIncoming,
    this.cancelledCall = PhosphorIconsRegular.phoneSlash,
    this.missedCall = PhosphorIconsRegular.phoneX,
    this.hangUp = PhosphorIconsFill.phoneDisconnect,
    this.speaker = PhosphorIconsRegular.speakerHigh,
    this.cameraOn = PhosphorIconsRegular.videoCamera,
    this.cameraOff = PhosphorIconsRegular.videoCameraSlash,
    this.switchCamera = PhosphorIconsRegular.cameraRotate,
    this.minimizeCall = PhosphorIconsRegular.caretDown,
    this.restoreCall = PhosphorIconsRegular.caretUp,
    this.offline = PhosphorIconsRegular.wifiSlash,
    this.showPassword = PhosphorIconsRegular.eye,
    this.hidePassword = PhosphorIconsRegular.eyeSlash,
    this.password = PhosphorIconsRegular.password,
    this.appearance = PhosphorIconsRegular.palette,
    this.onlineStatus = PhosphorIconsRegular.eye,
    this.logOut = PhosphorIconsRegular.signOut,
  });

  /// The icons of the nearest `TinodeChat`, or the defaults outside one.
  factory TinodeChatIcons.of(BuildContext context) =>
      TinodeChatIconsScope.maybeOf(context) ?? const TinodeChatIcons();

  /// The chats tab.
  final IconData chatsTab;

  /// The chats tab while it is current.
  final IconData chatsTabSelected;

  /// The calls tab.
  final IconData callsTab;

  /// The calls tab while it is current.
  final IconData callsTabSelected;

  /// The settings tab.
  final IconData settingsTab;

  /// The settings tab while it is current.
  final IconData settingsTabSelected;

  /// Back, at the start of a chat's and the appearance screen's header.
  final IconData back;

  /// The trailing arrow of the sign in and sign up buttons.
  final IconData forward;

  /// The chevron at the end of a settings row.
  final IconData disclosure;

  /// Closes a sheet or a panel.
  final IconData close;

  /// The search fields and the message search button.
  final IconData search;

  /// The account menu above the chat list, without the tab bar.
  final IconData account;

  /// Stands in for someone without a photo.
  final IconData avatarPlaceholder;

  /// Starts a new chat: the plus in the chat list's header.
  final IconData newChat;

  /// The new group row when starting a chat.
  final IconData newGroup;

  /// Opens the chat of a call in the calls history.
  final IconData openChat;

  /// A muted chat in the chat list.
  final IconData muted;

  /// The composer's attach button and the attach sheet's file row.
  final IconData attach;

  /// Picks a photo; a photo in the chat list's preview.
  final IconData photo;

  /// Takes a photo.
  final IconData camera;

  /// A file of any other kind, in bubbles, previews and the chat list.
  final IconData file;

  /// An audio file.
  final IconData audioFile;

  /// A video file.
  final IconData videoFile;

  /// An image file that isn't shown inline.
  final IconData imageFile;

  /// A PDF file.
  final IconData pdfFile;

  /// Sends a message, a voice message or an attachment.
  final IconData send;

  /// Records a voice message (and resumes it); a voice message in the chat
  /// list; the microphone of a call while it is on.
  final IconData microphone;

  /// The microphone of a call while it is muted.
  final IconData microphoneOff;

  /// Plays a voice message.
  final IconData play;

  /// Pauses a voice message or its recording.
  final IconData pause;

  /// The user's own message that is waiting to be sent.
  final IconData sending;

  /// The user's own message the server has.
  final IconData sent;

  /// The user's own message that reached the other side.
  final IconData delivered;

  /// The user's own message that was read; drawn in `readReceiptColor`.
  final IconData read;

  /// A message that couldn't be sent or a file that couldn't be fetched.
  final IconData failed;

  /// Shows who read a message.
  final IconData readBy;

  /// Tries again.
  final IconData retry;

  /// Deletes something for the user.
  final IconData delete;

  /// Deletes something for everyone, or for good.
  final IconData deleteForever;

  /// Leaves a group.
  final IconData leaveChat;

  /// Removes someone from a group.
  final IconData removeMember;

  /// A voice call: the button that starts one, its preview and its bar.
  final IconData voiceCall;

  /// A video call: the button that starts one, its preview and its bar.
  final IconData videoCall;

  /// A call the user made, in the calls history and the chat.
  final IconData outgoingCall;

  /// A call the user answered.
  final IconData incomingCall;

  /// A call the user made that didn't happen.
  final IconData cancelledCall;

  /// A call the user missed.
  final IconData missedCall;

  /// Ends or declines a call.
  final IconData hangUp;

  /// The speaker of a voice call.
  final IconData speaker;

  /// The camera of a video call while it is on.
  final IconData cameraOn;

  /// The camera of a video call while it is off.
  final IconData cameraOff;

  /// Flips between the front and the back camera.
  final IconData switchCamera;

  /// Minimizes a call.
  final IconData minimizeCall;

  /// Brings a minimized call back.
  final IconData restoreCall;

  /// The connection of a call was lost.
  final IconData offline;

  /// Shows the password being typed.
  final IconData showPassword;

  /// Hides the password being typed.
  final IconData hidePassword;

  /// Changes the password.
  final IconData password;

  /// Opens the appearance screen.
  final IconData appearance;

  /// The settings' switch for showing others when the user is online.
  final IconData onlineStatus;

  /// Logs out.
  final IconData logOut;

  List<IconData> get _all => [
    chatsTab,
    chatsTabSelected,
    callsTab,
    callsTabSelected,
    settingsTab,
    settingsTabSelected,
    back,
    forward,
    disclosure,
    close,
    search,
    account,
    avatarPlaceholder,
    newChat,
    newGroup,
    openChat,
    muted,
    attach,
    photo,
    camera,
    file,
    audioFile,
    videoFile,
    imageFile,
    pdfFile,
    send,
    microphone,
    microphoneOff,
    play,
    pause,
    sending,
    sent,
    delivered,
    read,
    failed,
    readBy,
    retry,
    delete,
    deleteForever,
    leaveChat,
    removeMember,
    voiceCall,
    videoCall,
    outgoingCall,
    incomingCall,
    cancelledCall,
    missedCall,
    hangUp,
    speaker,
    cameraOn,
    cameraOff,
    switchCamera,
    minimizeCall,
    restoreCall,
    offline,
    showPassword,
    hidePassword,
    password,
    appearance,
    onlineStatus,
    logOut,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TinodeChatIcons &&
          const ListEquality<IconData>().equals(_all, other._all);

  @override
  int get hashCode => Object.hashAll(_all);
}
