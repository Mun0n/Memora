# Aislamiento por rol: decisión técnica

Fecha: 2026-10-16. Relacionado con specs/ENGINEERING_AGENT_ISOLATION.md.
Estado: mecanismo del sistema implementado e integrado en el runner;
prueba CLI real (criterio 12) pendiente de ejecución humana.

## Resultado comprobado

Cursor instalado: 2026.10.14-0f9edde (consultas --version y --help; sin sesión).
Su ayuda ofrece --sandbox enabled/disabled y modos ask/plan de solo lectura.
Describe --force como autorización de comandos salvo denegaciones explícitas.
La ayuda no demuestra que el sandbox integrado imponga nuestras rutas por rol.

En este Mac existe /usr/bin/sandbox-exec. Docker no se encontró en PATH.

El probe inicial (`docs/engineering/probe_os_write_isolation.py`) demostró
denegación OS de escrituras fuera de una carpeta permitida (absoluta, `..`,
symlink, shell hijo, borrado, renombrado) con el archivo protegido intacto.

## Implementación

- `scripts/lib/role_sandbox.py` — preflight, manifiesto rol∩spec, perfil
  seatbelt, worktree externo, finalize/integración condicionada.
- `scripts/lib/cursor_cli.sh` — `run-agent` bajo sandbox; sin fallback permisivo.
- `scripts/run_slice.sh` — preflight obligatorio; prepare antes del agente;
  post-check/`orch.py guard` también tras fallos; evidencia en reports.
- `scripts/lib/orch.py` — cada rol solo su informe bajo `.agent/reports/`.
- `.agent/path_guards.json` — QA ya no puede mutar `scripts/validate.sh`.
- Pruebas: `scripts/tests/test_role_sandbox.py` (procesos y repos temporales).
- Docs: `docs/engineering/ROLE_SANDBOX.md`,
  `docs/engineering/cursor_cli_isolation_probe.md`.

Permisos efectivos = techo de rol ∩ `## Write scope` opcional en la spec.
Informes se especializan al archivo del rol. El worktree vive fuera del repo
principal (`MEMORA_ROLE_RUNS_DIR` o `$TMPDIR/memora-role-runs`) para que denegar
escritura en la raíz principal sea efectivo.

Toolchain Flutter (DOMAIN/UI/QA): solo `FLUTTER_ROOT/bin/cache` + `PUB_CACHE`/
`TMPDIR` en `aux/`. Analytics desactivadas por env (`CI`,
`FLUTTER_SUPPRESS_ANALYTICS`) para no abrir `$HOME`. No se concede home ni SDK
completo.

## Reproducción

```bash
python3 -B docs/engineering/probe_os_write_isolation.py
python3 -m unittest scripts.tests.test_role_sandbox -v
python3 scripts/lib/role_sandbox.py preflight
```

## Limitaciones

- Solo macOS con `sandbox-exec` funcional; resto falla cerrado en preflight.
- Aislamiento de escritura, no de lectura/red/exfiltración.
- Criterio 12 (CLI Cursor real) pendiente; ver
  `docs/engineering/cursor_cli_isolation_probe.md`.
- Validación Flutter completa falla hoy por un defecto de producto preexistente:
  `apps/user/test/pastime_player_test.dart` — “recovery offers Continuar
  without auto-entering play” (no encuentra `memora-user-pastime-recovery`).
  No forma parte de este cambio de arnés; no se tocó código de producto.

## No aplicado

`docs/engineering/maintenance-bootstrap.patch` y cambios a `AGENTS.md` no se
aplicaron, por autorización explícita del propietario para esta intervención
directa acotada.
