-- Slice 02 — family-space identity contract (draft schema + deny-by-default RLS).
-- Compatible with Supabase/PostgreSQL. Does not create or alter auth.users.
-- Capability matrix must stay identical to packages/domain FamilyAccessPolicy.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.family_spaces (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  household_timezone text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  row_version bigint not null default 1,
  constraint family_spaces_display_name_nonempty
    check (char_length(trim(display_name)) > 0),
  constraint family_spaces_household_timezone_iana
    check (
      household_timezone ~ '^(?:UTC|[A-Za-z]+(?:[_-][A-Za-z]+)*(?:/[A-Za-z0-9]+(?:[_-][A-Za-z0-9]+)*)+)$'
    )
);

create table public.family_memberships (
  id uuid primary key default gen_random_uuid(),
  family_space_id uuid not null references public.family_spaces (id),
  user_id uuid not null references auth.users (id),
  role text not null,
  status text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  row_version bigint not null default 1,
  constraint family_memberships_role_known
    check (role in (
      'supportedPerson',
      'primaryCaregiver',
      'caregiver',
      'familyContributor'
    )),
  constraint family_memberships_status_known
    check (status in ('active', 'invited', 'revoked')),
  constraint family_memberships_space_user_unique
    unique (family_space_id, user_id)
);

create unique index family_memberships_one_active_primary
  on public.family_memberships (family_space_id)
  where role = 'primaryCaregiver' and status = 'active';

create unique index family_memberships_one_active_supported
  on public.family_memberships (family_space_id)
  where role = 'supportedPerson' and status = 'active';

create index family_memberships_user_id_idx
  on public.family_memberships (user_id);

create index family_memberships_space_status_idx
  on public.family_memberships (family_space_id, status);

-- ---------------------------------------------------------------------------
-- Centralized capability evaluation (SECURITY DEFINER, pinned search_path)
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
      )
  );
$$;

revoke all on function public.memora_has_capability(uuid, text) from public;
grant execute on function public.memora_has_capability(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Atomic authenticated bootstrap (owner from auth.uid() only)
-- ---------------------------------------------------------------------------

create or replace function public.bootstrap_family_space(
  p_display_name text,
  p_household_timezone text
) returns public.family_spaces
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_space public.family_spaces;
begin
  if v_uid is null then
    raise exception 'authentication required'
      using errcode = '28000';
  end if;

  if char_length(trim(coalesce(p_display_name, ''))) = 0 then
    raise exception 'display_name required'
      using errcode = '22023';
  end if;

  insert into public.family_spaces (display_name, household_timezone)
  values (trim(p_display_name), p_household_timezone)
  returning * into v_space;

  insert into public.family_memberships (
    family_space_id,
    user_id,
    role,
    status
  ) values (
    v_space.id,
    v_uid,
    'primaryCaregiver',
    'active'
  );

  return v_space;
end;
$$;

revoke all on function public.bootstrap_family_space(text, text) from public;
grant execute on function public.bootstrap_family_space(text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Row Level Security (ENABLE + FORCE); deny-by-default
-- ---------------------------------------------------------------------------

alter table public.family_spaces enable row level security;
alter table public.family_spaces force row level security;

alter table public.family_memberships enable row level security;
alter table public.family_memberships force row level security;

-- Least-privilege table grants: authenticated only; never anon.
grant usage on schema public to authenticated;

revoke all on table public.family_spaces from public;
revoke all on table public.family_spaces from anon;
revoke all on table public.family_memberships from public;
revoke all on table public.family_memberships from anon;

grant select, update on table public.family_spaces to authenticated;
grant select, insert, update on table public.family_memberships to authenticated;
-- No DELETE grants. No direct INSERT on family_spaces (bootstrap only).

-- family_spaces policies
create policy family_spaces_select_active_member
  on public.family_spaces
  for select
  to authenticated
  using (public.memora_has_capability(id, 'viewFamilySpace'));

create policy family_spaces_update_primary
  on public.family_spaces
  for update
  to authenticated
  using (public.memora_has_capability(id, 'updateFamilySpace'))
  with check (public.memora_has_capability(id, 'updateFamilySpace'));

-- No INSERT / DELETE policies on family_spaces (deny direct create/delete).

-- family_memberships policies
create policy family_memberships_select
  on public.family_memberships
  for select
  to authenticated
  using (
    public.memora_has_capability(family_space_id, 'viewMemberships')
    or (
      status = 'active'
      and user_id = auth.uid()
    )
  );

create policy family_memberships_insert_managed
  on public.family_memberships
  for insert
  to authenticated
  with check (
    public.memora_has_capability(family_space_id, 'manageMemberships')
    and not (role = 'primaryCaregiver' and status = 'active')
  );

-- Primary may update other memberships. Sole active primary row is immutable
-- via direct UPDATE (transfer is a later explicit workflow).
create policy family_memberships_update_managed
  on public.family_memberships
  for update
  to authenticated
  using (
    public.memora_has_capability(family_space_id, 'manageMemberships')
    and not (role = 'primaryCaregiver' and status = 'active')
  )
  with check (
    public.memora_has_capability(family_space_id, 'manageMemberships')
    and not (role = 'primaryCaregiver' and status = 'active')
  );

-- No DELETE policy on family_memberships (revocation is a status update).
