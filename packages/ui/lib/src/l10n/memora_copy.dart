/// Spanish-first, localization-ready copy for Slice 4 routine vertical.
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

  // User home
  static const String userHomeTitle = 'Hoy';
  static const String todaysRoutines = 'Rutinas de hoy';
  static const String primaryActionComplete = 'Marcar como hecho';
  static const String primaryActionCorrect = 'Corregir: aún no hecho';
  static const String stepPending = 'Pendiente';
  static const String stepCompleted = 'Hecho';
  static const String noPrimaryAction = 'Todas las tareas de hoy están hechas.';
  static const String nextStepLabel = 'Siguiente paso';

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

  // Shared chrome
  static const String personaPrefix = 'Persona sintética';
}
