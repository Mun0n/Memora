-- Slice 14 — versioned pastime experience definition on existing pastimes.
-- Forced RLS preserved; editPastimes / viewPastimes unchanged.
-- Identifiers only — no URL/HTML/script/executable paths.
-- Fictional development only; no hosted project, credentials or LLM.

-- ---------------------------------------------------------------------------
-- Columns (legacy rows default to guided)
-- ---------------------------------------------------------------------------

alter table public.pastimes
  add column if not exists experience_type text not null default 'guided',
  add column if not exists experience_schema_version integer not null default 1,
  add column if not exists experience_config jsonb not null default '{}'::jsonb;

-- Backfill any pre-default rows defensively (idempotent).
update public.pastimes
set
  experience_type = coalesce(nullif(trim(experience_type), ''), 'guided'),
  experience_schema_version = coalesce(experience_schema_version, 1),
  experience_config = coalesce(experience_config, '{}'::jsonb)
where true;

alter table public.pastimes
  drop constraint if exists pastimes_experience_type_known;

alter table public.pastimes
  add constraint pastimes_experience_type_known
  check (
    experience_type in (
      'guided',
      'sudoku',
      'wordSearch',
      'spiderSolitaire'
    )
  );

alter table public.pastimes
  drop constraint if exists pastimes_experience_schema_supported;

alter table public.pastimes
  add constraint pastimes_experience_schema_supported
  check (experience_schema_version = 1);

alter table public.pastimes
  drop constraint if exists pastimes_experience_config_shape;

alter table public.pastimes
  add constraint pastimes_experience_config_shape
  check (
    (
      experience_type = 'guided'
      and experience_config = '{}'::jsonb
    )
    or (
      experience_type = 'sudoku'
      and jsonb_typeof(experience_config) = 'object'
      and experience_config ? 'boardSize'
      and experience_config ? 'puzzlePackId'
      and (experience_config ->> 'boardSize') in ('4x4', '6x6', '9x9')
      and (
        (
          (experience_config ->> 'boardSize') = '4x4'
          and (experience_config ->> 'puzzlePackId') = 'sudoku_starter_4x4_demo'
        )
        or (
          (experience_config ->> 'boardSize') = '6x6'
          and (experience_config ->> 'puzzlePackId') = 'sudoku_starter_6x6_demo'
        )
        or (
          (experience_config ->> 'boardSize') = '9x9'
          and (experience_config ->> 'puzzlePackId') = 'sudoku_starter_9x9_demo'
        )
      )
      -- Exact key set without subquery (CHECK forbids jsonb_object_keys SELECT).
      and (experience_config - 'boardSize' - 'puzzlePackId') = '{}'::jsonb
    )
    or (
      experience_type = 'wordSearch'
      and jsonb_typeof(experience_config) = 'object'
      and experience_config ? 'boardSize'
      and experience_config ? 'wordSetId'
      and (experience_config ->> 'boardSize') in ('8x8', '10x10')
      and (experience_config ->> 'wordSetId') in (
        'wordset_jardin_demo',
        'wordset_cocina_demo',
        'wordset_musica_demo'
      )
      and (experience_config - 'boardSize' - 'wordSetId') = '{}'::jsonb
    )
    or (
      experience_type = 'spiderSolitaire'
      and jsonb_typeof(experience_config) = 'object'
      and experience_config ? 'suitCount'
      and (experience_config ->> 'suitCount') in ('1', '2', '4')
      and (experience_config - 'suitCount') = '{}'::jsonb
    )
  );

-- ---------------------------------------------------------------------------
-- Restate forced RLS on pastimes (policies unchanged in capability terms)
-- ---------------------------------------------------------------------------

alter table public.pastimes enable row level security;
alter table public.pastimes force row level security;

drop policy if exists pastimes_select on public.pastimes;
drop policy if exists pastimes_insert on public.pastimes;
drop policy if exists pastimes_update on public.pastimes;

create policy pastimes_select
  on public.pastimes for select to authenticated
  using (
    public.memora_has_capability(family_space_id, 'editPastimes')
    or (
      public.memora_has_capability(family_space_id, 'viewPastimes')
      and lifecycle_status = 'active'
      and deleted_at is null
    )
  );

create policy pastimes_insert
  on public.pastimes for insert to authenticated
  with check (public.memora_has_capability(family_space_id, 'editPastimes'));

create policy pastimes_update
  on public.pastimes for update to authenticated
  using (
    public.memora_has_capability(family_space_id, 'editPastimes')
    or public.memora_has_capability(family_space_id, 'resolveSyncConflicts')
  )
  with check (
    public.memora_has_capability(family_space_id, 'editPastimes')
    or public.memora_has_capability(family_space_id, 'resolveSyncConflicts')
  );

revoke all on table public.pastimes from public, anon;
grant select, insert, update on table public.pastimes to authenticated;
