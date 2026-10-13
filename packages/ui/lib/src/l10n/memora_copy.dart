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
  static const String sharedLocalDemoPending =
      'Actualizando la lista compartida…';
  static const String sharedLocalDemoPullFailed =
      'No se pudo actualizar desde la demostración compartida. '
      'Se muestra lo guardado aquí.';
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

  // Navigation
  static const String navRoutines = 'Rutinas';
  static const String navPastimes = 'Pasatiempos';
  static const String navMemories = 'Recuerdos';
  static const String navObservations = 'Observaciones';
  static const String navSync = 'Sincronización';
  static const String navPrivacy = 'Privacidad';
  static const String navHelp = 'Ayuda';

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
      'Puedes enviar y recibir cuando quieras (modo demo local).';
  static const String syncSectionBodyIsolated =
      'Los cambios se guardan solo en este cliente. '
      'No se comparten con otra aplicación en esta demostración aislada.';
  static const String syncSectionBodyShared =
      'Los cambios se guardan primero aquí y se envían solos al demo local '
      'compartido en este ordenador. Sin producción.';
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
      'Contratos de demostración: exportación, eliminación y sesiones. '
      'No hay verificación remota ni envío a un servidor alojado.';
  static const String privacyExportAction = 'Solicitar exportación';
  static const String privacyDeletionAction = 'Solicitar eliminación';
  static const String privacyExportConfirmed =
      'Solicitud de exportación registrada (demostración).';
  static const String privacyDeletionConfirmed =
      'Solicitud de eliminación registrada (demostración).';
  static const String privacySessionsTitle = 'Sesiones de demostración';
  static const String privacySessionsEmpty = 'No hay sesiones activas.';
  static const String privacyRevokeSession = 'Cerrar sesión';
  static const String privacySessionRevoked = 'Sesión cerrada (demostración).';
  static const String privacyAuditNote =
      'El historial auditable guarda solo etiquetas (acción, objetivo, hora). '
      'No muestra contenido, valores de salud, tokens ni rutas de medios.';
  static const String privacyUnauthorized =
      'Tu membresía no puede usar estos contratos de privacidad.';

  // User home — Slice 7 four-tile shell
  static const String userHomeTitle = 'Hoy';
  static const String userHomeGreeting = 'Hola';
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
  static const String pasatiemposOpenHint = 'Ver indicación';
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

  // Quiero hablar — honest placeholder (no call success)
  static const String quieroHablarTitle = 'Quiero hablar';
  static const String quieroHablarBody =
      'Aquí aparecerán las personas de confianza que configure tu familia. '
      'Desde aquí no se hace ninguna llamada.';

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
  static const String pastimesUnauthorized =
      'Tu rol no puede configurar pasatiempos.';
  static const String pastimesActiveLimitError =
      'Ya hay seis pasatiempos activos. Archiva uno antes de activar otro.';

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
      'Memora ayuda con rutinas diarias y coordinación familiar. '
      'Usa solo datos de demostración en este entorno.';
  static const String helpAboutDisclaimer =
      'Memora no interpreta valores de peso ni tensión. '
      'No es un servicio médico ni de emergencias.';

  // Shared chrome
  static const String personaPrefix = 'Persona sintética';
}
