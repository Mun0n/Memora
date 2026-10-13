-- Slice 08 — family-scoped pastimes + viewPastimes/editPastimes capability wires.
-- Forced RLS; Dart FamilyAccessPolicy matrix must stay identical.
-- Fictional development only; no hosted project, credentials or media upload.

-- ---------------------------------------------------------------------------
-- Extend memora_has_capability with pastime wires (full matrix restated)
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
        or (p_capability = 'viewPastimes'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver'
          ))
        or (p_capability = 'editPastimes'
          and m.role in ('primaryCaregiver', 'caregiver'))
      )
  );
$$;

revoke all on function public.memora_has_capability(uuid, text) from public;
grant execute on function public.memora_has_capability(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- pastimes table
-- ---------------------------------------------------------------------------

create table public.pastimes (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  title text not null,
  instruction text not null,
  display_order integer not null default 0,
  lifecycle_status text not null,
  row_version bigint not null default 1,
  idempotency_key text,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pastimes_title_length
    check (
      char_length(trim(title)) between 1 and 60
    ),
  constraint pastimes_instruction_length
    check (
      char_length(trim(instruction)) between 1 and 240
    ),
  constraint pastimes_display_order_nonneg
    check (display_order >= 0),
  constraint pastimes_lifecycle_known
    check (lifecycle_status in ('draft', 'active', 'archived')),
  constraint pastimes_idempotency_unique unique (family_space_id, idempotency_key)
);

create index pastimes_family_space_idx on public.pastimes (family_space_id);

create index pastimes_family_active_idx
  on public.pastimes (family_space_id)
  where lifecycle_status = 'active' and deleted_at is null;

-- At most six active non-deleted pastimes per family space.
create or replace function public.memora_enforce_pastime_active_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  active_count integer;
begin
  if new.lifecycle_status = 'active' and new.deleted_at is null then
    select count(*)::integer into active_count
    from public.pastimes p
    where p.family_space_id = new.family_space_id
      and p.lifecycle_status = 'active'
      and p.deleted_at is null
      and p.id is distinct from new.id;
    if active_count >= 6 then
      raise exception
        'family already has 6 active pastimes'
        using errcode = 'check_violation';
    end if;
  end if;
  return new;
end;
$$;

create trigger pastimes_active_limit
  before insert or update on public.pastimes
  for each row
  execute procedure public.memora_enforce_pastime_active_limit();

alter table public.pastimes enable row level security;
alter table public.pastimes force row level security;

revoke all on table public.pastimes from public, anon;
grant select, insert, update on table public.pastimes to authenticated;

-- Supported person (viewPastimes only): active non-deleted rows.
-- Caregivers with editPastimes: full family-scoped read.
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
