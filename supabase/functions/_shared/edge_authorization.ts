export function canManuallyDispatchCommunications(input: {
  activeAccount: boolean;
  operationsAllowed: boolean;
}): boolean {
  return input.activeAccount && input.operationsAllowed;
}

export function canReconcilePayment(input: {
  userId: string;
  touristId: string;
  financeAllowed: boolean;
}): boolean {
  return input.userId === input.touristId || input.financeAllowed;
}
