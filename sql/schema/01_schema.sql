-- ============================================================
--  OneReserve — Bangladesh Tourism Reservation System
--  File: 01_schema.sql
--  Description: Complete production schema — 15 tables
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS onereserve;
CREATE DATABASE onereserve
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE onereserve;

-- ============================================================
-- TABLE 1: users
-- ============================================================
CREATE TABLE users (
    user_id       INT            AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100)   NOT NULL,
    email         VARCHAR(150)   NOT NULL,
    password      VARCHAR(255)   NOT NULL,
    phone         VARCHAR(20),
    created_at    TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    is_active     TINYINT(1)     NOT NULL DEFAULT 1,

    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_users_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_users_phone CHECK (phone REGEXP '^[0-9+]{10,15}$' OR phone IS NULL),

    INDEX idx_users_email  (email),
    INDEX idx_users_active (is_active)
);

-- ============================================================
-- TABLE 2: districts
-- ============================================================
CREATE TABLE districts (
    district_id   INT           AUTO_INCREMENT PRIMARY KEY,
    district_name VARCHAR(100)  NOT NULL,

    CONSTRAINT uq_districts_name UNIQUE (district_name),
    INDEX idx_districts_name (district_name)
);

-- ============================================================
-- TABLE 3: places
-- ============================================================
CREATE TABLE places (
    place_id      INT             AUTO_INCREMENT PRIMARY KEY,
    district_id   INT             NOT NULL,
    place_name    VARCHAR(150)    NOT NULL,
    description   TEXT,
    image_path    VARCHAR(255),
    latitude      DECIMAL(10,8),
    longitude     DECIMAL(11,8),
    google_map_url TEXT,
    category      VARCHAR(60),
    is_featured   TINYINT(1)      NOT NULL DEFAULT 0,

    CONSTRAINT fk_places_district
        FOREIGN KEY (district_id) REFERENCES districts(district_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_places_lat  CHECK (latitude  BETWEEN  -90  AND  90  OR latitude  IS NULL),
    CONSTRAINT chk_places_lng  CHECK (longitude BETWEEN -180  AND 180  OR longitude IS NULL),

    INDEX idx_places_district  (district_id),
    INDEX idx_places_category  (category),
    INDEX idx_places_featured  (is_featured),
    FULLTEXT INDEX ft_places_name_desc (place_name, description)
);

-- ============================================================
-- TABLE 4: bus_companies
-- ============================================================
CREATE TABLE bus_companies (
    company_id    INT           AUTO_INCREMENT PRIMARY KEY,
    company_name  VARCHAR(100)  NOT NULL,
    contact_no    VARCHAR(20),
    logo_path     VARCHAR(255),
    is_active     TINYINT(1)    NOT NULL DEFAULT 1,

    CONSTRAINT uq_bus_companies_name UNIQUE (company_name),
    INDEX idx_bus_companies_active (is_active)
);

-- ============================================================
-- TABLE 5: buses
-- ============================================================
CREATE TABLE buses (
    bus_id          INT          AUTO_INCREMENT PRIMARY KEY,
    company_id      INT          NOT NULL,
    bus_name        VARCHAR(100) NOT NULL,
    bus_type        VARCHAR(50)  NOT NULL,
    seat_capacity   INT          NOT NULL,
    available_seats INT          NOT NULL DEFAULT 0,

    CONSTRAINT fk_buses_company
        FOREIGN KEY (company_id) REFERENCES bus_companies(company_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_buses_capacity CHECK (seat_capacity > 0),
    CONSTRAINT chk_buses_avail    CHECK (available_seats >= 0 AND available_seats <= seat_capacity),

    INDEX idx_buses_company  (company_id),
    INDEX idx_buses_type     (bus_type)
);

-- ============================================================
-- TABLE 6: schedules
-- ============================================================
CREATE TABLE schedules (
    schedule_id      INT             AUTO_INCREMENT PRIMARY KEY,
    bus_id           INT             NOT NULL,
    place_id         INT             NOT NULL,
    departure_city   VARCHAR(100)    NOT NULL DEFAULT 'Dhaka',
    departure_time   DATETIME        NOT NULL,
    arrival_time     DATETIME        NOT NULL,
    fare             DECIMAL(10,2)   NOT NULL,
    is_active        TINYINT(1)      NOT NULL DEFAULT 1,

    CONSTRAINT fk_schedules_bus
        FOREIGN KEY (bus_id)   REFERENCES buses(bus_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_schedules_place
        FOREIGN KEY (place_id) REFERENCES places(place_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_schedules_fare       CHECK (fare > 0),
    CONSTRAINT chk_schedules_time_order CHECK (arrival_time > departure_time),

    INDEX idx_schedules_bus         (bus_id),
    INDEX idx_schedules_place       (place_id),
    INDEX idx_schedules_departure   (departure_time),
    INDEX idx_schedules_active      (is_active)
);

-- ============================================================
-- TABLE 7: hotels
-- ============================================================
CREATE TABLE hotels (
    hotel_id    INT             AUTO_INCREMENT PRIMARY KEY,
    place_id    INT             NOT NULL,
    hotel_name  VARCHAR(150)    NOT NULL,
    address     TEXT,
    rating      DECIMAL(2,1)    DEFAULT 0.0,
    image_path  VARCHAR(255),
    is_active   TINYINT(1)      NOT NULL DEFAULT 1,

    CONSTRAINT fk_hotels_place
        FOREIGN KEY (place_id) REFERENCES places(place_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_hotels_rating CHECK (rating BETWEEN 0.0 AND 5.0),

    INDEX idx_hotels_place   (place_id),
    INDEX idx_hotels_rating  (rating),
    INDEX idx_hotels_active  (is_active)
);

-- ============================================================
-- TABLE 8: room_types
-- ============================================================
CREATE TABLE room_types (
    room_type_id     INT             AUTO_INCREMENT PRIMARY KEY,
    hotel_id         INT             NOT NULL,
    room_name        VARCHAR(100)    NOT NULL,
    room_price       DECIMAL(10,2)   NOT NULL,
    room_capacity    INT             NOT NULL DEFAULT 2,
    available_rooms  INT             NOT NULL DEFAULT 0,
    amenities        TEXT,

    CONSTRAINT fk_room_types_hotel
        FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_room_price    CHECK (room_price > 0),
    CONSTRAINT chk_room_capacity CHECK (room_capacity > 0),
    CONSTRAINT chk_room_avail    CHECK (available_rooms >= 0),

    INDEX idx_room_types_hotel (hotel_id),
    INDEX idx_room_types_price (room_price)
);

-- ============================================================
-- TABLE 9: bookings  (master booking record)
-- ============================================================
CREATE TABLE bookings (
    booking_id      INT              AUTO_INCREMENT PRIMARY KEY,
    user_id         INT              NOT NULL,
    booking_date    TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,
    total_amount    DECIMAL(12,2)    NOT NULL DEFAULT 0.00,
    booking_status  VARCHAR(30)      NOT NULL DEFAULT 'pending',
    notes           TEXT,

    CONSTRAINT fk_bookings_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_bookings_status CHECK (
        booking_status IN ('pending','confirmed','cancelled','completed')
    ),
    CONSTRAINT chk_bookings_amount CHECK (total_amount >= 0),

    INDEX idx_bookings_user    (user_id),
    INDEX idx_bookings_status  (booking_status),
    INDEX idx_bookings_date    (booking_date)
);

-- ============================================================
-- TABLE 10: booking_bus
-- ============================================================
CREATE TABLE booking_bus (
    id           INT             AUTO_INCREMENT PRIMARY KEY,
    booking_id   INT             NOT NULL,
    schedule_id  INT             NOT NULL,
    seat_quantity INT            NOT NULL DEFAULT 1,
    fare         DECIMAL(10,2)   NOT NULL,

    CONSTRAINT fk_booking_bus_booking
        FOREIGN KEY (booking_id)  REFERENCES bookings(booking_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_booking_bus_schedule
        FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_bb_seats CHECK (seat_quantity > 0),
    CONSTRAINT chk_bb_fare  CHECK (fare > 0),

    UNIQUE INDEX uq_booking_bus (booking_id, schedule_id),
    INDEX idx_booking_bus_schedule (schedule_id)
);

-- ============================================================
-- TABLE 11: booking_hotel
-- ============================================================
CREATE TABLE booking_hotel (
    id             INT             AUTO_INCREMENT PRIMARY KEY,
    booking_id     INT             NOT NULL,
    room_type_id   INT             NOT NULL,
    checkin_date   DATE            NOT NULL,
    checkout_date  DATE            NOT NULL,
    nights         INT             NOT NULL,
    room_cost      DECIMAL(10,2)   NOT NULL,

    CONSTRAINT fk_booking_hotel_booking
        FOREIGN KEY (booking_id)   REFERENCES bookings(booking_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_booking_hotel_room
        FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_bh_dates  CHECK (checkout_date > checkin_date),
    CONSTRAINT chk_bh_nights CHECK (nights > 0),
    CONSTRAINT chk_bh_cost   CHECK (room_cost > 0),

    UNIQUE INDEX uq_booking_hotel (booking_id, room_type_id, checkin_date),
    INDEX idx_booking_hotel_room (room_type_id)
);

-- ============================================================
-- TABLE 12: payments
-- ============================================================
CREATE TABLE payments (
    payment_id      INT              AUTO_INCREMENT PRIMARY KEY,
    booking_id      INT              NOT NULL,
    amount          DECIMAL(12,2)    NOT NULL,
    payment_method  VARCHAR(50)      NOT NULL,
    payment_status  VARCHAR(30)      NOT NULL DEFAULT 'pending',
    payment_date    TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,
    transaction_ref VARCHAR(100),

    CONSTRAINT fk_payments_booking
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_payments_amount  CHECK (amount > 0),
    CONSTRAINT chk_payments_method  CHECK (
        payment_method IN ('bkash','nagad','rocket','card','bank_transfer','cash')
    ),
    CONSTRAINT chk_payments_status  CHECK (
        payment_status IN ('pending','completed','failed','refunded')
    ),

    INDEX idx_payments_booking (booking_id),
    INDEX idx_payments_status  (payment_status),
    INDEX idx_payments_method  (payment_method)
);

-- ============================================================
-- TABLE 13: reviews
-- ============================================================
CREATE TABLE reviews (
    review_id    INT          AUTO_INCREMENT PRIMARY KEY,
    user_id      INT          NOT NULL,
    place_id     INT          NOT NULL,
    rating       INT          NOT NULL,
    review_text  TEXT,
    review_date  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reviews_user
        FOREIGN KEY (user_id)  REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_reviews_place
        FOREIGN KEY (place_id) REFERENCES places(place_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT uq_reviews_user_place UNIQUE (user_id, place_id),

    INDEX idx_reviews_place  (place_id),
    INDEX idx_reviews_rating (rating)
);

-- ============================================================
-- TABLE 14: wishlist
-- ============================================================
CREATE TABLE wishlist (
    wishlist_id  INT        AUTO_INCREMENT PRIMARY KEY,
    user_id      INT        NOT NULL,
    place_id     INT        NOT NULL,
    added_at     TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_wishlist_user
        FOREIGN KEY (user_id)  REFERENCES users(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_wishlist_place
        FOREIGN KEY (place_id) REFERENCES places(place_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_wishlist_user_place UNIQUE (user_id, place_id),

    INDEX idx_wishlist_user  (user_id),
    INDEX idx_wishlist_place (place_id)
);

-- ============================================================
-- TABLE 15: booking_logs  (audit trail + trigger demo)
-- ============================================================
CREATE TABLE booking_logs (
    log_id       INT          AUTO_INCREMENT PRIMARY KEY,
    booking_id   INT,
    action_type  VARCHAR(50)  NOT NULL,
    old_status   VARCHAR(30),
    new_status   VARCHAR(30),
    performed_by VARCHAR(100),
    action_time  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    remarks      TEXT,

    INDEX idx_booking_logs_booking (booking_id),
    INDEX idx_booking_logs_action  (action_type),
    INDEX idx_booking_logs_time    (action_time)
);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- End of 01_schema.sql
-- ============================================================

-- ============================================================
--  OneReserve — Bangladesh Tourism Reservation System
--  File: 02_seed_core.sql
--  Description: Districts · Places · Bus Companies · Buses · Schedules
-- ============================================================

USE onereserve;

-- ============================================================
-- DISTRICTS  (all 15 required for the 20 places)
-- ============================================================
INSERT INTO districts (district_name) VALUES
("Cox's Bazar"),    -- 1
('Patuakhali'),     -- 2
('Chattogram'),     -- 3
('Noakhali'),       -- 4
('Moulvibazar'),    -- 5
('Sylhet'),         -- 6
('Sunamganj'),      -- 7
('Bandarban'),      -- 8
('Rangamati'),      -- 9
('Khagrachari'),    -- 10
('Khulna'),         -- 11
('Bagerhat'),       -- 12
('Naogaon'),        -- 13
('Bogura'),         -- 14
('Rajshahi');       -- 15

-- ============================================================
-- PLACES  (20 tourist destinations)
-- ============================================================
INSERT INTO places
    (district_id, place_name, description, image_path,
     latitude, longitude, google_map_url, category, is_featured)
VALUES
-- ── Coastal Escapes & Islands ──────────────────────────────
(1,  "Cox's Bazar",
     'Longest natural unbroken sea beach in the world, stretching 120 km along the Bay of Bengal.',
     'assets/places/coxs_bazar.jpg',    21.42720,  92.00580,
     'https://goo.gl/maps/coxsbazar',  'Coastal', 1),

(1,  "Saint Martin's Island",
     "Bangladesh's only coral island featuring crystal-clear blue waters and the secluded Chera Dwip peninsula.",
     'assets/places/saint_martin.jpg', 20.62720,  92.32280,
     'https://goo.gl/maps/saintmartin','Coastal', 1),

(2,  'Kuakata',
     'Known as Sagar Kannya (Daughter of the Sea) — the only beach in Bangladesh where you can witness both sunrise and sunset.',
     'assets/places/kuakata.jpg',       21.81670,  90.11670,
     'https://goo.gl/maps/kuakata',    'Coastal', 1),

(3,  'Patenga Beach',
     'A popular, bustling beach near Chattogram port city, ideal for sunset views and waterfront street food.',
     'assets/places/patenga.jpg',       22.23450,  91.79460,
     'https://goo.gl/maps/patenga',    'Coastal', 0),

(3,  'Guliakhali Beach',
     'Located in Sitakunda, this hidden gem is famous for its unique landscape of emerald grass meeting tidal canals.',
     'assets/places/guliakhali.jpg',    22.62890,  91.56450,
     'https://goo.gl/maps/guliakhali', 'Coastal', 0),

(4,  'Nijhum Dwip',
     'A tranquil island in the Bay of Bengal famous for dense mangrove forest and one of the largest herds of spotted deer in Bangladesh.',
     'assets/places/nijhum_dwip.jpg',   22.06280,  91.00280,
     'https://goo.gl/maps/nijhumdwip', 'Island',  0),

-- ── Lush Northeast — Sylhet Division ──────────────────────
(5,  'Srimangal',
     'The Tea Capital of Bangladesh — home to vast emerald tea estates, seven-layer tea, and the wildlife-rich Lawachara National Park.',
     'assets/places/srimangal.jpg',     24.30650,  91.72950,
     'https://goo.gl/maps/srimangal',  'Nature',  1),

(6,  'Jaflong',
     'A scenic gem at the foothills of the Khasi and Jaintia hills where crystal rivers carry giant boulders down from Meghalaya.',
     'assets/places/jaflong.jpg',       25.16340,  92.01930,
     'https://goo.gl/maps/jaflong',    'Nature',  0),

(6,  'Ratargul Swamp Forest',
     "Bangladesh's only freshwater swamp forest — a mystical flooded jungle navigable only by narrow wooden boats.",
     'assets/places/ratargul.jpg',      25.00040,  91.86870,
     'https://goo.gl/maps/ratargul',   'Nature',  1),

(7,  'Tanguar Haor',
     'A RAMSAR-designated vast wetland in Sunamganj hosting over 200 species of migratory birds and shimmering cloud reflections.',
     'assets/places/tanguar_haor.jpg',  25.09350,  91.07700,
     'https://goo.gl/maps/tanguarhaor','Wetland', 1),

(5,  'Madhabkunda Waterfall',
     'One of the largest cascading waterfalls in Bangladesh, set amid betel leaf plantations and rubber forest.',
     'assets/places/madhabkunda.jpg',   24.63670,  92.22410,
     'https://goo.gl/maps/madhabkunda','Nature',  0),

-- ── Hill Tracts ────────────────────────────────────────────
(8,  'Bandarban',
     'Bangladesh''s most dramatic hill district — home to Boga Lake, Saka Haphong (highest peak), Nilgiri, and rich indigenous culture.',
     'assets/places/bandarban.jpg',     22.19530,  92.21840,
     'https://goo.gl/maps/bandarban',  'Hills',   1),

(9,  'Rangamati',
     'The jewel of the Chittagong Hill Tracts, famous for the expansive Kaptai Lake, iconic hanging bridge, and tribal craft markets.',
     'assets/places/rangamati.jpg',     22.65330,  92.15250,
     'https://goo.gl/maps/rangamati',  'Hills',   1),

(10, 'Khagrachari',
     'A stunning hilly district known for the mysterious Alutila Cave, the Risang Khong hanging bridge, and scenic tribal villages.',
     'assets/places/khagrachari.jpg',   23.11050,  91.99610,
     'https://goo.gl/maps/khagrachari','Hills',   0),

-- ── History & Archaeology ──────────────────────────────────
(11, 'Sundarbans',
     'A UNESCO World Heritage Site and the largest mangrove forest in the world — last stronghold of the Royal Bengal Tiger.',
     'assets/places/sundarbans.jpg',    21.94970,  89.18330,
     'https://goo.gl/maps/sundarbans', 'Heritage',1),

(12, 'Bagerhat',
     'A UNESCO World Heritage City showcasing exquisite 15th-century Islamic architecture, headlined by the iconic Sixty Dome Mosque.',
     'assets/places/bagerhat.jpg',      22.65650,  89.78910,
     'https://goo.gl/maps/bagerhat',   'Heritage',1),

(13, 'Paharpur',
     'Home to Somapura Mahavihara — a UNESCO World Heritage site and one of the greatest ancient Buddhist monasteries in South Asia.',
     'assets/places/paharpur.jpg',      25.03050,  88.97740,
     'https://goo.gl/maps/paharpur',   'Heritage',0),

(14, 'Mahasthangarh',
     'Located in Bogura, this is the earliest known archaeological site in Bangladesh, with continuous occupation from the 3rd century BC.',
     'assets/places/mahasthangarh.jpg', 24.96200,  89.34560,
     'https://goo.gl/maps/mahasthangarh','Heritage',0),

(15, 'Puthia Temple Complex',
     'Rajshahi district houses the largest concentration of historically significant Hindu temples in Bangladesh in a single campus.',
     'assets/places/puthia.jpg',        24.36420,  88.83540,
     'https://goo.gl/maps/puthia',     'Heritage',0),

(15, 'Varendra Research Museum',
     'The oldest museum in Bangladesh, in Rajshahi, housing thousands of ancient sculptures, terracotta plaques, coins, and inscriptions.',
     'assets/places/varendra.jpg',      24.36670,  88.59960,
     'https://goo.gl/maps/varendra',   'Heritage',0);

-- ============================================================
-- BUS COMPANIES  (6)
-- ============================================================
INSERT INTO bus_companies (company_name, contact_no, logo_path) VALUES
('Green Line',            '01711122233', 'assets/logos/green_line.png'),
('Hanif Enterprise',      '01713046025', 'assets/logos/hanif.png'),
('Shyamoli Paribahan',    '01711428612', 'assets/logos/shyamoli.png'),
('Ena Transport',         '01711536974', 'assets/logos/ena.png'),
('Sohag Paribahan',       '01711645321', 'assets/logos/sohag.png'),
('Saintmartin Paribahan', '01711987654', 'assets/logos/saintmartin.png');

-- ============================================================
-- BUSES  (30 buses — 5 per company)
-- ============================================================
INSERT INTO buses (company_id, bus_name, bus_type, seat_capacity, available_seats) VALUES
-- Green Line (1)
(1,'Green Line Scania Multi-Axle',  'AC Business Class', 36, 36),
(1,'Green Line Volvo B11R',         'AC Premium',        36, 36),
(1,'Green Line Sleeper Coach',      'AC Sleeper',        30, 30),
(1,'Green Line Hino RM2',           'AC Economy',        40, 40),
(1,'Green Line Hyundai Universe',   'AC Business Class', 36, 36),
-- Hanif (2)
(2,'Hanif Hino AK1J-01',            'Non-AC',            40, 40),
(2,'Hanif Hino AK1J-02',            'Non-AC',            40, 40),
(2,'Hanif Volvo B9R',               'AC Deluxe',         36, 36),
(2,'Hanif Scania Touring',          'AC Business',       36, 36),
(2,'Hanif Hino AK1J-03',            'Non-AC',            40, 40),
-- Shyamoli (3)
(3,'Shyamoli Hino AK1J',            'Non-AC',            40, 40),
(3,'Shyamoli Hyundai Universe',     'AC Premium',        36, 36),
(3,'Shyamoli Scania K360',          'AC Business Class', 36, 36),
(3,'Shyamoli Hino AK1J-S2',         'Non-AC',            40, 40),
(3,'Shyamoli Volvo B11R',           'AC Deluxe',         36, 36),
-- Ena (4)
(4,'Ena Hino AK1J-E1',              'Non-AC',            40, 40),
(4,'Ena Hino AK1J-E2',              'Non-AC',            40, 40),
(4,'Ena Hyundai Universe-E1',       'AC Deluxe',         36, 36),
(4,'Ena Hyundai Universe-E2',       'AC Deluxe',         36, 36),
(4,'Ena Hino AK1J-E3',              'Non-AC',            40, 40),
-- Sohag (5)
(5,'Sohag Scania Multi-Axle',       'AC Business Class', 36, 36),
(5,'Sohag Volvo B11R',              'AC Premium',        36, 36),
(5,'Sohag Sleeper Coach',           'AC Sleeper',        30, 30),
(5,'Sohag Hino AK1J',               'Non-AC',            40, 40),
(5,'Sohag Scania Touring',          'AC Business Class', 36, 36),
-- Saintmartin Paribahan (6)
(6,'Saintmartin Hino RM2',          'AC Deluxe',         40, 40),
(6,'Saintmartin Hyundai Universe',  'AC Premium',        36, 36),
(6,'Saintmartin Sleeper Coach',     'AC Sleeper',        30, 30),
(6,'Saintmartin Hino AK1J',         'Non-AC',            40, 40),
(6,'Saintmartin Scania K360',       'AC Business Class', 36, 36);

-- ============================================================
-- SCHEDULES  (100 rows, Dhaka departures June 10–29 2026)
-- ============================================================
INSERT INTO schedules (bus_id, place_id, departure_city, departure_time, arrival_time, fare) VALUES
-- Chunk 1 (1–25)
(1,  1,  'Dhaka','2026-06-10 06:00:00','2026-06-10 16:00:00',1980.00),
(2,  2,  'Dhaka','2026-06-10 10:00:00','2026-06-10 22:00:00',2280.00),
(3,  3,  'Dhaka','2026-06-10 14:00:00','2026-06-10 22:00:00',1800.00),
(4,  4,  'Dhaka','2026-06-10 18:00:00','2026-06-11 00:00:00',1240.00),
(5,  5,  'Dhaka','2026-06-10 06:00:00','2026-06-10 12:00:00',1180.00),
(6,  6,  'Dhaka','2026-06-11 10:00:00','2026-06-11 19:00:00', 800.00),
(7,  7,  'Dhaka','2026-06-11 14:00:00','2026-06-11 19:00:00', 500.00),
(8,  8,  'Dhaka','2026-06-11 18:00:00','2026-06-12 00:00:00',1080.00),
(9,  9,  'Dhaka','2026-06-11 06:00:00','2026-06-11 12:00:00',1080.00),
(10, 10, 'Dhaka','2026-06-11 10:00:00','2026-06-11 17:00:00', 650.00),
(11, 11, 'Dhaka','2026-06-12 14:00:00','2026-06-12 20:00:00', 600.00),
(12, 12, 'Dhaka','2026-06-12 18:00:00','2026-06-13 02:00:00',1400.00),
(13, 13, 'Dhaka','2026-06-12 06:00:00','2026-06-12 14:00:00',1340.00),
(14, 14, 'Dhaka','2026-06-12 10:00:00','2026-06-12 17:00:00', 750.00),
(15, 15, 'Dhaka','2026-06-12 14:00:00','2026-06-12 21:00:00',1180.00),
(16, 16, 'Dhaka','2026-06-13 18:00:00','2026-06-14 00:00:00', 650.00),
(17, 17, 'Dhaka','2026-06-13 06:00:00','2026-06-13 12:00:00', 600.00),
(18, 18, 'Dhaka','2026-06-13 10:00:00','2026-06-13 15:00:00', 940.00),
(19, 19, 'Dhaka','2026-06-13 14:00:00','2026-06-13 19:00:00',1020.00),
(20, 20, 'Dhaka','2026-06-13 18:00:00','2026-06-13 23:00:00', 600.00),
(21, 1,  'Dhaka','2026-06-14 06:00:00','2026-06-14 16:00:00',1980.00),
(22, 2,  'Dhaka','2026-06-14 10:00:00','2026-06-14 22:00:00',2280.00),
(23, 3,  'Dhaka','2026-06-14 14:00:00','2026-06-14 22:00:00',1800.00),
(24, 4,  'Dhaka','2026-06-14 18:00:00','2026-06-15 00:00:00', 700.00),
(25, 5,  'Dhaka','2026-06-14 06:00:00','2026-06-14 12:00:00',1180.00),
-- Chunk 2 (26–50)
(26, 6,  'Dhaka','2026-06-15 10:00:00','2026-06-15 19:00:00',1280.00),
(27, 7,  'Dhaka','2026-06-15 14:00:00','2026-06-15 19:00:00', 920.00),
(28, 8,  'Dhaka','2026-06-15 18:00:00','2026-06-16 00:00:00',1400.00),
(29, 9,  'Dhaka','2026-06-15 06:00:00','2026-06-15 12:00:00', 600.00),
(30, 10, 'Dhaka','2026-06-15 10:00:00','2026-06-15 17:00:00',1160.00),
(1,  11, 'Dhaka','2026-06-16 14:00:00','2026-06-16 20:00:00',1080.00),
(2,  12, 'Dhaka','2026-06-16 18:00:00','2026-06-17 02:00:00',1400.00),
(3,  13, 'Dhaka','2026-06-16 06:00:00','2026-06-16 14:00:00',1700.00),
(4,  14, 'Dhaka','2026-06-16 10:00:00','2026-06-16 17:00:00',1260.00),
(5,  15, 'Dhaka','2026-06-16 14:00:00','2026-06-16 21:00:00',1180.00),
(6,  16, 'Dhaka','2026-06-17 18:00:00','2026-06-18 00:00:00', 650.00),
(7,  17, 'Dhaka','2026-06-17 06:00:00','2026-06-17 12:00:00', 600.00),
(8,  18, 'Dhaka','2026-06-17 10:00:00','2026-06-17 15:00:00', 940.00),
(9,  19, 'Dhaka','2026-06-17 14:00:00','2026-06-17 19:00:00',1020.00),
(10, 20, 'Dhaka','2026-06-17 18:00:00','2026-06-17 23:00:00', 600.00),
(11, 1,  'Dhaka','2026-06-18 06:00:00','2026-06-18 16:00:00',1200.00),
(12, 2,  'Dhaka','2026-06-18 10:00:00','2026-06-18 22:00:00',2280.00),
(13, 3,  'Dhaka','2026-06-18 14:00:00','2026-06-18 22:00:00',1400.00),
(14, 4,  'Dhaka','2026-06-18 18:00:00','2026-06-19 00:00:00', 700.00),
(15, 5,  'Dhaka','2026-06-18 06:00:00','2026-06-18 12:00:00',1180.00),
(16, 6,  'Dhaka','2026-06-19 10:00:00','2026-06-19 19:00:00', 800.00),
(17, 7,  'Dhaka','2026-06-19 14:00:00','2026-06-19 19:00:00', 500.00),
(18, 8,  'Dhaka','2026-06-19 18:00:00','2026-06-20 00:00:00',1080.00),
(19, 9,  'Dhaka','2026-06-19 06:00:00','2026-06-19 12:00:00',1080.00),
(20, 10, 'Dhaka','2026-06-19 10:00:00','2026-06-19 17:00:00', 650.00),
-- Chunk 3 (51–75)
(21, 11, 'Dhaka','2026-06-20 14:00:00','2026-06-20 20:00:00',1080.00),
(22, 12, 'Dhaka','2026-06-20 18:00:00','2026-06-21 02:00:00',1400.00),
(23, 13, 'Dhaka','2026-06-20 06:00:00','2026-06-20 14:00:00',1700.00),
(24, 14, 'Dhaka','2026-06-20 10:00:00','2026-06-20 17:00:00', 750.00),
(25, 15, 'Dhaka','2026-06-20 14:00:00','2026-06-20 21:00:00',1180.00),
(26, 16, 'Dhaka','2026-06-21 18:00:00','2026-06-22 00:00:00',1100.00),
(27, 17, 'Dhaka','2026-06-21 06:00:00','2026-06-21 12:00:00',1020.00),
(28, 18, 'Dhaka','2026-06-21 10:00:00','2026-06-21 15:00:00',1200.00),
(29, 19, 'Dhaka','2026-06-21 14:00:00','2026-06-21 19:00:00', 600.00),
(30, 20, 'Dhaka','2026-06-21 18:00:00','2026-06-21 23:00:00',1020.00),
(1,  1,  'Dhaka','2026-06-22 06:00:00','2026-06-22 16:00:00',1980.00),
(2,  2,  'Dhaka','2026-06-22 10:00:00','2026-06-22 22:00:00',2280.00),
(3,  3,  'Dhaka','2026-06-22 14:00:00','2026-06-22 22:00:00',1800.00),
(4,  4,  'Dhaka','2026-06-22 18:00:00','2026-06-23 00:00:00',1240.00),
(5,  5,  'Dhaka','2026-06-22 06:00:00','2026-06-22 12:00:00',1180.00),
(6,  6,  'Dhaka','2026-06-23 10:00:00','2026-06-23 19:00:00', 800.00),
(7,  7,  'Dhaka','2026-06-23 14:00:00','2026-06-23 19:00:00', 500.00),
(8,  8,  'Dhaka','2026-06-23 18:00:00','2026-06-24 00:00:00',1080.00),
(9,  9,  'Dhaka','2026-06-23 06:00:00','2026-06-23 12:00:00',1080.00),
(10, 10, 'Dhaka','2026-06-23 10:00:00','2026-06-23 17:00:00', 650.00),
(11, 11, 'Dhaka','2026-06-24 14:00:00','2026-06-24 20:00:00', 600.00),
(12, 12, 'Dhaka','2026-06-24 18:00:00','2026-06-25 02:00:00',1400.00),
(13, 13, 'Dhaka','2026-06-24 06:00:00','2026-06-24 14:00:00',1340.00),
(14, 14, 'Dhaka','2026-06-24 10:00:00','2026-06-24 17:00:00', 750.00),
(15, 15, 'Dhaka','2026-06-24 14:00:00','2026-06-24 21:00:00',1180.00),
-- Chunk 4 (76–100)
(16, 16, 'Dhaka','2026-06-25 18:00:00','2026-06-26 00:00:00', 650.00),
(17, 17, 'Dhaka','2026-06-25 06:00:00','2026-06-25 12:00:00', 600.00),
(18, 18, 'Dhaka','2026-06-25 10:00:00','2026-06-25 15:00:00', 940.00),
(19, 19, 'Dhaka','2026-06-25 14:00:00','2026-06-25 19:00:00',1020.00),
(20, 20, 'Dhaka','2026-06-25 18:00:00','2026-06-25 23:00:00', 600.00),
(21, 1,  'Dhaka','2026-06-26 06:00:00','2026-06-26 16:00:00',1980.00),
(22, 2,  'Dhaka','2026-06-26 10:00:00','2026-06-26 22:00:00',2280.00),
(23, 3,  'Dhaka','2026-06-26 14:00:00','2026-06-26 22:00:00',1800.00),
(24, 4,  'Dhaka','2026-06-26 18:00:00','2026-06-27 00:00:00', 700.00),
(25, 5,  'Dhaka','2026-06-26 06:00:00','2026-06-26 12:00:00',1180.00),
(26, 6,  'Dhaka','2026-06-27 10:00:00','2026-06-27 19:00:00',1280.00),
(27, 7,  'Dhaka','2026-06-27 14:00:00','2026-06-27 19:00:00', 920.00),
(28, 8,  'Dhaka','2026-06-27 18:00:00','2026-06-28 00:00:00',1400.00),
(29, 9,  'Dhaka','2026-06-27 06:00:00','2026-06-27 12:00:00', 600.00),
(30, 10, 'Dhaka','2026-06-27 10:00:00','2026-06-27 17:00:00',1160.00),
(1,  11, 'Dhaka','2026-06-28 14:00:00','2026-06-28 20:00:00',1080.00),
(2,  12, 'Dhaka','2026-06-28 18:00:00','2026-06-29 02:00:00',1400.00),
(3,  13, 'Dhaka','2026-06-28 06:00:00','2026-06-28 14:00:00',1700.00),
(4,  14, 'Dhaka','2026-06-28 10:00:00','2026-06-28 17:00:00',1260.00),
(5,  15, 'Dhaka','2026-06-28 14:00:00','2026-06-28 21:00:00',1180.00),
(6,  16, 'Dhaka','2026-06-29 18:00:00','2026-06-30 00:00:00', 650.00),
(7,  17, 'Dhaka','2026-06-29 06:00:00','2026-06-29 12:00:00', 600.00),
(8,  18, 'Dhaka','2026-06-29 10:00:00','2026-06-29 15:00:00', 940.00),
(9,  19, 'Dhaka','2026-06-29 14:00:00','2026-06-29 19:00:00',1020.00),
(10, 20, 'Dhaka','2026-06-29 18:00:00','2026-06-29 23:00:00', 600.00);

-- ============================================================
-- End of 02_seed_core.sql
-- ============================================================

-- ============================================================
--  OneReserve — Bangladesh Tourism Reservation System
--  File: 03_seed_hotels.sql
--  Description: Hotels (60 rows) + Room Types (180 rows — 3 per hotel)
-- ============================================================

USE onereserve;

-- ============================================================
-- HOTELS  (60 rows — 3 per place)
-- ============================================================

-- Places 1–7 (21 hotels)
INSERT INTO hotels (place_id, hotel_name, address, rating, image_path) VALUES
(1,'Sayeman Beach Resort',          'Marine Drive, Kolatoli, Cox''s Bazar',               4.7,'assets/hotels/sayeman.jpg'),
(1,'Ocean Paradise Hotel & Resort', 'VVIP Road, Kolatoli, Cox''s Bazar',                  4.5,'assets/hotels/ocean_paradise.jpg'),
(1,'Seagull Hotels Ltd',            'Sugandha Beach, Cox''s Bazar',                        4.3,'assets/hotels/seagull.jpg'),
(2,'Blue Marine Resort',            'Bazar Road, Saint Martin Island',                     4.2,'assets/hotels/blue_marine.jpg'),
(2,'Fantasy Jetty Resort',          'Jetty Ghat, Saint Martin Island',                     4.0,'assets/hotels/fantasy_jetty.jpg'),
(2,'Labiba Bilas Resort',           'West Beach, Saint Martin Island',                     4.1,'assets/hotels/labiba_bilas.jpg'),
(3,'Hotel Graver Inn International','Kuakata Beach Road, Patuakhali',                      4.4,'assets/hotels/graver_inn.jpg'),
(3,'Sikder Resort & Villas',        'Kuakata Eco Park Road, Patuakhali',                   4.6,'assets/hotels/sikder_resort.jpg'),
(3,'Hotel Khan Jahan Ali',          'Main Beach West Side, Kuakata',                       3.8,'assets/hotels/khan_jahan_kuakata.jpg'),
(4,'Hotel Sea World Patenga',       'Patenga Beach Road, Chattogram',                      3.9,'assets/hotels/sea_world_patenga.jpg'),
(4,'The Peninsula Chattogram',      'GEC Circle, Chattogram',                              4.5,'assets/hotels/peninsula.jpg'),
(4,'Chattogram Boat Club Resort',   'Patenga Road, Chattogram',                            4.2,'assets/hotels/boat_club.jpg'),
(5,'Sitakunda Guest House',         'Main Bazar Road, Sitakunda, Chattogram',              3.7,'assets/hotels/sitakunda_gh.jpg'),
(5,'Hotel Green Eye',               'By-pass Road, Sitakunda',                             3.6,'assets/hotels/green_eye.jpg'),
(5,'Guliakhali Eco Lodge',          'Guliakhali Beach Road, Sitakunda',                    3.9,'assets/hotels/guliakhali_eco.jpg'),
(6,'Nijhum Resort',                 'Forest Department Area, Nijhum Dwip',                 4.0,'assets/hotels/nijhum_resort.jpg'),
(6,'Hotel Island View',             'Bandartila Ghat, Nijhum Dwip',                        3.7,'assets/hotels/island_view.jpg'),
(6,'Sea Beach Eco Cottage',         'Namajpur Beach Road, Nijhum Dwip',                    3.8,'assets/hotels/nijhum_cottage.jpg'),
(7,'Grand Sultan Tea Resort & Golf','Radhanagar, Srimangal, Moulvibazar',                  4.9,'assets/hotels/grand_sultan.jpg'),
(7,'Lemon Garden Resort',           'Lawachara National Park Road, Srimangal',             4.4,'assets/hotels/lemon_garden.jpg'),
(7,'Balishira Resort',              'Radhanagar, Srimangal',                               4.5,'assets/hotels/balishira.jpg');

-- Places 8–14 (21 hotels)
INSERT INTO hotels (place_id, hotel_name, address, rating, image_path) VALUES
(8,'Jaflong Inn',                   'Tamabil Road, Jaflong, Sylhet',                       3.9,'assets/hotels/jaflong_inn.jpg'),
(8,'Green Valley Resort',           'Mama Dekho Mukh, Jaflong',                            4.1,'assets/hotels/green_valley.jpg'),
(8,'River View Guest House',        'Ghat Road, Jaflong',                                  3.7,'assets/hotels/river_view.jpg'),
(9,'Ratargul Eco Resort',           'Gowainghat, Near Swamp Forest, Sylhet',               4.2,'assets/hotels/ratargul_eco.jpg'),
(9,'Swamp View Cabins',             'Motor Ghat, Ratargul',                                4.0,'assets/hotels/swamp_view.jpg'),
(9,'Forest Lodge Sylhet',           'Khadimnagar (Near Ratargul Route)',                   4.1,'assets/hotels/forest_lodge.jpg'),
(10,'Haor Houseboat Premium',       'Tahirpur Ghat, Sunamganj',                            4.6,'assets/hotels/houseboat.jpg'),
(10,'Sunamganj Luxury Inn',         'Sadar Road, Sunamganj',                               3.9,'assets/hotels/sunamganj_inn.jpg'),
(10,'Tanguar Eco Camp',             'Tahandpur, Sunamganj',                                4.3,'assets/hotels/tanguar_camp.jpg'),
(11,'Madhabkunda Rest House',       'Parjatan Area, Barlekha, Moulvibazar',                3.8,'assets/hotels/madhabkunda_rh.jpg'),
(11,'Juri Valley Eco Lodge',        'Juri Road, Moulvibazar',                              4.0,'assets/hotels/juri_valley.jpg'),
(11,'Eco Falls Resort',             'Waterfall Road, Barlekha',                            3.9,'assets/hotels/eco_falls.jpg'),
(12,'Sairu Hill Resort',            'Chimbuk Road, Bandarban',                             4.8,'assets/hotels/sairu.jpg'),
(12,'Hotel Plaza Bandarban',        'Sadar Road, Bandarban',                               4.1,'assets/hotels/hotel_plaza.jpg'),
(12,'Green Peak Resort',            'Recha, Cantonment Road, Bandarban',                   4.4,'assets/hotels/green_peak.jpg'),
(13,'Hotel Sufia International',    'Kathaltoli, Rangamati',                               4.0,'assets/hotels/hotel_sufia.jpg'),
(13,'Parjatan Motel Rangamati',     'Hanging Bridge Road, Rangamati',                      4.2,'assets/hotels/parjatan_rangamati.jpg'),
(13,'Lake View Island Resort',      'Kaptai Lake, Rangamati',                              4.5,'assets/hotels/lake_view.jpg'),
(14,'Parjatan Motel Khagrachari',   'Chengi Square, Khagrachari',                          4.1,'assets/hotels/parjatan_khagrachari.jpg'),
(14,'Hotel Mount Diamond',          'Mahajan Para, Khagrachari',                           3.8,'assets/hotels/mount_diamond.jpg'),
(14,'Heritage Eco Resort',          'Alutila Road, Khagrachari',                           4.3,'assets/hotels/heritage_khagrachari.jpg');

-- Places 15–20 (18 hotels)
INSERT INTO hotels (place_id, hotel_name, address, rating, image_path) VALUES
(15,'Sundarban Tiger Roar Resort',  'Datta River Side, Shyamnagar, Satkhira',              4.4,'assets/hotels/tiger_roar.jpg'),
(15,'Pashur Parjatan Hotel',        'Mongla Port, Bagerhat (Sundarban Entry)',              4.0,'assets/hotels/pashur_mongla.jpg'),
(15,'Sundarban Eco Cottage',        'Karamjal Route, Khulna',                              4.2,'assets/hotels/sundarban_cottage.jpg'),
(16,'Hotel Shat Gombuj',            'Shat Gombuj Mosque Road, Bagerhat',                   3.9,'assets/hotels/shat_gombuj_hotel.jpg'),
(16,'Bagerhat Castle',              'Sadar Bypass Road, Bagerhat',                         4.0,'assets/hotels/bagerhat_castle.jpg'),
(16,'Khan Jahan Ali Guest House',   'Dargah Road, Bagerhat',                               3.7,'assets/hotels/khan_jahan_gh.jpg'),
(17,'Paharpur Archaeology Rest',    'Somapura Mahavihara Complex, Naogaon',                3.9,'assets/hotels/paharpur_rest.jpg'),
(17,'Hotel Naogaon Inn',            'Main Road, Naogaon Sadar',                            3.6,'assets/hotels/naogaon_inn.jpg'),
(17,'Vihara Lodge & Restaurant',    'Paharpur Bazar, Naogaon',                             3.8,'assets/hotels/vihara_lodge.jpg'),
(18,'Momo Inn Bogura',              'Nawwabganj Road, Bogura',                             4.7,'assets/hotels/momo_inn.jpg'),
(18,'Hotel Naz Garden',             'Silimpur, Bogura',                                    4.3,'assets/hotels/naz_garden.jpg'),
(18,'Bogura Parjatan Motel',        'Banani Mor, Bogura',                                  4.1,'assets/hotels/parjatan_bogura.jpg'),
(19,'Rajshahi Parjatan Motel',      'Abdul Hamid Road, Rajshahi',                          4.2,'assets/hotels/parjatan_rajshahi.jpg'),
(19,'Hotel Nice International',     'Ganakpara, Rajshahi',                                 3.9,'assets/hotels/hotel_nice.jpg'),
(19,'Puthia Royal Palace Hotel',    'Temple Road, Puthia, Rajshahi',                       3.7,'assets/hotels/puthia_royal.jpg'),
(20,'Hotel Grand River View',       'Lalon Shah River Road, Rajshahi',                     4.6,'assets/hotels/grand_river.jpg'),
(20,'Hotel Mukta International',    'Sheader Mor, Rajshahi',                               4.0,'assets/hotels/mukta_intl.jpg'),
(20,'Varendra Heritage Inn',        'Museum Road, Rajshahi',                               4.1,'assets/hotels/varendra_inn.jpg');

-- ============================================================
-- ROOM TYPES  (180 rows — 3 room types per hotel, 60 hotels)
-- Standard / Deluxe / Suite pricing calibrated to hotel rating
-- ============================================================

-- Helper: each INSERT block handles 10 hotels (30 rooms)

-- Hotels 1–10
INSERT INTO room_types (hotel_id, room_name, room_price, room_capacity, available_rooms, amenities) VALUES
(1,'Standard Sea View',    3500.00,2,8, 'Sea view, AC, WiFi, TV'),
(1,'Deluxe Pool Facing',   5500.00,2,5, 'Pool view, AC, WiFi, Mini-bar, TV'),
(1,'Premier Suite',        9500.00,3,3, 'Panoramic sea view, AC, Jacuzzi, WiFi, Mini-bar, Balcony'),
(2,'Standard Room',        3200.00,2,10,'AC, WiFi, TV, Room service'),
(2,'Deluxe Ocean View',    5200.00,2,6, 'Ocean view, AC, WiFi, TV, Mini-bar'),
(2,'Executive Suite',      8800.00,4,3, 'Suite, AC, WiFi, Bathtub, Balcony, Mini-bar'),
(3,'Standard Room',        2200.00,2,12,'AC, WiFi, TV'),
(3,'Superior Room',        3400.00,2,7, 'Garden view, AC, WiFi, TV'),
(3,'Deluxe Suite',         5800.00,3,3, 'Sea view, AC, WiFi, Sitting area, Mini-bar'),
(4,'Beach Cabin',          2800.00,2,6, 'Beach access, Fan, Solar power'),
(4,'Deluxe Cabin',         4200.00,2,4, 'Beach access, AC, Solar power, WiFi'),
(4,'Coral Suite',          7000.00,3,2, 'AC, WiFi, Balcony, Sea view, Generator backup'),
(5,'Standard Cottage',     2000.00,2,5, 'Fan, Solar power, Beach proximity'),
(5,'Deluxe Cottage',       3200.00,2,4, 'AC, WiFi, Solar power'),
(5,'Premium Cottage',      5000.00,3,2, 'AC, WiFi, Balcony, Sea view'),
(6,'Standard Cabin',       2400.00,2,4, 'Beach view, Fan, Solar power'),
(6,'Deluxe Cabin',         3800.00,2,3, 'AC, Generator backup, WiFi'),
(6,'Island Suite',         6200.00,4,2, 'AC, WiFi, Sunset view, Kitchenette'),
(7,'Standard Room',        1800.00,2,8, 'AC, WiFi, TV, Garden view'),
(7,'Deluxe Room',          2800.00,2,5, 'AC, WiFi, TV, Sea/canal view'),
(7,'Premium Suite',        4800.00,3,2, 'AC, WiFi, Large balcony, Canal view'),
(8,'Standard Room',        1600.00,2,8, 'AC, WiFi, TV'),
(8,'Deluxe Room',          2500.00,2,5, 'AC, WiFi, TV, Garden view'),
(8,'Premier Suite',        4500.00,3,2, 'AC, WiFi, Balcony, Mangrove view'),
(9,'Standard Room',        2800.00,2,10,'AC, WiFi, TV, Breakfast included'),
(9,'Deluxe Beach View',    4200.00,2,6, 'AC, WiFi, TV, Beach view, Breakfast'),
(9,'Honeymoon Suite',      7200.00,2,2, 'AC, WiFi, Balcony, Sea view, Jacuzzi, Breakfast'),
(10,'Standard Room',       2500.00,2,8, 'AC, WiFi, TV, City view'),
(10,'Deluxe Room',         3800.00,2,5, 'AC, WiFi, TV, Sea view'),
(10,'Executive Suite',     6500.00,3,2, 'AC, WiFi, Sitting lounge, Sea view, Bathtub');

-- Hotels 11–20
INSERT INTO room_types (hotel_id, room_name, room_price, room_capacity, available_rooms, amenities) VALUES
(11,'Standard Room',       1800.00,2,10,'AC, WiFi, TV'),
(11,'Deluxe Room',         2800.00,2,6, 'AC, WiFi, TV, Balcony'),
(11,'Family Suite',        4500.00,4,3, 'AC, WiFi, TV, Separate bedroom, Kitchen'),
(12,'Standard Room',       1500.00,2,10,'AC, WiFi, TV'),
(12,'Deluxe Room',         2300.00,2,6, 'AC, WiFi, TV, Garden view'),
(12,'Suite',               3800.00,4,3, 'AC, WiFi, TV, Large room, Sitting area'),
(13,'Standard Room',       1600.00,2,8, 'Fan, WiFi, TV'),
(13,'Deluxe Room',         2400.00,2,5, 'AC, WiFi, TV'),
(13,'Eco Suite',           3800.00,3,2, 'AC, WiFi, Nature view, Balcony'),
(14,'Standard Room',       1400.00,2,8, 'Fan, WiFi, TV'),
(14,'Deluxe Room',         2200.00,2,5, 'AC, WiFi, TV'),
(14,'Eco Cottage',         3500.00,3,3, 'AC, WiFi, Beach access, Private veranda'),
(15,'Standard Room',       1500.00,2,8, 'Fan, WiFi, TV'),
(15,'Deluxe Room',         2300.00,2,5, 'AC, WiFi, TV'),
(15,'Island Cottage',      3600.00,4,3, 'AC, WiFi, Island view, Hammock, Veranda'),
(16,'Standard Room',       1400.00,2,6, 'Fan, WiFi'),
(16,'Deluxe Room',         2100.00,2,4, 'AC, WiFi, TV'),
(16,'Forest View Suite',   3500.00,3,2, 'AC, WiFi, Forest panorama, Balcony'),
(17,'Standard Room',       1200.00,2,8, 'Fan, WiFi'),
(17,'Deluxe Room',         1900.00,2,5, 'AC, WiFi, TV'),
(17,'Tea Garden Suite',    3200.00,4,3, 'AC, WiFi, Tea garden view, Balcony, Mini-bar'),
(18,'Standard Room',       1300.00,2,8, 'AC, WiFi, TV'),
(18,'Deluxe Room',         2000.00,2,5, 'AC, WiFi, TV, Mountain view'),
(18,'Premier Chalet',      3500.00,3,3, 'AC, WiFi, Mountain panorama, Fireplace'),
(19,'Standard Room',       1400.00,2,8, 'Fan, WiFi'),
(19,'Deluxe Room',         2200.00,2,5, 'AC, WiFi, TV'),
(19,'Lake View Suite',     3800.00,4,3, 'AC, WiFi, Kaptai Lake view, Balcony'),
(20,'Standard Room',       1300.00,2,8, 'Fan, WiFi, TV'),
(20,'Deluxe Room',         2000.00,2,5, 'AC, WiFi, TV'),
(20,'Tribal Heritage Suite',3400.00,3,3,'AC, WiFi, Hill view, Ethnic decor, Balcony');

-- Hotels 21–30
INSERT INTO room_types (hotel_id, room_name, room_price, room_capacity, available_rooms, amenities) VALUES
(21,'Standard Room',       1500.00,2,8, 'AC, WiFi, TV'),
(21,'Deluxe Room',         2300.00,2,5, 'AC, WiFi, TV, Hill view'),
(21,'Cave View Suite',     3800.00,3,3, 'AC, WiFi, Alutila hill view, Balcony'),
(22,'Standard Room',       1300.00,2,8, 'Fan, WiFi'),
(22,'Deluxe Room',         2000.00,2,5, 'AC, WiFi, TV'),
(22,'Hill Suite',          3300.00,4,2, 'AC, WiFi, Valley panorama, Balcony'),
(23,'Standard Room',       1400.00,2,8, 'Fan, WiFi, TV'),
(23,'Deluxe Room',         2100.00,2,5, 'AC, WiFi, TV'),
(23,'Eco Heritage Suite',  3500.00,3,3, 'AC, WiFi, Forest view, Tribal motifs'),
(24,'Forest Tent',         2800.00,2,5, 'Fan, Solar power, Jungle proximity'),
(24,'Standard Cottage',    4200.00,2,4, 'AC, WiFi, Forest view, Balcony'),
(24,'Tiger Trail Suite',   7500.00,3,2, 'AC, WiFi, Sundarban view, Binoculars, Guide incl.'),
(25,'Standard Room',       1800.00,2,8, 'AC, WiFi, TV'),
(25,'Deluxe Room',         2800.00,2,5, 'AC, WiFi, TV, River view'),
(25,'Mangrove Suite',      4800.00,3,2, 'AC, WiFi, Sundarban panorama, Balcony'),
(26,'Standard Room',       1600.00,2,8, 'AC, WiFi, TV'),
(26,'Deluxe Room',         2400.00,2,5, 'AC, WiFi, TV, Mangrove view'),
(26,'Heritage Suite',      4000.00,3,2, 'AC, WiFi, Forest view, Kayak access'),
(27,'Standard Room',       1300.00,2,8, 'Fan, WiFi'),
(27,'Deluxe Room',         2000.00,2,5, 'AC, WiFi, TV'),
(27,'Mosque View Suite',   3300.00,3,2, 'AC, WiFi, Sixty Dome view, Heritage tour incl.'),
(28,'Standard Room',       1200.00,2,8, 'Fan, WiFi, TV'),
(28,'Deluxe Room',         1800.00,2,5, 'AC, WiFi, TV'),
(28,'Heritage Suite',      3000.00,4,2, 'AC, WiFi, Garden view, Heritage tour incl.'),
(29,'Standard Room',       1100.00,2,8, 'Fan, WiFi'),
(29,'Deluxe Room',         1700.00,2,5, 'AC, WiFi, TV'),
(29,'Vihara Suite',        2800.00,4,2, 'AC, WiFi, Archaeological site view');

-- Hotels 30–40
INSERT INTO room_types (hotel_id, room_name, room_price, room_capacity, available_rooms, amenities) VALUES
(30,'Standard Room',       1400.00,2,8, 'Fan, WiFi'),
(30,'Deluxe Room',         2100.00,2,5, 'AC, WiFi, TV'),
(30,'Archaeological Suite',3600.00,3,2, 'AC, WiFi, Site view, Museum pass incl.'),
(31,'Standard Room',       1200.00,2,8, 'Fan, WiFi'),
(31,'Deluxe Room',         1800.00,2,5, 'AC, WiFi, TV'),
(31,'Heritage Suite',      3000.00,4,2, 'AC, WiFi, Terracotta exhibits, Garden view'),
(32,'Standard Room',       2500.00,2,8, 'AC, WiFi, TV, Breakfast included'),
(32,'Deluxe Room',         3800.00,2,5, 'AC, WiFi, TV, Breakfast + Dinner, Bogura specialty'),
(32,'Royal Suite',         6500.00,3,2, 'AC, WiFi, Panoramic view, Full board, Bathtub'),
(33,'Standard Room',       1600.00,2,8, 'AC, WiFi, TV'),
(33,'Deluxe Room',         2400.00,2,5, 'AC, WiFi, TV, Mahasthangarh view'),
(33,'Archaeology Suite',   4200.00,3,2, 'AC, WiFi, Mural art, Balcony, Guided tour incl.'),
(34,'Standard Room',       1400.00,2,8, 'Fan, WiFi, TV'),
(34,'Deluxe Room',         2200.00,2,5, 'AC, WiFi, TV'),
(34,'Heritage Suite',      3600.00,3,2, 'AC, WiFi, Temple view, Cultural tour incl.'),
(35,'Standard Room',       1200.00,2,8, 'Fan, WiFi'),
(35,'Deluxe Room',         1900.00,2,5, 'AC, WiFi, TV'),
(35,'Museum Suite',        3200.00,4,2, 'AC, WiFi, Padma River view, Museum ticket incl.'),
(36,'Standard Room',       2200.00,2,8, 'AC, WiFi, TV, Padma view'),
(36,'Deluxe Room',         3400.00,2,5, 'AC, WiFi, TV, Padma River view, Breakfast'),
(36,'Presidential Suite',  7000.00,4,2, 'AC, WiFi, Full board, Padma view, Jacuzzi, Lounge');

-- Hotels 41–50
INSERT INTO room_types (hotel_id, room_name, room_price, room_capacity, available_rooms, amenities) VALUES
(37,'Standard Room',       1600.00,2,8, 'AC, WiFi, TV'),
(37,'Deluxe Room',         2500.00,2,5, 'AC, WiFi, TV, Museum proximity'),
(37,'Heritage Suite',      4000.00,3,2, 'AC, WiFi, Museum view, Breakfast, Cultural tour'),
(38,'Standard Room',       1300.00,2,8, 'Fan, WiFi'),
(38,'Deluxe Room',         2000.00,2,5, 'AC, WiFi, TV'),
(38,'Varendra Suite',      3300.00,4,2, 'AC, WiFi, Museum corridor view, Artifact replica decor'),
(39,'Standard Room',       3000.00,2,8, 'AC, WiFi, TV, Breakfast'),
(39,'Deluxe Hill View',    4800.00,2,5, 'AC, WiFi, TV, Hill panorama, Breakfast + Dinner'),
(39,'Premium Villa',       8500.00,3,2, 'Private villa, AC, WiFi, Infinity pool view, Full board'),
(40,'Standard Room',       2200.00,2,8, 'AC, WiFi, TV'),
(40,'Deluxe Room',         3400.00,2,5, 'AC, WiFi, TV, Mountain view'),
(40,'Summit Suite',        5800.00,3,2, 'AC, WiFi, 360° mountain view, Balcony, Telescope'),
(41,'Standard Room',       2400.00,2,8, 'AC, WiFi, TV'),
(41,'Deluxe Room',         3800.00,2,5, 'AC, WiFi, TV, Hill view'),
(41,'Panorama Suite',      6200.00,3,2, 'AC, WiFi, Full hill panorama, Balcony, Breakfast'),
(42,'Standard Room',       1800.00,2,8, 'AC, WiFi, TV'),
(42,'Deluxe Lake View',    2800.00,2,5, 'AC, WiFi, TV, Kaptai Lake view'),
(42,'Lake Suite',          4800.00,3,2, 'AC, WiFi, Lake panorama, Balcony, Kayak access'),
(43,'Standard Room',       2000.00,2,8, 'AC, WiFi, TV'),
(43,'Deluxe Lake View',    3200.00,2,5, 'AC, WiFi, TV, Kaptai Lake view, Breakfast'),
(43,'Honeymoon Suite',     5500.00,2,2, 'AC, WiFi, Private lake view, Jacuzzi, Breakfast + Dinner');

-- Hotels 51–60
INSERT INTO room_types (hotel_id, room_name, room_price, room_capacity, available_rooms, amenities) VALUES
(44,'Standard Room',       1700.00,2,8, 'AC, WiFi, TV'),
(44,'Deluxe Room',         2600.00,2,5, 'AC, WiFi, TV, Hill view'),
(44,'Valley Suite',        4200.00,3,3, 'AC, WiFi, Valley panorama, Balcony, Guided cave tour'),
(45,'Standard Room',       1500.00,2,8, 'Fan, WiFi, TV'),
(45,'Deluxe Room',         2300.00,2,5, 'AC, WiFi, TV'),
(45,'Cave View Suite',     3700.00,3,2, 'AC, WiFi, Hill view, Alutila cave guide incl.'),
(46,'Standard Room',       1600.00,2,8, 'Fan, WiFi, TV'),
(46,'Deluxe Room',         2500.00,2,5, 'AC, WiFi, TV, Hill view'),
(46,'Eco Suite',           4000.00,4,3, 'AC, WiFi, Tribal art, Nature veranda'),
(47,'Standard Room',       1800.00,2,8, 'AC, WiFi, TV'),
(47,'Deluxe Room',         2800.00,2,5, 'AC, WiFi, TV, Tea garden view'),
(47,'Tea Planter Suite',   5000.00,3,3, 'AC, WiFi, Tea estate panorama, Balcony, Golf access'),
(48,'Standard Room',       1600.00,2,8, 'AC, WiFi, TV'),
(48,'Deluxe Room',         2500.00,2,5, 'AC, WiFi, TV, Forest view'),
(48,'Nature Suite',        4200.00,3,3, 'AC, WiFi, Lawachara forest view, Bird watching deck'),
(49,'Standard Room',       1700.00,2,8, 'AC, WiFi, TV'),
(49,'Deluxe Room',         2600.00,2,5, 'AC, WiFi, TV, Tea garden view'),
(49,'Balishira Suite',     4500.00,3,3, 'AC, WiFi, Tea estate view, Balcony, Cycle tour'),
(50,'Standard Room',       1500.00,2,8, 'Fan, WiFi, TV'),
(50,'Deluxe River View',   2400.00,2,5, 'AC, WiFi, TV, River view'),
(50,'Boulder Suite',       4000.00,3,3, 'AC, WiFi, River & hill view, Balcony, Stone tour');

-- ============================================================
-- End of 03_seed_hotels.sql
-- ============================================================

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
-- ============================================================
--  OneReserve — Bangladesh Tourism Reservation System
--  File: 06_triggers.sql
--  Description: 6 production triggers covering seat management,
--               room availability, booking logs, and cost calc
-- ============================================================

USE onereserve;

DELIMITER $$

-- ============================================================
-- TRIGGER 1: After booking_bus INSERT
-- Reduces available_seats on the bus by seat_quantity
-- ============================================================
DROP TRIGGER IF EXISTS trg_booking_bus_after_insert$$
CREATE TRIGGER trg_booking_bus_after_insert
AFTER INSERT ON booking_bus
FOR EACH ROW
BEGIN
    -- Decrease available seats
    UPDATE buses b
    JOIN  schedules s ON s.bus_id = b.bus_id
    SET   b.available_seats = b.available_seats - NEW.seat_quantity
    WHERE s.schedule_id = NEW.schedule_id;

    -- Log the seat deduction
    INSERT INTO booking_logs (booking_id, action_type, remarks, action_time)
    VALUES (NEW.booking_id, 'SEATS_RESERVED',
            CONCAT('Reserved ', NEW.seat_quantity, ' seat(s) on schedule #', NEW.schedule_id),
            NOW());
END$$

-- ============================================================
-- TRIGGER 2: After booking_hotel INSERT
-- Reduces available_rooms on the room_type
-- ============================================================
DROP TRIGGER IF EXISTS trg_booking_hotel_after_insert$$
CREATE TRIGGER trg_booking_hotel_after_insert
AFTER INSERT ON booking_hotel
FOR EACH ROW
BEGIN
    UPDATE room_types
    SET    available_rooms = available_rooms - 1
    WHERE  room_type_id = NEW.room_type_id;

    INSERT INTO booking_logs (booking_id, action_type, remarks, action_time)
    VALUES (NEW.booking_id, 'ROOM_RESERVED',
            CONCAT('Reserved room_type #', NEW.room_type_id,
                   ' for ', NEW.nights, ' night(s)'),
            NOW());
END$$

-- ============================================================
-- TRIGGER 3: After booking status UPDATE
-- Logs every status transition with old → new values
-- ============================================================
DROP TRIGGER IF EXISTS trg_bookings_status_update$$
CREATE TRIGGER trg_bookings_status_update
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF OLD.booking_status <> NEW.booking_status THEN
        INSERT INTO booking_logs
            (booking_id, action_type, old_status, new_status, action_time, remarks)
        VALUES
            (NEW.booking_id,
             CASE NEW.booking_status
                 WHEN 'confirmed'  THEN 'BOOKING_CONFIRMED'
                 WHEN 'cancelled'  THEN 'BOOKING_CANCELLED'
                 WHEN 'completed'  THEN 'TRIP_COMPLETED'
                 ELSE 'STATUS_CHANGED'
             END,
             OLD.booking_status,
             NEW.booking_status,
             NOW(),
             CONCAT('Status changed: ', OLD.booking_status, ' → ', NEW.booking_status));
    END IF;
END$$

-- ============================================================
-- TRIGGER 4: After booking_bus DELETE (cancellation)
-- Restores available_seats when a bus booking is removed
-- ============================================================
DROP TRIGGER IF EXISTS trg_booking_bus_after_delete$$
CREATE TRIGGER trg_booking_bus_after_delete
AFTER DELETE ON booking_bus
FOR EACH ROW
BEGIN
    UPDATE buses b
    JOIN  schedules s ON s.bus_id = b.bus_id
    SET   b.available_seats = b.available_seats + OLD.seat_quantity
    WHERE s.schedule_id = OLD.schedule_id;

    INSERT INTO booking_logs (booking_id, action_type, remarks, action_time)
    VALUES (OLD.booking_id, 'SEATS_RELEASED',
            CONCAT('Released ', OLD.seat_quantity, ' seat(s) from schedule #', OLD.schedule_id),
            NOW());
END$$

-- ============================================================
-- TRIGGER 5: After booking_hotel DELETE (cancellation)
-- Restores available_rooms
-- ============================================================
DROP TRIGGER IF EXISTS trg_booking_hotel_after_delete$$
CREATE TRIGGER trg_booking_hotel_after_delete
AFTER DELETE ON booking_hotel
FOR EACH ROW
BEGIN
    UPDATE room_types
    SET    available_rooms = available_rooms + 1
    WHERE  room_type_id = OLD.room_type_id;

    INSERT INTO booking_logs (booking_id, action_type, remarks, action_time)
    VALUES (OLD.booking_id, 'ROOM_RELEASED',
            CONCAT('Released room_type #', OLD.room_type_id),
            NOW());
END$$

-- ============================================================
-- TRIGGER 6: After payment INSERT
-- Auto-confirms booking when payment is 'completed'
-- ============================================================
DROP TRIGGER IF EXISTS trg_payment_after_insert$$
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'completed' THEN
        UPDATE bookings
        SET    booking_status = 'confirmed'
        WHERE  booking_id     = NEW.booking_id
          AND  booking_status = 'pending';

        INSERT INTO booking_logs
            (booking_id, action_type, old_status, new_status, performed_by, action_time, remarks)
        VALUES
            (NEW.booking_id, 'PAYMENT_RECEIVED', 'pending', 'confirmed', 'system',
             NOW(), CONCAT('Auto-confirmed after ', NEW.payment_method,
                           ' payment ref: ', COALESCE(NEW.transaction_ref, 'N/A')));
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- End of 06_triggers.sql
-- ============================================================

-- ============================================================
--  OneReserve — Bangladesh Tourism Reservation System
--  File: 05_views.sql
--  Description: 8 production-ready VIEWs
-- ============================================================

USE onereserve;

-- ============================================================
-- VIEW 1: vw_place_details
-- Full place info including district name and review stats
-- ============================================================
CREATE OR REPLACE VIEW vw_place_details AS
SELECT
    p.place_id,
    p.place_name,
    p.description,
    p.category,
    p.image_path,
    p.latitude,
    p.longitude,
    p.google_map_url,
    p.is_featured,
    d.district_id,
    d.district_name,
    COUNT(r.review_id)           AS total_reviews,
    ROUND(AVG(r.rating), 1)      AS avg_rating,
    COUNT(w.wishlist_id)         AS wishlist_count
FROM places p
JOIN  districts d  ON p.district_id = d.district_id
LEFT JOIN reviews  r ON p.place_id   = r.place_id
LEFT JOIN wishlist w ON p.place_id   = w.place_id
GROUP BY p.place_id, p.place_name, p.description, p.category,
         p.image_path, p.latitude, p.longitude, p.google_map_url,
         p.is_featured, d.district_id, d.district_name;

-- ============================================================
-- VIEW 2: vw_schedule_details
-- Full schedule info with bus, company, and place name
-- ============================================================
CREATE OR REPLACE VIEW vw_schedule_details AS
SELECT
    s.schedule_id,
    s.departure_city,
    s.departure_time,
    s.arrival_time,
    s.fare,
    s.is_active,
    TIMESTAMPDIFF(HOUR, s.departure_time, s.arrival_time) AS journey_hours,
    b.bus_id,
    b.bus_name,
    b.bus_type,
    b.seat_capacity,
    b.available_seats,
    bc.company_id,
    bc.company_name,
    bc.logo_path   AS company_logo,
    p.place_id,
    p.place_name,
    p.category     AS place_category,
    d.district_name
FROM schedules s
JOIN buses        b  ON s.bus_id      = b.bus_id
JOIN bus_companies bc ON b.company_id  = bc.company_id
JOIN places       p  ON s.place_id    = p.place_id
JOIN districts    d  ON p.district_id = d.district_id;

-- ============================================================
-- VIEW 3: vw_hotel_details
-- Hotel with place info and room summary
-- ============================================================
CREATE OR REPLACE VIEW vw_hotel_details AS
SELECT
    h.hotel_id,
    h.hotel_name,
    h.address,
    h.rating,
    h.image_path,
    h.is_active,
    p.place_id,
    p.place_name,
    d.district_name,
    COUNT(rt.room_type_id)               AS room_type_count,
    MIN(rt.room_price)                   AS min_price,
    MAX(rt.room_price)                   AS max_price,
    SUM(rt.available_rooms)              AS total_available_rooms
FROM hotels h
JOIN  places     p  ON h.place_id    = p.place_id
JOIN  districts  d  ON p.district_id = d.district_id
LEFT JOIN room_types rt ON h.hotel_id = rt.hotel_id
GROUP BY h.hotel_id, h.hotel_name, h.address, h.rating,
         h.image_path, h.is_active, p.place_id, p.place_name, d.district_name;

-- ============================================================
-- VIEW 4: vw_booking_summary
-- Full booking overview for a user
-- ============================================================
CREATE OR REPLACE VIEW vw_booking_summary AS
SELECT
    bk.booking_id,
    bk.booking_date,
    bk.total_amount,
    bk.booking_status,
    bk.notes,
    u.user_id,
    u.full_name,
    u.email,
    -- Bus info
    p_bus.place_name   AS destination,
    d_bus.district_name,
    s.departure_time,
    s.arrival_time,
    b.bus_name,
    b.bus_type,
    bb.seat_quantity,
    bb.fare            AS bus_fare,
    -- Hotel info
    h.hotel_name,
    rt.room_name,
    bh.checkin_date,
    bh.checkout_date,
    bh.nights,
    bh.room_cost,
    -- Payment
    py.payment_status,
    py.payment_method,
    py.amount          AS paid_amount
FROM bookings bk
JOIN  users         u    ON bk.user_id      = u.user_id
LEFT JOIN booking_bus  bb   ON bk.booking_id    = bb.booking_id
LEFT JOIN schedules    s    ON bb.schedule_id   = s.schedule_id
LEFT JOIN buses        b    ON s.bus_id         = b.bus_id
LEFT JOIN places       p_bus ON s.place_id      = p_bus.place_id
LEFT JOIN districts    d_bus ON p_bus.district_id = d_bus.district_id
LEFT JOIN booking_hotel bh  ON bk.booking_id    = bh.booking_id
LEFT JOIN room_types   rt   ON bh.room_type_id  = rt.room_type_id
LEFT JOIN hotels       h    ON rt.hotel_id      = h.hotel_id
LEFT JOIN payments     py   ON bk.booking_id    = py.booking_id;

-- ============================================================
-- VIEW 5: vw_popular_places
-- Places ranked by booking count and avg rating
-- ============================================================
CREATE OR REPLACE VIEW vw_popular_places AS
SELECT
    p.place_id,
    p.place_name,
    p.category,
    p.image_path,
    d.district_name,
    COUNT(DISTINCT bb.booking_id)   AS total_bookings,
    COUNT(DISTINCT r.review_id)     AS total_reviews,
    ROUND(AVG(r.rating), 1)         AS avg_rating,
    COUNT(DISTINCT w.wishlist_id)   AS wishlist_count
FROM places p
JOIN  districts  d  ON p.district_id = d.district_id
LEFT JOIN schedules   s   ON p.place_id   = s.place_id
LEFT JOIN booking_bus bb  ON s.schedule_id = bb.schedule_id
LEFT JOIN reviews     r   ON p.place_id   = r.place_id
LEFT JOIN wishlist    w   ON p.place_id   = w.place_id
GROUP BY p.place_id, p.place_name, p.category, p.image_path, d.district_name
ORDER BY total_bookings DESC, avg_rating DESC;

-- ============================================================
-- VIEW 6: vw_revenue_summary
-- Revenue by payment method and booking status
-- ============================================================
CREATE OR REPLACE VIEW vw_revenue_summary AS
SELECT
    py.payment_method,
    py.payment_status,
    COUNT(py.payment_id)          AS transaction_count,
    SUM(py.amount)                AS total_revenue,
    ROUND(AVG(py.amount), 2)      AS avg_transaction,
    MIN(py.amount)                AS min_transaction,
    MAX(py.amount)                AS max_transaction
FROM payments py
GROUP BY py.payment_method, py.payment_status;

-- ============================================================
-- VIEW 7: vw_user_dashboard
-- Per-user stats: bookings, total spent, reviews, wishlist
-- ============================================================
CREATE OR REPLACE VIEW vw_user_dashboard AS
SELECT
    u.user_id,
    u.full_name,
    u.email,
    u.phone,
    u.created_at,
    COUNT(DISTINCT bk.booking_id)                                             AS total_bookings,
    SUM(CASE WHEN bk.booking_status = 'completed' THEN 1 ELSE 0 END)         AS completed_trips,
    SUM(CASE WHEN bk.booking_status = 'confirmed' THEN 1 ELSE 0 END)         AS upcoming_trips,
    SUM(CASE WHEN bk.booking_status = 'cancelled' THEN 1 ELSE 0 END)         AS cancelled_trips,
    COALESCE(SUM(py.amount), 0)                                               AS total_spent,
    COUNT(DISTINCT r.review_id)                                               AS reviews_written,
    COUNT(DISTINCT w.wishlist_id)                                             AS wishlist_items
FROM users u
LEFT JOIN bookings bk ON u.user_id = bk.user_id
LEFT JOIN payments py ON bk.booking_id = py.booking_id AND py.payment_status = 'completed'
LEFT JOIN reviews  r  ON u.user_id = r.user_id
LEFT JOIN wishlist w  ON u.user_id = w.user_id
GROUP BY u.user_id, u.full_name, u.email, u.phone, u.created_at;

-- ============================================================
-- VIEW 8: vw_available_schedules
-- Only active, future schedules with seats available
-- ============================================================
CREATE OR REPLACE VIEW vw_available_schedules AS
SELECT
    s.schedule_id,
    s.departure_city,
    s.departure_time,
    s.arrival_time,
    s.fare,
    TIMESTAMPDIFF(HOUR, s.departure_time, s.arrival_time) AS journey_hours,
    b.bus_name,
    b.bus_type,
    b.available_seats,
    bc.company_name,
    p.place_name    AS destination,
    d.district_name
FROM schedules s
JOIN buses         b  ON s.bus_id      = b.bus_id
JOIN bus_companies bc ON b.company_id  = bc.company_id
JOIN places        p  ON s.place_id    = p.place_id
JOIN districts     d  ON p.district_id = d.district_id
WHERE s.is_active        = 1
  AND b.available_seats  > 0
  AND s.departure_time   > NOW();

-- ============================================================
-- End of 05_views.sql
-- ============================================================
-- ============================================================
--  OneReserve — Bangladesh Tourism Reservation System
--  File: 08_functions.sql
--  Description: 6 stored functions for business logic
-- ============================================================

USE onereserve;

DELIMITER $$

-- ============================================================
-- FUNCTION 1: fn_calculate_booking_total
-- Returns bus fare + hotel cost for a hypothetical booking
-- ============================================================
DROP FUNCTION IF EXISTS fn_calculate_booking_total$$
CREATE FUNCTION fn_calculate_booking_total(
    p_schedule_id   INT,
    p_seat_qty      INT,
    p_room_type_id  INT,
    p_nights        INT
) RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_bus_fare    DECIMAL(10,2) DEFAULT 0;
    DECLARE v_room_price  DECIMAL(10,2) DEFAULT 0;

    SELECT fare       INTO v_bus_fare   FROM schedules  WHERE schedule_id  = p_schedule_id;
    SELECT room_price INTO v_room_price FROM room_types WHERE room_type_id = p_room_type_id;

    RETURN (v_bus_fare * p_seat_qty) + (v_room_price * p_nights);
END$$

-- ============================================================
-- FUNCTION 2: fn_get_place_avg_rating
-- Returns the average rating for a place, rounded to 1dp
-- ============================================================
DROP FUNCTION IF EXISTS fn_get_place_avg_rating$$
CREATE FUNCTION fn_get_place_avg_rating(p_place_id INT)
RETURNS DECIMAL(3,1)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_avg DECIMAL(3,1) DEFAULT 0.0;
    SELECT ROUND(AVG(rating), 1) INTO v_avg
    FROM   reviews
    WHERE  place_id = p_place_id;
    RETURN COALESCE(v_avg, 0.0);
END$$

-- ============================================================
-- FUNCTION 3: fn_seats_available
-- Returns remaining available seats for a schedule
-- ============================================================
DROP FUNCTION IF EXISTS fn_seats_available$$
CREATE FUNCTION fn_seats_available(p_schedule_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_avail INT DEFAULT 0;
    SELECT b.available_seats INTO v_avail
    FROM   buses b
    JOIN   schedules s ON s.bus_id = b.bus_id
    WHERE  s.schedule_id = p_schedule_id;
    RETURN COALESCE(v_avail, 0);
END$$

-- ============================================================
-- FUNCTION 4: fn_user_total_spent
-- Returns the total confirmed amount spent by a user
-- ============================================================
DROP FUNCTION IF EXISTS fn_user_total_spent$$
CREATE FUNCTION fn_user_total_spent(p_user_id INT)
RETURNS DECIMAL(14,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(14,2) DEFAULT 0;
    SELECT COALESCE(SUM(py.amount), 0) INTO v_total
    FROM   payments py
    JOIN   bookings bk ON py.booking_id = bk.booking_id
    WHERE  bk.user_id = p_user_id
      AND  py.payment_status = 'completed';
    RETURN v_total;
END$$

-- ============================================================
-- FUNCTION 5: fn_journey_hours
-- Returns journey duration in hours from a schedule
-- ============================================================
DROP FUNCTION IF EXISTS fn_journey_hours$$
CREATE FUNCTION fn_journey_hours(p_schedule_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_hours INT DEFAULT 0;
    SELECT TIMESTAMPDIFF(HOUR, departure_time, arrival_time)
    INTO   v_hours
    FROM   schedules
    WHERE  schedule_id = p_schedule_id;
    RETURN COALESCE(v_hours, 0);
END$$

-- ============================================================
-- FUNCTION 6: fn_booking_status_label
-- Returns a human-readable Bangla/English label for status
-- ============================================================
DROP FUNCTION IF EXISTS fn_booking_status_label$$
CREATE FUNCTION fn_booking_status_label(p_status VARCHAR(30))
RETURNS VARCHAR(60)
DETERMINISTIC
NO SQL
BEGIN
    RETURN CASE p_status
        WHEN 'pending'   THEN 'Pending Payment'
        WHEN 'confirmed' THEN 'Booking Confirmed ✓'
        WHEN 'cancelled' THEN 'Cancelled'
        WHEN 'completed' THEN 'Trip Completed ✓'
        ELSE 'Unknown Status'
    END;
END$$

DELIMITER ;

-- ============================================================
-- End of 08_functions.sql
-- ============================================================
-- ============================================================
--  OneReserve — Bangladesh Tourism Reservation System
--  File: 07_procedures.sql
--  Description: 6 stored procedures covering core workflows
-- ============================================================

USE onereserve;

DELIMITER $$

-- ============================================================
-- PROCEDURE 1: sp_create_booking
-- Creates a complete booking in one atomic transaction:
-- master record + bus + hotel + log entry
-- ============================================================
DROP PROCEDURE IF EXISTS sp_create_booking$$
CREATE PROCEDURE sp_create_booking(
    IN  p_user_id       INT,
    IN  p_schedule_id   INT,
    IN  p_seat_qty      INT,
    IN  p_room_type_id  INT,
    IN  p_checkin       DATE,
    IN  p_checkout      DATE,
    IN  p_notes         TEXT,
    OUT p_booking_id    INT,
    OUT p_total_amount  DECIMAL(12,2),
    OUT p_message       VARCHAR(255)
)
sp_create_booking: BEGIN
    DECLARE v_fare         DECIMAL(10,2);
    DECLARE v_avail_seats  INT;
    DECLARE v_room_price   DECIMAL(10,2);
    DECLARE v_avail_rooms  INT;
    DECLARE v_nights       INT;
    DECLARE v_bus_total    DECIMAL(10,2);
    DECLARE v_hotel_total  DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Transaction failed — booking rolled back.';
        SET p_booking_id = -1;
    END;

    -- Validate seat availability
    SELECT s.fare, b.available_seats
    INTO   v_fare, v_avail_seats
    FROM   schedules s
    JOIN   buses b ON s.bus_id = b.bus_id
    WHERE  s.schedule_id = p_schedule_id;

    IF v_avail_seats < p_seat_qty THEN
        SET p_message    = CONCAT('Not enough seats. Available: ', v_avail_seats);
        SET p_booking_id = -1;
        LEAVE sp_create_booking;
    END IF;

    -- Validate room availability
    SELECT room_price, available_rooms
    INTO   v_room_price, v_avail_rooms
    FROM   room_types
    WHERE  room_type_id = p_room_type_id;

    IF v_avail_rooms < 1 THEN
        SET p_message    = 'Room not available for selected dates.';
        SET p_booking_id = -1;
        LEAVE sp_create_booking;
    END IF;

    SET v_nights      = DATEDIFF(p_checkout, p_checkin);
    SET v_bus_total   = v_fare * p_seat_qty;
    SET v_hotel_total = v_room_price * v_nights;
    SET p_total_amount = v_bus_total + v_hotel_total;

    START TRANSACTION;

    -- Insert master booking
    INSERT INTO bookings (user_id, total_amount, booking_status, notes)
    VALUES (p_user_id, p_total_amount, 'pending', p_notes);
    SET p_booking_id = LAST_INSERT_ID();

    -- Insert bus booking
    INSERT INTO booking_bus (booking_id, schedule_id, seat_quantity, fare)
    VALUES (p_booking_id, p_schedule_id, p_seat_qty, v_bus_total);

    -- Insert hotel booking
    INSERT INTO booking_hotel (booking_id, room_type_id, checkin_date, checkout_date, nights, room_cost)
    VALUES (p_booking_id, p_room_type_id, p_checkin, p_checkout, v_nights, v_hotel_total);

    -- Log it
    INSERT INTO booking_logs (booking_id, action_type, new_status, performed_by, remarks)
    VALUES (p_booking_id, 'BOOKING_CREATED', 'pending',
            (SELECT email FROM users WHERE user_id = p_user_id),
            'Created via sp_create_booking');

    COMMIT;
    SET p_message = CONCAT('Booking #', p_booking_id, ' created successfully. Total: BDT ', p_total_amount);
END$$

-- ============================================================
-- PROCEDURE 2: sp_cancel_booking
-- Cancels a booking, refunds payment, restores inventory
-- ============================================================
DROP PROCEDURE IF EXISTS sp_cancel_booking$$
CREATE PROCEDURE sp_cancel_booking(
    IN  p_booking_id  INT,
    IN  p_reason      VARCHAR(255),
    OUT p_message     VARCHAR(255)
)
sp_cancel_booking: BEGIN
    DECLARE v_status VARCHAR(30);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Cancellation failed — rolled back.';
    END;

    SELECT booking_status INTO v_status
    FROM   bookings WHERE booking_id = p_booking_id;

    IF v_status = 'completed' THEN
        SET p_message = 'Cannot cancel a completed booking.';
        LEAVE sp_cancel_booking;
    END IF;

    IF v_status = 'cancelled' THEN
        SET p_message = 'Booking is already cancelled.';
        LEAVE sp_cancel_booking;
    END IF;

    START TRANSACTION;

    -- Cancel booking (triggers handle seat/room restoration)
    UPDATE bookings SET booking_status = 'cancelled' WHERE booking_id = p_booking_id;

    -- Delete bus & hotel booking lines (triggers fire to restore inventory)
    DELETE FROM booking_bus   WHERE booking_id = p_booking_id;
    DELETE FROM booking_hotel WHERE booking_id = p_booking_id;

    -- Mark payment as refunded
    UPDATE payments SET payment_status = 'refunded'
    WHERE  booking_id = p_booking_id AND payment_status = 'completed';

    -- Log the cancellation reason
    INSERT INTO booking_logs (booking_id, action_type, old_status, new_status, remarks)
    VALUES (p_booking_id, 'BOOKING_CANCELLED', v_status, 'cancelled', p_reason);

    COMMIT;
    SET p_message = CONCAT('Booking #', p_booking_id, ' cancelled successfully.');
END$$

-- ============================================================
-- PROCEDURE 3: sp_process_payment
-- Records a payment and auto-confirms the booking
-- ============================================================
DROP PROCEDURE IF EXISTS sp_process_payment$$
CREATE PROCEDURE sp_process_payment(
    IN  p_booking_id   INT,
    IN  p_method       VARCHAR(50),
    IN  p_amount       DECIMAL(12,2),
    IN  p_txn_ref      VARCHAR(100),
    OUT p_payment_id   INT,
    OUT p_message      VARCHAR(255)
)
sp_process_payment: BEGIN
    DECLARE v_total    DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message   = 'Payment processing failed.';
        SET p_payment_id = -1;
    END;

    SELECT total_amount INTO v_total
    FROM   bookings WHERE booking_id = p_booking_id;

    IF ABS(p_amount - v_total) > 1.00 THEN   -- 1 BDT tolerance
        SET p_message    = CONCAT('Amount mismatch. Expected: ', v_total, ', Received: ', p_amount);
        SET p_payment_id = -1;
        LEAVE sp_process_payment;
    END IF;

    START TRANSACTION;

    INSERT INTO payments (booking_id, amount, payment_method, payment_status, transaction_ref)
    VALUES (p_booking_id, p_amount, p_method, 'completed', p_txn_ref);
    SET p_payment_id = LAST_INSERT_ID();

    COMMIT;
    SET p_message = CONCAT('Payment #', p_payment_id, ' processed. Booking confirmed.');
END$$

-- ============================================================
-- PROCEDURE 4: sp_search_schedules
-- Search active schedules by destination and date
-- ============================================================
DROP PROCEDURE IF EXISTS sp_search_schedules$$
CREATE PROCEDURE sp_search_schedules(
    IN p_destination  VARCHAR(100),
    IN p_travel_date  DATE,
    IN p_bus_type     VARCHAR(50)   -- NULL = any type
)
sp_search_schedules: BEGIN
    SELECT
        s.schedule_id,
        p.place_name    AS destination,
        d.district_name,
        s.departure_city,
        s.departure_time,
        s.arrival_time,
        TIMESTAMPDIFF(HOUR, s.departure_time, s.arrival_time) AS hours,
        s.fare,
        b.bus_name,
        b.bus_type,
        b.available_seats,
        bc.company_name
    FROM schedules s
    JOIN buses         b  ON s.bus_id      = b.bus_id
    JOIN bus_companies bc ON b.company_id  = bc.company_id
    JOIN places        p  ON s.place_id    = p.place_id
    JOIN districts     d  ON p.district_id = d.district_id
    WHERE s.is_active        = 1
      AND b.available_seats  > 0
      AND DATE(s.departure_time) = p_travel_date
      AND (p.place_name LIKE CONCAT('%', p_destination, '%')
           OR d.district_name LIKE CONCAT('%', p_destination, '%'))
      AND (p_bus_type IS NULL OR b.bus_type = p_bus_type)
    ORDER BY s.fare ASC, s.departure_time ASC;
END$$

-- ============================================================
-- PROCEDURE 5: sp_get_booking_history
-- Returns paginated booking history for a user
-- ============================================================
DROP PROCEDURE IF EXISTS sp_get_booking_history$$
CREATE PROCEDURE sp_get_booking_history(
    IN p_user_id   INT,
    IN p_limit     INT,
    IN p_offset    INT
)
sp_get_booking_history: BEGIN
    SELECT
        bk.booking_id,
        bk.booking_date,
        bk.total_amount,
        bk.booking_status,
        bk.notes,
        p.place_name    AS destination,
        d.district_name,
        s.departure_time,
        h.hotel_name,
        rt.room_name,
        bh.checkin_date,
        bh.checkout_date,
        py.payment_method,
        py.payment_status,
        py.amount       AS paid_amount
    FROM bookings bk
    JOIN  users          u   ON bk.user_id      = u.user_id
    LEFT JOIN booking_bus   bb  ON bk.booking_id    = bb.booking_id
    LEFT JOIN schedules     s   ON bb.schedule_id   = s.schedule_id
    LEFT JOIN places        p   ON s.place_id       = p.place_id
    LEFT JOIN districts     d   ON p.district_id    = d.district_id
    LEFT JOIN booking_hotel bh  ON bk.booking_id    = bh.booking_id
    LEFT JOIN room_types    rt  ON bh.room_type_id  = rt.room_type_id
    LEFT JOIN hotels        h   ON rt.hotel_id      = h.hotel_id
    LEFT JOIN payments      py  ON bk.booking_id    = py.booking_id
    WHERE bk.user_id = p_user_id
    ORDER BY bk.booking_date DESC
    LIMIT p_limit OFFSET p_offset;
END$$

-- ============================================================
-- PROCEDURE 6: sp_monthly_revenue_report
-- Generates a monthly revenue summary for admin dashboard
-- ============================================================
DROP PROCEDURE IF EXISTS sp_monthly_revenue_report$$
CREATE PROCEDURE sp_monthly_revenue_report(
    IN p_year  INT
)
sp_monthly_revenue_report: BEGIN
    SELECT
        MONTH(py.payment_date)                  AS month_num,
        MONTHNAME(py.payment_date)              AS month_name,
        COUNT(py.payment_id)                    AS transactions,
        SUM(py.amount)                          AS total_revenue,
        SUM(CASE WHEN py.payment_status = 'completed' THEN py.amount ELSE 0 END) AS confirmed_revenue,
        SUM(CASE WHEN py.payment_status = 'refunded'  THEN py.amount ELSE 0 END) AS refunded_amount,
        ROUND(AVG(py.amount), 2)                AS avg_booking_value,
        COUNT(DISTINCT bk.user_id)              AS unique_customers
    FROM payments py
    JOIN bookings bk ON py.booking_id = bk.booking_id
    WHERE YEAR(py.payment_date) = p_year
      AND py.payment_status IN ('completed', 'refunded')
    GROUP BY MONTH(py.payment_date), MONTHNAME(py.payment_date)
    ORDER BY month_num;
END$$

DELIMITER ;

-- ============================================================
-- End of 07_procedures.sql
-- ============================================================
