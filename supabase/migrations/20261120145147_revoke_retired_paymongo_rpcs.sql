-- PayMongo is retired; its remaining RPCs must not be callable by app users.
revoke execute on function public.reserve_paymongo_refund(uuid, integer, text) from authenticated, anon, public;
revoke execute on function public.complete_paymongo_test_refund(uuid, integer, text) from authenticated, anon, public;
