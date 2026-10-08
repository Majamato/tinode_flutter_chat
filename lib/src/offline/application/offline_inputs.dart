import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';

part 'offline_inputs.g.dart';

/// Where the per-user caches live; tests override it with memory.
@Riverpod(keepAlive: true)
ChatStoreOpener chatStoreOpener(Ref ref) => DeviceChatStoreOpener();
