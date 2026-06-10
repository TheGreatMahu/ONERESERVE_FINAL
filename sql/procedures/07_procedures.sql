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
