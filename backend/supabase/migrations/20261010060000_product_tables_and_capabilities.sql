-- Slice 06 — product tables + extended capability wires (routines, reminders,
-- memories, media metadata, observations). Forced RLS; capability matrix must
-- stay identical to packages/domain FamilyAccessPolicy.
-- Media: metadata table only (no storage bucket / no hosted object paths).

-- ---------------------------------------------------------------------------
-- Extend memora_has_capability with product wires
-- ---------------------------------------------------------------------------

create or replace function public.memora_has_capability(
  p_family_space_id uuid,
  p_capability text
) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.family_memberships m
    where m.family_space_id = p_family_space_id
      and m.user_id = auth.uid()
      and m.status = 'active'
      and (
        (p_capability = 'viewFamilySpace'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver',
            'familyContributor'
          ))
        or (p_capability = 'updateFamilySpace'
          and m.role = 'primaryCaregiver')
        or (p_capability = 'viewMemberships'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'manageMemberships'
          and m.role = 'primaryCaregiver')
        or (p_capability = 'viewRoutines'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver',
            'familyContributor'
          ))
        or (p_capability = 'editRoutines'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'recordRoutineProgress'
          and m.role = 'supportedPerson')
        or (p_capability = 'viewReminders'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver'
          ))
        or (p_capability = 'configureReminders'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'viewApprovedMemories'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver',
            'familyContributor'
          ))
        or (p_capability = 'manageMemories'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'contributeMemories'
          and m.role = 'familyContributor')
        or (p_capability = 'manageMediaMetadata'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'viewObservations'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'recordObservations'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'resolveSyncConflicts'
          and m.role in ('primaryCaregiver', 'caregiver'))
      )
  );
$$;

revoke all on function public.memora_has_capability(uuid, text) from public;
grant execute on function public.memora_has_capability(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.routines (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  title text not null,
  steps jsonb not null,
  lifecycle_status text not null,
  row_version bigint not null default 1,
  idempotency_key text,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint routines_title_nonempty check (char_length(trim(title)) > 0),
  constraint routines_lifecycle_known
    check (lifecycle_status in ('active', 'archived')),
  constraint routines_idempotency_unique unique (family_space_id, idempotency_key)
);

create index routines_family_space_idx on public.routines (family_space_id);

create table public.reminders (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  title text not null,
  scheduled_at timestamptz not null,
  quiet_hours jsonb,
  row_version bigint not null default 1,
  idempotency_key text,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reminders_title_nonempty check (char_length(trim(title)) > 0),
  constraint reminders_idempotency_unique unique (family_space_id, idempotency_key)
);

create index reminders_family_space_idx on public.reminders (family_space_id);

create table public.memories (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  caption text not null,
  date_context text not null,
  display_order integer not null default 0,
  lifecycle_status text not null,
  created_by uuid references auth.users (id),
  row_version bigint not null default 1,
  idempotency_key text,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint memories_caption_nonempty check (char_length(trim(caption)) > 0),
  constraint memories_date_context_nonempty
    check (char_length(trim(date_context)) > 0),
  constraint memories_lifecycle_known
    check (lifecycle_status in ('proposed', 'approved', 'archived')),
  constraint memories_idempotency_unique unique (family_space_id, idempotency_key)
);

create index memories_family_space_idx on public.memories (family_space_id);

-- Metadata only — no storage.objects bucket in v0.1 MVP.
create table public.media_metadata (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  memory_id uuid not null references public.memories (id),
  family_scoped_path text not null,
  checksum text not null,
  upload_state text not null,
  row_version bigint not null default 1,
  idempotency_key text,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint media_metadata_path_nonempty
    check (char_length(trim(family_scoped_path)) > 0),
  constraint media_metadata_checksum_nonempty
    check (char_length(trim(checksum)) > 0),
  constraint media_metadata_upload_state_known
    check (upload_state in ('local', 'pending', 'failed', 'synced')),
  constraint media_metadata_path_family_prefix
    check (family_scoped_path like (family_space_id::text || '/%')),
  constraint media_metadata_idempotency_unique
    unique (family_space_id, idempotency_key)
);

create index media_metadata_family_space_idx
  on public.media_metadata (family_space_id);

create table public.weight_observations (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  kilograms numeric not null,
  recorded_at timestamptz not null,
  author_id uuid not null references auth.users (id),
  corrects_observation_id uuid references public.weight_observations (id),
  row_version bigint not null default 1,
  idempotency_key text,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint weight_observations_kg_positive check (kilograms > 0),
  constraint weight_observations_idempotency_unique
    unique (family_space_id, idempotency_key)
);

create index weight_observations_family_space_idx
  on public.weight_observations (family_space_id);

create table public.blood_pressure_observations (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  systolic_mm_hg integer not null,
  diastolic_mm_hg integer not null,
  recorded_at timestamptz not null,
  author_id uuid not null references auth.users (id),
  corrects_observation_id uuid
    references public.blood_pressure_observations (id),
  row_version bigint not null default 1,
  idempotency_key text,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint blood_pressure_systolic_positive check (systolic_mm_hg > 0),
  constraint blood_pressure_diastolic_positive check (diastolic_mm_hg > 0),
  constraint blood_pressure_idempotency_unique
    unique (family_space_id, idempotency_key)
);

create index blood_pressure_observations_family_space_idx
  on public.blood_pressure_observations (family_space_id);

create table public.audit_events (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  actor_user_id uuid not null references auth.users (id),
  action text not null,
  target_type text not null,
  target_id text not null,
  request_id text not null,
  occurred_at timestamptz not null default now(),
  constraint audit_events_action_nonempty check (char_length(trim(action)) > 0),
  constraint audit_events_target_type_nonempty
    check (char_length(trim(target_type)) > 0),
  constraint audit_events_target_id_nonempty
    check (char_length(trim(target_id)) > 0),
  constraint audit_events_request_id_nonempty
    check (char_length(trim(request_id)) > 0)
);

create index audit_events_family_space_idx
  on public.audit_events (family_space_id);

-- ---------------------------------------------------------------------------
-- FORCE RLS + grants (authenticated only; never anon)
-- ---------------------------------------------------------------------------

alter table public.routines enable row level security;
alter table public.routines force row level security;
alter table public.reminders enable row level security;
alter table public.reminders force row level security;
alter table public.memories enable row level security;
alter table public.memories force row level security;
alter table public.media_metadata enable row level security;
alter table public.media_metadata force row level security;
alter table public.weight_observations enable row level security;
alter table public.weight_observations force row level security;
alter table public.blood_pressure_observations enable row level security;
alter table public.blood_pressure_observations force row level security;
alter table public.audit_events enable row level security;
alter table public.audit_events force row level security;

revoke all on table public.routines from public, anon;
revoke all on table public.reminders from public, anon;
revoke all on table public.memories from public, anon;
revoke all on table public.media_metadata from public, anon;
revoke all on table public.weight_observations from public, anon;
revoke all on table public.blood_pressure_observations from public, anon;
revoke all on table public.audit_events from public, anon;

grant select, insert, update on table public.routines to authenticated;
grant select, insert, update on table public.reminders to authenticated;
grant select, insert, update on table public.memories to authenticated;
grant select, insert, update on table public.media_metadata to authenticated;
grant select, insert, update on table public.weight_observations to authenticated;
grant select, insert, update on table public.blood_pressure_observations
  to authenticated;
grant select, insert on table public.audit_events to authenticated;
-- No DELETE grants (tombstones via update).

-- ---------------------------------------------------------------------------
-- Policies: routines
-- ---------------------------------------------------------------------------

create policy routines_select
  on public.routines for select to authenticated
  using (public.memora_has_capability(family_space_id, 'viewRoutines'));

create policy routines_insert
  on public.routines for insert to authenticated
  with check (public.memora_has_capability(family_space_id, 'editRoutines'));

create policy routines_update
  on public.routines for update to authenticated
  using (
    public.memora_has_capability(family_space_id, 'editRoutines')
    or public.memora_has_capability(family_space_id, 'resolveSyncConflicts')
  )
  with check (
    public.memora_has_capability(family_space_id, 'editRoutines')
    or public.memora_has_capability(family_space_id, 'resolveSyncConflicts')
  );

-- ---------------------------------------------------------------------------
-- Policies: reminders
-- ---------------------------------------------------------------------------

create policy reminders_select
  on public.reminders for select to authenticated
  using (public.memora_has_capability(family_space_id, 'viewReminders'));

create policy reminders_insert
  on public.reminders for insert to authenticated
  with check (
    public.memora_has_capability(family_space_id, 'configureReminders')
  );

create policy reminders_update
  on public.reminders for update to authenticated
  using (public.memora_has_capability(family_space_id, 'configureReminders'))
  with check (
    public.memora_has_capability(family_space_id, 'configureReminders')
  );

-- ---------------------------------------------------------------------------
-- Policies: memories
-- ---------------------------------------------------------------------------

create policy memories_select
  on public.memories for select to authenticated
  using (
    (
      lifecycle_status = 'approved'
      and deleted_at is null
      and public.memora_has_capability(family_space_id, 'viewApprovedMemories')
    )
    or public.memora_has_capability(family_space_id, 'manageMemories')
    or (
      public.memora_has_capability(family_space_id, 'contributeMemories')
      and created_by = auth.uid()
    )
  );

create policy memories_insert
  on public.memories for insert to authenticated
  with check (
    public.memora_has_capability(family_space_id, 'manageMemories')
    or (
      public.memora_has_capability(family_space_id, 'contributeMemories')
      and lifecycle_status = 'proposed'
      and created_by = auth.uid()
    )
  );

create policy memories_update
  on public.memories for update to authenticated
  using (public.memora_has_capability(family_space_id, 'manageMemories'))
  with check (public.memora_has_capability(family_space_id, 'manageMemories'));

-- ---------------------------------------------------------------------------
-- Policies: media_metadata (metadata-only; no storage bucket)
-- ---------------------------------------------------------------------------

create policy media_metadata_select
  on public.media_metadata for select to authenticated
  using (
    public.memora_has_capability(family_space_id, 'viewApprovedMemories')
    or public.memora_has_capability(family_space_id, 'manageMediaMetadata')
    or public.memora_has_capability(family_space_id, 'contributeMemories')
  );

create policy media_metadata_insert
  on public.media_metadata for insert to authenticated
  with check (
    public.memora_has_capability(family_space_id, 'manageMediaMetadata')
    or public.memora_has_capability(family_space_id, 'contributeMemories')
  );

create policy media_metadata_update
  on public.media_metadata for update to authenticated
  using (
    public.memora_has_capability(family_space_id, 'manageMediaMetadata')
  )
  with check (
    public.memora_has_capability(family_space_id, 'manageMediaMetadata')
  );

-- ---------------------------------------------------------------------------
-- Policies: observations
-- ---------------------------------------------------------------------------

create policy weight_observations_select
  on public.weight_observations for select to authenticated
  using (public.memora_has_capability(family_space_id, 'viewObservations'));

create policy weight_observations_insert
  on public.weight_observations for insert to authenticated
  with check (
    public.memora_has_capability(family_space_id, 'recordObservations')
  );

create policy weight_observations_update
  on public.weight_observations for update to authenticated
  using (public.memora_has_capability(family_space_id, 'recordObservations'))
  with check (
    public.memora_has_capability(family_space_id, 'recordObservations')
  );

create policy blood_pressure_observations_select
  on public.blood_pressure_observations for select to authenticated
  using (public.memora_has_capability(family_space_id, 'viewObservations'));

create policy blood_pressure_observations_insert
  on public.blood_pressure_observations for insert to authenticated
  with check (
    public.memora_has_capability(family_space_id, 'recordObservations')
  );

create policy blood_pressure_observations_update
  on public.blood_pressure_observations for update to authenticated
  using (public.memora_has_capability(family_space_id, 'recordObservations'))
  with check (
    public.memora_has_capability(family_space_id, 'recordObservations')
  );

-- ---------------------------------------------------------------------------
-- Policies: audit_events (append-only to clients)
-- ---------------------------------------------------------------------------

create policy audit_events_select
  on public.audit_events for select to authenticated
  using (public.memora_has_capability(family_space_id, 'manageMemberships')
    or public.memora_has_capability(family_space_id, 'viewMemberships'));

create policy audit_events_insert
  on public.audit_events for insert to authenticated
  with check (
    public.memora_has_capability(family_space_id, 'viewFamilySpace')
    and actor_user_id = auth.uid()
  );
