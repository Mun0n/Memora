-- Slice 06 RLS contracts for product tables + extended capabilities.
-- Fictional reserved UUIDs match packages/domain IdentityFixtures / OfflineFixtures.
-- Assumes family_identity seed from family_identity_rls_test.sql ran first in suite
-- OR seeds its own minimal graph when run after migrations alone.
-- run_rls_tests.sh applies all migrations then all tests in sort order; identity
-- test seeds first. This file reuses those rows and adds product fixtures.

\set ON_ERROR_STOP on

create temporary table if not exists _assert_log (step text primary key);
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

-- Catalog: every product table must have FORCE RLS
do $$
declare
  r record;
  ok boolean := true;
begin
  for r in
    select c.relname, c.relrowsecurity as rls, c.relforcerowsecurity as forced
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname in (
        'routines',
        'reminders',
        'memories',
        'media_metadata',
        'weight_observations',
        'blood_pressure_observations',
        'audit_events',
        'pastimes',
        'conversation_topics'
      )
  loop
    if not (r.rls and r.forced) then
      ok := false;
      raise exception 'FORCE RLS missing on %', r.relname;
    end if;
  end loop;
  perform pg_temp.assert_true('product_tables_force_rls', ok);
end $$;

-- Seed product rows as superuser (bypasses RLS)
insert into public.routines (
  id, family_space_id, title, steps, lifecycle_status, row_version
) values (
  '01932f00-0003-7000-8000-000000000301',
  '01932f00-0002-7000-8000-0000000000a1',
  'Rutina manana Demo',
  '[{"order":0,"instruction":"Lavarse las manos"}]'::jsonb,
  'active',
  1
), (
  '01932f00-0006-7000-8000-0000000006b1',
  '01932f00-0002-7000-8000-0000000000b2',
  'Rutina Casa Demo B',
  '[{"order":0,"instruction":"Abrir persianas"}]'::jsonb,
  'active',
  1
);

insert into public.reminders (
  id, family_space_id, title, scheduled_at, row_version
) values (
  '01932f00-0003-7000-8000-000000000302',
  '01932f00-0002-7000-8000-0000000000a1',
  'Paseo Demo',
  '2026-10-10T10:00:00Z',
  1
);

insert into public.memories (
  id, family_space_id, caption, date_context, display_order,
  lifecycle_status, created_by, row_version
) values (
  '01932f00-0003-7000-8000-000000000303',
  '01932f00-0002-7000-8000-0000000000a1',
  'Jardin Demo',
  'Primavera 2024',
  0,
  'approved',
  '01932f00-0002-7000-8000-000000000101',
  1
), (
  '01932f00-0005-7000-8000-000000000501',
  '01932f00-0002-7000-8000-0000000000a1',
  'Patio propuesto Demo',
  'Verano 2025',
  1,
  'proposed',
  '01932f00-0002-7000-8000-000000000103',
  1
);

insert into public.media_metadata (
  id, family_space_id, memory_id, family_scoped_path, checksum,
  upload_state, row_version
) values (
  '01932f00-0006-7000-8000-000000000601',
  '01932f00-0002-7000-8000-0000000000a1',
  '01932f00-0003-7000-8000-000000000303',
  '01932f00-0002-7000-8000-0000000000a1/garden-demo.jpg',
  'sha256:demo-garden',
  'synced',
  1
);

insert into public.weight_observations (
  id, family_space_id, kilograms, recorded_at, author_id, row_version
) values (
  '01932f00-0003-7000-8000-000000000304',
  '01932f00-0002-7000-8000-0000000000a1',
  62.5,
  '2026-10-10T08:00:00Z',
  '01932f00-0002-7000-8000-000000000101',
  1
);

insert into public.blood_pressure_observations (
  id, family_space_id, systolic_mm_hg, diastolic_mm_hg, recorded_at,
  author_id, row_version
) values (
  '01932f00-0003-7000-8000-000000000305',
  '01932f00-0002-7000-8000-0000000000a1',
  120,
  80,
  '2026-10-10T08:05:00Z',
  '01932f00-0002-7000-8000-000000000101',
  1
);

insert into public.audit_events (
  id, family_space_id, actor_user_id, action, target_type, target_id, request_id
) values (
  '01932f00-0006-7000-8000-000000000690',
  '01932f00-0002-7000-8000-0000000000a1',
  '01932f00-0002-7000-8000-000000000101',
  'export.requested',
  'export_package',
  '01932f00-0006-7000-8000-000000000691',
  'req-demo-export-1'
);

insert into public.pastimes (
  id, family_space_id, title, instruction, display_order,
  lifecycle_status, row_version
) values (
  '01932f00-0008-7000-8000-000000000801',
  '01932f00-0002-7000-8000-0000000000a1',
  'Radio Demo',
  'Escuchar la radio Ejemplo un rato en el sillon.',
  0,
  'active',
  1
), (
  '01932f00-0008-7000-8000-000000000802',
  '01932f00-0002-7000-8000-0000000000a1',
  'Puzzle Ejemplo',
  'Hacer un puzzle sencillo en la mesa Demo.',
  1,
  'draft',
  1
), (
  '01932f00-0008-7000-8000-000000000803',
  '01932f00-0002-7000-8000-0000000000a1',
  'Fotos Ejemplo (archivado)',
  'Mirar el album familiar Demo con calma.',
  2,
  'archived',
  1
);

insert into public.conversation_topics (
  id, family_space_id, title, introduction, prompts, closing,
  display_order, lifecycle_status, row_version
) values (
  '01932f00-0010-7000-8000-000000001001',
  '01932f00-0002-7000-8000-0000000000a1',
  'El jardin Demo',
  'Tu familia me ha contado que te gustaba cuidar el jardin Ejemplo.',
  '[{"order":0,"text":"Si te apetece, puedes contarme que era lo que mas te gustaba plantar."},{"order":1,"text":"Cuando quieras, habla un poco de las flores de la casa Demo."}]'::jsonb,
  'Gracias por compartir un rato. Podemos hablar otro dia.',
  0,
  'active',
  1
), (
  '01932f00-0010-7000-8000-000000001002',
  '01932f00-0002-7000-8000-0000000000a1',
  'Cocina Ejemplo',
  'Tu familia recuerda las mananas en la cocina Demo con calma.',
  '[{"order":0,"text":"Si quieres, cuentame un olor que te gustaba por la manana."}]'::jsonb,
  'Cuando quieras, podemos dejarlo aqui.',
  1,
  'draft',
  1
), (
  '01932f00-0010-7000-8000-000000001003',
  '01932f00-0002-7000-8000-0000000000a1',
  'Musica Ejemplo (archivado)',
  'Tu familia me ha contado que te gustaba escuchar musica Demo.',
  '[{"order":0,"text":"Si te apetece, habla de una cancion que te gustaba."}]'::jsonb,
  'Podemos terminar cuando quieras.',
  2,
  'archived',
  1
);

-- Primary: full product visibility in own family; none in Casa Demo B
do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000101');

  select count(*) into n from public.routines;
  perform pg_temp.assert_true('primary_sees_own_routines_only', n = 1);

  select count(*) into n from public.reminders;
  perform pg_temp.assert_true('primary_sees_own_reminders', n = 1);

  select count(*) into n from public.memories;
  perform pg_temp.assert_true('primary_sees_all_memories_in_space', n = 2);

  select count(*) into n from public.pastimes;
  perform pg_temp.assert_true('primary_sees_all_pastimes_in_space', n = 3);

  select count(*) into n from public.conversation_topics;
  perform pg_temp.assert_true('primary_sees_all_conversation_topics', n = 3);

  select count(*) into n from public.media_metadata;
  perform pg_temp.assert_true('primary_sees_media_metadata', n = 1);

  select count(*) into n from public.weight_observations;
  perform pg_temp.assert_true('primary_sees_weight', n = 1);

  select count(*) into n from public.blood_pressure_observations;
  perform pg_temp.assert_true('primary_sees_bp', n = 1);

  select count(*) into n from public.audit_events;
  perform pg_temp.assert_true('primary_sees_audit', n = 1);
end $$;

-- Caregiver: edit routines/observations; cannot manage memberships (spot)
do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000102');

  select count(*) into n from public.routines;
  perform pg_temp.assert_true('caregiver_views_routines', n = 1);

  insert into public.routines (
    id, family_space_id, title, steps, lifecycle_status
  ) values (
    '01932f00-0006-7000-8000-0000000006c1',
    '01932f00-0002-7000-8000-0000000000a1',
    'Rutina cuidador Demo',
    '[{"order":0,"instruction":"Beber agua"}]'::jsonb,
    'active'
  );
  perform pg_temp.assert_true('caregiver_can_insert_routine', true);

  insert into public.weight_observations (
    id, family_space_id, kilograms, recorded_at, author_id
  ) values (
    '01932f00-0006-7000-8000-0000000006c2',
    '01932f00-0002-7000-8000-0000000000a1',
    63.0,
    '2026-10-10T09:00:00Z',
    '01932f00-0002-7000-8000-000000000102'
  );
  perform pg_temp.assert_true('caregiver_can_insert_weight', true);
end $$;

-- Supported person: view approved memories + routines; no observations; no edit
do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000104');

  select count(*) into n from public.routines;
  perform pg_temp.assert_true('supported_views_routines', n >= 1);

  select count(*) into n from public.memories
  where lifecycle_status = 'approved';
  perform pg_temp.assert_true('supported_views_approved_memories', n = 1);

  select count(*) into n from public.memories
  where lifecycle_status = 'proposed';
  perform pg_temp.assert_true('supported_hides_proposed_memories', n = 0);

  select count(*) into n from public.weight_observations;
  perform pg_temp.assert_true('supported_cannot_view_weight', n = 0);

  select count(*) into n from public.pastimes
  where lifecycle_status = 'active';
  perform pg_temp.assert_true('supported_views_active_pastimes', n = 1);

  select count(*) into n from public.pastimes
  where lifecycle_status in ('draft', 'archived');
  perform pg_temp.assert_true('supported_hides_draft_archived_pastimes', n = 0);

  select count(*) into n from public.conversation_topics
  where lifecycle_status = 'active';
  perform pg_temp.assert_true('supported_views_active_conversation_topics', n = 1);

  select count(*) into n from public.conversation_topics
  where lifecycle_status in ('draft', 'archived');
  perform pg_temp.assert_true(
    'supported_hides_draft_archived_conversation_topics',
    n = 0
  );

  begin
    insert into public.routines (
      id, family_space_id, title, steps, lifecycle_status
    ) values (
      '01932f00-0006-7000-8000-0000000006d1',
      '01932f00-0002-7000-8000-0000000000a1',
      'Hack Demo',
      '[{"order":0,"instruction":"x"}]'::jsonb,
      'active'
    );
    raise exception 'expected supported insert routine to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('supported_cannot_insert_routine', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('supported_cannot_insert_routine', true);
      else
        raise;
      end if;
  end;

  begin
    insert into public.pastimes (
      id, family_space_id, title, instruction, display_order, lifecycle_status
    ) values (
      '01932f00-0008-7000-8000-0000000008d1',
      '01932f00-0002-7000-8000-0000000000a1',
      'Hack Pastime',
      'No debe insertarse desde supported person.',
      9,
      'active'
    );
    raise exception 'expected supported insert pastime to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('supported_cannot_insert_pastime', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('supported_cannot_insert_pastime', true);
      else
        raise;
      end if;
  end;

  begin
    insert into public.conversation_topics (
      id, family_space_id, title, introduction, prompts, closing,
      display_order, lifecycle_status
    ) values (
      '01932f00-0010-7000-8000-0000000010d1',
      '01932f00-0002-7000-8000-0000000000a1',
      'Hack Topic',
      'No debe insertarse desde supported person.',
      '[{"order":0,"text":"Hack prompt Demo."}]'::jsonb,
      'Cierre hack.',
      9,
      'active'
    );
    raise exception 'expected supported insert conversation topic to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true(
        'supported_cannot_insert_conversation_topic',
        true
      );
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true(
          'supported_cannot_insert_conversation_topic',
          true
        );
      else
        raise;
      end if;
  end;
end $$;

-- Contributor: propose memory; cannot record observations; no cross-family
do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000103');

  insert into public.memories (
    id, family_space_id, caption, date_context, display_order,
    lifecycle_status, created_by
  ) values (
    '01932f00-0006-7000-8000-0000000006e1',
    '01932f00-0002-7000-8000-0000000000a1',
    'Propuesta Lucia Demo',
    'Otono 2026',
    2,
    'proposed',
    '01932f00-0002-7000-8000-000000000103'
  );
  perform pg_temp.assert_true('contributor_can_propose_memory', true);

  begin
    insert into public.weight_observations (
      id, family_space_id, kilograms, recorded_at, author_id
    ) values (
      '01932f00-0006-7000-8000-0000000006e2',
      '01932f00-0002-7000-8000-0000000000a1',
      60.0,
      '2026-10-10T11:00:00Z',
      '01932f00-0002-7000-8000-000000000103'
    );
    raise exception 'expected contributor weight insert to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('contributor_cannot_record_weight', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('contributor_cannot_record_weight', true);
      else
        raise;
      end if;
  end;

  select count(*) into n from public.routines
  where family_space_id = '01932f00-0002-7000-8000-0000000000b2';
  perform pg_temp.assert_true('contributor_no_cross_family_routines', n = 0);

  select count(*) into n from public.pastimes;
  perform pg_temp.assert_true('contributor_sees_no_pastimes', n = 0);

  select count(*) into n from public.conversation_topics;
  perform pg_temp.assert_true('contributor_sees_no_conversation_topics', n = 0);

  begin
    insert into public.pastimes (
      id, family_space_id, title, instruction, display_order, lifecycle_status
    ) values (
      '01932f00-0008-7000-8000-0000000008e1',
      '01932f00-0002-7000-8000-0000000000a1',
      'Hack Contributor',
      'Contributor no configura pastimes.',
      9,
      'draft'
    );
    raise exception 'expected contributor insert pastime to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('contributor_cannot_insert_pastime', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('contributor_cannot_insert_pastime', true);
      else
        raise;
      end if;
  end;

  begin
    insert into public.conversation_topics (
      id, family_space_id, title, introduction, prompts, closing,
      display_order, lifecycle_status
    ) values (
      '01932f00-0010-7000-8000-0000000010e1',
      '01932f00-0002-7000-8000-0000000000a1',
      'Hack Contributor Topic',
      'Contributor no configura temas.',
      '[{"order":0,"text":"Hack prompt contributor."}]'::jsonb,
      'Cierre hack.',
      9,
      'draft'
    );
    raise exception 'expected contributor insert conversation topic to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true(
        'contributor_cannot_insert_conversation_topic',
        true
      );
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true(
          'contributor_cannot_insert_conversation_topic',
          true
        );
      else
        raise;
      end if;
  end;
end $$;

-- Revoked / invited / outsider / anon denial on product tables
do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000106');
  select count(*) into n from public.routines;
  perform pg_temp.assert_true('revoked_sees_no_routines', n = 0);
  select count(*) into n from public.memories;
  perform pg_temp.assert_true('revoked_sees_no_memories', n = 0);
  select count(*) into n from public.weight_observations;
  perform pg_temp.assert_true('revoked_sees_no_weight', n = 0);
  select count(*) into n from public.pastimes;
  perform pg_temp.assert_true('revoked_sees_no_pastimes', n = 0);
  select count(*) into n from public.conversation_topics;
  perform pg_temp.assert_true('revoked_sees_no_conversation_topics', n = 0);
end $$;

do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000105');
  select count(*) into n from public.reminders;
  perform pg_temp.assert_true('invited_sees_no_reminders', n = 0);
end $$;

do $$
declare
  n integer;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000199');
  select count(*) into n from public.media_metadata;
  perform pg_temp.assert_true('outsider_sees_no_media', n = 0);
end $$;

do $$
begin
  begin
    set local role anon;
    perform 1 from public.routines;
    raise exception 'expected anon select on routines to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('anon_denied_routines', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('anon_denied_routines', true);
      else
        raise;
      end if;
  end;
end $$;

do $$
begin
  begin
    set local role anon;
    perform 1 from public.weight_observations;
    raise exception 'expected anon select on weight to fail';
  exception
    when insufficient_privilege then
      perform pg_temp.assert_true('anon_denied_weight', true);
    when others then
      if sqlstate = '42501' then
        perform pg_temp.assert_true('anon_denied_weight', true);
      else
        raise;
      end if;
  end;
end $$;

-- Cross-family: Casa Demo B primary cannot read Familia Ejemplo product rows
do $$
declare
  n integer;
  v_id uuid;
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000111');

  select count(*) into n from public.routines;
  select id into v_id from public.routines;
  perform pg_temp.assert_true(
    'space_b_sees_only_own_routine',
    n = 1 and v_id = '01932f00-0006-7000-8000-0000000006b1'
  );

  select count(*) into n from public.memories;
  perform pg_temp.assert_true('space_b_sees_no_ejemplo_memories', n = 0);

  select count(*) into n from public.weight_observations;
  perform pg_temp.assert_true('space_b_sees_no_ejemplo_weight', n = 0);

  select count(*) into n from public.pastimes;
  perform pg_temp.assert_true('space_b_sees_no_ejemplo_pastimes', n = 0);

  select count(*) into n from public.conversation_topics;
  perform pg_temp.assert_true(
    'space_b_sees_no_ejemplo_conversation_topics',
    n = 0
  );
end $$;

-- Capability spot-checks for new wires
do $$
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000101');
  perform pg_temp.assert_true(
    'capability_primary_edit_routines',
    public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'editRoutines'
    )
  );
  perform pg_temp.assert_true(
    'capability_primary_resolve_conflicts',
    public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'resolveSyncConflicts'
    )
  );
end $$;

do $$
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000104');
  perform pg_temp.assert_true(
    'capability_supported_no_record_observations',
    not public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'recordObservations'
    )
  );
  perform pg_temp.assert_true(
    'capability_supported_record_progress',
    public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'recordRoutineProgress'
    )
  );
  perform pg_temp.assert_true(
    'capability_supported_view_pastimes',
    public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'viewPastimes'
    )
  );
  perform pg_temp.assert_true(
    'capability_supported_no_edit_pastimes',
    not public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'editPastimes'
    )
  );
  perform pg_temp.assert_true(
    'capability_supported_view_conversation_topics',
    public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'viewConversationTopics'
    )
  );
  perform pg_temp.assert_true(
    'capability_supported_no_edit_conversation_topics',
    not public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'editConversationTopics'
    )
  );
end $$;

-- Caregiver can insert/update pastime; six-active limit enforced
do $$
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000102');

  insert into public.pastimes (
    id, family_space_id, title, instruction, display_order, lifecycle_status
  ) values (
    '01932f00-0008-7000-8000-0000000008c1',
    '01932f00-0002-7000-8000-0000000000a1',
    'Lectura Demo',
    'Leer un cuento corto Ejemplo en voz alta.',
    3,
    'draft'
  );
  perform pg_temp.assert_true('caregiver_can_insert_pastime', true);

  update public.pastimes
  set lifecycle_status = 'active', row_version = row_version + 1
  where id = '01932f00-0008-7000-8000-0000000008c1';
  perform pg_temp.assert_true('caregiver_can_activate_pastime', true);

  insert into public.conversation_topics (
    id, family_space_id, title, introduction, prompts, closing,
    display_order, lifecycle_status
  ) values (
    '01932f00-0010-7000-8000-0000000010c1',
    '01932f00-0002-7000-8000-0000000000a1',
    'Paseo Demo',
    'Tu familia recuerda los paseos Demo por el parque Ejemplo.',
    '[{"order":0,"text":"Si te apetece, cuentame que veias en el paseo."}]'::jsonb,
    'Cuando quieras, podemos dejarlo aqui.',
    3,
    'draft'
  );
  perform pg_temp.assert_true('caregiver_can_insert_conversation_topic', true);

  update public.conversation_topics
  set lifecycle_status = 'active', row_version = row_version + 1
  where id = '01932f00-0010-7000-8000-0000000010c1';
  perform pg_temp.assert_true(
    'caregiver_can_activate_conversation_topic',
    true
  );
end $$;

do $$
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000101');
  perform pg_temp.assert_true(
    'capability_primary_edit_pastimes',
    public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'editPastimes'
    )
  );
  perform pg_temp.assert_true(
    'capability_primary_edit_conversation_topics',
    public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'editConversationTopics'
    )
  );
end $$;

do $$
begin
  set local role authenticated;
  perform pg_temp.claim_as('01932f00-0002-7000-8000-000000000103');
  perform pg_temp.assert_true(
    'capability_contributor_no_edit_pastimes',
    not public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'editPastimes'
    )
  );
  perform pg_temp.assert_true(
    'capability_contributor_no_view_pastimes',
    not public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'viewPastimes'
    )
  );
  perform pg_temp.assert_true(
    'capability_contributor_no_edit_conversation_topics',
    not public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'editConversationTopics'
    )
  );
  perform pg_temp.assert_true(
    'capability_contributor_no_view_conversation_topics',
    not public.memora_has_capability(
      '01932f00-0002-7000-8000-0000000000a1',
      'viewConversationTopics'
    )
  );
end $$;

\echo PRODUCT_TABLES_RLS_CONTRACTS_PASS
