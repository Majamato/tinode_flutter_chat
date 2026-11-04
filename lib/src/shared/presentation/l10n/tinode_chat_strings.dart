import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings_scope.dart';

/// Every text `TinodeChat` shows, in English, Spanish or French.
///
/// Left unset, `TinodeChat` picks the texts of the app's locale with
/// [TinodeChatStrings.forLocale]. Pass your own to `TinodeChat.strings` to
/// force a language, or to reword some texts:
///
/// ```dart
/// TinodeChat(
///   config: config,
///   strings: const TinodeChatStrings.es(chatListTitle: 'Conversaciones'),
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
    this.recordVoiceMessage = 'Record voice message',
    this.sendVoiceMessage = 'Send voice message',
    this.deleteRecording = 'Delete recording',
    this.pauseRecording = 'Pause',
    this.resumeRecording = 'Resume',
    this.recordingVoiceMessage = 'Recording voice message',
    this.playVoiceMessage = 'Play voice message',
    this.pauseVoiceMessage = 'Pause voice message',
    this.microphoneDeniedForVoice =
        'Allow access to the microphone to record voice messages.',
    this.voiceMessageTooShort = 'Too short to send. Tap the mic to record.',
    this.cannotRecordDuringCall = "You can't record during a call.",
    this.cannotPlayVoiceMessage = "Can't play this voice message.",
    this.recorderFailed = "Couldn't record a voice message.",
    this.today = 'Today',
    this.yesterday = 'Yesterday',
    this.backToChats = 'Back to chats',
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
    this.callSpeakerLabel = 'Speaker',
    this.callMuteLabel = 'Mute',
    this.callEndLabel = 'End',
    this.minimizeCall = 'Back to chat',
    this.returnToCall = 'Return to call',
    this.callReconnecting = 'Reconnecting…',
    this.cameraOff = 'Camera off',
    this.yourCamera = 'Your camera',
    this.toggleCallControls = 'Show or hide call controls',
    this.callBusy = 'This chat is still in a call. Try again in a moment.',
    this.callUnavailable = 'Calls are not available in this chat.',
    this.callPermissionDenied =
        'Allow access to the microphone and camera to make calls.',
    this.callFailed = 'The call could not be connected.',
    this.callLost = 'The connection dropped. The call ended.',
    this.callOffline = "You're offline. The call ended.",
    this.callAgain = 'Call again',
    this.closeCall = 'Close',
    this.unknownCaller = 'Unknown caller',
    this.ongoingCall = 'Call in progress',
    this.missedVoiceCall = 'Missed voice call',
    this.missedVideoCall = 'Missed video call',
    this.logOut = 'Log out',
    this.messageWaiting = 'Waiting to send',
    this.messageSent = 'Sent',
    this.messageNotSent = 'Not sent',
    this.discardMessage = 'Discard',
    this.deleteForMe = 'Delete for me',
    this.deleteForEveryone = 'Delete for everyone',
    this.newChat = 'New chat',
    this.newMessage = 'New message',
    this.accountMenu = 'Account',
    this.searchChats = 'Search',
    this.chatMuted = 'Muted',
    this.newMessageArrived = 'New message',
    this.photoMessage = 'Photo',
    this.voiceMessage = 'Voice message',
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
    this.online = 'online',
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
    this.signUpTab = 'Sign up',
    this.loginHeadline = 'Welcome back',
    this.loginSubtitle = 'Sign in to pick up where you left off.',
    this.signUpHeadline = 'Create your account',
    this.signUpSubtitle = 'It takes less than a minute.',
    this.signUpTerms = '',
    this.showPassword = 'Show password',
    this.hidePassword = 'Hide password',
    this.loginBubbleHello = '¡Hola!',
    this.loginBubbleLater = 'Call me later?',
    this.displayNameField = 'Your name',
    this.signUp = 'Create account',
    this.forgotPassword = 'Forgot password?',
    this.resetPasswordTitle = 'Reset password',
    this.emailField = 'Email',
    this.sendResetCode = 'Send code',
    this.resetCodeSent = 'If an account has this email, a code is on its way.',
    this.resetCodeField = 'Code from the email',
    this.newPasswordField = 'New password',
    this.setPassword = 'Set password',
    this.passwordResetDone = 'Password changed. Sign in with the new one.',
    this.profile = 'Profile',
    this.nameField = 'Name',
    this.noteField = 'About',
    this.save = 'Save',
    this.profileSaved = 'Profile saved.',
    this.changePhoto = 'Change photo',
    this.changePassword = 'Change password',
    this.newLoginField = 'New login (optional)',
    this.passwordChanged = 'Password changed.',
    this.deleteAccount = 'Delete account',
    this.deleteAccountConfirm =
        'Delete your account, with your chats and messages? '
        'This cannot be undone.',
    this.chatInfo = 'Chat info',
    this.members = 'Members',
    this.ownerLabel = 'Owner',
    this.youLabel = 'You',
    this.removeMember = 'Remove',
    this.deleteChat = 'Delete chat',
    this.deleteChatConfirm = 'Delete this chat and its messages for you?',
    this.deleteGroup = 'Delete group',
    this.deleteGroupConfirm =
        'Delete this group and its messages for everyone?',
    this.leaveGroup = 'Leave group',
    this.leaveGroupConfirm =
        'Leave this group? You will not see its messages any more.',
    this.cancel = 'Cancel',
    this.loginTaken = 'This login is taken.',
    this.credentialsRefused =
        'The server refused this login or password. It may be too short.',
    this.wrongResetCode = 'The code is wrong or has expired.',
    this.chatGone = 'This chat is no longer available.',
    this.emailOptionalField = 'Email (optional)',
    this.confirmEmailTitle = 'Confirm your email',
    this.confirmEmailText =
        'Enter the code from the email the server sent you.',
    this.confirm = 'Confirm',
    this.emailTaken = 'This email belongs to another account.',
    this.invalidEmail = 'This is not an email address.',
    this.confirmEmailFirst =
        'Confirm your email first: sign in with your password.',
    this.findPeople = 'Find people and groups',
    this.searchInChat = 'Search in chat',
    this.messageSearchHint = 'Search this chat',
    this.messageSearchIdle = 'Searches the messages kept on this device.',
    this.noMessagesFound = 'No messages found',
    this.messageUnavailable = 'This message is not available right now.',
    this.removeMemberConfirm = _removeMemberConfirm,
    this.callsTitle = 'Calls',
    this.settingsTitle = 'Settings',
    this.noCalls = 'No calls yet',
    this.callBack = 'Call back',
    this.openChat = 'Open chat',
    this.profileSubtitle = 'Name, photo and password',
    this.appearance = 'Appearance',
    this.appearanceColor = 'Color',
    this.appearanceColorHelp =
        'Changes your bubbles, buttons and icons. Only you see your color.',
    this.appearanceTheme = 'Theme',
    this.themeLight = 'Light',
    this.themeDark = 'Dark',
    this.themeSystem = 'System',
    this.appearancePreviewQuestion = 'Which color are we using?',
    this.appearancePreviewAnswer = _appearancePreviewAnswer,
    this.resetPalette = _resetPalette,
    this.unreadCount = _unreadCount,
  });

  /// Creates the texts in Spanish; any left out keep their Spanish default.
  const TinodeChatStrings.es({
    this.chatListTitle = 'Chats',
    this.noChats = 'Aún no hay chats',
    this.connecting = 'Conectando…',
    this.loginTitle = 'Iniciar sesión',
    this.loginField = 'Usuario',
    this.passwordField = 'Contraseña',
    this.signIn = 'Iniciar sesión',
    this.retry = 'Reintentar',
    this.reconnect = 'Reconectar',
    this.reconnecting = 'Reconectando…',
    this.messageHint = 'Mensaje',
    this.send = 'Enviar',
    this.recordVoiceMessage = 'Grabar mensaje de voz',
    this.sendVoiceMessage = 'Enviar mensaje de voz',
    this.deleteRecording = 'Eliminar grabación',
    this.pauseRecording = 'Pausar',
    this.resumeRecording = 'Reanudar',
    this.recordingVoiceMessage = 'Grabando mensaje de voz',
    this.playVoiceMessage = 'Reproducir mensaje de voz',
    this.pauseVoiceMessage = 'Pausar mensaje de voz',
    this.microphoneDeniedForVoice =
        'Permite el acceso al micrófono para grabar mensajes de voz.',
    this.voiceMessageTooShort =
        'Demasiado corto para enviarlo. Toca el micrófono para grabar.',
    this.cannotRecordDuringCall = 'No puedes grabar durante una llamada.',
    this.cannotPlayVoiceMessage = 'No se puede reproducir este mensaje de voz.',
    this.recorderFailed = 'No se pudo grabar el mensaje de voz.',
    this.today = 'Hoy',
    this.yesterday = 'Ayer',
    this.backToChats = 'Volver a los chats',
    this.readOnly = 'Solo los administradores pueden publicar aquí.',
    this.unreachable = 'No se puede conectar con el servidor de chat.',
    this.connectionLost = 'Se perdió la conexión con el servidor de chat.',
    this.badCredentials = 'Usuario o contraseña incorrectos.',
    this.timeout = 'El servidor de chat no respondió a tiempo.',
    this.rejected = 'El servidor de chat rechazó la solicitud.',
    this.unexpected = 'Algo salió mal.',
    this.voiceCall = 'Llamada de voz',
    this.videoCall = 'Videollamada',
    this.outgoingVoiceCall = 'Llamada de voz saliente',
    this.outgoingVideoCall = 'Videollamada saliente',
    this.incomingVoiceCall = 'Llamada de voz entrante',
    this.incomingVideoCall = 'Videollamada entrante',
    this.callInProgress = 'En curso',
    this.callMissed = 'Perdida',
    this.callNoAnswer = 'Sin respuesta',
    this.callDeclined = 'Rechazada',
    this.callNotConnected = 'No conectada',
    this.calling = 'Llamando…',
    this.ringing = 'Sonando…',
    this.callConnecting = 'Conectando…',
    this.callEnded = 'Llamada finalizada',
    this.acceptCall = 'Aceptar',
    this.declineCall = 'Rechazar',
    this.hangUp = 'Colgar',
    this.muteMicrophone = 'Silenciar',
    this.unmuteMicrophone = 'Activar micrófono',
    this.turnCameraOff = 'Apagar cámara',
    this.turnCameraOn = 'Encender cámara',
    this.switchCamera = 'Cambiar cámara',
    this.speakerOn = 'Activar altavoz',
    this.speakerOff = 'Desactivar altavoz',
    this.callSpeakerLabel = 'Altavoz',
    this.callMuteLabel = 'Silenciar',
    this.callEndLabel = 'Colgar',
    this.minimizeCall = 'Volver al chat',
    this.returnToCall = 'Volver a la llamada',
    this.callReconnecting = 'Reconectando…',
    this.cameraOff = 'Cámara apagada',
    this.yourCamera = 'Tu cámara',
    this.toggleCallControls = 'Mostrar u ocultar los controles de la llamada',
    this.callBusy =
        'Este chat sigue en una llamada. Inténtalo de nuevo en un momento.',
    this.callUnavailable = 'Las llamadas no están disponibles en este chat.',
    this.callPermissionDenied =
        'Permite el acceso al micrófono y a la cámara para hacer llamadas.',
    this.callFailed = 'No se pudo conectar la llamada.',
    this.callLost = 'Se cortó la conexión. La llamada terminó.',
    this.callOffline = 'No tienes conexión. La llamada terminó.',
    this.callAgain = 'Volver a llamar',
    this.closeCall = 'Cerrar',
    this.unknownCaller = 'Desconocido',
    this.ongoingCall = 'Llamada en curso',
    this.missedVoiceCall = 'Llamada de voz perdida',
    this.missedVideoCall = 'Videollamada perdida',
    this.logOut = 'Cerrar sesión',
    this.messageWaiting = 'Pendiente de envío',
    this.messageSent = 'Enviado',
    this.messageNotSent = 'No enviado',
    this.discardMessage = 'Descartar',
    this.deleteForMe = 'Eliminar para mí',
    this.deleteForEveryone = 'Eliminar para todos',
    this.newChat = 'Nuevo chat',
    this.newMessage = 'Nuevo mensaje',
    this.accountMenu = 'Cuenta',
    this.searchChats = 'Buscar',
    this.chatMuted = 'Silenciado',
    this.newMessageArrived = 'Nuevo mensaje',
    this.photoMessage = 'Foto',
    this.voiceMessage = 'Mensaje de voz',
    this.findHint = 'Busca por usuario, correo o teléfono',
    this.nobodyFound = 'No se encontró a nadie',
    this.groupLabel = 'Grupo',
    this.channelLabel = 'Canal',
    this.newGroup = 'Nuevo grupo',
    this.groupNameField = 'Nombre del grupo',
    this.addMembersHint = 'Añadir miembros',
    this.createGroup = 'Crear',
    this.membersNotAdded = 'No se pudo añadir a algunos miembros.',
    this.messageDelivered = 'Entregado',
    this.messageRead = 'Leído',
    this.readBy = 'Leído por',
    this.deliveredTo = 'Entregado a',
    this.notReadYet = 'Nadie lo ha leído todavía',
    this.unknownMember = 'Desconocido',
    this.typingDirect = 'escribiendo…',
    this.online = 'en línea',
    this.typingOne = _typingOneEs,
    this.typingTwo = _typingTwoEs,
    this.typingMany = _typingManyEs,
    this.attach = 'Adjuntar',
    this.attachPhoto = 'Foto',
    this.attachCamera = 'Cámara',
    this.attachFile = 'Archivo',
    this.captionHint = 'Añade una descripción',
    this.uploading = 'Subiendo…',
    this.cancelUpload = 'Cancelar',
    this.fileTooLarge = 'El archivo es demasiado grande para enviarlo.',
    this.fileTooLargeLimit = _fileTooLargeLimitEs,
    this.downloadFailed = 'No se pudo descargar el archivo.',
    this.cannotOpenFile =
        'Ninguna app de este dispositivo puede abrir este archivo.',
    this.openFile = 'Abrir',
    this.imageLabel = 'Imagen',
    this.fileLabel = 'Archivo',
    this.signUpTab = 'Registrarse',
    this.loginHeadline = 'Hola de nuevo',
    this.loginSubtitle = 'Inicia sesión para seguir donde lo dejaste.',
    this.signUpHeadline = 'Crea tu cuenta',
    this.signUpSubtitle = 'Te llevará menos de un minuto.',
    this.signUpTerms = '',
    this.showPassword = 'Mostrar contraseña',
    this.hidePassword = 'Ocultar contraseña',
    this.loginBubbleHello = '¡Hola!',
    this.loginBubbleLater = '¿Me llamas luego?',
    this.displayNameField = 'Tu nombre',
    this.signUp = 'Crear cuenta',
    this.forgotPassword = '¿Olvidaste tu contraseña?',
    this.resetPasswordTitle = 'Restablecer contraseña',
    this.emailField = 'Correo electrónico',
    this.sendResetCode = 'Enviar código',
    this.resetCodeSent =
        'Si hay una cuenta con este correo, el código ya va de camino.',
    this.resetCodeField = 'Código del correo',
    this.newPasswordField = 'Nueva contraseña',
    this.setPassword = 'Guardar contraseña',
    this.passwordResetDone = 'Contraseña cambiada. Inicia sesión con la nueva.',
    this.profile = 'Perfil',
    this.nameField = 'Nombre',
    this.noteField = 'Sobre mí',
    this.save = 'Guardar',
    this.profileSaved = 'Perfil guardado.',
    this.changePhoto = 'Cambiar foto',
    this.changePassword = 'Cambiar contraseña',
    this.newLoginField = 'Nuevo usuario (opcional)',
    this.passwordChanged = 'Contraseña cambiada.',
    this.deleteAccount = 'Eliminar cuenta',
    this.deleteAccountConfirm =
        '¿Eliminar tu cuenta, con tus chats y mensajes? No se puede deshacer.',
    this.chatInfo = 'Info del chat',
    this.members = 'Miembros',
    this.ownerLabel = 'Propietario',
    this.youLabel = 'Tú',
    this.removeMember = 'Quitar',
    this.deleteChat = 'Eliminar chat',
    this.deleteChatConfirm = '¿Eliminar este chat y sus mensajes para ti?',
    this.deleteGroup = 'Eliminar grupo',
    this.deleteGroupConfirm = '¿Eliminar este grupo y sus mensajes para todos?',
    this.leaveGroup = 'Salir del grupo',
    this.leaveGroupConfirm = '¿Salir de este grupo? Ya no verás sus mensajes.',
    this.cancel = 'Cancelar',
    this.loginTaken = 'Este usuario ya existe.',
    this.credentialsRefused =
        'El servidor rechazó este usuario o contraseña. Puede que sea '
        'demasiado corto.',
    this.wrongResetCode = 'El código es incorrecto o ha caducado.',
    this.chatGone = 'Este chat ya no está disponible.',
    this.emailOptionalField = 'Correo electrónico (opcional)',
    this.confirmEmailTitle = 'Confirma tu correo',
    this.confirmEmailText =
        'Escribe el código del correo que te envió el servidor.',
    this.confirm = 'Confirmar',
    this.emailTaken = 'Este correo pertenece a otra cuenta.',
    this.invalidEmail = 'Esto no es una dirección de correo.',
    this.confirmEmailFirst =
        'Primero confirma tu correo: inicia sesión con tu contraseña.',
    this.findPeople = 'Buscar personas y grupos',
    this.searchInChat = 'Buscar en el chat',
    this.messageSearchHint = 'Buscar en este chat',
    this.messageSearchIdle =
        'Busca en los mensajes guardados en este dispositivo.',
    this.noMessagesFound = 'No se encontraron mensajes',
    this.messageUnavailable = 'Este mensaje no está disponible ahora mismo.',
    this.removeMemberConfirm = _removeMemberConfirmEs,
    this.callsTitle = 'Llamadas',
    this.settingsTitle = 'Ajustes',
    this.noCalls = 'Aún no hay llamadas',
    this.callBack = 'Devolver llamada',
    this.openChat = 'Abrir chat',
    this.profileSubtitle = 'Nombre, foto y contraseña',
    this.appearance = 'Apariencia',
    this.appearanceColor = 'Color',
    this.appearanceColorHelp =
        'Cambia tus burbujas, botones e iconos. Solo tú ves tu color.',
    this.appearanceTheme = 'Tema',
    this.themeLight = 'Claro',
    this.themeDark = 'Oscuro',
    this.themeSystem = 'Sistema',
    this.appearancePreviewQuestion = '¿Qué color estamos usando?',
    this.appearancePreviewAnswer = _appearancePreviewAnswerEs,
    this.resetPalette = _resetPaletteEs,
    this.unreadCount = _unreadCountEs,
  });

  /// Creates the texts in French; any left out keep their French default.
  const TinodeChatStrings.fr({
    this.chatListTitle = 'Discussions',
    this.noChats = 'Aucune discussion pour le moment',
    this.connecting = 'Connexion…',
    this.loginTitle = 'Se connecter',
    this.loginField = 'Identifiant',
    this.passwordField = 'Mot de passe',
    this.signIn = 'Se connecter',
    this.retry = 'Réessayer',
    this.reconnect = 'Se reconnecter',
    this.reconnecting = 'Reconnexion…',
    this.messageHint = 'Message',
    this.send = 'Envoyer',
    this.recordVoiceMessage = 'Enregistrer un message vocal',
    this.sendVoiceMessage = 'Envoyer le message vocal',
    this.deleteRecording = "Supprimer l'enregistrement",
    this.pauseRecording = 'Pause',
    this.resumeRecording = 'Reprendre',
    this.recordingVoiceMessage = 'Enregistrement du message vocal',
    this.playVoiceMessage = 'Lire le message vocal',
    this.pauseVoiceMessage = 'Mettre en pause le message vocal',
    this.microphoneDeniedForVoice =
        "Autorisez l'accès au micro pour enregistrer des messages vocaux.",
    this.voiceMessageTooShort =
        'Trop court pour être envoyé. Touchez le micro pour enregistrer.',
    this.cannotRecordDuringCall =
        'Vous ne pouvez pas enregistrer pendant un appel.',
    this.cannotPlayVoiceMessage = 'Impossible de lire ce message vocal.',
    this.recorderFailed = "Impossible d'enregistrer le message vocal.",
    this.today = "Aujourd'hui",
    this.yesterday = 'Hier',
    this.backToChats = 'Retour aux discussions',
    this.readOnly = 'Seuls les administrateurs peuvent publier ici.',
    this.unreachable = 'Impossible de joindre le serveur de discussion.',
    this.connectionLost = 'La connexion au serveur de discussion a été perdue.',
    this.badCredentials = 'Identifiant ou mot de passe incorrect.',
    this.timeout = "Le serveur de discussion n'a pas répondu à temps.",
    this.rejected = 'Le serveur de discussion a refusé la requête.',
    this.unexpected = "Une erreur s'est produite.",
    this.voiceCall = 'Appel vocal',
    this.videoCall = 'Appel vidéo',
    this.outgoingVoiceCall = 'Appel vocal sortant',
    this.outgoingVideoCall = 'Appel vidéo sortant',
    this.incomingVoiceCall = 'Appel vocal entrant',
    this.incomingVideoCall = 'Appel vidéo entrant',
    this.callInProgress = 'En cours',
    this.callMissed = 'Manqué',
    this.callNoAnswer = 'Sans réponse',
    this.callDeclined = 'Refusé',
    this.callNotConnected = 'Non connecté',
    this.calling = 'Appel…',
    this.ringing = 'Ça sonne…',
    this.callConnecting = 'Connexion…',
    this.callEnded = 'Appel terminé',
    this.acceptCall = 'Accepter',
    this.declineCall = 'Refuser',
    this.hangUp = 'Raccrocher',
    this.muteMicrophone = 'Couper le micro',
    this.unmuteMicrophone = 'Réactiver le micro',
    this.turnCameraOff = 'Désactiver la caméra',
    this.turnCameraOn = 'Activer la caméra',
    this.switchCamera = 'Changer de caméra',
    this.speakerOn = 'Activer le haut-parleur',
    this.speakerOff = 'Désactiver le haut-parleur',
    this.callSpeakerLabel = 'Haut-parleur',
    this.callMuteLabel = 'Muet',
    this.callEndLabel = 'Fin',
    this.minimizeCall = 'Retour à la discussion',
    this.returnToCall = "Revenir à l'appel",
    this.callReconnecting = 'Reconnexion…',
    this.cameraOff = 'Caméra désactivée',
    this.yourCamera = 'Votre caméra',
    this.toggleCallControls = "Afficher ou masquer les commandes d'appel",
    this.callBusy =
        'Cette discussion est encore en appel. Réessayez dans un instant.',
    this.callUnavailable =
        'Les appels ne sont pas disponibles dans cette discussion.',
    this.callPermissionDenied =
        "Autorisez l'accès au micro et à la caméra pour passer des appels.",
    this.callFailed = "L'appel n'a pas pu être établi.",
    this.callLost = "La connexion a été coupée. L'appel est terminé.",
    this.callOffline = "Vous êtes hors ligne. L'appel est terminé.",
    this.callAgain = 'Rappeler',
    this.closeCall = 'Fermer',
    this.unknownCaller = 'Appelant inconnu',
    this.ongoingCall = 'Appel en cours',
    this.missedVoiceCall = 'Appel vocal manqué',
    this.missedVideoCall = 'Appel vidéo manqué',
    this.logOut = 'Se déconnecter',
    this.messageWaiting = "En attente d'envoi",
    this.messageSent = 'Envoyé',
    this.messageNotSent = 'Non envoyé',
    this.discardMessage = 'Abandonner',
    this.deleteForMe = 'Supprimer pour moi',
    this.deleteForEveryone = 'Supprimer pour tout le monde',
    this.newChat = 'Nouvelle discussion',
    this.newMessage = 'Nouveau message',
    this.accountMenu = 'Compte',
    this.searchChats = 'Rechercher',
    this.chatMuted = 'En sourdine',
    this.newMessageArrived = 'Nouveau message',
    this.photoMessage = 'Photo',
    this.voiceMessage = 'Message vocal',
    this.findHint = 'Rechercher par identifiant, e-mail ou téléphone',
    this.nobodyFound = 'Aucun résultat',
    this.groupLabel = 'Groupe',
    this.channelLabel = 'Canal',
    this.newGroup = 'Nouveau groupe',
    this.groupNameField = 'Nom du groupe',
    this.addMembersHint = 'Ajouter des membres',
    this.createGroup = 'Créer',
    this.membersNotAdded = "Certains membres n'ont pas pu être ajoutés.",
    this.messageDelivered = 'Distribué',
    this.messageRead = 'Lu',
    this.readBy = 'Lu par',
    this.deliveredTo = 'Distribué à',
    this.notReadYet = "Personne ne l'a encore lu",
    this.unknownMember = 'Inconnu',
    this.typingDirect = "en train d'écrire…",
    this.online = 'en ligne',
    this.typingOne = _typingOneFr,
    this.typingTwo = _typingTwoFr,
    this.typingMany = _typingManyFr,
    this.attach = 'Joindre',
    this.attachPhoto = 'Photo',
    this.attachCamera = 'Appareil photo',
    this.attachFile = 'Fichier',
    this.captionHint = 'Ajouter une légende',
    this.uploading = 'Envoi…',
    this.cancelUpload = 'Annuler',
    this.fileTooLarge = 'Le fichier est trop volumineux pour être envoyé.',
    this.fileTooLargeLimit = _fileTooLargeLimitFr,
    this.downloadFailed = "Le fichier n'a pas pu être téléchargé.",
    this.cannotOpenFile =
        'Aucune app de cet appareil ne peut ouvrir ce fichier.',
    this.openFile = 'Ouvrir',
    this.imageLabel = 'Image',
    this.fileLabel = 'Fichier',
    this.signUpTab = "S'inscrire",
    this.loginHeadline = 'Bon retour',
    this.loginSubtitle = 'Connectez-vous pour reprendre là où vous en étiez.',
    this.signUpHeadline = 'Créez votre compte',
    this.signUpSubtitle = "Cela prend moins d'une minute.",
    this.signUpTerms = '',
    this.showPassword = 'Afficher le mot de passe',
    this.hidePassword = 'Masquer le mot de passe',
    this.loginBubbleHello = 'Salut\u00A0!',
    this.loginBubbleLater = "On s'appelle plus tard\u00A0?",
    this.displayNameField = 'Votre nom',
    this.signUp = 'Créer un compte',
    this.forgotPassword = 'Mot de passe oublié\u00A0?',
    this.resetPasswordTitle = 'Réinitialiser le mot de passe',
    this.emailField = 'E-mail',
    this.sendResetCode = 'Envoyer le code',
    this.resetCodeSent =
        'Si un compte utilise cet e-mail, un code est en route.',
    this.resetCodeField = 'Code reçu par e-mail',
    this.newPasswordField = 'Nouveau mot de passe',
    this.setPassword = 'Enregistrer le mot de passe',
    this.passwordResetDone =
        'Mot de passe modifié. Connectez-vous avec le nouveau.',
    this.profile = 'Profil',
    this.nameField = 'Nom',
    this.noteField = 'À propos',
    this.save = 'Enregistrer',
    this.profileSaved = 'Profil enregistré.',
    this.changePhoto = 'Changer de photo',
    this.changePassword = 'Changer de mot de passe',
    this.newLoginField = 'Nouvel identifiant (facultatif)',
    this.passwordChanged = 'Mot de passe modifié.',
    this.deleteAccount = 'Supprimer le compte',
    this.deleteAccountConfirm =
        'Supprimer votre compte, avec vos discussions et vos messages\u00A0? '
        'Cette action est irréversible.',
    this.chatInfo = 'Infos de la discussion',
    this.members = 'Membres',
    this.ownerLabel = 'Propriétaire',
    this.youLabel = 'Vous',
    this.removeMember = 'Retirer',
    this.deleteChat = 'Supprimer la discussion',
    this.deleteChatConfirm =
        'Supprimer cette discussion et ses messages pour vous\u00A0?',
    this.deleteGroup = 'Supprimer le groupe',
    this.deleteGroupConfirm =
        'Supprimer ce groupe et ses messages pour tout le monde\u00A0?',
    this.leaveGroup = 'Quitter le groupe',
    this.leaveGroupConfirm =
        'Quitter ce groupe\u00A0? Vous ne verrez plus ses messages.',
    this.cancel = 'Annuler',
    this.loginTaken = 'Cet identifiant est déjà pris.',
    this.credentialsRefused =
        'Le serveur a refusé cet identifiant ou ce mot de passe. Il est '
        'peut-être trop court.',
    this.wrongResetCode = 'Le code est incorrect ou a expiré.',
    this.chatGone = "Cette discussion n'est plus disponible.",
    this.emailOptionalField = 'E-mail (facultatif)',
    this.confirmEmailTitle = 'Confirmez votre e-mail',
    this.confirmEmailText =
        "Saisissez le code de l'e-mail que le serveur vous a envoyé.",
    this.confirm = 'Confirmer',
    this.emailTaken = 'Cet e-mail appartient à un autre compte.',
    this.invalidEmail = "Ce n'est pas une adresse e-mail.",
    this.confirmEmailFirst =
        "Confirmez d'abord votre e-mail\u00A0: connectez-vous avec votre mot "
        'de passe.',
    this.findPeople = 'Trouver des personnes et des groupes',
    this.searchInChat = 'Rechercher dans la discussion',
    this.messageSearchHint = 'Rechercher dans cette discussion',
    this.messageSearchIdle =
        'Recherche dans les messages conservés sur cet appareil.',
    this.noMessagesFound = 'Aucun message trouvé',
    this.messageUnavailable = "Ce message n'est pas disponible pour le moment.",
    this.removeMemberConfirm = _removeMemberConfirmFr,
    this.callsTitle = 'Appels',
    this.settingsTitle = 'Paramètres',
    this.noCalls = 'Aucun appel pour le moment',
    this.callBack = 'Rappeler',
    this.openChat = 'Ouvrir la discussion',
    this.profileSubtitle = 'Nom, photo et mot de passe',
    this.appearance = 'Apparence',
    this.appearanceColor = 'Couleur',
    this.appearanceColorHelp =
        "Change vos bulles, vos boutons et vos icônes. Cette couleur n'est "
        'visible que par vous.',
    this.appearanceTheme = 'Thème',
    this.themeLight = 'Clair',
    this.themeDark = 'Sombre',
    this.themeSystem = 'Système',
    this.appearancePreviewQuestion = 'On utilise quelle couleur\u00A0?',
    this.appearancePreviewAnswer = _appearancePreviewAnswerFr,
    this.resetPalette = _resetPaletteFr,
    this.unreadCount = _unreadCountFr,
  });

  /// The built-in texts for [locale]'s language: Spanish, French, or
  /// English for any other.
  factory TinodeChatStrings.forLocale(Locale locale) =>
      switch (locale.languageCode) {
        'es' => const TinodeChatStrings.es(),
        'fr' => const TinodeChatStrings.fr(),
        _ => const TinodeChatStrings(),
      };

  /// The texts of the nearest `TinodeChat`, or outside one those of the
  /// app's locale.
  factory TinodeChatStrings.of(BuildContext context) =>
      TinodeChatStringsScope.maybeOf(context) ??
      TinodeChatStrings.forLocale(
        Localizations.maybeLocaleOf(context) ?? const Locale('en'),
      );

  /// The languages with built-in texts. Hand them to
  /// `MaterialApp.supportedLocales`, so the app's locale can resolve to
  /// them.
  static const supportedLocales = [Locale('en'), Locale('es'), Locale('fr')];

  /// Title of the chat list screen.
  final String chatListTitle;

  /// Shown when the chat list is empty.
  final String noChats;

  /// Shown while connecting to the server.
  final String connecting;

  /// The login screen's switch to signing in.
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

  /// Shown while the client restores a dropped connection by itself: in
  /// place of the chat list's and calls' titles, and under a chat's name.
  final String reconnecting;

  /// Placeholder of the message field.
  final String messageHint;

  /// Tooltip of the send button.
  final String send;

  /// Tooltip of the send button while the field is empty: it records.
  final String recordVoiceMessage;

  /// Tooltip of the send button while a voice message records.
  final String sendVoiceMessage;

  /// The recording panel's button that drops the voice message being
  /// recorded.
  final String deleteRecording;

  /// The recording panel's button that pauses the recording.
  final String pauseRecording;

  /// The recording panel's button that carries on a paused recording.
  final String resumeRecording;

  /// Read out when a voice message starts recording.
  final String recordingVoiceMessage;

  /// The play button of a voice message.
  final String playVoiceMessage;

  /// The play button of a voice message while it plays.
  final String pauseVoiceMessage;

  /// The user did not allow the microphone for a voice message.
  final String microphoneDeniedForVoice;

  /// A voice message shorter than two seconds was not sent.
  final String voiceMessageTooShort;

  /// The mic was tapped while a call holds the microphone.
  final String cannotRecordDuringCall;

  /// A voice message's recording could not be fetched or played.
  final String cannotPlayVoiceMessage;

  /// The recorder failed to start or to save.
  final String recorderFailed;

  /// The date above today's first message.
  final String today;

  /// The date above yesterday's first message.
  final String yesterday;

  /// Read out for the chat's back button.
  final String backToChats;

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

  /// The caller on the phone's own ringing screen, when the chat isn't on
  /// the device yet.
  final String unknownCaller;

  /// The phone's notification while a call goes on.
  final String ongoingCall;

  /// The phone's notification, and the chat list's preview, for a voice
  /// call the user didn't answer.
  final String missedVoiceCall;

  /// The phone's notification, and the chat list's preview, for a video
  /// call the user didn't answer.
  final String missedVideoCall;

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

  /// The word under the voice call's loudspeaker button.
  final String callSpeakerLabel;

  /// The word under the voice call's mute button.
  final String callMuteLabel;

  /// The word under the voice call's button that ends it.
  final String callEndLabel;

  /// Tooltip of the chevron that shrinks the call to a bar over the chats.
  final String minimizeCall;

  /// What the bar of a minimized call does when tapped.
  final String returnToCall;

  /// Shown while the link between the two devices drops during a call and
  /// may come back.
  final String callReconnecting;

  /// The user's own video tile in a video call, while their camera is off.
  final String cameraOff;

  /// What screen readers call the user's own video tile.
  final String yourCamera;

  /// What screen readers call the video, a tap on which hides or shows the
  /// controls.
  final String toggleCallControls;

  /// A call could not start because the chat already has one, e.g. one
  /// the server still holds after a dropped connection.
  final String callBusy;

  /// The server or the chat does not take calls.
  final String callUnavailable;

  /// The user did not allow the microphone or camera.
  final String callPermissionDenied;

  /// A call failed to connect or dropped.
  final String callFailed;

  /// A connected call whose link dropped and didn't come back.
  final String callLost;

  /// A call that ended because this device lost the chat server: the
  /// server ends a call whose session drops.
  final String callOffline;

  /// The button that calls the same peer again after a lost call.
  final String callAgain;

  /// The button that closes the screen of a call that ended.
  final String closeCall;

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

  /// Tooltip of the chat list header's compose button, which finds people
  /// to chat with.
  final String newChat;

  /// Tooltip of the chat list's floating button, which does the same.
  final String newMessage;

  /// Tooltip of the chat list's account menu (profile, appearance, log
  /// out), shown without the tab bar.
  final String accountMenu;

  /// The hint of the chat list's search field.
  final String searchChats;

  /// The label of a muted chat's icon in the chat list.
  final String chatMuted;

  /// A chat list preview when the newest message isn't on this device yet.
  final String newMessageArrived;

  /// A chat list preview of a photo without a caption.
  final String photoMessage;

  /// A chat list preview of a voice message without a caption.
  final String voiceMessage;

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

  /// Under a direct chat's title while the peer is online and not typing.
  final String online;

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

  /// The login screen's switch to signing up, where sign-up is offered.
  final String signUpTab;

  /// The login sheet's title while signing in.
  final String loginHeadline;

  /// Under [loginHeadline].
  final String loginSubtitle;

  /// The login sheet's title while signing up.
  final String signUpHeadline;

  /// Under [signUpHeadline].
  final String signUpSubtitle;

  /// Under the sign-up button, e.g. what signing up agrees to. Nothing
  /// when empty, the default.
  final String signUpTerms;

  /// Tooltip of a password field's eye while the password is hidden.
  final String showPassword;

  /// Tooltip of a password field's eye while the password shows.
  final String hidePassword;

  /// The incoming bubble floating over the login screen. Decoration only:
  /// screen readers skip it.
  final String loginBubbleHello;

  /// The outgoing bubble floating over the login screen. Decoration only.
  final String loginBubbleLater;

  /// Label of the name field on sign-up, shown to others.
  final String displayNameField;

  /// Submits the sign-up form.
  final String signUp;

  /// Opens the password reset from the sign-in screen.
  final String forgotPassword;

  /// Title of the password reset screen.
  final String resetPasswordTitle;

  /// Label of the account's email field.
  final String emailField;

  /// Asks the server to email a reset code.
  final String sendResetCode;

  /// Shown once a reset code was asked for.
  final String resetCodeSent;

  /// Label of the reset code field.
  final String resetCodeField;

  /// Label of a new password field.
  final String newPasswordField;

  /// Submits a new password.
  final String setPassword;

  /// Shown on the sign-in screen after a reset.
  final String passwordResetDone;

  /// Opens the user's profile, and titles it.
  final String profile;

  /// Label of the profile name field.
  final String nameField;

  /// Label of the profile note field.
  final String noteField;

  /// Saves changes.
  final String save;

  /// Shown once the profile was saved.
  final String profileSaved;

  /// Picks a new profile photo.
  final String changePhoto;

  /// Opens the password change, and titles it.
  final String changePassword;

  /// Label of the field that also changes the login.
  final String newLoginField;

  /// Shown once the password was changed.
  final String passwordChanged;

  /// Deletes the user's account.
  final String deleteAccount;

  /// Asks before deleting the account.
  final String deleteAccountConfirm;

  /// Title of the screen about one chat.
  final String chatInfo;

  /// Heads a group's member list.
  final String members;

  /// Marks the group's owner in the member list.
  final String ownerLabel;

  /// Marks the user in the member list.
  final String youLabel;

  /// Removes a member from a group.
  final String removeMember;

  /// Deletes a 1:1 chat for the user.
  final String deleteChat;

  /// Asks before deleting a 1:1 chat.
  final String deleteChatConfirm;

  /// Deletes a group the user owns, for everyone.
  final String deleteGroup;

  /// Asks before deleting a group.
  final String deleteGroupConfirm;

  /// Leaves a group for good.
  final String leaveGroup;

  /// Asks before leaving a group.
  final String leaveGroupConfirm;

  /// Closes a question without doing anything.
  final String cancel;

  /// The login is already used by someone else.
  final String loginTaken;

  /// The server's rules refuse the login or password.
  final String credentialsRefused;

  /// A password reset code was refused.
  final String wrongResetCode;

  /// The chat was deleted, or the user was removed from it.
  final String chatGone;

  /// Label of the email field on sign-up where the server needs none.
  final String emailOptionalField;

  /// Title of the screen that confirms the email with a code.
  final String confirmEmailTitle;

  /// Explains the email confirmation.
  final String confirmEmailText;

  /// Sends the email confirmation code.
  final String confirm;

  /// The email is already used.
  final String emailTaken;

  /// The server refused the email as malformed.
  final String invalidEmail;

  /// A token login found the email still unconfirmed.
  final String confirmEmailFirst;

  /// Asks before removing the member `name` from a group.
  final String Function(String name) removeMemberConfirm;

  /// Opens the search for people and groups from the chat list.
  final String findPeople;

  /// Opens message search in a chat, from its app bar.
  final String searchInChat;

  /// The message search field.
  final String messageSearchHint;

  /// Shown before the user types: message search finds only what this
  /// device keeps.
  final String messageSearchIdle;

  /// Message search found nothing.
  final String noMessagesFound;

  /// A message picked from message search can't be shown: deleted, or
  /// not on the device while offline.
  final String messageUnavailable;

  /// Title of the calls history, and its tab.
  final String callsTitle;

  /// Title of the settings screen, its tab, and the way back to it.
  final String settingsTitle;

  /// Shown when the calls history is empty.
  final String noCalls;

  /// What tapping a call in the calls history does, for screen readers.
  final String callBack;

  /// Opens a call's chat from the calls history.
  final String openChat;

  /// Under the user's name in settings: what the profile holds.
  final String profileSubtitle;

  /// Title of the appearance screen, and its entry in settings.
  final String appearance;

  /// The palette section of the appearance screen.
  final String appearanceColor;

  /// Under the palettes: what picking one changes.
  final String appearanceColorHelp;

  /// The light, dark or system section of the appearance screen.
  final String appearanceTheme;

  /// Always light.
  final String themeLight;

  /// Always dark.
  final String themeDark;

  /// Light or dark, as the device is.
  final String themeSystem;

  /// The other person's message in the appearance screen's preview.
  final String appearancePreviewQuestion;

  /// The user's answer in the preview, naming the palette `name`.
  final String Function(String name) appearancePreviewAnswer;

  /// Goes back to the default palette, named `name`.
  final String Function(String name) resetPalette;

  /// The unread count of the chats tab, for screen readers.
  final String Function(int count) unreadCount;
}

String _typingOne(String name) => '$name is typing…';

String _typingTwo(String first, String second) =>
    '$first and $second are typing…';

String _typingMany(int count) => '$count people are typing…';

String _fileTooLargeLimit(String limit) =>
    'The file is too large to send: the limit is $limit.';

String _removeMemberConfirm(String name) => 'Remove $name from the group?';

String _appearancePreviewAnswer(String name) => '$name, obviously';

String _resetPalette(String name) => 'Reset to $name';

String _unreadCount(int count) => '$count unread';

String _typingOneEs(String name) => '$name está escribiendo…';

String _typingTwoEs(String first, String second) =>
    '$first y $second están escribiendo…';

String _typingManyEs(int count) => '$count personas están escribiendo…';

String _fileTooLargeLimitEs(String limit) =>
    'El archivo es demasiado grande para enviarlo: el límite es $limit.';

String _removeMemberConfirmEs(String name) => '¿Quitar a $name del grupo?';

String _appearancePreviewAnswerEs(String name) => '$name, obviamente';

String _resetPaletteEs(String name) => 'Volver a $name';

String _unreadCountEs(int count) => '$count sin leer';

String _typingOneFr(String name) => '$name écrit…';

String _typingTwoFr(String first, String second) =>
    '$first et $second écrivent…';

String _typingManyFr(int count) => '$count personnes écrivent…';

String _fileTooLargeLimitFr(String limit) =>
    'Le fichier est trop volumineux pour être envoyé\u00A0: la limite est '
    'de $limit.';

String _removeMemberConfirmFr(String name) => 'Retirer $name du groupe\u00A0?';

String _appearancePreviewAnswerFr(String name) => '$name, évidemment';

String _resetPaletteFr(String name) => 'Revenir à $name';

/// French counts zero and one in the singular.
String _unreadCountFr(int count) =>
    count <= 1 ? '$count non lu' : '$count non lus';
