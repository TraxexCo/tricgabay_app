-- The privacy notice said background location is requested for driver
-- service. The app does not request background location: drivers share their
-- location with a foreground notification, only while online or on an active
-- trip. Only that clause changes; any other edits the operator made to the
-- notice are kept. A new version asks each user to read and accept the
-- corrected notice once.

update public.service_configuration
set
  privacy_notice_en = replace(
    privacy_notice_en,
    'background location is requested only for driver service',
    'drivers share location only while online or on an active trip, with a notification showing, and the app does not request background location'
  ),
  privacy_notice_fil = replace(
    privacy_notice_fil,
    'Kailangan lamang ang background location habang nagseserbisyo ang driver.',
    'Nagbabahagi lang ng lokasyon ang mga driver habang online o may aktibong biyahe, may nakikitang notification, at hindi humihingi ng background location ang app.'
  ),
  privacy_notice_version = '2026-11-26'
where singleton
  and (
    privacy_notice_en like '%background location is requested only for driver service%'
    or privacy_notice_fil like '%Kailangan lamang ang background location%'
  );

alter table public.service_configuration
  alter column privacy_notice_en set default 'Tric Gabay uses your name, email and phone to manage your account and trip contact. Pickup and trip location are used for matching, navigation and safety; drivers share location only while online or on an active trip, with a notification showing, and the app does not request background location. Driver identity and vehicle documents are reviewed by authorised administrators. Supabase stores account and trip records; Mapbox processes route coordinates; GCash payments go directly from tourist to driver, and Tric Gabay keeps the GCash reference number and any proof you submit for payment disputes; Firebase supports notifications. Optional crash and performance diagnostics may include device and app information; the app does not attach contact details, pickup codes, precise location or payment details to diagnostic reports. You may decline diagnostics and still book. Account deletion removes profile details, documents and avatars, and disconnects retained trip and financial records from your account. Financial transaction identifiers and amounts remain under the operator retention policy; provider copies and backups follow their own policies. For privacy or deletion help, use Help & support in your account.',
  alter column privacy_notice_version set default '2026-11-26';
