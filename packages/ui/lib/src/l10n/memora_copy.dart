/// Spanish-first, localization-ready copy for Slice 4–6 presentation.
///
/// Values are the default `es` surface. Keys are stable identifiers for a
/// future ARB/`AppLocalizations` migration — do not hardcode English-only
/// critical copy in widgets; use these accessors instead.
abstract final class MemoraCopy {
  static const String localeTag = 'es';

  // Demo / non-production
  static const String demoBanner = 'DEMOSTRACIÓN — NO PRODUCCIÓN';
  static const String demoBannerSemantics =
      'Entorno de demostración, no producción';
  static const String syntheticMarker = 'SYNTHETIC / NON-PRODUCTION';
  static const String noRealData =
      'Sin datos reales. Sin conexión remota de producción.';
  static const String notMedical =
      'Memora no es un servicio médico ni de emergencias.';
  static const String isolatedLocalDemoNotice =
      'Demostración local aislada: los cambios de este cliente no aparecen '
      'en otra aplicación.';
  static const String sharedLocalDemoNotice =
      'Demostración local compartida en este ordenador. '
      'Sin servidor de producción.';
  static const String sharedLocalDemoPending = 'Actualizando…';
  static const String sharedLocalDemoPullFailed =
      'No se pudo actualizar. Se muestra lo guardado aquí.';
  static const String sharedLocalDemoDeliveryFailed =
      'El cambio se guardó aquí, pero aún no llegó al otro dispositivo.';

  // Sync / recovery (plain language)
  static const String syncLocal = 'Guardado en este dispositivo';
  static const String syncPending = 'Pendiente de sincronizar';
  static const String syncSynced = 'Sincronizado';
  static const String syncConflicted =
      'Hay un conflicto de sincronización. Puedes seguir usando la rutina.';
  static const String syncFailed =
      'No se pudo sincronizar. Los cambios siguen en este dispositivo.';
  static const String stateEmpty = 'No hay rutinas activas para hoy.';
  static const String stateLoading = 'Cargando rutinas…';
  static const String stateOffline =
      'Sin red. Puedes usar las rutinas con normalidad.';
  static const String recoveryRetry = 'Reintentar';
  static const String recoveryContinueOffline = 'Seguir sin red';
  static const String recoveryReviewConflict = 'Revisar conflicto';
  static const String recoveryCreateRoutine = 'Crear rutina Demo';

  // Brand / product chrome
  static const String brandTitle = 'Memora';
  static const String familyWebSemantics = 'Memora, web familiar';
  static const String changesSaved = 'Cambios guardados';
  static const String configurePreferredNameCta = 'Configurar el nombre';
  static const String syncNeedsAttention =
      'Hay un problema de sincronización. Puedes reintentar o revisarlo.';

  // Navigation
  static const String navRoutines = 'Rutinas';
  static const String navPastimes = 'Pasatiempos';
  static const String navConversations = 'Conversaciones';
  static const String navMemories = 'Recuerdos';
  static const String navObservations = 'Observaciones';
  static const String navSupportedPersonProfile = 'Persona apoyada';
  static const String navSync = 'Sincronización';
  static const String navPrivacy = 'Privacidad';
  static const String navHelp = 'Ayuda';
  static const String navPrimarySemantics = 'Navegación principal';
  static const String navSecondarySemantics = 'Ajustes y ayuda';

  // Session boundary (names only — no credential values)
  static const String sessionDemoTitle = 'Sesión de demostración (sin red)';
  static const String sessionSignedOutTitle = 'Sesión cerrada';
  static const String sessionNamedCredentialsTitle =
      'Credenciales configuradas por nombre (sin valores en pantalla)';
  static const String sessionCredentialNamesHint =
      'Solo nombres de configuración: MEMORA_SUPABASE_URL y '
      'MEMORA_SUPABASE_ANON_KEY. Sin claves de servicio.';

  // Explicit sync chrome
  static const String syncSectionTitle = 'Sincronización';
  static const String syncSectionBody =
      'Los cambios se guardan primero en este dispositivo. '
      'Puedes enviar o recibir cuando haga falta.';
  static const String syncSectionBodyIsolated =
      'Los cambios se guardan en este dispositivo.';
  static const String syncSectionBodyShared =
      'Los cambios se guardan primero aquí y se envían cuando hay conexión.';
  static const String syncPushAction = 'Enviar cambios';
  static const String syncPullAction = 'Recibir cambios';
  static const String syncBusy = 'Sincronizando…';
  static const String syncPushSummaryPrefix = 'Envío:';
  static const String syncPullSummaryPrefix = 'Recepción:';
  static const String syncConflictsTitle = 'Conflictos por resolver';
  static const String syncConflictsEmpty = 'No hay conflictos pendientes.';
  static const String syncConflictRoutine = 'Rutina';
  static const String syncConflictObservation =
      'Observación (se conservan ambas entradas; sin fusionar valores)';
  static const String syncConflictOther = 'Cambio';
  static const String syncResolveKeepLocal = 'Quedarse con la local';
  static const String syncResolveKeepRemote = 'Quedarse con la remota';
  static const String syncResolveKeepBoth = 'Conservar ambas';
  static const String syncResolveUnauthorized =
      'Tu rol no puede resolver conflictos de sincronización.';
  static const String syncCannotResolveObservations =
      'Las observaciones no se fusionan. Se conservan ambas entradas.';

  // Privacy contracts
  static const String privacySectionTitle = 'Privacidad y sesión';
  static const String privacySectionBody =
      'Puedes solicitar la exportación o la eliminación de los datos '
      'familiares y cerrar sesiones activas.';
  static const String privacyExportAction = 'Solicitar exportación';
  static const String privacyDeletionAction = 'Solicitar eliminación';
  static const String privacyExportConfirmed =
      'Solicitud de exportación registrada.';
  static const String privacyDeletionConfirmed =
      'Solicitud de eliminación registrada.';
  static const String privacySessionsTitle = 'Sesiones activas';
  static const String privacySessionsEmpty = 'No hay sesiones activas.';
  static const String privacyRevokeSession = 'Cerrar sesión';
  static const String privacySessionRevoked = 'Sesión cerrada.';

  /// Product-facing label for the current browser session (never fixture ids).
  static const String privacyCurrentBrowserSession = 'Este navegador';

  /// Implementation detail for redaction proofs / optional disclosures only —
  /// not shown on the primary Privacy page.
  static const String privacyAuditNote =
      'El historial auditable guarda solo etiquetas (acción, objetivo, hora). '
      'No muestra contenido, valores de salud, tokens ni rutas de medios.';
  static const String privacyUnauthorized =
      'Tu membresía no puede usar estos contratos de privacidad.';

  // User home — Slice 7 four-tile shell / Slice 12 preferred-name greeting
  static const String userHomeTitle = 'Hoy';

  /// Safe fallback when no cached preferred name is available.
  static const String userHomeGreeting = 'Hola';

  /// Neutral invitation after the greeting (Slice 13). Not a tutorial or modal.
  static const String userHomeInvitation =
      'Toca una opción para elegir qué quieres hacer.';

  // Family web — supported-person preferred-name profile (Slice 12)
  static const String supportedPersonProfileSectionTitle = 'Persona apoyada';
  static const String supportedPersonProfileSectionBody =
      'Configura el nombre que verá la persona apoyada en la pantalla de '
      'inicio de Memora. Solo la persona cuidadora principal puede '
      'cambiarlo.';
  static const String preferredNameFieldLabel = 'Nombre que verá en Memora';
  static const String savePreferredName = 'Guardar nombre';
  static const String correctPreferredName = 'Corregir nombre';
  static const String supportedPersonProfileLoading = 'Cargando el perfil…';
  static const String supportedPersonProfileEmpty =
      'Aún no hay un nombre configurado.';
  static const String supportedPersonProfileValidationError =
      'Escribe un nombre de 1 a 40 caracteres, sin espacios solos.';
  static const String supportedPersonProfileUnauthorized =
      'Tu rol no puede cambiar el nombre de la persona apoyada.';
  static const String supportedPersonProfileReadOnly =
      'Puedes ver el nombre, pero solo la persona cuidadora principal '
      'puede cambiarlo.';
  static const String homeTileMiDia = 'Mi día';
  static const String homeTilePasatiempos = 'Pasatiempos';
  static const String homeTileQuieroHablar = 'Quiero hablar';
  static const String homeTileRecuerdos = 'Recuerdos';
  static const String homeSemanticsLabel = 'Inicio de Memora';
  static const String returnHome = 'Volver al inicio';
  static const String todaysRoutines = 'Rutinas de hoy';
  static const String primaryActionComplete = 'Marcar como hecho';
  static const String primaryActionCorrect = 'Corregir: aún no hecho';
  static const String stepPending = 'Pendiente';
  static const String stepCompleted = 'Hecho';
  static const String noPrimaryAction = 'Todas las tareas de hoy están hechas.';
  static const String nextStepLabel = 'Siguiente paso';
  static const String miDiaTitle = 'Mi día';
  static const String miDiaEmptyBody =
      'Hoy no hay un paso pendiente. Puedes volver al inicio cuando quieras.';

  // Pasatiempos — family-configured cards (no completion / performed claim)
  static const String pasatiemposTitle = 'Pasatiempos';
  static const String pasatiemposBody =
      'Aquí aparecerán las actividades que configure tu familia. '
      'De momento no hay ninguna preparada.';
  static const String pasatiemposBackToList = 'Volver a Pasatiempos';
  static const String pasatiemposOpenHint = 'Abrir';
  static const String pasatiemposLoading = 'Cargando pasatiempos…';
  static const String pasatiemposOffline =
      'Sin red. Los pasatiempos guardados siguen disponibles.';
  static const String pasatiemposIsolatedDemoNotice =
      'Esta lista es solo de demostración en este dispositivo.';
  static const String pasatiemposSharedPullFailed =
      'No se pudieron cargar los cambios de tu familia. '
      'Se muestran las actividades guardadas aquí.';
  static const String pasatiemposSharedPending =
      'Actualizando las actividades…';
  static const String pasatiemposStart = 'Empezar';
  static const String pasatiemposFinish = 'Terminar';
  static const String pasatiemposRestart = 'Volver a empezar';
  static const String pasatiemposRestartConfirm =
      '¿Quieres volver a empezar esta actividad? '
      'Se perderá el progreso actual.';
  static const String pasatiemposExitConfirm =
      '¿Quieres salir de esta actividad? Puedes volver más tarde.';
  static const String pasatiemposExitConfirmYes = 'Salir';
  static const String pasatiemposExitConfirmStay = 'Seguir';
  static const String pasatiemposConfirmYes = 'Sí';
  static const String pasatiemposConfirmNo = 'No';
  static const String pasatiemposCompletedTitle =
      'Has terminado. ¿Qué quieres hacer ahora?';
  static const String pasatiemposPlayAgain = 'Jugar otra vez';
  static const String pasatiemposContinue = 'Continuar';
  static const String pasatiemposStartOver = 'Empezar de nuevo';
  static const String pasatiemposRecoveryBody =
      'Hay una actividad sin terminar en este dispositivo.';
  static const String pasatiemposRecoveryDiscarded =
      'No se pudo recuperar la actividad anterior. Puedes empezar de nuevo.';
  static const String pasatiemposUnavailable =
      'Esta actividad no se puede abrir ahora. Vuelve a Pasatiempos.';
  static const String pasatiemposUndo = 'Deshacer';
  static const String pasatiemposClear = 'Borrar';
  static const String pasatiemposNotes = 'Notas';
  static const String pasatiemposShowSolution = 'Mostrar la solución';
  static const String pasatiemposShowSolutionConfirm =
      'Si muestras la solución, esta partida terminará. ¿Continuar?';
  static const String pasatiemposSolutionShown = 'Solución mostrada';
  static const String pasatiemposSolutionContinue =
      'Continuar después de la solución';
  static const String pasatiemposShowHint = 'Mostrar un movimiento';
  static const String pasatiemposDealStock = 'Repartir cartas';
  static const String pasatiemposGoToColumn = 'Ir a columna';
  static const String pasatiemposWordList = 'Palabras';
  static const String pasatiemposCancelSelection = 'Cancelar selección';

  // Quiero hablar — family-guided conversation topics (never a telephone)
  static const String quieroHablarTitle = 'Quiero hablar';
  static const String quieroHablarInvitation =
      'Elige un tema familiar cuando quieras hablar un rato.';
  static const String quieroHablarEmptyBody =
      'Tu familia aún no ha preparado una conversación. Puedes volver al inicio.';
  static const String quieroHablarPickForMe = 'Elige tú por mí';
  static const String quieroHablarStart = 'Empezar';
  static const String quieroHablarContinue = 'Continuar';
  static const String quieroHablarFinishedSpeaking = 'He terminado';
  static const String quieroHablarRepeat = 'Repetir';
  static const String quieroHablarChangeTopic = 'Cambiar de tema';
  static const String quieroHablarFinish = 'Terminar';
  static const String quieroHablarBackToTopics = 'Volver a los temas';
  static const String quieroHablarListening =
      'Te escucho… Puedes hablar con calma.';
  static const String quieroHablarMemoraSpeaking = 'Memora está hablando';
  static const String quieroHablarMicReleased = 'Micrófono liberado';
  static const String quieroHablarManualSpeak = 'Hablar';
  static const String quieroHablarSpeechOutputUnavailable =
      'Ahora no puedo hablar en voz alta. Puedes leer el texto y pulsar '
      'Hablar cuando quieras que te escuche.';
  static const String quieroHablarSharedPullFailed =
      'No se pudieron cargar los cambios de tu familia. '
      'Se muestran los temas guardados aquí.';
  static const String quieroHablarSharedPending = 'Actualizando los temas…';
  static const String quieroHablarIsolatedDemoNotice =
      'Esta lista es solo de demostración en este dispositivo.';
  static const String quieroHablarOffline =
      'Sin red. Los temas guardados siguen disponibles.';
  static const String quieroHablarOpenHint = 'Ver tema';
  static const String quieroHablarNeutralAck = 'Gracias por contármelo';
  static const String quieroHablarSilenceRecovery =
      'No pasa nada. Podemos seguir, cambiar de tema o terminar';
  static const String quieroHablarNoMeAcuerdoRecovery =
      'No pasa nada. Podemos hablar de otra cosa';
  static const String quieroHablarRecognitionFailure =
      'No te he entendido. Puedes repetir, cambiar de tema o terminar';
  static const String quieroHablarUnavailable =
      'Ahora no puedo escucharte. Puedes leer el tema y usar los botones '
      'para seguir o terminar';
  static const String quieroHablarSafetyLimitation =
      'Memora no es un servicio médico ni de emergencias. No diagnostica, '
      'no aconseja tratamientos ni afirma que se haya contactado con ayuda. '
      'Si necesitas ayuda urgente, usa los canales de emergencia de tu zona.';

  /// Kept for destination chrome keys; body is invitation / empty / session.
  static const String quieroHablarBody = quieroHablarInvitation;

  // Voice guidance — Slice 9 (mirrors VoiceGuidanceCopy; tap-gated, on-device)
  static const String homeAyudameLabel = 'Ayúdame';
  static const String homeAyudameSemantics = 'Ayúdame a elegir';
  static const String voicePermissionExplain =
      'El micrófono se usa solo mientras te ayudamos a elegir';
  static const String voicePermissionRequesting =
      'Esperando permiso para usar el micrófono…';
  static const String voiceListeningPrompt =
      'Te estoy escuchando… Dime qué te gustaría hacer';
  static const String voiceProcessing = 'He terminado de escuchar';
  static const String voiceUnderstood = 'He entendido:';
  static const String voiceUnclear =
      'No te he entendido. Puedo ayudarte a elegir entre las opciones de '
      'esta pantalla';
  static const String voiceNothingPrepared =
      'Ahora mismo no tengo una actividad preparada para recomendarte';
  static const String voiceSafetyLimitation =
      'Memora no es un servicio médico ni de emergencias. No diagnostica, '
      'no aconseja tratamientos ni afirma que se haya contactado con ayuda. '
      'Si necesitas ayuda urgente, usa los canales de emergencia de tu zona.';
  static const String voiceRecognizerUnavailable =
      'Ahora no puedo escucharte. Puedes elegir una de las cuatro opciones';
  static const String voicePermissionDenied =
      'No puedo usar el micrófono. Puedes elegir una de las cuatro opciones.';
  static const String voiceSilence =
      'No he oído nada. Puedes volver a intentarlo o elegir una opción.';
  static const String voiceTimeout =
      'He dejado de escuchar. Puedes volver a intentarlo o elegir una opción.';
  static const String voiceListenError =
      'No he podido escucharte. Puedes volver a intentarlo o elegir una opción.';
  static const String voiceCancel = 'Cancelar';
  static const String voiceRetry = 'Volver a intentarlo';
  static const String voiceContinue = 'Activar micrófono';
  static const String voiceNotNow = 'No, ahora no';
  static const String voiceChooseManually = 'Elegir en la pantalla';
  static const String voiceSuggestMiDia =
      'Te recomiendo Mi día. ¿Quieres ir ahora?';
  static const String voiceSuggestPasatiempos =
      'Te recomiendo Pasatiempos. ¿Quieres ir ahora?';
  static const String voiceSuggestRecuerdos =
      'Te recomiendo Recuerdos. ¿Quieres ir ahora?';
  static const String voiceSuggestQuieroHablar =
      'Te recomiendo Quiero hablar. Es un espacio para conversar con temas '
      'de tu familia; desde aquí no se hace ninguna llamada. ¿Quieres ir ahora?';
  static const String voiceGoToMiDia = 'Ir a Mi día';
  static const String voiceGoToPasatiempos = 'Ir a Pasatiempos';
  static const String voiceGoToRecuerdos = 'Ir a Recuerdos';
  static const String voiceGoToQuieroHablar = 'Ir a Quiero hablar';

  // Family web — pastime configure
  static const String pastimesSectionTitle = 'Pasatiempos de la familia';
  static const String pastimesSectionBody =
      'Prepara hasta seis actividades activas con un título y una indicación '
      'breve. No se marca si se hizo la actividad.';
  static const String createPastime = 'Crear pasatiempo';
  static const String editPastime = 'Editar pasatiempo';
  static const String savePastime = 'Guardar pasatiempo';
  static const String activatePastime = 'Activar';
  static const String archivePastime = 'Archivar';
  static const String movePastimeUp = 'Subir';
  static const String movePastimeDown = 'Bajar';
  static const String pastimeTitleLabel = 'Título';
  static const String pastimeInstructionLabel = 'Indicación breve';
  static const String pastimeLifecycleDraft = 'Borrador';
  static const String pastimeLifecycleActive = 'Activo';
  static const String pastimeLifecycleArchived = 'Archivado';
  static const String pastimesEmptyConfigure =
      'Aún no hay pasatiempos. Crea uno para la persona apoyada.';
  static const String pastimesValidationError =
      'Título (1–60) e indicación (1–240) son obligatorios.';
  static const String pastimesExperienceValidationError =
      'Revisa el tipo de pasatiempo y sus opciones antes de guardar.';
  static const String pastimesUnauthorized =
      'Tu rol no puede configurar pasatiempos.';
  static const String pastimesActiveLimitError =
      'Ya hay seis pasatiempos activos. Archiva uno antes de activar otro.';
  static const String pastimesActivateExperienceError =
      'No se puede activar: la configuración del pasatiempo no está completa '
      'o no es compatible.';
  static const String pastimeTypeLabel = 'Tipo de pasatiempo';
  static const String pastimeTypeGuided = 'Actividad guiada';
  static const String pastimeTypeGuidedDesc =
      'Título e indicación. La persona lee la actividad; no hay tablero en '
      'Memora.';
  static const String pastimeTypeSudoku = 'Sudoku';
  static const String pastimeTypeSudokuDesc =
      'Tablero numérico. El tamaño 9×9 tiene más reglas que el 4×4.';
  static const String pastimeTypeWordSearch = 'Sopa de letras';
  static const String pastimeTypeWordSearchDesc =
      'Buscar palabras en un tablero. El tablero 10×10 es más amplio.';
  static const String pastimeTypeSpider = 'Solitario Spider';
  static const String pastimeTypeSpiderDesc =
      'Solitario con columnas. Más palos implica más variedad de cartas.';
  static const String pastimeTypeChangeConfirm =
      'Al cambiar el tipo se reinician las opciones que ya no aplican. '
      '¿Continuar?';
  static const String pastimeSudokuSizeLabel = 'Tamaño del tablero';
  static const String pastimeSudokuLevelLabel = 'Nivel inicial revisado';
  static const String pastimeWordSearchSizeLabel = 'Tamaño del tablero';
  static const String pastimeWordSearchThemeLabel = 'Tema de palabras';
  static const String pastimeSpiderSuitsLabel = 'Número de palos';
  static const String pastimePreviewLabel = 'Vista previa';
  static const String pastimePreviewHint =
      'Vista no interactiva del modelo elegido. No es la partida de la '
      'persona apoyada.';
  static const String pastimeQuarantinedLabel = 'Configuración no usable';
  static const String pastimeSudokuSize4 = '4×4';
  static const String pastimeSudokuSize6 = '6×6';
  static const String pastimeSudokuSize9 = '9×9';
  static const String pastimeWordSearchSize8 = '8×8';
  static const String pastimeWordSearchSize10 = '10×10';
  static const String pastimeSpiderSuits1 = '1 palo';
  static const String pastimeSpiderSuits2 = '2 palos';
  static const String pastimeSpiderSuits4 = '4 palos';
  static const String pastimeSudokuLevelStarter = 'Nivel inicial Demo';

  // Family web — conversation topic configure
  static const String conversationsSectionTitle =
      'Conversaciones guiadas de la familia';
  static const String conversationsSectionBody =
      'Prepara hasta seis temas activos con una introducción, invitaciones '
      'para hablar y un cierre. El contenido debe invitar, no examinar.';
  static const String conversationsGuidance =
      'Evita formulaciones como «¿Te acuerdas de…?», preguntas con una sola '
      'respuesta correcta, instrucciones de corrección, afirmaciones médicas '
      'o escenarios de emergencia.';
  static const String createConversationTopic = 'Crear tema';
  static const String editConversationTopic = 'Editar tema';
  static const String saveConversationTopic = 'Guardar tema';
  static const String activateConversationTopic = 'Activar';
  static const String archiveConversationTopic = 'Archivar';
  static const String moveConversationTopicUp = 'Subir';
  static const String moveConversationTopicDown = 'Bajar';
  static const String conversationTopicTitleLabel = 'Título';
  static const String conversationIntroductionLabel = 'Introducción';
  static const String conversationPromptsLabel = 'Invitaciones para hablar';
  static const String conversationPromptLabel = 'Invitación';
  static const String conversationClosingLabel = 'Cierre';
  static const String conversationMemoryLinkLabel =
      'Recuerdo aprobado (opcional)';
  static const String conversationMemoryLinkNone = 'Sin recuerdo vinculado';
  static const String conversationAddPrompt = 'Añadir invitación';
  static const String conversationRemovePrompt = 'Quitar invitación';
  static const String conversationRemovePromptConfirm =
      'Quitar esta invitación también quita su ayuda familiar. ¿Continuar?';
  static const String conversationRemovePromptConfirmAction = 'Sí, quitar';
  static const String conversationRemovePromptCancel = 'Conservar';
  static const String conversationHelpSectionLabel = 'Ayuda familiar';
  static const String conversationHelpGuidance =
      'Escribe una pista breve que dé contexto, no una pregunta de examen. '
      'Evita «¿Te acuerdas de…?», respuestas correctas, correcciones, '
      'sorpresas delicadas, afirmaciones médicas o situaciones de emergencia.';
  static const String conversationHelpCueLabel = 'Pista breve (opcional)';
  static const String conversationHelpMemoryLabel =
      'Recuerdo de ayuda (opcional)';
  static const String conversationHelpMemoryNone = 'Sin recuerdo de ayuda';
  static const String conversationHelpClear = 'Quitar ayuda familiar';
  static const String conversationPreviewHelpAffordance = 'Dame una idea';
  static const String conversationPreviewTitle = 'Vista de la persona apoyada';
  static const String conversationLifecycleDraft = 'Borrador';
  static const String conversationLifecycleActive = 'Activo';
  static const String conversationLifecycleArchived = 'Archivado';
  static const String conversationsEmptyConfigure =
      'Aún no hay temas. Crea uno para la persona apoyada.';
  static const String conversationsValidationError =
      'Título (1–60), introducción (1–240), entre 1 y 5 invitaciones '
      '(1–240 cada una) y cierre (1–160) son obligatorios.';
  static const String conversationsHelpValidationError =
      'La ayuda familiar de una invitación no es válida. '
      'Revisa la pista (1–160) o el recuerdo aprobado.';
  static const String conversationsHelpMemoryError =
      'Hay un recuerdo de ayuda que no está aprobado o no pertenece a esta '
      'familia. Corrige la invitación marcada antes de activar.';
  static const String conversationsUnauthorized =
      'Tu rol no puede configurar conversaciones.';
  static const String conversationsActiveLimitError =
      'Ya hay seis temas activos. Archiva uno antes de activar otro.';

  // Supported-person — prompt help (Slice 11)
  static const String quieroHablarRequestHelp = 'Dame una idea';
  static const String quieroHablarHelpUnavailable =
      'Ahora no tengo una idea preparada para esto. Puedes seguir, repetir, '
      'cambiar de tema o terminar.';
  static const String quieroHablarHelpRevealedLabel = 'Idea familiar';

  // Family web configure
  static const String familyHomeTitle = 'Rutinas y recordatorios';
  static const String routinesSection = 'Rutinas';
  static const String remindersSection = 'Recordatorios';
  static const String createRoutine = 'Crear rutina';
  static const String editRoutine = 'Editar rutina';
  static const String saveRoutine = 'Guardar rutina';
  static const String activateRoutine = 'Activar';
  static const String archiveRoutine = 'Archivar';
  static const String moveStepUp = 'Subir paso';
  static const String moveStepDown = 'Bajar paso';
  static const String addStep = 'Añadir paso';
  static const String removeStep = 'Quitar paso';
  static const String routineTitleLabel = 'Título de la rutina';
  static const String stepInstructionLabel = 'Instrucción del paso';
  static const String lifecycleActive = 'Activa';
  static const String lifecycleArchived = 'Archivada';
  static const String createReminder = 'Crear recordatorio';
  static const String editReminder = 'Editar recordatorio';
  static const String saveReminder = 'Guardar recordatorio';
  static const String reminderTitleLabel = 'Título del recordatorio';
  static const String quietHoursLabel = 'Horas de silencio';
  static const String quietHoursHint =
      'Durante estas horas no se muestran avisos de comodidad.';
  static const String reminderConvenienceNotice =
      'Los recordatorios son avisos de comodidad. '
      'No son cobertura de emergencia ni alerta médica.';
  static const String quietStartLabel = 'Inicio (hora local)';
  static const String quietEndLabel = 'Fin (hora local)';

  // Memories
  static const String memoriesTitle = 'Recuerdos de la familia';
  static const String memoriesApprovedTitle = 'Recuerdos';
  static const String memoriesEmpty = 'No hay recuerdos para mostrar.';
  static const String memoriesLoading = 'Cargando recuerdos…';
  static const String memoriesOffline =
      'Sin red. Los recuerdos guardados siguen disponibles.';
  static const String createMemory = 'Crear recuerdo';
  static const String contributeMemory = 'Proponer recuerdo';
  static const String editMemory = 'Editar recuerdo';
  static const String saveMemory = 'Guardar recuerdo';
  static const String approveMemory = 'Aprobar';
  static const String archiveMemory = 'Archivar';
  static const String moveMemoryUp = 'Subir recuerdo';
  static const String moveMemoryDown = 'Bajar recuerdo';
  static const String memoryCaptionLabel = 'Pie de foto / descripción';
  static const String memoryDateContextLabel = 'Contexto de fecha';
  static const String memoryLifecycleProposed = 'Propuesto';
  static const String memoryLifecycleApproved = 'Aprobado';
  static const String memoryLifecycleArchived = 'Archivado';
  static const String mediaStatusLabel = 'Estado del medio';
  static const String mediaFailedPlaceholder =
      'La imagen no está disponible. Puedes seguir con el recuerdo.';
  static const String mediaRetryUpload = 'Reintentar medio';
  static const String continueAfterFailedMedia = 'Seguir viendo recuerdos';
  static const String memoryMediaPathLabel = 'Ruta (familia)';
  static const String memoryMediaChecksumLabel = 'Suma de comprobación';

  // Observations (non-clinical storage only)
  static const String observationsTitle = 'Peso y tensión (registro)';
  static const String observationDisclaimer =
      'Memora no interpreta estos valores. '
      'No es un servicio médico ni de emergencias.';
  static const String weightSection = 'Peso';
  static const String bloodPressureSection = 'Tensión arterial';
  static const String weightValueLabel = 'Peso (kg)';
  static const String systolicLabel = 'Sistólica (mmHg)';
  static const String diastolicLabel = 'Diastólica (mmHg)';
  static const String saveWeight = 'Guardar peso';
  static const String saveBloodPressure = 'Guardar tensión';
  static const String correctObservation = 'Corregir (añadir fila)';
  static const String tombstoneObservation = 'Marcar como retirado';
  static const String observationHistory = 'Historial cronológico';
  static const String observationAuthorLabel = 'Autor';
  static const String observationCorrectionOf = 'Corrección de';
  static const String observationTombstoned = 'Retirado';
  static const String observationsEmpty = 'No hay observaciones registradas.';
  static const String observationsLoading = 'Cargando observaciones…';

  // Help / About
  static const String helpAboutTitle = 'Ayuda y acerca de';
  static const String helpAboutBody =
      'Memora ayuda con rutinas diarias y coordinación familiar.';
  static const String helpAboutDisclaimer =
      'Memora no interpreta valores de peso ni tensión. '
      'No es un servicio médico ni de emergencias.';

  // Shared chrome
  static const String personaPrefix = 'Persona sintética';
}
