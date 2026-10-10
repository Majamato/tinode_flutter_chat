import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings_scope.dart';

/// Every text `TinodeChat` shows, in English by default.
///
/// Pass your own to `TinodeChat.strings` to translate or reword them:
///
/// ```dart
/// TinodeChat(
///   config: config,
///   strings: const TinodeChatStrings(chatListTitle: 'Conversaciones'),
/// )
/// ```
///
/// Texts that name someone or count something are functions, e.g.
/// [typingOne]; pass a top-level function or a static method, so the
/// strings can stay `const`.
@immutable
class TinodeChatStrings {
  /// Creates the texts; any left out keep their English default.
  const TinodeChatStrings({
    this.chatListTitle = 'Chats',
    this.noChats = 'No chats yet',
    this.connecting = 'Connecting…',
    this.loginTitle = 'Sign in',
    this.loginField = 'Login',
    this.passwordField = 'Password',
    this.signIn = 'Sign in',
    this.retry = 'Retry',
    this.reconnect = 'Reconnect',
    this.reconnecting = 'Reconnecting…',
    this.messageHint = 'Message',
    this.send = 'Send',
    this.readOnly = 'Only admins can post here.',
    this.unreachable = 'Cannot reach the chat server.',
    this.connectionLost = 'The connection to the chat server was lost.',
    this.badCredentials = 'Wrong login or password.',
    this.timeout = 'The chat server did not answer in time.',
    this.rejected = 'The chat server refused the request.',
    this.unexpected = 'Something went wrong.',
    this.voiceCall = 'Voice call',
    this.videoCall = 'Video call',
    this.outgoingVoiceCall = 'Outgoing voice call',
    this.outgoingVideoCall = 'Outgoing video call',
    this.incomingVoiceCall = 'Incoming voice call',
    this.incomingVideoCall = 'Incoming video call',
    this.callInProgress = 'In progress',
    this.callMissed = 'Missed',
    this.callNoAnswer = 'No answer',
    this.callDeclined = 'Declined',
    this.callNotConnected = 'Not connected',
    this.calling = 'Calling…',
    this.ringing = 'Ringing…',
    this.callConnecting = 'Connecting…',
    this.callEnded = 'Call ended',
    this.acceptCall = 'Accept',
    this.declineCall = 'Decline',
    this.hangUp = 'Hang up',
    this.muteMicrophone = 'Mute',
    this.unmuteMicrophone = 'Unmute',
    this.turnCameraOff = 'Turn camera off',
    this.turnCameraOn = 'Turn camera on',
    this.switchCamera = 'Switch camera',
    this.speakerOn = 'Turn speaker on',
    this.speakerOff = 'Turn speaker off',
    this.callBusy = 'This chat is already in a call.',
    this.callUnavailable = 'Calls are not available in this chat.',
    this.callPermissionDenied =
        'Allow access to the microphone and camera to make calls.',
    this.callFailed = 'The call could not be connected.',
    this.logOut = 'Log out',
    this.messageWaiting = 'Waiting to send',
    this.messageSent = 'Sent',
    this.messageNotSent = 'Not sent',
    this.discardMessage = 'Discard',
    this.deleteForMe = 'Delete for me',
    this.deleteForEveryone = 'Delete for everyone',
    this.newChat = 'New chat',
    this.findHint = 'Search by login, email or phone',
    this.nobodyFound = 'Nobody found',
    this.groupLabel = 'Group',
    this.channelLabel = 'Channel',
    this.newGroup = 'New group',
    this.groupNameField = 'Group name',
    this.addMembersHint = 'Add members',
    this.createGroup = 'Create',
    this.membersNotAdded = 'Some members could not be added.',
    this.messageDelivered = 'Delivered',
    this.messageRead = 'Read',
    this.readBy = 'Read by',
    this.deliveredTo = 'Delivered to',
    this.notReadYet = 'Nobody has read it yet',
    this.unknownMember = 'Unknown',
    this.typingDirect = 'typing…',
    this.typingOne = _typingOne,
    this.typingTwo = _typingTwo,
    this.typingMany = _typingMany,
    this.attach = 'Attach',
    this.attachPhoto = 'Photo',
    this.attachCamera = 'Camera',
    this.attachFile = 'File',
    this.captionHint = 'Add a caption',
    this.uploading = 'Uploading…',
    this.cancelUpload = 'Cancel',
    this.fileTooLarge = 'The file is too large to send.',
    this.fileTooLargeLimit = _fileTooLargeLimit,
    this.downloadFailed = 'The file could not be downloaded.',
    this.cannotOpenFile = 'No app on this device opens this file.',
    this.openFile = 'Open',
    this.imageLabel = 'Image',
    this.fileLabel = 'File',
  });

  /// The texts of the nearest `TinodeChat`, or the defaults outside one.
  factory TinodeChatStrings.of(BuildContext context) =>
      TinodeChatStringsScope.maybeOf(context) ?? const TinodeChatStrings();

  /// Title of the chat list screen.
  final String chatListTitle;

  /// Shown when the chat list is empty.
  final String noChats;

  /// Shown while connecting to the server.
  final String connecting;

  /// Title of the login screen.
  final String loginTitle;

  /// Label of the login name field.
  final String loginField;

  /// Label of the password field.
  final String passwordField;

  /// Label of the login button.
  final String signIn;

  /// Label of buttons that try a failed load again.
  final String retry;

  /// Label of the button that connects again after a failure.
  final String reconnect;

  /// Shown while the client restores a dropped connection by itself.
  final String reconnecting;

  /// Placeholder of the message field.
  final String messageHint;

  /// Tooltip of the send button.
  final String send;

  /// Shown instead of the message field where the user cannot post, e.g.
  /// to channel followers.
  final String readOnly;

  /// The server could not be reached.
  final String unreachable;

  /// An open connection dropped.
  final String connectionLost;

  /// The server rejected the login.
  final String badCredentials;

  /// A request got no answer in time.
  final String timeout;

  /// The server rejected a request.
  final String rejected;

  /// Any other error.
  final String unexpected;

  /// Tooltip of the button that starts a voice call.
  final String voiceCall;

  /// Tooltip of the button that starts a video call.
  final String videoCall;

  /// A voice call the user made, in the chat.
  final String outgoingVoiceCall;

  /// A video call the user made, in the chat.
  final String outgoingVideoCall;

  /// A voice call the user received, in the chat and on the ringing
  /// screen.
  final String incomingVoiceCall;

  /// A video call the user received, in the chat and on the ringing
  /// screen.
  final String incomingVideoCall;

  /// A call that is still ringing or going on.
  final String callInProgress;

  /// A call the user received but did not answer.
  final String callMissed;

  /// A call the user made that nobody answered.
  final String callNoAnswer;

  /// A call that the callee refused.
  final String callDeclined;

  /// A call that dropped before it was answered.
  final String callNotConnected;

  /// Shown while a call the user made waits for the peer's device.
  final String calling;

  /// Shown while the peer's device rings.
  final String ringing;

  /// Shown while an answered call sets up its audio and video.
  final String callConnecting;

  /// Shown briefly when a call ends.
  final String callEnded;

  /// Label of the button that takes an incoming call.
  final String acceptCall;

  /// Label of the button that refuses an incoming call.
  final String declineCall;

  /// Tooltip of the button that ends a call.
  final String hangUp;

  /// Tooltip of the button that mutes the microphone.
  final String muteMicrophone;

  /// Tooltip of the button that unmutes the microphone.
  final String unmuteMicrophone;

  /// Tooltip of the button that stops sending video.
  final String turnCameraOff;

  /// Tooltip of the button that sends video again.
  final String turnCameraOn;

  /// Tooltip of the button that swaps the front and back cameras.
  final String switchCamera;

  /// Tooltip of the button that plays the call on the loudspeaker.
  final String speakerOn;

  /// Tooltip of the button that plays the call on the earpiece.
  final String speakerOff;

  /// A call could not start because the chat already has one.
  final String callBusy;

  /// The server or the chat does not take calls.
  final String callUnavailable;

  /// The user did not allow the microphone or camera.
  final String callPermissionDenied;

  /// A call failed to connect or dropped.
  final String callFailed;

  /// Label of the menu item that logs out and deletes the chats kept on
  /// the device.
  final String logOut;

  /// A message in the outbox, waiting for the link or on its way.
  final String messageWaiting;

  /// A message the server took.
  final String messageSent;

  /// A message the server refused; the user can retry or discard it.
  final String messageNotSent;

  /// Label of the action that drops a message that was not sent.
  final String discardMessage;

  /// Label of the action that deletes a message for the user only.
  final String deleteForMe;

  /// Label of the action that deletes a message for everyone in the chat.
  final String deleteForEveryone;

  /// Tooltip of the chat list's button that finds people to chat with.
  final String newChat;

  /// Hint of the search field, saying what a search can match.
  final String findHint;

  /// A search that found no one.
  final String nobodyFound;

  /// Under a search result that is a group.
  final String groupLabel;

  /// Under a search result that is a channel.
  final String channelLabel;

  /// Title of the screen that creates a group, and of the entry opening it.
  final String newGroup;

  /// Label of the new group's name field.
  final String groupNameField;

  /// Hint of the field that finds people to add to a new group.
  final String addMembersHint;

  /// Label of the button that creates the new group.
  final String createGroup;

  /// The group was created, but the server refused some of its members.
  final String membersNotAdded;

  /// Status of one of the user's messages that every other member
  /// received.
  final String messageDelivered;

  /// Status of one of the user's messages that every other member read.
  final String messageRead;

  /// The entry that lists who read one of the user's group messages, and
  /// the heading of those who did.
  final String readBy;

  /// Heading of the members who received the message but haven't read it.
  final String deliveredTo;

  /// Shown in the read-by list while no other member read the message.
  final String notReadYet;

  /// In place of the name of a member whose profile isn't known yet.
  final String unknownMember;

  /// Under a direct chat's title while the peer types.
  final String typingDirect;

  /// Under a group's title while one member types.
  final String Function(String name) typingOne;

  /// Under a group's title while two members type.
  final String Function(String first, String second) typingTwo;

  /// Under a group's title while three or more members type, given how
  /// many.
  final String Function(int count) typingMany;

  /// Tooltip of the composer's button that sends an image or a file.
  final String attach;

  /// Sends a photo from the gallery.
  final String attachPhoto;

  /// Takes a photo with the camera and sends it.
  final String attachCamera;

  /// Sends any file.
  final String attachFile;

  /// Hint of the caption field before sending an image or a file.
  final String captionHint;

  /// Shown while an image or a file goes to the server.
  final String uploading;

  /// Stops an upload and drops the message.
  final String cancelUpload;

  /// The server refused a file as too large, or it is over the limit.
  final String fileTooLarge;

  /// [fileTooLarge] with the server's limit, e.g. `32 MB`.
  final String Function(String limit) fileTooLargeLimit;

  /// A received file could not be fetched.
  final String downloadFailed;

  /// Nothing on the device opens a received file.
  final String cannotOpenFile;

  /// Opens a received file.
  final String openFile;

  /// Names an image without a file name, e.g. for screen readers.
  final String imageLabel;

  /// Names a file without a file name.
  final String fileLabel;
}

String _typingOne(String name) => '$name is typing…';

String _typingTwo(String first, String second) =>
    '$first and $second are typing…';

String _typingMany(int count) => '$count people are typing…';

String _fileTooLargeLimit(String limit) =>
    'The file is too large to send: the limit is $limit.';
