-- Add workflow states separately so PostgreSQL can commit enum values before use.

alter type public.booking_status add value if not exists 'scheduled' before 'pending';
alter type public.booking_status add value if not exists 'replacement_pending' after 'accepted';
