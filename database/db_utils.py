from sqlalchemy import text
from database import db

def execute_query(sql, params=None):
    with db.engine.connect() as conn:
        result = conn.execute(text(sql), params or {})
        cols = result.keys()
        return [dict(zip(cols, row)) for row in result.fetchall()]

def execute_write(sql, params=None):
    with db.engine.begin() as conn:
        conn.execute(text(sql), params or {})

def call_create_booking(user_id, schedule_id, seat_qty, room_type_id, checkin, checkout, notes):
    from models import Schedule, Bus, RoomType
    from models import Booking, BookingBus, BookingHotel, BookingLog
    schedule = Schedule.query.get(schedule_id)
    bus = Bus.query.get(schedule.bus_id) if schedule else None
    if not schedule or not bus:
        return None, "Invalid schedule."
    if bus.available_seats < seat_qty:
        return None, f"Only {bus.available_seats} seat(s) available."
    bus_total = float(schedule.fare) * seat_qty
    room_total = 0.0
    nights = 0
    room_type = None
    if room_type_id:
        room_type = RoomType.query.get(room_type_id)
        if not room_type:
            return None, "Invalid room type."
        if room_type.available_rooms < 1:
            return None, "Room not available."
        if not checkin or not checkout:
            return None, "Hotel check-in and check-out dates are required when selecting a room."
        nights = (checkout - checkin).days
        if nights <= 0:
            return None, "Checkout must be after checkin."
        room_total = float(room_type.room_price) * nights
    total = bus_total + room_total
    try:
        booking = Booking(user_id=user_id, total_amount=total, booking_status="pending", notes=notes)
        db.session.add(booking)
        db.session.flush()
        bb = BookingBus(booking_id=booking.booking_id, schedule_id=schedule_id, seat_quantity=seat_qty, fare=bus_total)
        db.session.add(bb)
        if room_type:
            bh = BookingHotel(booking_id=booking.booking_id, room_type_id=room_type_id, checkin_date=checkin, checkout_date=checkout, nights=nights, room_cost=room_total)
            db.session.add(bh)
            room_type.available_rooms -= 1
        bus.available_seats -= seat_qty
        log = BookingLog(booking_id=booking.booking_id, action_type="BOOKING_CREATED", new_status="pending", remarks="Created via Flask")
        db.session.add(log)
        db.session.commit()
        return booking, "Booking created successfully."
    except Exception as e:
        db.session.rollback()
        return None, str(e)

def call_cancel_booking(booking_id, reason="User requested"):
    from models import Booking, BookingBus, BookingHotel, BookingLog, Payment, Schedule, Bus, RoomType
    booking = Booking.query.get(booking_id)
    if not booking:
        return False, "Booking not found."
    if booking.booking_status in ("completed", "cancelled"):
        return False, f"Cannot cancel a {booking.booking_status} booking."
    try:
        old_status = booking.booking_status
        for bb in booking.bus_bookings:
            s = Schedule.query.get(bb.schedule_id)
            if s:
                bus = Bus.query.get(s.bus_id)
                if bus:
                    bus.available_seats += bb.seat_quantity
        for bh in booking.hotel_bookings:
            room = RoomType.query.get(bh.room_type_id)
            if room:
                room.available_rooms += 1
        BookingBus.query.filter_by(booking_id=booking_id).delete()
        BookingHotel.query.filter_by(booking_id=booking_id).delete()
        Payment.query.filter_by(booking_id=booking_id, payment_status="completed").update({"payment_status": "refunded"})
        booking.booking_status = "cancelled"
        log = BookingLog(booking_id=booking_id, action_type="BOOKING_CANCELLED", old_status=old_status, new_status="cancelled", remarks=reason)
        db.session.add(log)
        db.session.commit()
        return True, "Booking cancelled successfully."
    except Exception as e:
        db.session.rollback()
        return False, str(e)

def fn_calculate_bus_cost(schedule_id, seat_qty):
    row = execute_query("SELECT fare FROM schedules WHERE schedule_id = :sid", {"sid": schedule_id})
    return float(row[0]["fare"]) * seat_qty if row else 0.0

def fn_calculate_hotel_cost(room_type_id, nights):
    row = execute_query("SELECT room_price FROM room_types WHERE room_type_id = :rid", {"rid": room_type_id})
    return float(row[0]["room_price"]) * nights if row else 0.0

def fn_calculate_total_trip_cost(schedule_id, seat_qty, room_type_id, nights):
    return fn_calculate_bus_cost(schedule_id, seat_qty) + fn_calculate_hotel_cost(room_type_id, nights)

def get_popular_places_view(limit=10):
    return execute_query("SELECT * FROM vw_popular_places LIMIT :lim", {"lim": limit})

def get_revenue_view():
    return execute_query("SELECT * FROM vw_revenue_summary ORDER BY total_revenue DESC")

def popular_destination_report():
    return execute_query("""
        SELECT p.place_id, p.place_name, p.category, d.district_name,
            COUNT(DISTINCT bb.booking_id) AS total_bookings,
            ROUND(AVG(r.rating),1) AS avg_rating,
            COUNT(DISTINCT r.review_id) AS review_count
        FROM places p
        JOIN districts d ON p.district_id=d.district_id
        LEFT JOIN schedules s ON p.place_id=s.place_id
        LEFT JOIN booking_bus bb ON s.schedule_id=bb.schedule_id
        LEFT JOIN reviews r ON p.place_id=r.place_id
        GROUP BY p.place_id,p.place_name,p.category,d.district_name
        ORDER BY total_bookings DESC, avg_rating DESC LIMIT 20
    """)

def monthly_revenue_report(year):
    return execute_query("""
        SELECT MONTH(py.payment_date) AS month_num, MONTHNAME(py.payment_date) AS month_name,
            COUNT(py.payment_id) AS transactions,
            SUM(py.amount) AS total_revenue,
            SUM(CASE WHEN py.payment_status='completed' THEN py.amount ELSE 0 END) AS confirmed_revenue,
            ROUND(AVG(py.amount),2) AS avg_booking_value,
            COUNT(DISTINCT bk.user_id) AS unique_customers
        FROM payments py JOIN bookings bk ON py.booking_id=bk.booking_id
        WHERE YEAR(py.payment_date)=:yr AND py.payment_status IN ('completed','refunded')
        GROUP BY MONTH(py.payment_date),MONTHNAME(py.payment_date)
        ORDER BY month_num
    """, {"yr": year})
