# Tric Gabay language glossary

Display brand: **Tric Gabay**, supplied by `AppBrand.name`. Route names, place names, person names and owner-authored records retain their spelling. Do not translate protocol identifiers or legal policy versions in storage.

Use plain, polite instructions and sentence case for interface labels. Capitalize a term only at the beginning of a sentence or label. Keep proper names and acronyms such as GPS, SOS and MDRRMO. Use “mo” for brief personal instructions and avoid switching between English and Filipino nouns in the same Filipino message.

| English | Filipino | Usage |
| --- | --- | --- |
| booking | reserbasyon | A request or reserved ride; never “booking” in Filipino UI |
| book / reserve | magpareserba | Action |
| driver | drayber | Person driving the vehicle |
| tourist | turista | Person requesting the ride |
| tricycle | traysikel | Vehicle; preserve names of official documents |
| trip | biyahe | The journey, distinct from its reservation |
| pickup | sunduan | The meeting point or pickup stage |
| pickup code | kodigo sa sunduan | Verification secret; never translate its value |
| stop | hintuan | A location on a trip |
| destination | destinasyon | A place the tourist chooses |
| itinerary | itineraryo | Ordered trip plan |
| fare | pamasahe | Published or agreed price |
| payment | pagbabayad | Action or settlement |
| refund | pagsasauli ng bayad | Returned payment |
| cancel | kanselahin | Action |
| pending | naghihintay | Awaiting action |
| completed | natapos | Finished trip |
| service area | sakop ng serbisyo | Geographic boundary |
| offline | offline | Established connectivity term |
| online | online | Established availability/connectivity term |
| account | account | Established account term |
| password | password | Established authentication term |
| emergency | emerhensiya | Urgent safety assistance |

Dates, times, decimal numbers and Philippine peso amounts use `AppFormatters` with `en_PH` or `fil_PH`. Peso amounts show ₱ and grouping, for example ₱12,345.67. Manila appointment times use the localized Philippine-time label; the underlying UTC instant is unchanged. Editable numeric values and CSV exchange values intentionally use an ungrouped decimal format.

The default follows the device language: `fil` and `tl` select Filipino; other languages select English. A saved manual choice takes priority. “Use device language” removes the override. Existing saved choices are migrated as explicit overrides.

`localization-review.csv` exports every typed key and both ICU messages. These Filipino translations are implementation drafts, **not professionally reviewed**. A native-speaker reviewer should check grammar, naturalness, accessibility labels and the agreed terms before release. Owner-authored place descriptions, user statements, legal text and contact names require their own content review; they are data, not source-text lookup keys.
