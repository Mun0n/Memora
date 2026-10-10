-- Slice 02 RLS contract tests.
-- All application assertions run as non-superuser role `authenticated`.
-- Fictional reserved UUIDs match packages/domain IdentityFixtures.

\set ON_ERROR_STOP on

create temporary table _assert_log (step text primary key);
grant select, insert, update, delete on _assert_log to authenticated, anon;

create or replace function pg_temp.claim_as(p_user uuid)
returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claim.sub', p_user::text, true);
end;
$$;

create or replace function pg_temp.assert_true(p_step text, p_condition boolean)
returns void
language plpgsql
as $$
begin
  if not coalesce(p_condition, false) then
    raise exception 'ASSERT FAILED: %', p_step;
  end if;
  insert into _assert_log(step) values (p_step)
  on conflict (step) do nothing;
end;
$$;

-- ---------------------------------------------------------------------------
-- Catalog: RLS must be enabled + forced (negative guard)
-- ---------------------------------------------------------------------------

do $$
declare
  v_spaces record;
  v_members record;
begin
  select c.relrowsecurity as rls, c.relforcerowsecurity as forced
    into v_spaces
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'family_spaces';

  select c.relrowsecurity as rls, c.relforcerowsecurity as forced
    into v_members
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname = 'family_memberships';

  perform pg_temp.assert_true(
    'rls_enabled_family_spaces',
    v_spaces.rls and v_spaces.forced
  );
  perform pg_temp.assert_true(
    'rls_enabled_family_memberships',
    v_members.rls and v_members.forced
  );
end $$;

-- ---------------------------------------------------------------------------
-- Seed auth.users + family graph as superuser (bypasses RLS; test harness only)
-- ---------------------------------------------------------------------------

insert into auth.users (id) values
  ('01932f00-0002-7000-8000-000000000101'), -- Elena Demo primary
  ('01932f00-0002-7000-8000-000000000102'), -- Carlos Demo caregiver
  ('01932f00-0002-7000-8000-000000000103'), -- Lucia Demo contributor
  ('01932f00-0002-7000-8000-000000000104'), -- Amparo Demo supported
  ('01932f00-0002-7000-8000-000000000105'), -- invited
  ('01932f00-0002-7000-8000-000000000106'), -- revoked
  ('01932f00-0002-7000-8000-000000000111'), -- Casa Demo B primary
  ('01932f00-0002-7000-8000-000000000198'), -- unused for negative primary insert
  ('01932f00-0002-7000-8000-000000000199'), -- Outsider Demo
  ('01932f00-0002-7000-8000-000000000301'); -- bootstrap actor

insert into public.family_spaces (id, display_name, household_timezone) values
  ('01932f00-0002-7000-8000-0000000000a1', 'Familia Ejemplo', 'Europe/Madrid'),
  ('01932f00-0002-7000-8000-0000000000b2', 'Casa Demo B', 'Atlantic/Canary');

insert into public.family_memberships (
  id, family_space_id, user_id, role, status
) values
  ('01932f00-0002-7000-8000-000000000201',
   '01932f00-0002-7000-8000-0000000000a1',
   '01932f00-0002-7000-8000-000000000101',
   'primaryCaregiver', 'active'),
  ('01932f00-0002-7000-8000-000000000202',
   '01932f00-0002-7000-8000-0000000000a1',
   '01932f00-0002-7000-8000-000000000102',
   'caregiver', 'active'),
  ('01932f00-0002-7000-8000-000000000203',
   '01932f00-0002-7000-8000-0000000000a1',
   '01932f00-0002-7000-8000-000000000103',
   'familyContributor', 'active'),
  ('01932f00-0002-7000-8000-000000000204',
   '01932f00-0002-7000-8000-0000000000a1',
   '01932f00-0002-7000-8000-000000000104',
   'supportedPerson', 'active'),
  ('01932f00-0002-7000-8000-000000000205',
   '01932f00-0002-7000-8000-0000000000a1',
   '01932f00-0002-7000-8000-000000000105',
   'caregiver', 'invited'),
  ('01932f00-0002-7000-8000-000000000206',
   '01932f00-0002-7000-8000-0000000000a1',
   '01932f00-0002-7000-8000-000000000106',
   'familyContributor', 'revoked'),
  ('01932f00-0002-7000-8000-000000000211',
   '01932f00-0002-7000-8000-0000000000b2',
   '01932f00-0002-7000-8000-000000000111',
   'primaryCaregiver', 'active');

-- ---------------------------------------------------------------------------
-- Prove current_user is not a superuser under SET ROLE authenticated
-- ---------------------------------------------------------------------------

do $$
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000101');
  perform pg_temp.assert_true(
    'session_is_non_superuser',
    not exists (
      select 1 from pg_roles where rolname = current_user and rolsuper
    )
  );
  perform pg_temp.assert_true(
    'session_role_authenticated',
    current_user = 'authenticated'
  );
end $$;

-- ---------------------------------------------------------------------------
-- Same-family permitted reads (primary)
-- ---------------------------------------------------------------------------

do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000101');

  select count(*) into n from public.family_spaces
  where id = '01932f00-0002-7000-8000-0000000000a1';
  perform pg_temp.assert_true('primary_sees_own_family_space', n = 1);

  select count(*) into n from public.family_memberships
  where family_space_id = '01932f00-0002-7000-8000-0000000000a1';
  perform pg_temp.assert_true('primary_sees_all_memberships_in_space', n = 6);

  select count(*) into n from public.family_spaces
  where id = '01932f00-0002-7000-8000-0000000000b2';
  perform pg_temp.assert_true('primary_cannot_see_other_family_space', n = 0);
end $$;

-- ---------------------------------------------------------------------------
-- Caregiver: view space + memberships; cannot update space or manage roles
-- ---------------------------------------------------------------------------

do $$
declare
  n integer;
  v_name text;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000102');

  select count(*) into n from public.family_spaces;
  perform pg_temp.assert_true('caregiver_views_family_space', n = 1);

  select count(*) into n from public.family_memberships
  where family_space_id = '01932f00-0002-7000-8000-0000000000a1';
  perform pg_temp.assert_true('caregiver_views_memberships', n = 6);

  update public.family_spaces
  set display_name = 'Hack Demo'
  where id = '01932f00-0002-7000-8000-0000000000a1';
  get diagnostics n = row_count;
  perform pg_temp.assert_true('caregiver_cannot_update_family_space', n = 0);

  -- Confirm value unchanged even if a buggy policy returned success with 0 rows
  reset role;
  select display_name into v_name from public.family_spaces
  where id = '01932f00-0002-7000-8000-0000000000a1';
  perform pg_temp.assert_true(
    'caregiver_update_did_not_mutate_row',
    v_name = 'Familia Ejemplo'
  );

  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000102');
  begin
    insert into public.family_memberships (
      family_space_id, user_id, role, status
    ) values (
      '01932f00-0002-7000-8000-0000000000a1',
      '01932f00-0002-7000-8000-000000000199',
      'caregiver',
      'invited'
    );
    raise exception 'expected caregiver insert to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('caregiver_cannot_manage_memberships_insert', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('caregiver_cannot_manage_memberships_insert', true);
      else
        raise;
      end if;
  end;

  -- Superuser residual: denied insert must not create a row
  reset role;
  select count(*) into n from public.family_memberships
  where family_space_id = '01932f00-0002-7000-8000-0000000000a1'
    and user_id = '01932f00-0002-7000-8000-000000000199';
  perform pg_temp.assert_true(
    'caregiver_denied_insert_created_no_row',
    n = 0
  );
end $$;

-- ---------------------------------------------------------------------------
-- Contributor: view space; own membership; no escalation
-- ---------------------------------------------------------------------------

do $$
declare
  n integer;
  v_role text;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000103');

  select count(*) into n from public.family_spaces;
  perform pg_temp.assert_true('contributor_views_family_space', n = 1);

  select count(*) into n from public.family_memberships;
  perform pg_temp.assert_true(
    'contributor_reads_own_membership_only',
    n = 1
    and (select user_id from public.family_memberships limit 1)
      = '01932f00-0002-7000-8000-000000000103'
  );

  update public.family_memberships
  set role = 'primaryCaregiver'
  where id = '01932f00-0002-7000-8000-000000000203';
  get diagnostics n = row_count;
  perform pg_temp.assert_true('contributor_cannot_self_promote', n = 0);

  reset role;
  select role into v_role from public.family_memberships
  where id = '01932f00-0002-7000-8000-000000000203';
  perform pg_temp.assert_true(
    'contributor_role_unchanged',
    v_role = 'familyContributor'
  );
end $$;

-- ---------------------------------------------------------------------------
-- Caregiver cannot self-promote to primaryCaregiver
-- ---------------------------------------------------------------------------

do $$
declare
  n integer;
  v_role text;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000102');

  update public.family_memberships
  set role = 'primaryCaregiver'
  where id = '01932f00-0002-7000-8000-000000000202';
  get diagnostics n = row_count;
  perform pg_temp.assert_true('caregiver_cannot_self_promote', n = 0);

  reset role;
  select role into v_role from public.family_memberships
  where id = '01932f00-0002-7000-8000-000000000202';
  perform pg_temp.assert_true(
    'caregiver_role_unchanged',
    v_role = 'caregiver'
  );
end $$;

-- ---------------------------------------------------------------------------
-- Supported person: view space; own membership only; no self-promote
-- ---------------------------------------------------------------------------

do $$
declare
  n integer;
  v_role text;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000104');

  select count(*) into n from public.family_spaces;
  perform pg_temp.assert_true('supported_views_family_space', n = 1);

  select count(*) into n from public.family_memberships;
  perform pg_temp.assert_true('supported_reads_own_membership_only', n = 1);

  update public.family_memberships
  set role = 'primaryCaregiver'
  where id = '01932f00-0002-7000-8000-000000000204';
  get diagnostics n = row_count;
  perform pg_temp.assert_true('supported_cannot_self_promote', n = 0);

  reset role;
  select role into v_role from public.family_memberships
  where id = '01932f00-0002-7000-8000-000000000204';
  perform pg_temp.assert_true(
    'supported_role_unchanged',
    v_role = 'supportedPerson'
  );
end $$;

-- ---------------------------------------------------------------------------
-- Outsider / invited / revoked denial
-- ---------------------------------------------------------------------------

do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000199');
  select count(*) into n from public.family_spaces;
  perform pg_temp.assert_true('outsider_sees_no_spaces', n = 0);
  select count(*) into n from public.family_memberships;
  perform pg_temp.assert_true('outsider_sees_no_memberships', n = 0);
end $$;

do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000105');
  select count(*) into n from public.family_spaces;
  perform pg_temp.assert_true('invited_sees_no_spaces', n = 0);
  select count(*) into n from public.family_memberships;
  perform pg_temp.assert_true('invited_sees_no_memberships', n = 0);
end $$;

do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000106');
  select count(*) into n from public.family_spaces;
  perform pg_temp.assert_true('revoked_sees_no_spaces', n = 0);
  select count(*) into n from public.family_memberships;
  perform pg_temp.assert_true('revoked_sees_no_memberships', n = 0);
end $$;

-- ---------------------------------------------------------------------------
-- Anonymous denial (no table grants / no policies for anon)
-- ---------------------------------------------------------------------------

do $$
begin
  begin
    set local role anon;
    perform 1 from public.family_spaces;
    raise exception 'expected anon select on family_spaces to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('anon_denied_family_spaces', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('anon_denied_family_spaces', true);
      else
        raise;
      end if;
  end;
end $$;

-- ---------------------------------------------------------------------------
-- Primary caregiver membership management + sole-primary protection
-- ---------------------------------------------------------------------------

do $$
declare
  n integer;
  v_status text;
  v_role text;
  v_name text;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000101');

  insert into public.family_memberships (
    id, family_space_id, user_id, role, status
  ) values (
    '01932f00-0002-7000-8000-000000000220',
    '01932f00-0002-7000-8000-0000000000a1',
    '01932f00-0002-7000-8000-000000000199',
    'caregiver',
    'invited'
  );

  select status into v_status from public.family_memberships
  where id = '01932f00-0002-7000-8000-000000000220';
  perform pg_temp.assert_true('primary_can_invite_membership', v_status = 'invited');

  update public.family_memberships
  set status = 'active', updated_at = now(), row_version = row_version + 1
  where id = '01932f00-0002-7000-8000-000000000220';
  get diagnostics n = row_count;
  perform pg_temp.assert_true('primary_can_activate_membership', n = 1);

  update public.family_memberships
  set status = 'revoked', updated_at = now(), row_version = row_version + 1
  where id = '01932f00-0002-7000-8000-000000000220';
  get diagnostics n = row_count;
  perform pg_temp.assert_true('primary_can_revoke_other_membership', n = 1);

  update public.family_memberships
  set status = 'revoked'
  where id = '01932f00-0002-7000-8000-000000000201';
  get diagnostics n = row_count;
  perform pg_temp.assert_true('sole_primary_cannot_be_revoked', n = 0);

  update public.family_memberships
  set role = 'caregiver'
  where id = '01932f00-0002-7000-8000-000000000201';
  get diagnostics n = row_count;
  perform pg_temp.assert_true('sole_primary_cannot_be_demoted', n = 0);

  update public.family_spaces
  set display_name = 'Familia Ejemplo Actualizada',
      updated_at = now(),
      row_version = row_version + 1
  where id = '01932f00-0002-7000-8000-0000000000a1';
  get diagnostics n = row_count;
  perform pg_temp.assert_true('primary_can_update_family_space', n = 1);

  update public.family_spaces
  set display_name = 'Familia Ejemplo'
  where id = '01932f00-0002-7000-8000-0000000000a1';

  begin
    delete from public.family_memberships
    where id = '01932f00-0002-7000-8000-000000000202';
    raise exception 'expected membership delete to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('direct_membership_delete_denied', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('direct_membership_delete_denied', true);
      else
        raise;
      end if;
  end;

  begin
    delete from public.family_spaces
    where id = '01932f00-0002-7000-8000-0000000000a1';
    raise exception 'expected family_space delete to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('direct_family_space_delete_denied', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('direct_family_space_delete_denied', true);
      else
        raise;
      end if;
  end;

  begin
    insert into public.family_memberships (
      family_space_id, user_id, role, status
    ) values (
      '01932f00-0002-7000-8000-0000000000a1',
      '01932f00-0002-7000-8000-000000000198',
      'primaryCaregiver',
      'active'
    );
    raise exception 'expected second active primary insert to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('cannot_insert_second_active_primary', true);
    when unique_violation then
      perform pg_temp.assert_true('cannot_insert_second_active_primary', true);
    when others then
      -- 42501 RLS/WITH CHECK; 23505 unique partial index
      if sqlstate in ('42501', '23505') then
        perform pg_temp.assert_true('cannot_insert_second_active_primary', true);
      else
        raise;
      end if;
  end;

  -- Negative: protected primary must still be active primary after denied mutations
  reset role;
  select status, role into v_status, v_role
  from public.family_memberships
  where id = '01932f00-0002-7000-8000-000000000201';
  perform pg_temp.assert_true(
    'protected_primary_row_still_active',
    v_status = 'active' and v_role = 'primaryCaregiver'
  );

  select count(*) into n from public.family_memberships
  where family_space_id = '01932f00-0002-7000-8000-0000000000a1'
    and role = 'primaryCaregiver'
    and status = 'active';
  perform pg_temp.assert_true(
    'exactly_one_active_primary_remains',
    n = 1
  );

  select display_name into v_name from public.family_spaces
  where id = '01932f00-0002-7000-8000-0000000000a1';
  perform pg_temp.assert_true(
    'family_space_still_present',
    v_name = 'Familia Ejemplo'
  );
end $$;

-- ---------------------------------------------------------------------------
-- Bootstrap: auth.uid() ownership; reject missing identity
-- ---------------------------------------------------------------------------

do $$
declare
  v_space public.family_spaces;
  v_role text;
  v_uid uuid;
  n integer;
begin
  begin
    set local role authenticated;
    perform set_config('request.jwt.claim.sub', '', true);
    perform public.bootstrap_family_space('Should Fail Demo', 'UTC');
    raise exception 'expected bootstrap without auth.uid to fail';
  exception
    when others then
      if sqlerrm like '%authentication required%' or sqlstate = '28000' then
        perform pg_temp.assert_true('bootstrap_rejects_missing_identity', true);
      else
        raise;
      end if;
  end;

  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000301');
  v_space := public.bootstrap_family_space('Bootstrap Demo Space', 'Europe/Madrid');

  select m.user_id, m.role into v_uid, v_role
  from public.family_memberships m
  where m.family_space_id = v_space.id and m.status = 'active';

  perform pg_temp.assert_true(
    'bootstrap_creates_space_for_auth_uid',
    v_uid = '01932f00-0002-7000-8000-000000000301'
    and v_role = 'primaryCaregiver'
    and v_space.display_name = 'Bootstrap Demo Space'
  );

  select count(*) into n from public.family_memberships
  where family_space_id = v_space.id;
  perform pg_temp.assert_true('bootstrap_membership_count_one', n = 1);
end $$;

-- ---------------------------------------------------------------------------
-- Cross-family isolation for Casa Demo B primary
-- ---------------------------------------------------------------------------

do $$
declare
  n integer;
  v_id uuid;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000111');

  select count(*) into n from public.family_spaces;
  select id into v_id from public.family_spaces;
  perform pg_temp.assert_true(
    'space_b_primary_sees_only_own_space',
    n = 1 and v_id = '01932f00-0002-7000-8000-0000000000b2'
  );

  select count(*) into n from public.family_memberships
  where family_space_id = '01932f00-0002-7000-8000-0000000000a1';
  perform pg_temp.assert_true(
    'space_b_primary_cannot_read_space_a_memberships',
    n = 0
  );
end $$;

-- ---------------------------------------------------------------------------
-- Capability helper matrix spot-check as authenticated
-- ---------------------------------------------------------------------------

do $$
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000101');
  perform pg_temp.assert_true(
    'capability_primary_manage',
    public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'manageMemberships'
    )
  );
end $$;

do $$
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000103');
  perform pg_temp.assert_true(
    'capability_contributor_no_manage',
    not public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'manageMemberships'
    )
  );
  perform pg_temp.assert_true(
    'capability_contributor_view_space',
    public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'viewFamilySpace'
    )
  );
end $$;

select pg_temp.assert_true(
  'assert_log_non_empty',
  (select count(*) from _assert_log) >= 20
);

\echo FAMILY_IDENTITY_RLS_CONTRACTS_PASS
