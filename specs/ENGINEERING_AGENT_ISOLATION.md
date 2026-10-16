# Ingeniería — aislamiento de ejecución por rol

## Estado y propósito

Especificación preparada para el módulo 3 del curso, a petición del usuario.
No es una nueva funcionalidad de producto ni reabre Slice 14. No ejecutar con
`run_slice.sh`: el runner actual solo admite slices numéricas y sus roles no
tienen autorización para modificar la infraestructura de orquestación.
La preparación de este documento no autoriza modificar los contratos protegidos.

Objetivo: impedir escrituras fuera del alcance de un rol antes de que alteren
el proyecto, conservar la detección posterior y ofrecer evidencia reproducible.

## Evidencia de partida — 2026-10-16

- `scripts/lib/cursor_cli.sh` ejecuta el CLI con `-p --trust --force` y
  `--workspace "$ROOT"`; no selecciona permisos distintos por rol.
  La semántica efectiva de estos flags debe verificarse para la versión instalada.
- `scripts/run_slice.sh` toma un snapshot, ejecuta el agente y comprueba el guard
  después. Si el proceso falla, retorna antes de esa comprobación.
- `scripts/lib/orch.py` almacena hashes, no copias restaurables. El guard detecta
  cambios pero no los impide ni los revierte.
- El snapshot enumera archivos Git seguidos y no ignorados. No demuestra protección
  de archivos ignorados, rutas externas, metadatos Git o destinos de enlaces.
- DOMAIN no puede editar contratos de orquestación. `.agent/workflow.md` y
  `.agent/path_guards.json` son rutas protegidas.
- Hay artefactos locales no seguidos en `apps/user/test/failures/`; preservarlos.

## Alcance

Infraestructura de ejecución, permisos, pruebas y documentación del arnés.
No cambiar producto, Flutter, backend, políticas offline, telemetría ni funciones IA.
No push, despliegue, credenciales nuevas ni datos personales.

## Diseño exigido

1. Investigar las capacidades del CLI instalado y del entorno de ejecución.
   Registrar versión, mecanismo de restricción y evidencia de escritura denegada.
   No deducir aislamiento a partir de nombres de flags, prompts o directorios.
2. Aplicar restricciones a herramientas de edición y procesos de shell hijos.
   Un contenedor, sandbox del sistema o mecanismo equivalente debe impedir que
   una escritura prohibida alcance el repositorio principal u otras rutas del host.
   Un worktree o copia aislada sin permisos efectivos no cumple este requisito.
3. Si el mecanismo no está disponible o falla, detenerse antes de lanzar el agente.
   No degradar silenciosamente a la ejecución actual con permisos amplios.
4. Resolver rutas canónicas y enlaces antes de autorizar accesos. Denegar escapes
   por rutas absolutas, `..`, enlaces simbólicos y destinos externos. Incluir
   metadatos Git y archivos ignorados; los permisos no deben depender de Git ignore.
5. Declarar las escrituras auxiliares mínimas para informes, temporales y caches.
   Las excepciones de toolchain deben ser acotadas y no permitir alterar fuentes
   prohibidas. No conceder acceso general al home para que una prueba pase.
6. Mantener el guard posterior como control adicional. Recoger evidencia también
   si el agente sale con error o se interrumpe; una interrupción abrupta debe dejar
   un estado detectable que impida aceptar automáticamente el trabajo incompleto.
7. No restaurar todo el árbol automáticamente. Preservar cambios previos del usuario
   y resultados fallidos para inspección; ninguna infracción debe integrar cambios
   en la copia principal. La integración de resultados permitidos debe comprobar
   que la base no cambió y detenerse ante conflictos.

## Política por rol

- UI: solo presentación y composición autorizadas por la spec activa.
- DOMAIN: solo dominio, datos y backend autorizados por la spec activa.
- QA: pruebas y fixtures autorizados; no producción ni el mecanismo que valida
  su propia ejecución. Cualquier excepción actual debe revisarse explícitamente.
- SUPERVISOR y AUDITOR: fuentes de solo lectura; cada uno puede escribir su informe.
- Ningún rol puede cambiar sus permisos, contratos protegidos o política del runner.
- Los permisos efectivos son la intersección entre rol y spec, no la unión.

## Arranque del mantenimiento

Antes de implementar, preparar un cambio separado y revisable que habilite un flujo
de mantenimiento específico para esta tarea. No ampliar DOMAIN/UI globalmente ni
permitir que un agente se conceda permisos a sí mismo.

Candidatos a modificar bajo ese flujo: `scripts/lib/cursor_cli.sh`,
`scripts/lib/orch.py`, `scripts/run_slice.sh`, nuevos helpers bajo `scripts/lib/`,
`scripts/tests/`, README y documentación técnica. Los cambios necesarios en
`.agent/workflow.md`, `.agent/path_guards.json`, contratos de rol o AGENTS.md deben
enumerarse y autorizarse explícitamente antes de aplicar el cambio de arranque.
El usuario inicia la ejecución de agentes desde Terminal, como exige el contrato
actual. No presentar `run_slice.sh 15` como una vía disponible para este documento.

## Prueba práctica y criterios de aceptación

Ejecutar procesos reales contra un repositorio temporal con contenido ficticio,
usando el mismo mecanismo de permisos que utilizará el runner. No sustituir la
comprobación de bloqueo por mocks del sistema de archivos o del guard.

1. UI modifica un archivo de presentación permitido: éxito y contenido esperado.
2. UI intenta escribir una regla en `packages/domain/`: escritura denegada y bytes
   originales intactos, tanto mediante editor como mediante shell hijo.
3. UI intenta borrar o renombrar un archivo prohibido: denegado sin pérdida.
4. Intentos mediante ruta absoluta, `..`, symlink y archivo ignorado: denegados.
   Un archivo testigo externo al workspace y los metadatos Git permanecen intactos.
5. UI intenta editar política/contratos o permisos: denegado.
6. QA intenta modificar producción: denegado. Una prueba permitida sí se modifica.
7. AUDITOR/SUPERVISOR pueden generar su informe, pero no cambiar fuentes ni informes
   ajenos. El ejecutor, fuera del agente, gestiona los logs necesarios.
8. Proceso con salida no cero e interrupción: evidencias y estado fallido conservados;
   no aceptación ni integración automática. Se preserva trabajo previo del usuario.
9. Sandbox ausente o configuración inválida: no se inicia el proceso del agente.
10. Cambio concurrente en la base: integración detenida, sin sobrescritura.
11. Pruebas existentes del arnés y validación completa pasan tras la implementación.
12. Prueba real con el CLI, iniciada por el usuario, confirma edición legítima y
    bloqueo de escritura prohibida en el repositorio temporal. No basta el sustituto
    de proceso de las pruebas automáticas para afirmar compatibilidad con el CLI.

Cada resultado incluirá comando, salida, código de retorno y comparación del estado
anterior/posterior. Registrar por separado controles preventivos, detecciones
posteriores y límites que no se hayan comprobado. No afirmar que este aislamiento
de escritura protege por sí mismo lecturas de secretos, red o servicios externos.

## Entregables y cierre

- Decisión técnica con capacidades comprobadas y limitaciones del entorno.
- Cambio de arranque y permisos acotados revisados antes de ejecutar mantenimiento.
- Implementación utilizada por el runner real, sin fallback inseguro.
- Pruebas de los criterios anteriores y registro de la prueba con CLI real.
- Documentación de ejecución, recuperación e integración de resultados.
- Revisión independiente y aceptación humana. No iniciar una slice de producto.

Aprendizaje esperado: distinguir instrucciones, permisos preventivos, aislamiento
del trabajo, guard posterior y recuperación; explicar con evidencia dónde actúa
cada mecanismo dentro del flujo de Memora.
