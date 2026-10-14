-- Slice 12 — family-scoped supported-person preferred-name profile.
-- Forced RLS; Dart FamilyAccessPolicy matrix must stay identical.
-- Fictional development only; no hosted project, credentials, LLM or real PII.

-- ---------------------------------------------------------------------------
-- Extend memora_has_capability with preferred-name wires (full matrix)
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
        or (p_capability = 'viewConversationTopics'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver'
          ))
        or (p_capability = 'editConversationTopics'
          and m.role in ('primaryCaregiver', 'caregiver'))
        or (p_capability = 'viewSupportedPersonProfile'
          and m.role in (
            'supportedPerson',
            'primaryCaregiver',
            'caregiver'
          ))
        or (p_capability = 'editSupportedPersonProfile'
          and m.role = 'primaryCaregiver')
      )
  );
$$;

revoke all on function public.memora_has_capability(uuid, text) from public;
grant execute on function public.memora_has_capability(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- supported_person_profiles table (one preferred name per family space)
-- ---------------------------------------------------------------------------

create table public.supported_person_profiles (
  id uuid primary key,
  family_space_id uuid not null references public.family_spaces (id),
  preferred_name text not null,
  row_version bigint not null default 1,
  idempotency_key text,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint supported_person_profiles_one_per_space
    unique (family_space_id),
  constraint supported_person_profiles_preferred_name_length
    check (
      char_length(trim(preferred_name)) between 1 and 40
    ),
  constraint supported_person_profiles_preferred_name_no_control
    check (trim(preferred_name) !~ '[[:cntrl:]]'),
  constraint supported_person_profiles_idempotency_unique
    unique (family_space_id, idempotency_key)
);

create index supported_person_profiles_family_space_idx
  on public.supported_person_profiles (family_space_id);

-- Normalize preferred_name to trimmed form on write.
create or replace function public.memora_trim_supported_person_preferred_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.preferred_name := trim(new.preferred_name);
  return new;
end;
$$;

create trigger supported_person_profiles_trim_name
  before insert or update on public.supported_person_profiles
  for each row
  execute procedure public.memora_trim_supported_person_preferred_name();

alter table public.supported_person_profiles enable row level security;
alter table public.supported_person_profiles force row level security;

revoke all on table public.supported_person_profiles from public, anon;
grant select, insert, update on table public.supported_person_profiles
  to authenticated;

-- Supported person + caregivers with viewSupportedPersonProfile may read.
-- Only primary (editSupportedPersonProfile) may insert/update; sync repair
-- also allows resolveSyncConflicts on update.
create policy supported_person_profiles_select
  on public.supported_person_profiles for select to authenticated
  using (
    public.memora_has_capability(
      family_space_id,
      'viewSupportedPersonProfile'
    )
  );

create policy supported_person_profiles_insert
  on public.supported_person_profiles for insert to authenticated
  with check (
    public.memora_has_capability(
      family_space_id,
      'editSupportedPersonProfile'
    )
  );

-- Primary-only mutation: do not open resolveSyncConflicts to ordinary
-- caregivers (they must not silently rename the supported person).
create policy supported_person_profiles_update
  on public.supported_person_profiles for update to authenticated
  using (
    public.memora_has_capability(
      family_space_id,
      'editSupportedPersonProfile'
    )
  )
  with check (
    public.memora_has_capability(
      family_space_id,
      'editSupportedPersonProfile'
    )
  );
