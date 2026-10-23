import 'package:tinode_flutter_chat/src/chats/domain/message_receipt.dart';
import 'package:tinode_flutter_chat/src/chats/domain/tinode_bubble.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';

/// The status a bubble builder sees for a numbered message's [receipt].
TinodeBubbleStatus bubbleStatusOfReceipt(MessageReceipt? receipt) =>
    switch (receipt) {
      MessageReceipt.read => TinodeBubbleStatus.read,
      MessageReceipt.delivered => TinodeBubbleStatus.delivered,
      MessageReceipt.sent || null => TinodeBubbleStatus.sent,
    };

/// The status a bubble builder sees for a message in the outbox.
TinodeBubbleStatus bubbleStatusOfOutbox(OutgoingStatus status) =>
    switch (status) {
      OutgoingStatus.queued ||
      OutgoingStatus.sending => TinodeBubbleStatus.waiting,
      OutgoingStatus.failed => TinodeBubbleStatus.failed,
    };
