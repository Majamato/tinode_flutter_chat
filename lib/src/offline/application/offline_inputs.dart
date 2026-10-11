import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/offline/domain/tinode_cache_limits.dart';

part 'offline_inputs.g.dart';

/// Where the per-user caches live; tests override it with memory.
@Riverpod(keepAlive: true)
ChatStoreOpener chatStoreOpener(Ref ref) => DeviceChatStoreOpener();

/// How much of each user's chats stays on the device;
/// `createTinodeContainer` overrides it with the host's.
@Riverpod(keepAlive: true)
TinodeCacheLimits tinodeCacheLimits(Ref ref) => const TinodeCacheLimits();
