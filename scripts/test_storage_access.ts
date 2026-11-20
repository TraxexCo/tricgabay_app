import { literal, sql } from "./local_database.ts";
import { actors, has } from "./security/access_rules.ts";
import { localAdmin, localClient, logDirectory } from "./local_api.ts";

const identities = actors.map((a) => ({
    ...a,
    id: a.index ? crypto.randomUUID() : "",
  })
  ),
  admin = localAdmin();
let seed = "begin;";
for (const a of identities.filter((a) => a.index)) {
  seed +=
    `insert into auth.users(id,email,raw_user_meta_data)values('${a.id}','storage-${a.id}@example.test',${
      literal(
        JSON.stringify({
          full_name: "Synthetic storage actor",
          requested_role: [3, 4, 6].includes(a.index) ? "driver" : "tourist",
        }),
      )
    }::jsonb);`;
  if (a.capability) {
    seed +=
      `update public.profiles set role='admin' where id='${a.id}';insert into public.admin_capabilities(profile_id,capability)values('${a.id}','${a.capability}');`;
  } else if (a.index === 5) {
    seed += `update public.profiles set status='suspended' where id='${a.id}';`;
  } else if ([3, 4].includes(a.index)) {
    seed += `update public.profiles set status='active' where id='${a.id}';`;
  }
}
await sql(seed + "commit;");
const owner = identities.find((a) => a.index === 1)!,
  pending = identities.find((a) => a.index === 6)!;
const jpeg = new Uint8Array([255, 216, 255, 217]),
  png = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]);
const buckets = [
  {
    name: "driver-documents",
    path: `${pending.id}/vehicle-registration.jpg`,
    mime: "image/jpeg",
    bytes: jpeg,
    read: (a: typeof actors[number]) =>
      a.index === 6 || has(a, "driver_compliance"),
    write: (a: typeof actors[number]) => a.index === 6,
    public: false,
  },
  {
    name: "profile-images",
    path: `${owner.id}/avatars/storage-read.jpg`,
    mime: "image/jpeg",
    bytes: jpeg,
    read: (a: typeof actors[number]) => a.index === 1,
    write: (a: typeof actors[number]) => a.index === 1,
    public: false,
  },
  {
    name: "tourist-spots",
    path: `storage-${owner.id}/${crypto.randomUUID()}.jpg`,
    mime: "image/jpeg",
    bytes: jpeg,
    read: () => true,
    write: (a: typeof actors[number]) => has(a, "content"),
    public: true,
  },
  {
    name: "app-assets",
    path: `storage-${owner.id}.png`,
    mime: "image/png",
    bytes: png,
    read: () => true,
    write: (a: typeof actors[number]) => has(a, "content"),
    public: true,
  },
];
const results: {
  bucket: string;
  actor: string;
  operation: string;
  expected: boolean;
  actual: boolean;
  error?: string;
}[] = [];
const cleanup = new Map<string, Set<string>>();
function keep(bucket: string, path: string) {
  if (!cleanup.has(bucket)) cleanup.set(bucket, new Set());
  cleanup.get(bucket)!.add(path);
}
try {
  for (const bucket of buckets) {
    const initial = await admin.storage.from(bucket.name).upload(
      bucket.path,
      bucket.bytes,
      { contentType: bucket.mime, cacheControl: "31536000" },
    );
    if (initial.error) throw initial.error;
    keep(bucket.name, bucket.path);
    for (const actor of identities) {
      const client = await localClient(actor.id || undefined);
      const read = await client.storage.from(bucket.name).download(bucket.path);
      results.push({
        bucket: bucket.name,
        actor: actor.name,
        operation: "download",
        expected: bucket.read(actor),
        actual: !read.error,
        error: read.error?.message,
      });
      const list = await client.storage.from(bucket.name).list(
        bucket.path.slice(0, bucket.path.lastIndexOf("/") + 1).replace(
          /\/$/,
          "",
        ),
      );
      const found = !list.error &&
        list.data.some((row) => row.name === bucket.path.split("/").at(-1));
      results.push({
        bucket: bucket.name,
        actor: actor.name,
        operation: "list-owner-object",
        expected: bucket.read(actor),
        actual: found,
        error: list.error?.message,
      });
      const path = bucket.name === "driver-documents"
        ? `${pending.id}/license.jpg`
        : bucket.name === "profile-images"
        ? `${owner.id}/avatars/${crypto.randomUUID()}.jpg`
        : bucket.name === "tourist-spots"
        ? `storage-${owner.id}/${crypto.randomUUID()}.jpg`
        : `storage-${crypto.randomUUID()}.png`;
      const upload = await client.storage.from(bucket.name).upload(
        path,
        bucket.bytes,
        { contentType: bucket.mime, upsert: false, cacheControl: "31536000" },
      );
      if (!upload.error) {
        keep(bucket.name, path);
        await admin.storage.from(bucket.name).remove([path]);
      }
      results.push({
        bucket: bucket.name,
        actor: actor.name,
        operation: "upload-owner-prefix",
        expected: bucket.write(actor),
        actual: !upload.error,
        error: upload.error?.message,
      });
      const update = await client.storage.from(bucket.name).update(
        bucket.path,
        bucket.bytes,
        { contentType: bucket.mime },
      );
      const updateAllowed =
        (bucket.name === "driver-documents" && actor.index === 6) ||
        (bucket.name === "app-assets" && has(actor, "content"));
      results.push({
        bucket: bucket.name,
        actor: actor.name,
        operation: "overwrite",
        expected: updateAllowed,
        actual: !update.error,
        error: update.error?.message,
      });
      const deletion = await client.storage.from(bucket.name).remove([
        bucket.path,
      ]);
      const removed = !deletion.error &&
        deletion.data.some((row) => row.name === bucket.path);
      const deleteAllowed =
        (bucket.name === "driver-documents" && actor.index === 6) ||
        (bucket.name === "profile-images" && actor.index === 1) ||
        (["app-assets", "tourist-spots"].includes(bucket.name) &&
          has(actor, "content"));
      results.push({
        bucket: bucket.name,
        actor: actor.name,
        operation: "delete",
        expected: deleteAllowed,
        actual: removed,
        error: deletion.error?.message,
      });
      if (removed) {
        const restored = await admin.storage.from(bucket.name).upload(
          bucket.path,
          bucket.bytes,
          { contentType: bucket.mime, cacheControl: "31536000" },
        );
        if (restored.error) throw restored.error;
      }
    }
    const url =
      admin.storage.from(bucket.name).getPublicUrl(bucket.path).data.publicUrl;
    const publicRead = await fetch(url);
    const publiclyReadable = publicRead.ok;
    await publicRead.body?.cancel();
    results.push({
      bucket: bucket.name,
      actor: "anon",
      operation: "public-url",
      expected: bucket.public,
      actual: publiclyReadable,
    });
    if (bucket.name === "tourist-spots") {
      const response = await fetch(url);
      const header = response.headers.get("cache-control") ?? "";
      await response.body?.cancel();
      results.push({
        bucket: bucket.name,
        actor: "anon",
        operation: "versioned-cache-control",
        expected: true,
        actual: /max-age=31536000/.test(header),
      });
    }
  }
  const content = await localClient(
      identities.find((a) => a.capability === "content")!.id,
    ),
    driver = await localClient(pending.id);
  for (
    const [bucket, client, path, bytes, mime] of [
      [
        "driver-documents",
        driver,
        `${pending.id}/license.jpg`,
        png,
        "image/png",
      ],
      [
        "driver-documents",
        driver,
        `${pending.id}/license.png`,
        jpeg,
        "image/jpeg",
      ],
      [
        "tourist-spots",
        content,
        `storage-${owner.id}/not-versioned.jpg`,
        jpeg,
        "image/jpeg",
      ],
      [
        "tourist-spots",
        content,
        `storage-${owner.id}/${crypto.randomUUID()}.jpg`,
        new Uint8Array(5242881),
        "image/jpeg",
      ],
      [
        "app-assets",
        content,
        `storage-${owner.id}-oversize.png`,
        new Uint8Array(1048577),
        "image/png",
      ],
    ] as const
  ) {
    const result = await client.storage.from(bucket).upload(path, bytes, {
      contentType: mime,
    });
    if (!result.error) keep(bucket, path);
    results.push({
      bucket,
      actor: "validation",
      operation: path.endsWith(".png") ? "type-or-size" : "path-or-size",
      expected: false,
      actual: !result.error,
      error: result.error?.message,
    });
  }
  const failures = results.filter((r) => r.actual !== r.expected);
  await Deno.mkdir(logDirectory(), { recursive: true });
  await Deno.writeTextFile(
    `${logDirectory()}/storage-authorization.json`,
    JSON.stringify(
      {
        actors: identities.length,
        buckets: buckets.length,
        cases: results.length,
        failures,
        results,
        limits: [
          "Bucket/API enforce metadata MIME, canonical extension and size. Flutter checks magic bytes. A malicious direct client can forge MIME and magic prefixes; server-side decoding/antivirus is not implemented.",
        ],
      },
      null,
      2,
    ),
  );
  console.log(
    `STORAGE_MATRIX actors=${identities.length} buckets=${buckets.length} cases=${results.length} failures=${failures.length}`,
  );
  if (failures.length) throw new Error(JSON.stringify(failures, null, 2));
} finally {
  for (const [bucket, paths] of cleanup) {
    await admin.storage.from(bucket).remove([...paths]);
  }
  for (const a of identities.filter((a) => a.index)) {
    await admin.auth.admin.deleteUser(a.id);
  }
}
