-- The privacy notice still named PayMongo for online checkout, which was
-- removed in favour of GCash paid directly to the driver. Only that clause
-- changes; any other edits the operator made to the notice are kept. A new
-- version asks each user to read and accept the updated notice once.

update public.service_configuration
set
  privacy_notice_en = replace(
    privacy_notice_en,
    'PayMongo handles online checkout',
    'GCash payments go directly from tourist to driver, and Tric Gabay keeps the GCash reference number and any proof you submit for payment disputes'
  ),
  privacy_notice_fil = replace(
    privacy_notice_fil,
    'PayMongo ang online checkout',
    'diretso sa driver ang bayad sa GCash (itinatago ang reference number at patunay na isinumite mo para sa reklamo sa bayad)'
  ),
  privacy_notice_version = '2026-11-22'
where singleton
  and (privacy_notice_en like '%PayMongo%' or privacy_notice_fil like '%PayMongo%');

alter table public.service_configuration
  alter column privacy_notice_en set default 'Tric Gabay uses your name, email and phone to manage your account and trip contact. Pickup and trip location are used for matching, navigation and safety; background location is requested only for driver service. Driver identity and vehicle documents are reviewed by authorised administrators. Supabase stores account and trip records; Mapbox processes route coordinates; GCash payments go directly from tourist to driver, and Tric Gabay keeps the GCash reference number and any proof you submit for payment disputes; Firebase supports notifications. Optional crash and performance diagnostics may include device and app information; the app does not attach contact details, pickup codes, precise location or payment details to diagnostic reports. You may decline diagnostics and still book. Account deletion removes profile details, documents and avatars, and disconnects retained trip and financial records from your account. Financial transaction identifiers and amounts remain under the operator retention policy; provider copies and backups follow their own policies. For privacy or deletion help, use Help & support in your account.',
  alter column privacy_notice_version set default '2026-11-22';
