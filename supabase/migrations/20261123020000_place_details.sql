-- Researched details for the 11 tour-package places: real addresses,
-- longer histories, opening hours and tips (2026-11-23).
-- Sources: Sto. Niño Parish (snpbustos.weebly.com), Google Maps listings,
-- Diocese of Malolos, Province of Bulacan, galileewonderland.com.

update public.tourist_spots set
  name='Bustos Heritage Park',
  description='The town''s heritage park inside the Municipal Hall compound, where every Tric-Gabay tour begins. It holds the Bulacan Military Area (BMA) monument plaza, the municipal library and museum, and the Arts, Culture and Tourism Center that runs the tours.',
  history='Bustos began as a barrio of Baliuag. In 1862 a boat carrying parents, children and godparents to a baptism in Baliuag overturned on the Angat River, and the grief that followed led the people to ask for their own town and parish. Bustos separated from Baliuag on 29 April 1867, was returned to it during the American period, and became a municipality again on 1 January 1916; its first municipal hall opened in 1917 with Leon Prado as mayor.

The park also remembers the town''s role in World War II. The Bulacan Military Area, formed on 3 July 1942, made Bustos the headquarters of the province''s guerrillas under Bustos-born Capt. (later General) Alejo Santos. A historical marker for Santos was unveiled here in 2022, and the BMA grounds host the Minasa Festival every January.',
  address='Municipal Compound, Brgy. Poblacion, Bustos, Bulacan',
  opening_hours='Mon–Fri 8:00 AM–5:00 PM',
  entrance_fee_note='Free',
  tips='["The park grounds are open every day; the museum and tourism center follow office hours", "Ask the tourism staff about the BMA monument and the Bustos centennial exhibit", "Bring water and sun protection for the outdoor plaza"]'::jsonb
where id='bustos-heritage-park';

update public.tourist_spots set
  name='Sta. Cruz Chapel',
  description='The Chapel of the Holy Cross (Bisita ng Sta. Cruz) of Barangay Talampas, a community chapel of Sto. Niño Parish and a stop on the TRIC LAKBAY route.',
  history='Talampas is one of the old barrios that once lay across the Angat River from Baliuag. Before Bustos had its own parish, families from Talampas, Tanawan and Bonga had to cross the river to reach the church in Baliuag, and it was on one of these crossings in 1862 that a boat carrying children to their baptism capsized. That tragedy led to the founding of the Sto. Niño Parish in 1867.

Today Talampas keeps its own chapel under the parish, dedicated to the Holy Cross. It is run by the barangay''s parish pastoral council, which gathers the community for Masses, novenas and the yearly fiesta in honor of the Cross.',
  address='Purok 3, Brgy. Talampas, Bustos, Bulacan',
  opening_hours='Mon–Fri 8:00 AM–5:00 PM',
  entrance_fee_note='Free',
  tips='["Visits are arranged by the Bustos Tourism Office during tour hours", "Dress modestly and keep voices low if a service is going on", "Sunday and fiesta Mass times are announced by Sto. Niño Parish"]'::jsonb
where id='sta-cruz-chapel';

update public.tourist_spots set
  name='Sta. Monica Chapel',
  description='The Chapel of St. Monica (Bisita ni Sta. Monica) of Barangay Bonga Mayor, beside the highway near Tibagan, and the only chapel included in all three tour packages.',
  history='Bonga Mayor was one of the two Bonga barrios joined to the new town when Bustos separated from Baliuag in 1867. Its chapel is dedicated to St. Monica, the mother of St. Augustine. The choice reflects the Augustinian roots of the local Church: the Augustinians founded the Sto. Niño Parish of Bustos, and St. Monica and St. Augustine are carved on the main doors of the parish church.

The chapel serves the families of Bonga Mayor and the neighboring part of Tibagan under the Sto. Niño Parish, which holds Masses here and leads the community''s devotions and fiesta.',
  address='Gen. Alejo G. Santos Hwy, Brgy. Bonga Mayor, Bustos, Bulacan',
  opening_hours='Mon–Fri 8:00 AM–5:00 PM',
  entrance_fee_note='Free',
  tips='["Weekend evening services are held on Saturdays and Sundays", "The chapel faces the busy highway, so stay on the shoulder when taking photos", "Dress modestly inside the chapel"]'::jsonb
where id='sta-monica-chapel';

update public.tourist_spots set
  name='Sto. Niño Parish Church',
  description='The parish church of the Sto. Niño de Bustos, the town''s patron, in Poblacion. Founded in 1867, it was named a Jubilee Church of the Diocese of Malolos for the 500 years of Christianity in the Philippines.',
  history='The parish exists because of a tragedy. In 1862 a boat carrying parents, children and godparents to a baptism in Baliuag overturned in the Angat River. The people asked for a parish of their own so no one would have to cross the river again, and chose the Holy Child (Sto. Niño) as patron in memory of the infants who drowned. The Augustinians established the parish in 1867, with Padre Gabriel Alvarez as its first parish priest.

The church has a facade crowned by Christ the Redeemer, with niches for the Sto. Niño, St. Augustine and the crucified Christ. Its wooden doors are carved with St. Monica and St. Augustine, and its ceiling paintings follow the Sistine Chapel. The parish celebrated its 150th anniversary in 2017 together with the town''s centennial, and honors the Sto. Niño every third Sunday of January with the Tugyaw (tugtog at sayaw) street dancing.',
  address='Beltran St. cor. C.L. Hilario Hwy, Brgy. Poblacion, Bustos, Bulacan',
  opening_hours='Tue–Sat 8:00 AM–12:00 PM · Tue–Sat 2:00 PM–5:00 PM · Sun 9:30 AM–12:00 PM',
  entrance_fee_note='Free',
  tips='["Mass: Sundays 6:30 AM, 8:00 AM and 5:00 PM; Monday to Saturday 6:30 AM", "The parish office is closed on Mondays; call (044) 796 2194", "Do not walk around during Mass or private prayer"]'::jsonb
where id='sto-nino-church';

update public.tourist_spots set
  name='Zeny''s Minasa',
  description='A family-run pasalubong store near the Municipal Hall, known for Bustos minasa and other Bulacan delicacies. It is the last stop of all three tour packages.',
  history='Minasa are crisp cassava cookies made from cassava flour, egg yolk, yeast, butter and coconut milk. The name comes from the kneading (masa) of the dough. In Spanish times they were baked for well-off Bulakeño families, and local lore links them to the egg yolks left over when egg whites were used in building stone houses. Bustos holds the Minasa Festival every January, and the town''s motto is "Minasa ng kaunlaran!"

Zeny''s bakes its minasa in small batches. Maria Elena de Lara learned the recipe from her grandmother, who learned it from the family before her. Besides minasa, the store sells lengua de gato, barquillos and other native treats that visitors and balikbayans bring home.',
  address='7 Tanawan, Bustos, Bulacan (near the Municipal Hall)',
  opening_hours='Mon–Fri 7:00 AM–6:00 PM · Sat, Sun 7:00 AM–5:00 PM',
  entrance_fee_note='No entrance fee',
  tips='["Minasa is fragile; ask for a sturdy box if you are travelling far", "Buy at the end of the tour so the cookies stay crisp", "Contact: (044) 617 0227"]'::jsonb
where id='zenys-minasa';

update public.tourist_spots set
  name='St. Peter Chapel',
  description='The Chapel of St. Peter (Bisita ni San Pedro), the community chapel of Barangay San Pedro under Sto. Niño Parish, on the TRIC SAYA route.',
  history='San Pedro takes its name from its patron, St. Peter the Apostle, and its chapel stands at the heart of the barangay along Col. P. Garcia Street. It is one of the chapels of the Sto. Niño Parish, which has served the barrios of Bustos since 1867.

The chapel''s San Pedro parish pastoral council organizes Masses, novenas and the yearly fiesta. The chapel keeps images of St. Peter and other saints that are brought out for the barangay''s processions. It is a short ride from the Galilee Wonderland complex on the highway.',
  address='Col. P. Garcia St., Brgy. San Pedro, Bustos, Bulacan',
  opening_hours='Mon–Fri 8:00 AM–5:00 PM',
  entrance_fee_note='Free',
  tips='["Visits are arranged by the Bustos Tourism Office during tour hours", "Dress modestly and keep voices low", "The images of the saints are devotional objects, so please do not touch them"]'::jsonb
where id='st-peter-chapel';

update public.tourist_spots set
  name='Sto. Niño Chapel',
  description='A small community chapel dedicated to the Sto. Niño, the patron of Bustos, and a stop on the TRIC SAYA route.',
  history='Devotion to the Sto. Niño is at the center of Bustos life. The town chose the Holy Child as its patron in memory of the infants who drowned in the Angat River in 1862, the tragedy that led to the founding of the parish and the town in 1867.

Neighborhood chapels like this one keep that devotion close to home. Families gather here to pray to the Holy Child, especially in January, when the whole town celebrates the Sto. Niño feast with processions and the Tugyaw street dancing.',
  address='WWX6+MQX, Bustos, Bulacan',
  opening_hours='Mon–Fri 8:00 AM–5:00 PM',
  entrance_fee_note='Free',
  tips='["Visits are arranged by the Bustos Tourism Office during tour hours", "The busiest time is the Sto. Niño feast every third Sunday of January", "Dress modestly inside the chapel"]'::jsonb
where id='sto-nino-chapel';

update public.tourist_spots set
  name='Our Lady of Perpetual Help Chapel',
  description='The Chapel of Our Lady of Perpetual Help (Bisita ng Ina ng Laging Saklolo) in Sitio Pitong Gatang, Poblacion, a short walk from the Heritage Park and a stop on TRIC TUKLAS.',
  history='This is the Poblacion chapel of the Sto. Niño Parish. It is dedicated to Our Mother of Perpetual Help, the Marian devotion whose Wednesday novena is one of the most widely prayed in the Philippines. It serves the families of Sitio Pitong Gatang, a neighborhood of the town center.

Inside, a framed icon of the Virgin and Child is set on a carved wooden altar flanked by images of Mary. The Poblacion parish pastoral council keeps the chapel and leads its novenas and devotions.',
  address='67 Domingo St., Sitio Pitong Gatang, Brgy. Poblacion, Bustos, Bulacan',
  opening_hours='Mon–Fri 8:00 AM–5:00 PM',
  entrance_fee_note='Free',
  tips='["Visits are arranged by the Bustos Tourism Office during tour hours", "Wednesday is the traditional day of the Perpetual Help novena", "The chapel is on a narrow street; tricycles drop off at the corner"]'::jsonb
where id='perpetual-help-chapel';

update public.tourist_spots set
  name='Sto. Rosario Chapel',
  description='The Chapel of the Holy Rosary in Barangay Bonga Menor, a white chapel with a blue spire and a stop on the TRIC TUKLAS route.',
  history='Bonga Menor is one of the two Bonga barrios that joined Bustos when it became its own town in 1867. It is the birthplace of Gen. Alejo Santos, who led the Bulacan guerrillas in World War II. It is also home to several of the town''s ancestral houses.

The barangay''s chapel is dedicated to Our Lady of the Holy Rosary. It is a rounded white building with a blue conical spire and a bell turret over its gate. It belongs to the Sto. Niño Parish, which celebrates Mass here, and the community gathers in it for the Rosary devotions of October.',
  address='Ester Compound, C.L. Hilario St., Brgy. Bonga Menor, Bustos, Bulacan',
  opening_hours='Mon–Fri 8:00 AM–5:00 PM',
  entrance_fee_note='Free',
  tips='["Visits are arranged by the Bustos Tourism Office during tour hours", "October, the month of the Rosary, is the chapel’s busiest season", "Combine with a look at the ancestral houses of Bonga Menor from the road"]'::jsonb
where id='sto-rosario-chapel';

update public.tourist_spots set
  name='Immaculate Conception Chapel',
  description='The Chapel of the Immaculate Conception (Bisita ng Inmaculada Concepcion) of Barangay Malamig, a community chapel of Sto. Niño Parish on the TRIC TUKLAS route.',
  history='Malamig is a farming barangay south of the town center, on the road toward Liciada and Pandi. Its chapel is dedicated to the Immaculate Conception, a devotion close to Bulacan, whose cathedral in Malolos shares the same title.

The chapel belongs to the Sto. Niño Parish and is cared for by the Malamig parish pastoral council. It is a two-storey cream building with a tall arched entrance, and its blue-and-white interior centers on the crucifix and an image of the Immaculate Conception. The community''s biggest celebration is the feast of the Immaculate Conception on 8 December.',
  address='Brgy. Malamig, Bustos, Bulacan',
  opening_hours='Mon–Fri 8:00 AM–5:00 PM',
  entrance_fee_note='Free',
  tips='["Visits are arranged by the Bustos Tourism Office during tour hours", "The feast on 8 December draws the most people", "Dress modestly inside the chapel"]'::jsonb
where id='immaculate-conception-chapel';

update public.tourist_spots set
  name='Galilee Wailing Wall',
  description='A prayer wall inside Galilee Wonderland Waterpark and Hotel, modelled on Jerusalem''s Western Wall, where visitors write prayers on paper and tuck them between the stones.',
  history='Galilee opened on 5 March 2004 in San Pedro, Bustos, as Galilee Mansion and Garden Resort, and has since grown into Galilee Wonderland Waterpark and Hotel. The whole complex is built around biblical themes. Its pools and halls carry names such as Noah''s Ark, the Jordan River, Mt. Sinai and the Garden of Eden.

The Wailing Wall follows the Western Wall in Jerusalem, the last remaining wall of the Temple Mount, where pilgrims have long placed written prayers in the cracks. Here visitors can do the same in a quiet corner of the resort, near its church.',
  address='Galilee Wonderland Resort, Gen. Alejo G. Santos Hwy, Brgy. San Pedro, Bustos, Bulacan',
  opening_hours='Mon–Sun 7:00 AM–3:00 PM · Mon–Sun 4:00 PM–11:00 PM',
  entrance_fee_note='Resort entrance: ₱200 adults, ₱180 kids, ₱160 seniors and PWD',
  tips='["The wall is inside the resort, so the resort entrance fee may apply; confirm at the gate", "Bring a pen and a small piece of paper for your prayer", "Respect people who are praying at the wall"]'::jsonb
where id='galilee-wailing-wall';
