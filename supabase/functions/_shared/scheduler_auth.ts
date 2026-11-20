export function constantTimeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

export function isSchedulerRequest(
  headers: Headers,
  expectedToken: string | null | undefined,
): boolean {
  const supplied = headers.get("x-tricgabay-scheduler") ?? "";
  return supplied.length >= 32 &&
    Boolean(expectedToken) &&
    constantTimeEqual(supplied, expectedToken!);
}
