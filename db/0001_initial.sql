-- BIG-BUS Travel: starter Cloudflare D1 schema. No real passenger data belongs in git.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS routes (
 id TEXT PRIMARY KEY,
 departure_date TEXT NOT NULL,
 departure_time TEXT NOT NULL,
 direction TEXT NOT NULL CHECK(direction IN ('out','back')),
 stops_json TEXT NOT NULL,
 vehicle_type TEXT NOT NULL CHECK(vehicle_type IN ('bus','coach')),
 seat_count INTEGER NOT NULL CHECK(seat_count IN (7,41)),
 prices_json TEXT NOT NULL DEFAULT '{}',
 currency TEXT NOT NULL DEFAULT 'EUR',
 state TEXT NOT NULL DEFAULT 'scheduled' CHECK(state IN ('scheduled','cancelled','completed')),
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS routes_by_departure ON routes(departure_date,departure_time);

CREATE TABLE IF NOT EXISTS bookings (
 id TEXT PRIMARY KEY,
 route_id TEXT NOT NULL REFERENCES routes(id),
 from_stop INTEGER NOT NULL,
 to_stop INTEGER NOT NULL,
 passenger_phone TEXT NOT NULL,
 passengers_json TEXT NOT NULL,
 total_eur_cents INTEGER NOT NULL CHECK(total_eur_cents >= 0),
 paid INTEGER NOT NULL DEFAULT 0 CHECK(paid IN (0,1)),
 state TEXT NOT NULL DEFAULT 'pending' CHECK(state IN ('pending','confirmed','boarded','cancelled')),
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CHECK(from_stop>=0 AND to_stop>from_stop)
);
CREATE INDEX IF NOT EXISTS bookings_by_route ON bookings(route_id,state);
-- Each numbered seat is reserved at most once per entire journey.
-- Conservative restriction: later phase may allow non-overlapping travel segments,
-- but only with transactional collision checks on the same route.
CREATE TABLE IF NOT EXISTS booked_seats (
 route_id TEXT NOT NULL REFERENCES routes(id),
 seat_number INTEGER NOT NULL CHECK(seat_number>=1),
 booking_id TEXT NOT NULL REFERENCES bookings(id),
 PRIMARY KEY(route_id,seat_number)
);
CREATE INDEX IF NOT EXISTS booked_seats_by_booking ON booked_seats(booking_id);

CREATE TABLE IF NOT EXISTS parcels (
 id TEXT PRIMARY KEY,
 route_id TEXT REFERENCES routes(id),
 sender_phone TEXT NOT NULL,
 recipient_phone TEXT,
 description TEXT,
 weight_kg REAL CHECK(weight_kg IS NULL OR weight_kg>=0),
 state TEXT NOT NULL DEFAULT 'pending',
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sync_events (
 id TEXT PRIMARY KEY,
 source TEXT NOT NULL CHECK(source IN ('website','google_sheets')),
 external_id TEXT,
 entity_type TEXT NOT NULL,
 entity_id TEXT NOT NULL,
 event_type TEXT NOT NULL,
 processed_at TEXT,
 error_text TEXT,
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS sync_events_external ON sync_events(source,external_id) WHERE external_id IS NOT NULL;
