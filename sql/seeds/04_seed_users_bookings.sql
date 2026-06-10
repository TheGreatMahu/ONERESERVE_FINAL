-- ============================================================
--  OneReserve — Bangladesh Tourism Reservation System
--  File: 04_seed_users_bookings.sql
--  Description: Users · Bookings · booking_bus · booking_hotel ·
--               Payments · Reviews · Wishlist · booking_logs
-- ============================================================

USE onereserve;

-- ============================================================
-- USERS  (15 sample users — passwords are bcrypt hashes of
--         "Password@123" for demo purposes)
-- ============================================================
INSERT INTO users (full_name, email, password, phone, created_at) VALUES
('Rahim Uddin',       'rahim.uddin@gmail.com',      '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01711234567', '2026-01-05 09:10:00'),
('Fatema Khanam',     'fatema.khanam@yahoo.com',     '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01811234568', '2026-01-12 10:30:00'),
('Karim Hossain',     'karim.hossain@outlook.com',   '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01911234569', '2026-01-20 11:00:00'),
('Nasrin Akter',      'nasrin.akter@gmail.com',      '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01611234570', '2026-02-03 08:45:00'),
('Jahangir Alam',     'jahangir.alam@gmail.com',     '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01511234571', '2026-02-15 14:20:00'),
('Sumaiya Islam',     'sumaiya.islam@gmail.com',     '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01311234572', '2026-02-28 16:00:00'),
('Tanvir Ahmed',      'tanvir.ahmed@proton.me',      '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01411234573', '2026-03-07 09:30:00'),
('Roksana Begum',     'roksana.begum@gmail.com',     '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01211234574', '2026-03-14 11:15:00'),
('Mizanur Rahman',    'mizanur.rahman@yahoo.com',    '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01711234575', '2026-03-22 13:45:00'),
('Anika Sultana',     'anika.sultana@gmail.com',     '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01811234576', '2026-04-01 10:00:00'),
('Shahed Iqbal',      'shahed.iqbal@gmail.com',      '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01911234577', '2026-04-10 08:00:00'),
('Dilruba Haque',     'dilruba.haque@outlook.com',   '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01611234578', '2026-04-18 15:30:00'),
('Sabbir Hasan',      'sabbir.hasan@gmail.com',      '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01511234579', '2026-05-02 09:45:00'),
('Mahmuda Parvin',    'mahmuda.parvin@gmail.com',    '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01311234580', '2026-05-15 12:20:00'),
('Nayeem Hossain',    'nayeem.hossain@gmail.com',    '$2b$12$xvKRKWfHhSXLHgCmxIw4yOHUHGlIuqtQVhJXIuHbP7rjFxCVWxjVW', '01411234581', '2026-05-28 10:10:00');

-- ============================================================
-- BOOKINGS  (20 master booking records)
-- ============================================================
INSERT INTO bookings (user_id, booking_date, total_amount, booking_status, notes) VALUES
(1,  '2026-06-01 10:05:00', 11480.00, 'confirmed',  'Cox''s Bazar trip with family'),
(2,  '2026-06-01 11:30:00', 12560.00, 'confirmed',  'Saint Martin honeymoon package'),
(3,  '2026-06-02 09:15:00',  7600.00, 'confirmed',  'Srimangal tea estate visit'),
(4,  '2026-06-02 14:40:00',  9200.00, 'confirmed',  'Bandarban adventure trip'),
(5,  '2026-06-03 08:55:00',  6350.00, 'confirmed',  'Rangamati lake tour'),
(6,  '2026-06-03 16:20:00',  4980.00, 'completed',  'Srimangal nature weekend'),
(7,  '2026-06-04 09:00:00',  8440.00, 'confirmed',  'Sundarbans forest tour'),
(8,  '2026-06-04 13:10:00',  5400.00, 'confirmed',  'Ratargul swamp boat tour'),
(9,  '2026-06-05 10:30:00', 14060.00, 'confirmed',  'Cox''s Bazar premium stay'),
(10, '2026-06-05 15:45:00',  6780.00, 'confirmed',  'Kuakata sunrise sunset tour'),
(11, '2026-06-06 08:20:00',  3700.00, 'completed',  'Mahasthangarh history tour'),
(12, '2026-06-06 11:00:00',  7050.00, 'confirmed',  'Tanguar Haor birdwatching'),
(13, '2026-06-07 09:35:00',  5180.00, 'cancelled',  'Cancelled due to weather'),
(14, '2026-06-07 14:15:00',  9380.00, 'confirmed',  'Bagerhat heritage tour'),
(15, '2026-06-08 10:00:00',  6600.00, 'confirmed',  'Jaflong stone river tour'),
(1,  '2026-06-08 16:30:00',  4200.00, 'confirmed',  'Weekend Patenga trip'),
(2,  '2026-06-09 09:00:00',  8160.00, 'pending',    'Khagrachari cave tour'),
(3,  '2026-06-09 10:45:00',  5240.00, 'pending',    'Nijhum Dwip deer island'),
(4,  '2026-06-09 12:00:00',  7800.00, 'pending',    'Paharpur Buddhist ruins'),
(5,  '2026-06-09 13:30:00', 10400.00, 'pending',    'Saint Martin coral island');

-- ============================================================
-- BOOKING_BUS  (one bus booking per master booking)
-- ============================================================
INSERT INTO booking_bus (booking_id, schedule_id, seat_quantity, fare) VALUES
(1,  1,  2, 3960.00),  -- Rahim → Cox's Bazar, 2 seats × 1980
(2,  2,  2, 4560.00),  -- Fatema → Saint Martin, 2 seats × 2280
(3,  7,  2, 1000.00),  -- Karim → Srimangal, 2 seats × 500
(4,  12, 2, 2800.00),  -- Nasrin → Bandarban, 2 seats × 1400
(5,  13, 2, 2680.00),  -- Jahangir → Rangamati, 2 seats × 1340
(6,  7,  2, 1000.00),  -- Sumaiya → Srimangal, 2 seats × 500
(7,  15, 2, 2360.00),  -- Tanvir → Sundarbans, 2 seats × 1180
(8,  9,  2, 2160.00),  -- Roksana → Ratargul, 2 seats × 1080
(9,  1,  2, 3960.00),  -- Mizan → Cox's Bazar, 2 seats × 1980
(10, 3,  2, 3600.00),  -- Anika → Kuakata, 2 seats × 1800
(11, 18, 2, 1880.00),  -- Shahed → Mahasthangarh, 2 seats × 940
(12, 10, 2, 1300.00),  -- Dilruba → Tanguar Haor, 2 seats × 650
(13, 12, 2, 2800.00),  -- Sabbir → Bandarban (cancelled)
(14, 16, 2, 1300.00),  -- Mahmuda → Bagerhat, 2 seats × 650
(15, 8,  2, 2160.00),  -- Nayeem → Jaflong, 2 seats × 1080
(16, 4,  2, 2480.00),  -- Rahim → Patenga, 2 seats × 1240
(17, 14, 2, 1500.00),  -- Fatema → Khagrachari, 2 seats × 750
(18, 6,  2, 1600.00),  -- Karim → Nijhum Dwip, 2 seats × 800
(19, 17, 2, 1200.00),  -- Nasrin → Paharpur, 2 seats × 600
(20, 22, 2, 4560.00);  -- Jahangir → Saint Martin, 2 seats × 2280

-- ============================================================
-- BOOKING_HOTEL  (one hotel booking per master booking)
-- ============================================================
INSERT INTO booking_hotel (booking_id, room_type_id, checkin_date, checkout_date, nights, room_cost) VALUES
(1,  2,  '2026-06-11','2026-06-14', 3, 16500.00),  -- Deluxe, Ocean Paradise, 3n × 5500
(2,  5,  '2026-06-11','2026-06-13', 2,  8000.00),  -- Deluxe Cabin, Fantasy Jetty, 2n × 4000 (adjusted)
(3,  56, '2026-06-12','2026-06-14', 2,  3800.00),  -- Deluxe, Grand Sultan, 2n × 1900
(4,  40, '2026-06-13','2026-06-16', 3,  6600.00),  -- Deluxe, Sairu Hill, 3n × 2200 (adjusted)
(5,  49, '2026-06-13','2026-06-15', 2,  5600.00),  -- Deluxe Lake View, Lake View, 2n × 2800
(6,  56, '2026-06-12','2026-06-13', 1,  1900.00),  -- Deluxe, Grand Sultan, 1n
(7,  73, '2026-06-13','2026-06-16', 3,  8400.00),  -- Standard Cottage, Tiger Roar, 3n × 2800
(8,  70, '2026-06-12','2026-06-13', 1,  4200.00),  -- Deluxe Cottage, Ratargul Eco, 1n
(9,  3,  '2026-06-11','2026-06-14', 3, 28500.00),  -- Premier Suite, Sayeman, 3n × 9500
(10, 8,  '2026-06-11','2026-06-13', 2,  5600.00),  -- Deluxe, Sikder Resort, 2n × 2800 (adjusted)
(11, 85, '2026-06-14','2026-06-15', 1,  1820.00),  -- Deluxe, Momo Inn, 1n (adjusted)
(12, 30, '2026-06-12','2026-06-14', 2,  9200.00),  -- Houseboat Premium, 2n × 4600 (adjusted)
(13, 40, '2026-06-13','2026-06-14', 1,  2200.00),  -- Cancelled booking, Sairu
(14, 78, '2026-06-14','2026-06-16', 2,  8080.00),  -- Deluxe, Hotel Shat Gombuj, 2n × 4040 (adj)
(15, 65, '2026-06-12','2026-06-14', 2,  8240.00),  -- Deluxe, Jaflong Inn/Green Valley, 2n × 4120 (adj)
(16, 11, '2026-06-11','2026-06-12', 1,  4500.00),  -- Deluxe, Peninsula, 1n × 4500 (adj)
(17, 61, '2026-06-13','2026-06-15', 2,  5200.00),  -- Deluxe, Parjatan Khag, 2n × 2600
(18, 16, '2026-06-12','2026-06-14', 2,  4800.00),  -- Deluxe, Nijhum Resort, 2n × 2400 (adj)
(19, 88, '2026-06-14','2026-06-16', 2,  5200.00),  -- Deluxe, Paharpur Rest, 2n × 2600 (adj)
(20, 6,  '2026-06-11','2026-06-14', 3, 12600.00);  -- Labiba Bilas, 3n × 4200 (adj)

-- ============================================================
-- PAYMENTS
-- ============================================================
INSERT INTO payments (booking_id, amount, payment_method, payment_status, payment_date, transaction_ref) VALUES
(1,  11480.00,'bkash',         'completed','2026-06-01 10:08:00','BK20260601001'),
(2,  12560.00,'nagad',         'completed','2026-06-01 11:34:00','NG20260601002'),
(3,   7600.00,'card',          'completed','2026-06-02 09:18:00','CD20260602003'),
(4,   9200.00,'bkash',         'completed','2026-06-02 14:43:00','BK20260602004'),
(5,   6350.00,'rocket',        'completed','2026-06-03 08:58:00','RK20260603005'),
(6,   4980.00,'bkash',         'completed','2026-06-03 16:23:00','BK20260603006'),
(7,   8440.00,'nagad',         'completed','2026-06-04 09:04:00','NG20260604007'),
(8,   5400.00,'card',          'completed','2026-06-04 13:14:00','CD20260604008'),
(9,  14060.00,'bank_transfer', 'completed','2026-06-05 10:35:00','BT20260605009'),
(10,  6780.00,'bkash',         'completed','2026-06-05 15:48:00','BK20260605010'),
(11,  3700.00,'nagad',         'completed','2026-06-06 08:24:00','NG20260606011'),
(12,  7050.00,'card',          'completed','2026-06-06 11:05:00','CD20260606012'),
(13,  5180.00,'bkash',         'refunded', '2026-06-07 09:38:00','BK20260607013'),
(14,  9380.00,'rocket',        'completed','2026-06-07 14:18:00','RK20260607014'),
(15,  6600.00,'bkash',         'completed','2026-06-08 10:05:00','BK20260608015'),
(16,  4200.00,'nagad',         'completed','2026-06-08 16:34:00','NG20260608016'),
(17,  8160.00,'card',          'pending',  '2026-06-09 09:03:00','CD20260609017'),
(18,  5240.00,'bkash',         'pending',  '2026-06-09 10:48:00','BK20260609018'),
(19,  7800.00,'nagad',         'pending',  '2026-06-09 12:04:00','NG20260609019'),
(20, 10400.00,'card',          'pending',  '2026-06-09 13:33:00','CD20260609020');

-- ============================================================
-- REVIEWS  (20 reviews — mix of users & places)
-- ============================================================
INSERT INTO reviews (user_id, place_id, rating, review_text, review_date) VALUES
(1,  1,  5, "Cox's Bazar is breathtaking! The 120 km beach at dawn is an experience I'll carry forever. The waves, the sky, and the local hilsa fish dinner — perfect.", '2026-06-05 19:30:00'),
(2,  2,  5, 'Saint Martin Island is pure paradise. Snorkeling around Chera Dwip with crystal-clear water and coral formations was the highlight of our honeymoon.', '2026-06-05 20:10:00'),
(3,  7,  4, 'Srimangal exceeded all expectations. The seven-layer tea at Nilkantha is a must-try. Grand Sultan resort has incredible service and the golf course overlooks the tea estate.', '2026-06-05 21:00:00'),
(4, 12,  5, 'Bandarban stole my heart. Hiking to Nilgiri at sunrise with clouds below your feet is surreal. Sairu Hill Resort is luxurious and the staff truly care about guests.', '2026-06-06 10:00:00'),
(5, 13,  4, 'Rangamati is stunning. The Kaptai Lake boat ride at golden hour was unforgettable. The hanging bridge is smaller than photos suggest but still charming.', '2026-06-06 11:30:00'),
(6,  7,  5, 'A weekend escape to Srimangal for the soul. The scent of tea leaves in the morning air is unmatched anywhere in Bangladesh.', '2026-06-05 18:45:00'),
(7, 15,  5, 'The Sundarbans is unlike anywhere on Earth. Our 3-day tour had a Royal Bengal Tiger sighting on day 2 — the forest holds its breath in a way that humbles you.', '2026-06-07 22:00:00'),
(8,  9,  4, "Ratargul swamp forest is mysteriously beautiful. The flooded trees create an ethereal atmosphere. Hire a local boatman — they know every channel. Best in monsoon season.", '2026-06-06 14:20:00'),
(9,  1,  5, "Stayed at Sayeman Beach Resort and it was world-class. The private beach access, the infinity pool, and watching the longest beach in the world at sunrise from our balcony — 10/10.", '2026-06-07 09:00:00'),
(10, 3,  4, 'Kuakata delivered on its promise — we watched sunrise on the beach and turned around for sunset. The seafood market in the evening is vibrant and delicious.', '2026-06-07 17:00:00'),
(11,18,  4, 'Mahasthangarh is a history lover''s dream. Walking through 2,300 years of Bangladesh history in a single site is humbling. The museum next door is small but excellent.', '2026-06-07 21:00:00'),
(12,10,  5, 'Tanguar Haor during peak winter is one of the most spectacular sights in Bangladesh. The houseboat stay was rustic but magical — birds calling before dawn, fog on the water.', '2026-06-08 08:30:00'),
(14,16,  4, 'Bagerhat is criminally undervisited. The Sixty Dome Mosque is awe-inspiring and the town is peaceful. Highly recommend an early morning walk around the complex.', '2026-06-08 19:00:00'),
(15, 8,  4, 'Jaflong is where water meets mountain in the most dramatic way. The boulders rolling in the crystal river from Meghalaya are a geological wonder.', '2026-06-09 08:00:00'),
(1,  4,  3, 'Patenga is a nice quick getaway from Dhaka if you''re transiting through Chattogram. The street food especially the mezbani beef is excellent. Beach itself is small.', '2026-06-09 14:00:00'),
(3, 11,  4, 'Madhabkunda Waterfall was powerful during this season. The trek through rubber plantations to reach it adds to the adventure. Very refreshing after a hot journey.', '2026-06-08 15:00:00'),
(4, 14,  3, 'Khagrachari is beautiful but Alutila cave requires a strong stomach for darkness. The Risang Khong waterfall is worth the extra hike.', '2026-06-09 11:00:00'),
(5, 17,  4, 'Paharpur Mahavihara is a UNESCO gem that deserves more attention. The archaeological scale is staggering — as large as the greatest monasteries of the ancient world.', '2026-06-09 16:00:00'),
(2, 19,  4, 'Puthia Temple Complex in Rajshahi is extraordinary. The Govinda Temple and the Shiva Temple are beautifully preserved. Best visited in the cool hours of morning.', '2026-06-09 17:30:00'),
(6,  6,  4, 'Nijhum Dwip is truly "silent" as the name promises. The spotted deer herds in the mangrove forest at dusk are magical. This island deserves far more recognition.', '2026-06-09 18:00:00');

-- ============================================================
-- WISHLIST  (20 entries)
-- ============================================================
INSERT INTO wishlist (user_id, place_id) VALUES
(1,  2),  -- Rahim wishlist: Saint Martin
(1,  7),  -- Rahim wishlist: Srimangal
(2,  1),  -- Fatema: Cox's Bazar
(2, 12),  -- Fatema: Bandarban
(3,  9),  -- Karim: Ratargul
(3, 15),  -- Karim: Sundarbans
(4, 10),  -- Nasrin: Tanguar Haor
(4, 13),  -- Nasrin: Rangamati
(5,  2),  -- Jahangir: Saint Martin
(5,  8),  -- Jahangir: Jaflong
(6, 12),  -- Sumaiya: Bandarban
(6,  3),  -- Sumaiya: Kuakata
(7,  9),  -- Tanvir: Ratargul
(7, 10),  -- Tanvir: Tanguar Haor
(8,  1),  -- Roksana: Cox's Bazar
(8, 16),  -- Roksana: Bagerhat
(9, 17),  -- Mizan: Paharpur
(10, 18), -- Anika: Mahasthangarh
(11, 6),  -- Shahed: Nijhum Dwip
(12, 20); -- Dilruba: Varendra Museum

-- ============================================================
-- BOOKING_LOGS  (sample audit entries — triggers will add more)
-- ============================================================
INSERT INTO booking_logs (booking_id, action_type, old_status, new_status, performed_by, action_time, remarks) VALUES
(1,  'BOOKING_CREATED',  NULL,        'pending',   'rahim.uddin@gmail.com',   '2026-06-01 10:05:00', 'New booking created via web'),
(1,  'PAYMENT_RECEIVED', 'pending',   'confirmed', 'system',                  '2026-06-01 10:08:00', 'bKash payment BK20260601001 confirmed'),
(2,  'BOOKING_CREATED',  NULL,        'pending',   'fatema.khanam@yahoo.com', '2026-06-01 11:30:00', 'New booking created via web'),
(2,  'PAYMENT_RECEIVED', 'pending',   'confirmed', 'system',                  '2026-06-01 11:34:00', 'Nagad payment NG20260601002 confirmed'),
(3,  'BOOKING_CREATED',  NULL,        'pending',   'karim.hossain@outlook.com','2026-06-02 09:15:00','New booking created via mobile'),
(3,  'PAYMENT_RECEIVED', 'pending',   'confirmed', 'system',                  '2026-06-02 09:18:00', 'Card payment CD20260602003 confirmed'),
(6,  'BOOKING_CREATED',  NULL,        'pending',   'sumaiya.islam@gmail.com', '2026-06-03 16:20:00', 'New booking created via web'),
(6,  'PAYMENT_RECEIVED', 'pending',   'confirmed', 'system',                  '2026-06-03 16:23:00', 'bKash payment BK20260603006 confirmed'),
(6,  'TRIP_COMPLETED',   'confirmed', 'completed', 'admin',                   '2026-06-05 12:00:00', 'Trip marked as completed by admin'),
(11, 'BOOKING_CREATED',  NULL,        'pending',   'shahed.iqbal@gmail.com',  '2026-06-06 08:20:00', 'New booking created via web'),
(11, 'PAYMENT_RECEIVED', 'pending',   'confirmed', 'system',                  '2026-06-06 08:24:00', 'Nagad payment NG20260606011 confirmed'),
(11, 'TRIP_COMPLETED',   'confirmed', 'completed', 'admin',                   '2026-06-07 20:00:00', 'Trip marked completed'),
(13, 'BOOKING_CREATED',  NULL,        'pending',   'sabbir.hasan@gmail.com',  '2026-06-07 09:35:00', 'New booking created via web'),
(13, 'PAYMENT_RECEIVED', 'pending',   'confirmed', 'system',                  '2026-06-07 09:38:00', 'bKash payment BK20260607013 received'),
(13, 'BOOKING_CANCELLED','confirmed', 'cancelled', 'sabbir.hasan@gmail.com',  '2026-06-07 14:00:00', 'User cancelled due to weather forecast'),
(13, 'REFUND_ISSUED',    'cancelled', 'cancelled', 'admin',                   '2026-06-07 16:00:00', 'Full refund processed to bKash BK20260607013');

-- ============================================================
-- End of 04_seed_users_bookings.sql
-- ============================================================
