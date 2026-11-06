
/**********Search_Client*****************/
SELECT
    id_client,
    last_name,
    first_name,
    phone,
    email
FROM Clients
WHERE
      last_name LIKE CONCAT(?, '%')
   OR first_name LIKE CONCAT(?, '%')
   OR phone LIKE CONCAT(?, '%')
   OR email LIKE CONCAT(?, '%')
ORDER BY last_name
LIMIT 50;
/**********Search_Client*****************/

/**********Search_Booking*****************/
SELECT
    b.id_booking,
    c.last_name,
    c.first_name,
    b.number_room,
    b.date_check_in,
    b.date_check_out,
    b.status_booking
FROM Booking b
JOIN Clients c ON b.id_client = c.id_client
WHERE
      c.last_name LIKE CONCAT(?, '%')
   OR b.number_room LIKE CONCAT(?, '%')
ORDER BY b.date_check_in DESC
LIMIT 50;
/**********Search_Booking*****************/

/**********Search_Booking_Service*****************/
SELECT
    number_room,
    name_services,
    description_services,
    quantity,
    price_services,
    subtotal_service_price,
    date_check_in,
    date_check_out,
    status_booking,
    booking_total_price
FROM vw_booking_services
WHERE
    number_room LIKE CONCAT(?, '%')
    OR name_services LIKE CONCAT(?, '%')
ORDER BY date_check_in DESC
LIMIT 50;
/**********Search_Booking_Service*****************/

/**********Search_Room*****************/
SELECT
    number_room,
    price_room,
    capacity,
    comfort_level
FROM Room
WHERE status_room='free'
AND capacity >= ?
AND comfort_level = ?
ORDER BY price_room;
/**********Search_Room*****************/

/**********Search_Staff*****************/
SELECT
    id_staff,
    last_name_staff,
    first_name_staff,
    job_title,
    phone
FROM Staff
WHERE
      last_name_staff LIKE CONCAT(?, '%')
   OR phone LIKE CONCAT(?, '%')
   OR job_title LIKE CONCAT(?, '%')
ORDER BY last_name_staff;
/**********Search_Staff*****************/

/**********Search_SERVICES*****************/
SELECT
    id_services,
    name_services,
    price_services
FROM Servicess
WHERE name_services LIKE CONCAT(?, '%')
ORDER BY name_services;

/**********Search_SERVICES*****************/


/**********Search_MAINTENANCE*****************/
SELECT *
FROM Maintenance
WHERE
		number_room LIKE CONCAT(?, '%')
	OR  reason LIKE CONCAT(?, '%')
ORDER BY start_date DESC;
/**********Search_MAINTENANCE*****************/


/*********** MySQL Event Scheduler********/
DELIMITER //
CREATE EVENT update_room_statuses
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_DATE + INTERVAL 1 DAY
DO
BEGIN
    -- ── 1. Освобождаем номера у которых выезд сегодня или раньше ──
    UPDATE Room r
    JOIN Booking b ON b.number_room = r.number_room
    SET r.status_room = 'free'
    WHERE b.date_check_out <= CURRENT_DATE
      AND b.status_booking  = 'reservat'
      AND r.status_room     = 'occupied';

    -- ── 2. Переводим брони в completed ──
    UPDATE Booking
    SET status_booking = 'completed'
    WHERE date_check_out <= CURRENT_DATE
      AND status_booking  = 'reservat';

    -- ── 3. Занимаем номера у которых заезд сегодня ──
    UPDATE Room r
    JOIN Booking b ON b.number_room = r.number_room
    SET r.status_room = 'occupied'
    WHERE b.date_check_in  = CURRENT_DATE
      AND b.status_booking = 'reservat';

    -- ── 4. Закрываем обслуживание у которых end_date наступил ──
    -- Если есть активная бронь — ставим occupied, иначе free
    UPDATE Room r
    JOIN Maintenance m ON m.number_room = r.number_room
    SET r.status_room = CASE
        WHEN EXISTS (
            SELECT 1 FROM Booking b
            WHERE b.number_room    = r.number_room
              AND b.status_booking = 'reservat'
        ) THEN 'occupied'
        ELSE 'free'
    END
    WHERE m.end_date      <= CURRENT_DATE
      AND m.end_date       IS NOT NULL
      AND r.status_room    = 'maintenance';

END //
DELIMITER ;
/*********** MySQL Event Scheduler********/





