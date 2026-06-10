from flask import Blueprint, render_template, redirect, url_for, request, flash, abort
from flask_login import login_required, current_user, login_user, logout_user
import services as svc
from models import Place, District, Hotel, RoomType, Schedule, Booking
from database import db

web_bp = Blueprint("web", __name__)

# ── Home ──────────────────────────────────────────────────────
@web_bp.route("/")
def home():
    featured = svc.get_featured_places(6)
    popular  = svc.get_all_places(page=1, per_page=8)["places"]
    categories = svc.get_categories()
    stats = {"places": Place.query.count(), "bookings": Booking.query.count(), "districts": District.query.count()}
    return render_template("home.html", featured=featured, popular=popular, categories=categories, stats=stats)

# ── Auth ──────────────────────────────────────────────────────
@web_bp.route("/register", methods=["GET","POST"])
def register():
    if current_user.is_authenticated: return redirect(url_for("web.home"))
    if request.method == "POST":
        user, err = svc.register_user(request.form.get("full_name",""), request.form.get("email",""), request.form.get("password",""), request.form.get("phone",""))
        if err: flash(err, "error"); return render_template("auth/register.html")
        login_user(user); flash("Welcome to OneReserve!", "success")
        return redirect(url_for("web.home"))
    return render_template("auth/register.html")

@web_bp.route("/login", methods=["GET","POST"])
def login():
    if current_user.is_authenticated: return redirect(url_for("web.home"))
    if request.method == "POST":
        user, err = svc.login_user_service(request.form.get("email",""), request.form.get("password",""))
        if err: flash(err, "error"); return render_template("auth/login.html")
        login_user(user, remember=bool(request.form.get("remember_me")))
        flash(f"Welcome back, {user.full_name}!", "success")
        return redirect(request.args.get("next") or url_for("web.home"))
    return render_template("auth/login.html")

@web_bp.route("/logout")
@login_required
def logout():
    logout_user(); flash("You have been logged out.", "info")
    return redirect(url_for("web.home"))

# ── Destinations ──────────────────────────────────────────────
@web_bp.route("/destinations")
def destinations():
    category    = request.args.get("category","")
    district_id = request.args.get("district_id", type=int)
    search_q    = request.args.get("q","")
    page        = request.args.get("page", 1, type=int)
    if search_q:
        result = svc.search_places(search_q, page=page, per_page=12)
    else:
        result = svc.get_all_places(category=category or None, district_id=district_id, page=page, per_page=12)
    districts  = District.query.order_by(District.district_name).all()
    categories = svc.get_categories()
    return render_template("places/destinations.html", result=result, districts=districts, categories=categories, category=category, district_id=district_id, search_q=search_q)

@web_bp.route("/destinations/<int:place_id>")
def destination_detail(place_id):
    data = svc.get_place_detail(place_id)
    in_wishlist = False
    if current_user.is_authenticated:
        in_wishlist = svc.is_in_wishlist(current_user.user_id, place_id)
    schedules = svc.get_schedules(place_id=place_id, page=1, per_page=10)["schedules"]
    hotels    = svc.get_hotels(place_id=place_id, page=1, per_page=6)["hotels"]
    return render_template("places/detail.html", place=data, schedules=schedules, hotels=hotels, in_wishlist=in_wishlist)

# ── Booking Flow ──────────────────────────────────────────────
@web_bp.route("/book/bus/<int:place_id>")
@login_required
def select_bus(place_id):
    place = Place.query.get_or_404(place_id)
    date_str  = request.args.get("date","")
    bus_type  = request.args.get("bus_type","")
    schedules = svc.get_schedules(place_id=place_id, travel_date=date_str or None, bus_type=bus_type or None, page=1, per_page=30)["schedules"]
    bus_types = ["AC Business Class","AC Premium","AC Sleeper","AC Deluxe","AC Economy","AC Business","Non-AC"]
    return render_template("booking/bus_selection.html", place=place, schedules=schedules, bus_types=bus_types, date_str=date_str, bus_type=bus_type)

@web_bp.route("/book/hotel/<int:schedule_id>")
@login_required
def select_hotel(schedule_id):
    schedule = Schedule.query.get_or_404(schedule_id)
    place    = schedule.place
    checkin  = request.args.get("checkin","")
    checkout = request.args.get("checkout","")
    seats    = request.args.get("seats", 1, type=int)
    hotels   = [h.to_dict(include_rooms=True) for h in Hotel.query.filter_by(place_id=place.place_id, is_active=True).all()]
    return render_template("booking/hotel_selection.html", schedule=schedule, place=place, hotels=hotels, checkin=checkin, checkout=checkout, seats=seats)

@web_bp.route("/book/summary")
@login_required
def booking_summary():
    schedule_id  = request.args.get("schedule_id", type=int)
    room_type_id = request.args.get("room_type_id", type=int)
    checkin      = request.args.get("checkin","")
    checkout     = request.args.get("checkout","")
    seats        = request.args.get("seats", 1, type=int)
    if not schedule_id or seats < 1:
        flash("Incomplete booking details.", "error")
        return redirect(url_for("web.destinations"))
    cost, err = svc.calculate_trip_cost(schedule_id, seats, room_type_id, checkin, checkout)
    if err:
        flash(err, "error")
        return redirect(url_for("web.destinations"))
    schedule = Schedule.query.get(schedule_id)
    room_type = RoomType.query.get(room_type_id) if room_type_id else None
    return render_template("booking/summary.html", schedule=schedule, room_type=room_type, cost=cost, checkin=checkin, checkout=checkout, seats=seats)

@web_bp.route("/book/confirm", methods=["POST"])
@login_required
def confirm_booking():
    schedule_id  = request.form.get("schedule_id", type=int)
    room_type_id = request.form.get("room_type_id", type=int)
    checkin      = request.form.get("checkin","")
    checkout     = request.form.get("checkout","")
    seats        = request.form.get("seats", 1, type=int)
    pay_method   = request.form.get("payment_method","bkash")
    notes        = request.form.get("notes","")
    booking, msg = svc.create_booking(current_user.user_id, schedule_id, seats, room_type_id or None, checkin, checkout, notes)
    if not booking:
        flash(msg, "error")
        args = {"schedule_id": schedule_id, "seats": seats}
        if room_type_id:
            args.update({"room_type_id": room_type_id, "checkin": checkin, "checkout": checkout})
        return redirect(url_for("web.booking_summary", **args))
    payment, pmsg = svc.process_payment(booking.booking_id, pay_method, float(booking.total_amount), user_email=current_user.email)
    if payment:
        flash("Booking confirmed! Have a great trip! 🎉", "success")
    else:
        flash(f"Booking created but payment pending: {pmsg}", "warning")
    return redirect(url_for("web.booking_confirmed", booking_id=booking.booking_id))

@web_bp.route("/book/confirmed/<int:booking_id>")
@login_required
def booking_confirmed(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    if booking.user_id != current_user.user_id: abort(403)
    return render_template("booking/confirmed.html", booking=booking)

# ── My Bookings ───────────────────────────────────────────────
@web_bp.route("/my-bookings")
@login_required
def my_bookings():
    page   = request.args.get("page", 1, type=int)
    result = svc.get_user_bookings(current_user.user_id, page=page)
    return render_template("user/bookings.html", result=result)

@web_bp.route("/my-bookings/<int:booking_id>/cancel", methods=["POST"])
@login_required
def cancel_booking_web(booking_id):
    ok, msg = svc.cancel_booking(booking_id, current_user.user_id)
    flash(msg, "success" if ok else "error")
    return redirect(url_for("web.my_bookings"))

# ── Wishlist ──────────────────────────────────────────────────
@web_bp.route("/wishlist")
@login_required
def wishlist():
    items = svc.get_user_wishlist(current_user.user_id)
    return render_template("user/wishlist.html", items=items)

@web_bp.route("/wishlist/toggle/<int:place_id>", methods=["POST"])
@login_required
def toggle_wishlist_web(place_id):
    added, msg = svc.toggle_wishlist(current_user.user_id, place_id)
    flash(msg, "success")
    return redirect(request.form.get("next") or url_for("web.wishlist"))

# ── Profile ───────────────────────────────────────────────────
@web_bp.route("/profile", methods=["GET","POST"])
@login_required
def profile():
    if request.method == "POST":
        action = request.form.get("action","update")
        if action == "update":
            user, err = svc.update_profile(current_user.user_id, request.form.get("full_name",""), request.form.get("phone",""))
            flash(err if err else "Profile updated!", "error" if err else "success")
        elif action == "password":
            ok, msg = svc.change_password(current_user.user_id, request.form.get("current_password",""), request.form.get("new_password",""))
            flash(msg, "success" if ok else "error")
    reviews = svc.get_user_reviews(current_user.user_id)
    return render_template("user/profile.html", reviews=reviews)

# ── Admin ─────────────────────────────────────────────────────
@web_bp.route("/admin")
@login_required
def admin_dashboard():
    from database.db_utils import popular_destination_report, monthly_revenue_report
    stats    = svc.get_dashboard_stats()
    popular  = popular_destination_report()[:8]
    revenue  = monthly_revenue_report(2026)
    bookings = svc.get_all_bookings(page=1, per_page=10)
    users    = svc.get_all_users(page=1, per_page=5)
    return render_template("admin/dashboard.html", stats=stats, popular=popular, revenue=revenue, bookings=bookings, users=users)

@web_bp.route("/admin/bookings")
@login_required
def admin_bookings():
    status = request.args.get("status","")
    page   = request.args.get("page", 1, type=int)
    result = svc.get_all_bookings(status=status or None, page=page, per_page=20)
    return render_template("admin/bookings.html", result=result, status=status)

@web_bp.route("/admin/users")
@login_required
def admin_users():
    page   = request.args.get("page", 1, type=int)
    result = svc.get_all_users(page=page, per_page=20)
    return render_template("admin/users.html", result=result)
