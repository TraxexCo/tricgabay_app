/** Local-only implementation. Not deployed or exercised against Auth/Storage.
 * Each step is retryable. Database preparation disconnects personal identity;
 * documents/avatars are removed before Auth deletion. A durable private request
 * remains after interruption and a service-role worker can resume it.
 */
export async function deleteAccountSteps(steps: {
  prepare: () => Promise<void>;
  eraseStorage: () => Promise<void>;
  revokeSessions: () => Promise<void>;
  deleteIdentity: () => Promise<void>;
  finish: () => Promise<void>;
}): Promise<void> {
  await steps.prepare();
  await steps.eraseStorage();
  await steps.revokeSessions();
  await steps.deleteIdentity();
  await steps.finish();
}
