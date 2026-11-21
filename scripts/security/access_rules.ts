export type Actor = {
  name: string;
  id: string;
  index: number;
  dbRole: string;
  capability?: string;
};
export const id = (entity: number, subject = 1): string =>
  `a4${entity.toString(16).padStart(6, "0")}-0000-4000-8000-${
    String(subject).padStart(12, "0")
  }`;
export const actors: Actor[] = [
  { name: "anon", id: "", index: 0, dbRole: "anon" },
  ...[
    "tourist_a",
    "tourist_b",
    "driver_a",
    "driver_b",
    "suspended",
    "pending_driver",
  ].map((name, index) => ({
    name,
    id: id(1, index + 1),
    index: index + 1,
    dbRole: "authenticated",
  })),
  ...[
    "super_admin",
    "finance",
    "driver_compliance",
    "content",
    "support",
    "operations",
  ].map((capability, index) => ({
    name: `admin_${capability}`,
    id: id(1, index + 11),
    index: index + 11,
    dbRole: "authenticated",
    capability,
  })),
];
export const has = (actor: Actor, capability: string): boolean =>
  actor.capability === "super_admin" || actor.capability === capability;
export const publicDefiners = new Set([
  "current_profile_role",
  "get_client_configuration",
  "get_privacy_notice",
  "has_admin_capability",
  "is_admin",
  "is_approved_driver",
]);
export type RelationRule = {
  where: string;
  read: (actor: Actor) => boolean;
  insert?: (actor: Actor) => boolean;
  update?: (actor: Actor) => boolean;
  delete?: (actor: Actor) => boolean;
  updateColumn?: string;
  rowless?: boolean;
};
const everybody = () => true;
const nobody = () => false;
export function relationRule(key: string, group = 1): RelationRule {
  const owner = (a: Actor) => a.index === group;
  const participant = (a: Actor) => a.index === group || a.index === group + 2;
  const booking = (a: Actor) =>
    participant(a) || has(a, "operations") || has(a, "finance") ||
    has(a, "support");
  const money = (a: Actor) => participant(a) || has(a, "finance");
  const ops = (a: Actor) => participant(a) || has(a, "operations");
  const field = (entity: number, column = "id") =>
    `${column}='${id(entity, group)}'`;
  const rule = (
    where: string,
    read: RelationRule["read"],
    extra: Partial<RelationRule> = {},
  ): RelationRule => ({ where, read, ...extra });
  switch (key) {
    case "public.profiles":
      return rule(
        field(1),
        (a) =>
          participant(a) || has(a, "support") || has(a, "driver_compliance") ||
          has(a, "finance") || has(a, "operations"),
      );
    case "public.driver_profiles":
      return rule(
        `profile_id='${id(1, group + 2)}'`,
        (a) =>
          participant(a) || has(a, "driver_compliance") || has(a, "operations"),
      );
    case "public.bookings":
      return rule(field(2), booking);
    case "public.booking_stops":
      return rule(field(7), booking);
    case "public.trip_events":
      return rule(
        `${field(2, "booking_id")} and event_type='matrix_fixture'`,
        booking,
      );
    case "public.driver_locations":
      return rule(
        `driver_id='${id(1, group + 2)}'`,
        (a) => participant(a) || has(a, "operations"),
      );
    case "public.driver_location_history":
      return rule(
        field(2, "booking_id"),
        (a) => participant(a) || has(a, "operations"),
      );
    case "public.payments":
      return rule(field(8), money);
    case "public.refunds":
      return rule(field(9), money);
    case "public.financial_ledger_entries":
      return rule(
        `${field(8, "payment_id")} and entry_type='payment_received'`,
        money,
      );
    case "public.disputes":
      return rule(field(10), money);
    case "public.dispute_statements":
      return rule(field(11), (a) => money(a) || has(a, "support"));
    case "public.cash_confirmations":
      return rule(field(12), money);
    case "public.booking_reviews":
      return rule(field(2, "booking_id"), everybody);
    case "public.booking_route_changes":
      return rule(field(13), ops);
    case "public.booking_offers":
      return rule(field(2, "booking_id"), ops);
    case "public.notifications":
      return rule(field(15), owner, { update: owner, updateColumn: "read_at" });
    case "public.feedback":
      return rule(field(16), (a) => owner(a) || has(a, "support"), {
        insert: owner,
      });
    case "public.push_tokens":
      return rule(`token='matrix-token-${group}'`, owner);
    case "public.consent_history":
      return rule(field(17), (a) => owner(a) || has(a, "support"));
    case "public.privacy_consents":
      return rule(field(1, "profile_id"), nobody);
    case "public.data_subject_requests":
      return rule(field(19), (a) => owner(a) || has(a, "support"));
    case "public.data_subject_exports":
      return rule(field(19, "request_id"), owner);
    case "public.data_subject_request_audit":
      return rule(field(21), (a) => owner(a) || has(a, "support"));
    case "public.announcement_audit":
      return rule(`id='${id(18)}'`, (a) => has(a, "support"));
    case "public.admin_capabilities":
      return rule(
        `profile_id='${id(1, 15)}'`,
        (a) => a.index === 15 || has(a, "super_admin"),
      );
    case "public.operational_alerts":
      return rule(`id='${id(23)}'`, (a) => has(a, "operations"));
    case "public.message_deliveries":
      return rule(`id='${id(26)}'`, (a) => has(a, "operations"));
    case "public.emergency_contacts":
      return rule("id='mdrrmo'", everybody);
    case "public.emergency_contact_audit":
      return rule(`id='${id(22)}'`, (a) => has(a, "operations"));
    case "public.tourist_spots":
      return rule(
        `id='matrix-${group === 1 ? "a" : "b"}'`,
        (a) => group === 1 || has(a, "content"),
        {
          insert: (a) => has(a, "content"),
          update: (a) => has(a, "content"),
          delete: (a) => has(a, "content"),
        },
      );
    case "public.tour_packages":
      return rule(
        `id='matrix-package-${group === 1 ? "a" : "b"}'`,
        (a) => group === 1 || has(a, "content"),
        {
          insert: (a) => has(a, "content"),
          update: (a) => has(a, "content"),
          delete: (a) => has(a, "content"),
        },
      );
    case "public.tour_package_stops":
      return rule(
        `package_id='matrix-package-${group === 1 ? "a" : "b"}'`,
        everybody,
        {
          insert: (a) => has(a, "content"),
          update: (a) => has(a, "content"),
          delete: (a) => has(a, "content"),
        },
      );
    case "public.fare_revisions":
      return rule(`id='${id(5)}'`, everybody);
    case "public.cancellation_policies":
      return rule(`id='${id(6)}'`, everybody);
    case "public.service_configuration":
      return rule("singleton", everybody);
    case "public.internal_runtime_settings":
      return rule("key='matrix-fixture'", nobody);
    case "public.internal_scheduler_tokens":
      return rule("name='matrix-fixture'", nobody);
    case "public.payment_webhook_events":
      return rule("provider_event_id='evt_matrix'", nobody);
    case "public.checkout_expiry_requests":
      return rule(field(8, "payment_id"), nobody);
    case "public.account_deletion_requests":
      return rule(`user_id='${id(1, 5)}'`, nobody);
    case "public.booking_reminders":
      return rule("true", nobody, { rowless: true });
    case "public.operations_health":
      return rule("true", nobody, { rowless: true });
    case "public.spatial_ref_sys":
      return rule("srid=4326", everybody);
    case "public.geography_columns":
    case "public.geometry_columns":
      return rule("true", everybody, { rowless: true });
    // Storage rejects direct SQL DELETE even when API deletion is permitted.
    // The real Storage HTTP matrix separately asserts successful API deletion.
    case "storage.objects":
      return group === 1
        ? rule(
          `bucket_id='driver-documents' and name='${id(1, 6)}/license.jpg'`,
          (a) => a.index === 6 || has(a, "driver_compliance"),
          {
            insert: (a) => a.index === 6,
            update: (a) => a.index === 6,
            delete: nobody,
          },
        )
        : rule(
          `bucket_id='profile-images' and name='${
            id(1, 1)
          }/avatars/matrix.jpg'`,
          (a) => a.index === 1,
        );
    case "storage.buckets":
      return rule("id='driver-documents'", nobody);
    case "storage.buckets_analytics":
      return rule("name='matrix-analytics'", nobody);
    case "storage.migrations":
    case "storage.s3_multipart_uploads":
    case "storage.s3_multipart_uploads_parts":
    case "storage.buckets_vectors":
    case "storage.vector_indexes":
    case "storage.iceberg_namespaces":
    case "storage.iceberg_tables":
      return rule("true", nobody, { rowless: true });
    default:
      throw new Error(`No expected-access rule for new relation: ${key}`);
  }
}

export const rpcGroups: Record<string, string[]> = {
  public: [
    "current_profile_role",
    "get_client_configuration",
    "get_privacy_notice",
    "has_admin_capability",
    "is_admin",
    "is_approved_driver",
    "valid_image_object",
  ],
  self: [
    "is_pending_driver_application",
    "update_own_profile",
    "register_push_token",
    "revoke_push_token",
    "record_own_privacy_consent",
    "record_own_privacy_consent_with_language",
    "get_privacy_consent_status",
    "request_own_data_export",
    "owns_booking_as_tourist",
    "has_active_booking_offer",
    "notification_booking_id",
    "count_online_drivers",
  ],
  tourist: [
    "create_booking",
    "create_booking_with_requirements",
    "create_booking_with_schedule",
    "confirm_stop_arrival",
    "submit_driver_review",
    "decide_driver_replacement",
    "recover_booking_pickup_code",
    "reissue_booking_pickup_code",
    "retry_booking_dispatch",
    "refresh_booking_offers",
  ],
  driver: [
    "accept_booking",
    "start_trip",
    "report_pickup_arrival",
    "report_stop_arrival",
    "complete_trip",
    "declare_tourist_no_show",
    "decline_booking_offer",
    "request_driver_replacement",
    "report_vehicle_breakdown",
    "resume_after_breakdown",
    "report_route_deviation",
  ],
  both: [
    "cancel_booking",
    "open_dispute",
    "add_dispute_statement",
    "confirm_cash",
    "propose_route_change",
    "decide_route_change",
    "decide_breakdown_wait",
  ],
  driverSelf: [
    "set_driver_online",
    "publish_driver_location",
    "publish_driver_location_with_flags",
    "update_driver_service_profile",
  ],
  pending: ["submit_driver_application"],
  finance: [
    "publish_fares",
    "publish_cancellation_policy",
    "reserve_paymongo_refund",
    "resolve_booking_charge",
    "complete_paymongo_test_refund",
    "approve_test_refund",
  ],
  driver_compliance: [
    "admin_set_driver_status",
    "admin_review_driver_compliance",
  ],
  content: ["set_spot_availability"],
  support: [
    "send_announcement",
    "admin_set_tourist_status",
    "fulfil_data_subject_request",
  ],
  operations: ["update_emergency_contact", "get_operations_health"],
  super_admin: ["configure_service", "set_admin_capabilities"],
};
export function rpcAllowed(name: string, actor: Actor): boolean {
  const group = Object.entries(rpcGroups).find(([, names]) =>
    names.includes(name)
  )?.[0];
  if (!group) {
    throw new Error(
      `Missing semantic rule for callable application RPC: ${name}`,
    );
  }
  if (group === "public") return true;
  if (actor.dbRole === "anon") return false;
  if (group === "self") return true;
  if (group === "pending") return actor.index === 6;
  if (group === "driverSelf") return actor.index === 3 || actor.index === 4;
  if (group === "tourist") {
    return name.startsWith("create_booking")
      ? (actor.index === 1 || actor.index === 2)
      : actor.index === 1;
  }
  if (group === "driver") return actor.index === 3;
  if (group === "both") return actor.index === 1 || actor.index === 3;
  return has(actor, group);
}

export function rpcArguments(name: string, actor: Actor): string[] | undefined {
  const booking = `'${id(2)}'::uuid`,
    stop = `'${id(7)}'::uuid`,
    request = `'${id(19)}'::uuid`;
  const uuid = `'${id(40)}'::uuid`,
    reason = "'Synthetic matrix reason'",
    notice = "public.get_privacy_notice()->>'version'";
  const create = [
    "null::text",
    "'cash'::public.payment_method",
    "'Synthetic pickup'",
    "14.9571::double precision",
    "120.9188::double precision",
    '\'[{"spot_id":"matrix-a","stop_order":1}]\'::jsonb',
  ];
  const map: Record<string, string[]> = {
    has_admin_capability: ["'finance'"],
    owns_booking_as_tourist: [booking],
    has_active_booking_offer: [booking, `'${id(1, 3)}'::uuid`],
    valid_image_object: [
      "'fixture.jpg'",
      '\'{"mimetype":"image/jpeg","size":4}\'::jsonb',
      "5242880",
      "true",
    ],
    notification_booking_id: [`'/tourist/bookings/${id(2)}'`],
    update_own_profile: [
      "'Matrix Updated Name'",
      "'+639171234567'",
      "null::text",
      "null::text",
      "null::text",
    ],
    register_push_token: [
      "'matrix-new-device-token'",
      "'android'",
      "'matrix-device'",
    ],
    revoke_push_token: [`'matrix-token-${actor.index}'`],
    record_own_privacy_consent: [notice],
    record_own_privacy_consent_with_language: [notice, "'fil'"],
    request_own_data_export: [uuid, "'en'"],
    create_booking: create,
    create_booking_with_requirements: [...create, "1", "''", "''"],
    create_booking_with_schedule: [
      ...create,
      "1",
      "''",
      "''",
      "null::timestamptz",
      uuid,
    ],
    recover_booking_pickup_code: [booking, uuid, "'2468'"],
    reissue_booking_pickup_code: [booking, uuid, "'2468'"],
    start_trip: [booking, "'2468'"],
    submit_driver_review: [booking, "5", reason],
    decide_driver_replacement: [booking, "true"],
    request_driver_replacement: [booking, reason],
    report_vehicle_breakdown: [booking, reason],
    report_route_deviation: [booking, "200::double precision"],
    cancel_booking: [booking, reason],
    open_dispute: [booking, reason],
    add_dispute_statement: [`'${id(10)}'::uuid`, reason],
    confirm_cash: [booking, "'payment'"],
    propose_route_change: [booking, "'skip'", stop, "null::jsonb", reason],
    decide_route_change: [`'${id(13)}'::uuid`, "true"],
    decide_breakdown_wait: [booking, "true"],
    set_driver_online: ["true"],
    publish_driver_location: ["14.9571", "120.9188", "5", "0", "0", "now()"],
    publish_driver_location_with_flags: [
      "14.9571",
      "120.9188",
      "5",
      "0",
      "0",
      "now()",
      "false",
    ],
    update_driver_service_profile: ["3", "true"],
    submit_driver_application: [
      "'MATRIX-RESUME'",
      "'MATRIX-FR-RESUME'",
      "current_date+365",
      "current_date+365",
      "3",
      "true",
      "auth.uid()::text||'/license.jpg'",
      "auth.uid()::text||'/vehicle-registration.jpg'",
    ],
    publish_fares: ["10000", "'{}'::jsonb", reason],
    publish_cancellation_policy: [
      "5",
      "20",
      "10",
      "50",
      "1",
      "'Synthetic policy terms that are long enough'",
      reason,
    ],
    reserve_paymongo_refund: [booking, "1000", reason],
    resolve_booking_charge: [booking, "9000", reason],
    complete_paymongo_test_refund: [booking, "1000", reason],
    approve_test_refund: [booking, "1000", reason],
    admin_set_driver_status: [
      `'${id(1, 6)}'::uuid`,
      "'pending'::public.driver_approval_status",
      reason,
      "null::timestamptz",
    ],
    admin_review_driver_compliance: [
      `'${id(1, 6)}'::uuid`,
      "current_date+365",
      "current_date+365",
      "current_date+365",
      "'Matrix service area'",
      "14.9571",
      "120.9188",
      "15",
      "false",
      reason,
    ],
    set_spot_availability: [
      "'matrix-a'",
      "'open'",
      reason,
      "null::timestamptz",
    ],
    send_announcement: [
      "'Matrix title'",
      "'Synthetic matrix body'",
      "'all'",
      uuid,
    ],
    admin_set_tourist_status: [
      `'${id(1, 2)}'::uuid`,
      "'suspended'::public.account_status",
      reason,
    ],
    fulfil_data_subject_request: [request],
    configure_service: ["14.9571", "120.9188", "15", "3", "''"],
    update_emergency_contact: [
      "'mdrrmo'",
      "null::text",
      "'Matrix MDRRMO'",
      "'Matrix MDRRMO'",
    ],
    set_admin_capabilities: [
      `'${id(1, 15)}'::uuid`,
      "array['support']::text[]",
    ],
  };
  if (map[name]) return map[name];
  if (
    [
      "accept_booking",
      "report_pickup_arrival",
      "report_stop_arrival",
      "complete_trip",
      "declare_tourist_no_show",
      "decline_booking_offer",
      "resume_after_breakdown",
      "confirm_stop_arrival",
      "retry_booking_dispatch",
      "refresh_booking_offers",
    ].includes(name)
  ) return [booking];
  if (
    [
      "is_admin",
      "is_approved_driver",
      "current_profile_role",
      "get_client_configuration",
      "get_privacy_notice",
      "get_privacy_consent_status",
      "get_operations_health",
    ].includes(name)
  ) return [];
  return undefined;
}

export function rpcPreparation(name: string): string {
  const where = `where id='${id(2)}'`;
  if (name.startsWith("create_booking")) {
    return "update public.bookings set status='completed' where id::text like 'a4000002%';";
  }
  if (name === "accept_booking") {
    return `update public.bookings set status='pending',driver_id=null,dispatch_expires_at=now()+interval '10 minutes' ${where};`;
  }
  if (
    [
      "report_pickup_arrival",
      "start_trip",
      "declare_tourist_no_show",
      "request_driver_replacement",
      "reissue_booking_pickup_code",
    ].includes(name)
  ) {
    return `update public.bookings set status='accepted',driver_arrived_at=now()-interval '20 minutes',pickup_wait_expires_at=now()-interval '10 minutes',started_at=null ${where};`;
  }
  if (name === "fulfil_data_subject_request") {
    return `delete from public.data_subject_exports where request_id='${
      id(19)
    }';`;
  }
  if (name === "submit_driver_review") {
    return `delete from public.booking_reviews where booking_id='${
      id(2)
    }';update public.bookings set status='completed' ${where};`;
  }
  if (name === "complete_trip") {
    return `update public.bookings set confirmed_stop_count=1 ${where};`;
  }
  if (name === "confirm_stop_arrival") {
    return `update public.bookings set arrival_pending=true ${where};`;
  }
  if (
    [
      "submit_driver_review",
      "open_dispute",
      "confirm_cash",
      "resolve_booking_charge",
      "reserve_paymongo_refund",
      "complete_paymongo_test_refund",
      "approve_test_refund",
    ].includes(name)
  ) {
    return `update public.bookings set status='completed',final_charge_centavos=9000,payment_status='refund_required' ${where};`;
  }
  if (name === "decide_driver_replacement") {
    return `update public.bookings set status='replacement_pending',replacement_requested_by='${
      id(1, 3)
    }' ${where};`;
  }
  if (["resume_after_breakdown", "decide_breakdown_wait"].includes(name)) {
    return `update public.bookings set interrupted_at=now() ${where};`;
  }
  return "";
}
