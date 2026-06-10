# services/__init__.py  — all service functions
import re, uuid
from datetime import datetime
from flask_bcrypt import Bcrypt
from sqlalchemy import or_, and_, func, desc
from database import db
from database.db_utils import (call_create_booking, call_cancel_booking,
    fn_calculate_bus_cost, fn_calculate_hotel_cost, popular_destination_report,
    monthly_revenue_report, get_revenue_view)

bcrypt = Bcrypt()

# ── Auth ──────────────────────────────────────────────────────
def validate_email(e): return bool(re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", e.strip()))

def register_user(full_name, email, password, phone=None):
    from models import User
    full_name = full_name.strip(); email = email.strip().lower()
    if not full_name: return None, "Full name is required."
    if not validate_email(email): return None, "Invalid email address."
    if len(password) < 6: return None, "Password must be at least 6 characters."
    if User.query.filter_by(email=email).first(): return None, "Email is already registered."
    hashed = bcrypt.generate_password_hash(password).decode("utf-8")
    user = User(full_name=full_name, email=email, password=hashed, phone=phone.strip() if phone else None)
    db.session.add(user); db.session.commit()
    return user, None

def login_user_service(email, password):
    from models import User
    email = email.strip().lower()
    user = User.query.filter_by(email=email, is_active=True).first()
    if not user: return None, "No account found with that email."
    if not bcrypt.check_password_hash(user.password, password): return None, "Incorrect password."
    return user, None

def update_profile(user_id, full_name, phone):
    from models import User
    user = User.query.get(user_id)
    if not user: return None, "User not found."
    if not full_name.strip(): return None, "Full name cannot be empty."
    user.full_name = full_name.strip(); user.phone = phone.strip() if phone else user.phone
    db.session.commit(); return user, None

def change_password(user_id, current_password, new_password):
    from models import User
    user = User.query.get(user_id)
    if not user: return False, "User not found."
    if not bcrypt.check_password_hash(user.password, current_password): return False, "Current password is incorrect."
    if len(new_password) < 6: return False, "Password must be at least 6 characters."
    user.password = bcrypt.generate_password_hash(new_password).decode("utf-8")
    db.session.commit(); return True, "Password updated successfully."

# ── Places ────────────────────────────────────────────────────
def get_all_places(category=None, district_id=None, featured_only=False, page=1, per_page=12):
    from models import Place, District
    q = Place.query.join(District)
    if category: q = q.filter(Place.category == category)
    if district_id: q = q.filter(Place.district_id == district_id)
    if featured_only: q = q.filter(Place.is_featured.is_(True))
    pag = q.order_by(Place.place_name).paginate(page=page, per_page=per_page, error_out=False)
    return {"places":[p.to_dict() for p in pag.items],"total":pag.total,"pages":pag.pages,"current_page":pag.page,"has_next":pag.has_next,"has_prev":pag.has_prev}

def search_places(query, page=1, per_page=12):
    from models import Place, District
    q = (Place.query.join(District).filter(or_(
        Place.place_name.ilike(f"%{query}%"), Place.description.ilike(f"%{query}%"),
        Place.category.ilike(f"%{query}%"), District.district_name.ilike(f"%{query}%"))))
    pag = q.paginate(page=page, per_page=per_page, error_out=False)
    return {"query":query,"places":[p.to_dict() for p in pag.items],"total":pag.total,"pages":pag.pages,"current_page":pag.page,"has_next":pag.has_next,"has_prev":pag.has_prev}

def get_place_detail(place_id):
    from models import Place, Review
    from flask import abort
    place = Place.query.get(place_id)
    if not place: abort(404)
    data = place.to_dict(detail=True)
    data["reviews"] = [r.to_dict() for r in Review.query.filter_by(place_id=place_id).order_by(Review.review_date.desc()).limit(20)]
    data["hotels"] = [h.to_dict() for h in place.hotels.filter_by(is_active=True)]
    data["schedules_count"] = place.schedules.filter_by(is_active=True).count()
    return data

def get_featured_places(limit=6):
    from models import Place
    return [p.to_dict() for p in Place.query.filter_by(is_featured=True).limit(limit).all()]

def get_categories():
    from models import Place
    rows = db.session.query(Place.category).distinct().filter(Place.category.isnot(None)).all()
    return [r[0] for r in rows]

# ── Bus ───────────────────────────────────────────────────────
def get_schedules(place_id=None, travel_date=None, bus_type=None, page=1, per_page=20):
    from models import Schedule, Bus, BusCompany, Place, District
    q = (Schedule.query.join(Bus).join(BusCompany).join(Place).join(District)
         .filter(Schedule.is_active.is_(True)).filter(Bus.available_seats > 0))
    if place_id: q = q.filter(Schedule.place_id == place_id)
    if travel_date:
        if isinstance(travel_date, str):
            travel_date = datetime.strptime(travel_date, "%Y-%m-%d").date()
        q = q.filter(and_(
            Schedule.departure_time >= datetime.combine(travel_date, datetime.min.time()),
            Schedule.departure_time < datetime.combine(travel_date, datetime.max.time())))
    if bus_type: q = q.filter(Bus.bus_type == bus_type)
    pag = q.order_by(Schedule.fare.asc()).paginate(page=page, per_page=per_page, error_out=False)
    return {"schedules":[s.to_dict() for s in pag.items],"total":pag.total,"pages":pag.pages,"current_page":pag.page,"has_next":pag.has_next}

def get_companies():
    from models import BusCompany
    return [c.to_dict() for c in BusCompany.query.filter_by(is_active=True).all()]

# ── Hotel ─────────────────────────────────────────────────────
def get_hotels(place_id=None, min_rating=None, max_price=None, page=1, per_page=12):
    from models import Hotel, Place, District, RoomType
    q = Hotel.query.join(Place).join(District).filter(Hotel.is_active.is_(True))
    if place_id: q = q.filter(Hotel.place_id == place_id)
    if min_rating: q = q.filter(Hotel.rating >= min_rating)
    if max_price:
        cheap = RoomType.query.with_entities(RoomType.hotel_id).filter(RoomType.room_price <= max_price).subquery()
        q = q.filter(Hotel.hotel_id.in_(cheap))
    pag = q.order_by(Hotel.rating.desc()).paginate(page=page, per_page=per_page, error_out=False)
    return {"hotels":[h.to_dict(include_rooms=True) for h in pag.items],"total":pag.total,"pages":pag.pages,"current_page":pag.page}

def get_hotel_detail(hotel_id):
    from models import Hotel
    from flask import abort
    hotel = Hotel.query.get(hotel_id)
    if not hotel: abort(404)
    return hotel.to_dict(include_rooms=True)

def get_room_types(hotel_id):
    from models import Hotel, RoomType
    from flask import abort
    hotel = Hotel.query.get(hotel_id)
    if not hotel: abort(404)
    return [rt.to_dict() for rt in hotel.room_types.filter(RoomType.available_rooms > 0)]

# ── Booking ───────────────────────────────────────────────────
def calculate_trip_cost(schedule_id, seat_qty, room_type_id=None, checkin_str="", checkout_str=""):
    from models import Schedule, RoomType
    if seat_qty < 1: return None, "Seat quantity must be at least 1."
    schedule = Schedule.query.get(schedule_id)
    if not schedule: return None, "Schedule not found."
    if schedule.bus.available_seats < seat_qty:
        return None, f"Only {schedule.bus.available_seats} seat(s) available."
    bus_cost = float(schedule.fare) * seat_qty
    if not room_type_id:
        return {"schedule_id":schedule_id,"seat_quantity":seat_qty,"bus_fare_each":float(schedule.fare),
                "bus_cost":bus_cost,"room_type_id":None,"room_name":None,
                "room_price_night":0.0,"nights":0,
                "checkin":None,"checkout":None,"hotel_cost":0.0,
                "total_amount":bus_cost}, None
    try:
        checkin = datetime.strptime(checkin_str, "%Y-%m-%d").date()
        checkout = datetime.strptime(checkout_str, "%Y-%m-%d").date()
    except ValueError:
        return None, "Invalid date format. Use YYYY-MM-DD."
    if checkout <= checkin: return None, "Checkout must be after checkin."
    room_type = RoomType.query.get(room_type_id)
    if not room_type: return None, "Room type not found."
    if room_type.available_rooms < 1: return None, "No rooms available."
    nights = (checkout - checkin).days
    room_cost = float(room_type.room_price) * nights
    return {"schedule_id":schedule_id,"seat_quantity":seat_qty,"bus_fare_each":float(schedule.fare),
            "bus_cost":bus_cost,"room_type_id":room_type_id,"room_name":room_type.room_name,
            "room_price_night":float(room_type.room_price),"nights":nights,
            "checkin":checkin_str,"checkout":checkout_str,"hotel_cost":room_cost,
            "total_amount":bus_cost+room_cost}, None

def create_booking(user_id, schedule_id, seat_qty, room_type_id=None, checkin_str="", checkout_str="", notes=""):
    try:
        checkin = datetime.strptime(checkin_str, "%Y-%m-%d").date() if checkin_str else None
        checkout = datetime.strptime(checkout_str, "%Y-%m-%d").date() if checkout_str else None
    except ValueError:
        return None, "Invalid date format."
    if room_type_id and (not checkin or not checkout):
        return None, "Hotel check-in and check-out dates are required when selecting a room."
    if room_type_id and checkout <= checkin:
        return None, "Checkout must be after checkin."
    return call_create_booking(user_id, schedule_id, seat_qty, room_type_id, checkin, checkout, notes)

def process_payment(booking_id, method, amount, txn_ref=None, user_email="system"):
    from models import Booking, Payment, BookingLog
    VALID = {"bkash","nagad","rocket","card","bank_transfer","cash"}
    if method not in VALID: return None, f"Invalid payment method."
    booking = Booking.query.get(booking_id)
    if not booking: return None, "Booking not found."
    if booking.booking_status == "cancelled": return None, "Cannot pay for a cancelled booking."
    if booking.payments.filter_by(payment_status="completed").first(): return None, "Already paid."
    if abs(amount - float(booking.total_amount)) > 1.0: return None, f"Amount mismatch. Expected ৳{booking.total_amount:.2f}."
    try:
        ref = txn_ref or str(uuid.uuid4())[:12].upper()
        payment = Payment(booking_id=booking_id, amount=amount, payment_method=method, payment_status="completed", transaction_ref=ref)
        db.session.add(payment)
        booking.booking_status = "confirmed"
        log = BookingLog(booking_id=booking_id, action_type="PAYMENT_RECEIVED", old_status="pending", new_status="confirmed", performed_by=user_email, remarks=f"{method} ref:{ref}")
        db.session.add(log); db.session.commit()
        return payment, "Payment processed. Booking confirmed."
    except Exception as e:
        db.session.rollback(); return None, str(e)

def cancel_booking(booking_id, user_id, reason="User requested"):
    from models import Booking
    from flask import abort
    booking = Booking.query.get(booking_id)
    if not booking: return False, "Booking not found."
    if booking.user_id != user_id: abort(403)
    return call_cancel_booking(booking_id, reason)

def get_user_bookings(user_id, page=1, per_page=10):
    from models import Booking
    pag = Booking.query.filter_by(user_id=user_id).order_by(Booking.booking_date.desc()).paginate(page=page, per_page=per_page, error_out=False)
    return {"bookings":[b.to_dict(detail=True) for b in pag.items],"total":pag.total,"pages":pag.pages,"current_page":pag.page,"has_next":pag.has_next,"has_prev":pag.has_prev}

# ── Reviews & Wishlist ────────────────────────────────────────
def get_user_reviews(user_id):
    from models import Review
    return [r.to_dict() for r in Review.query.filter_by(user_id=user_id).order_by(Review.review_date.desc()).all()]

def add_review(user_id, place_id, rating, review_text):
    from models import Review, Place
    from flask import abort
    if not (1 <= rating <= 5): return None, "Rating must be 1–5."
    if not review_text or not review_text.strip(): return None, "Review text required."
    if not Place.query.get(place_id): abort(404)
    if Review.query.filter_by(user_id=user_id, place_id=place_id).first(): return None, "You already reviewed this place."
    r = Review(user_id=user_id, place_id=place_id, rating=rating, review_text=review_text.strip())
    try:
        db.session.add(r); db.session.commit(); return r, None
    except: db.session.rollback(); return None, "Already reviewed."

def get_user_wishlist(user_id):
    from models import Wishlist
    return [w.to_dict() for w in Wishlist.query.filter_by(user_id=user_id).order_by(Wishlist.added_at.desc()).all()]

def toggle_wishlist(user_id, place_id):
    from models import Wishlist, Place
    from flask import abort
    if not Place.query.get(place_id): abort(404)
    existing = Wishlist.query.filter_by(user_id=user_id, place_id=place_id).first()
    if existing:
        db.session.delete(existing); db.session.commit(); return False, "Removed from wishlist."
    try:
        w = Wishlist(user_id=user_id, place_id=place_id)
        db.session.add(w); db.session.commit(); return True, "Added to wishlist."
    except: db.session.rollback(); return False, "Already in wishlist."

def is_in_wishlist(user_id, place_id):
    from models import Wishlist
    return Wishlist.query.filter_by(user_id=user_id, place_id=place_id).first() is not None

# ── Admin ─────────────────────────────────────────────────────
def get_dashboard_stats():
    from models import User, Booking, Payment, Place, District, BusCompany, Bus, Schedule, BookingBus
    total_users = User.query.filter_by(is_active=True).count()
    total_bookings = Booking.query.count()
    confirmed = Booking.query.filter(Booking.booking_status.in_(["confirmed","completed"])).count()
    cancelled = Booking.query.filter_by(booking_status="cancelled").count()
    total_revenue = db.session.query(func.coalesce(func.sum(Payment.amount),0)).filter_by(payment_status="completed").scalar()
    popular_place = (db.session.query(Place.place_name, func.count(BookingBus.id).label("cnt"))
        .join(Schedule, Schedule.place_id==Place.place_id).join(BookingBus, BookingBus.schedule_id==Schedule.schedule_id)
        .group_by(Place.place_id, Place.place_name).order_by(desc("cnt")).first())
    top_company = (db.session.query(BusCompany.company_name, func.count(BookingBus.id).label("cnt"))
        .join(Bus, Bus.company_id==BusCompany.company_id).join(Schedule, Schedule.bus_id==Bus.bus_id)
        .join(BookingBus, BookingBus.schedule_id==Schedule.schedule_id)
        .group_by(BusCompany.company_id, BusCompany.company_name).order_by(desc("cnt")).first())
    return {"total_users":total_users,"total_bookings":total_bookings,"confirmed_bookings":confirmed,
            "cancelled_bookings":cancelled,"total_revenue":float(total_revenue or 0),
            "most_popular_place":popular_place[0] if popular_place else "N/A",
            "top_bus_company":top_company[0] if top_company else "N/A"}

def get_all_users(page=1, per_page=20):
    from models import User
    pag = User.query.order_by(User.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)
    return {"users":[u.to_dict() for u in pag.items],"total":pag.total,"pages":pag.pages,"current_page":pag.page}

def get_all_bookings(status=None, page=1, per_page=20):
    from models import Booking
    q = Booking.query
    if status: q = q.filter_by(booking_status=status)
    pag = q.order_by(Booking.booking_date.desc()).paginate(page=page, per_page=per_page, error_out=False)
    return {"bookings":[b.to_dict(detail=True) for b in pag.items],"total":pag.total,"pages":pag.pages,"current_page":pag.page}
