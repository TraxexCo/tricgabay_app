// Only package names/locked versions are sent to OSV, never source or credentials.
type Package = { name: string; version: string; ecosystem: string };
const destination = Deno.args[0] ?? ".audit-output/batch4/dependency-scan.json";
const lock = await Deno.readTextFile("pubspec.lock");
const packages: Package[] = [];
for (
  const match of lock.matchAll(
    /^  ([a-zA-Z0-9_]+):\r?\n([\s\S]*?)(?=^  [a-zA-Z0-9_]+:|^sdks:|$(?![\s\S]))/gm,
  )
) {
  if (!/^    source: hosted\r?$/m.test(match[2])) continue;
  const version = match[2].match(/^    version: "?([^"\s]+)"?\r?$/m)?.[1];
  if (version) packages.push({ name: match[1], version, ecosystem: "Pub" });
}
const denoLock = JSON.parse(
  await Deno.readTextFile("supabase/functions/deno.lock"),
);
for (const identity of Object.keys(denoLock.npm ?? {})) {
  const match = identity.match(/^(.+)@([^@]+)$/);
  if (match) {
    packages.push({
      name: match[1],
      version: match[2].split("_")[0],
      ecosystem: "npm",
    });
  }
}
if (packages.length < 50) {
  throw new Error(
    "Dependency parsing found too few packages; refusing an empty scan.",
  );
}
const findings: Array<{ package: Package; vulnerabilities: unknown[] }> = [];
for (let offset = 0; offset < packages.length; offset += 100) {
  const batch = packages.slice(offset, offset + 100);
  const response = await fetch("https://api.osv.dev/v1/querybatch", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      queries: batch.map(({ version, name, ecosystem }) => ({
        version,
        package: { name, ecosystem },
      })),
    }),
    signal: AbortSignal.timeout(60000),
  });
  if (!response.ok) {
    throw new Error(`OSV query failed: HTTP ${response.status}`);
  }
  const result = await response.json();
  if (result.results?.length !== batch.length) {
    throw new Error("Incomplete OSV response.");
  }
  for (let i = 0; i < batch.length; i++) {
    if (result.results[i].next_page_token) {
      throw new Error(
        "OSV result needs pagination; incomplete results are not a pass.",
      );
    }
    if (result.results[i].vulns?.length) {
      const details = [];
      for (const vuln of result.results[i].vulns) {
        const detail = await fetch(
          `https://api.osv.dev/v1/vulns/${encodeURIComponent(vuln.id)}`,
          { signal: AbortSignal.timeout(30000) },
        );
        if (!detail.ok) {
          throw new Error("Could not retrieve vulnerability details.");
        }
        details.push(await detail.json());
      }
      findings.push({ package: batch[i], vulnerabilities: details });
    }
  }
}
await Deno.mkdir(destination.replace(/[/\\][^/\\]+$/, ""), { recursive: true });
await Deno.writeTextFile(
  destination,
  JSON.stringify(
    {
      scanned_at: new Date().toISOString(),
      packages,
      findings,
      limits: [
        "Flutter SDK bundled code is not queried as a Pub package.",
        "Native Android resolved dependencies require the separate Gradle dependency review.",
      ],
    },
    null,
    2,
  ),
);
console.log(
  `OSV_RESULT packages=${packages.length} affected_packages=${findings.length} vulnerabilities=${
    findings.reduce((sum, f) => sum + f.vulnerabilities.length, 0)
  }`,
);
if (findings.length) Deno.exit(1);
