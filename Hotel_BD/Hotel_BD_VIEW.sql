USE hotel_bd;


DROP VIEW IF EXISTS ActiveBookingService;

CREATE VIEW ActiveBookingService AS
SELECT
    b.id_booking,
    bs.id_services,
    b.number_room,
    b.date_check_in,
    b.date_check_out,
    b.status_booking,
    b.total_price AS booking_total_price,
    s.name_services,
    s.description_services,
    s.price_services,
    bs.quantity,
    (bs.quantity * s.price_services) AS subtotal_service_price,
    bs.assigned_staff_id,
    COALESCE(bs.service_task_status, 'assigned') AS service_task_status,
    CASE
        WHEN st.id_Staff IS NOT NULL
        THEN CONCAT(st.last_name_staff, ' ', st.first_name_staff)
        ELSE ''
    END AS assigned_staff_name
FROM Booking_services bs
INNER JOIN Booking b ON bs.id_booking = b.id_booking
INNER JOIN Servicess s ON bs.id_services = s.id_services
LEFT JOIN Staff st ON bs.assigned_staff_id = st.id_Staff
WHERE bs.is_deleted = 0;

/**********************************************************************************/

CREATE VIEW view_client_history AS
SELECT 
    b.id_booking,
    b.id_client,
    r.number_room,
    r.comfort_level,
    b.date_reservation,
    b.total_price,
    GROUP_CONCAT(s.name_services SEPARATOR ', ') AS services_used
FROM booking b
JOIN room r ON b.number_room = r.number_room
LEFT JOIN booking_services bs ON b.id_booking = bs.id_booking
LEFT JOIN servicess s ON bs.id_services = s.id_services
GROUP BY b.id_booking, b.id_client, r.number_room, r.comfort_level, b.date_reservation, b.total_price;

SELECT * FROM view_client_history WHERE id_client = 1;
/**********************************************************************************/

CREATE VIEW vw_booking_services AS
SELECT 
    b.id_booking,                    -- нужен для JOIN и CRUD, но не показываем UI
    bs.id_services,                  -- аналогично
    
    -- Из Booking
    b.number_room,
    b.date_check_in,
    b.date_check_out,
    b.status_booking,
    b.total_price AS booking_total_price,
    
    -- Из Servicess
    s.name_services,
    s.description_services,
    s.price_services,
    
    -- Из Booking_services
    bs.quantity,
    
    -- Вычисляемое поле
    (bs.quantity * s.price_services) AS subtotal_service_price

FROM Booking_services bs
INNER JOIN Booking b ON bs.id_booking = b.id_booking
INNER JOIN Servicess s ON bs.id_services = s.id_services;


/*******************************************************************/

CREATE VIEW vw_Booking AS
SELECT
    -- Бронирование
    b.id_booking,
    b.number_room,
    b.date_reservation,
    b.date_check_in,
    b.date_check_out,
    b.status_booking,
    b.total_price,

    -- Клиент (личные данные)
    CONCAT(c.last_name, ' ', c.first_name, ' ', COALESCE(c.middle_name, '')) AS full_name,
    c.birth_date,
    c.gender,
    c.citizenship,
    c.phone,
    c.email,

    -- Документ (для регистрации по закону)
    c.document_type,
    c.document_number,
    c.document_issued_by,
    c.document_issue_date

FROM Booking b
JOIN Clients c ON b.id_client = c.id_client;

/*******************************************************************/
CREATE VIEW ActiveClients AS
SELECT * FROM Clients WHERE is_deleted = 0;
/*******************************************************************/
CREATE VIEW ActiveRooms AS
SELECT * FROM Room WHERE is_deleted = 0;
/*******************************************************************/
CREATE VIEW ActiveStaff AS
SELECT * FROM Staff WHERE is_deleted = 0;
/*******************************************************************/
CREATE VIEW ActiveServices AS
SELECT * FROM Servicess WHERE is_deleted = 0;
/*******************************************************************/


/*******************************************************************/
CREATE VIEW vw_Report_Bookings AS
SELECT
    id_booking,
    full_name,
    number_room,
    date_reservation,
    date_check_in,
    date_check_out,
    DATEDIFF(date_check_out, date_check_in) AS nights_count,
    status_booking,
    total_price,
    phone,
    email
FROM vw_Booking;
/*******************************************************************/
CREATE VIEW vw_Report_ServiceUsage AS
SELECT
    id_booking,
    id_services,
    number_room,
    date_check_in,
    date_check_out,
    status_booking,
    name_services,
    price_services,
    quantity,
    subtotal_service_price
FROM ActiveBookingService;
/*******************************************************************/ 
CREATE VIEW vw_Report_Maintenance AS
SELECT
    m.id_maintenance,
    m.number_room,
    m.start_date,
    m.end_date,
    DATEDIFF(COALESCE(m.end_date, CURRENT_DATE()), m.start_date) + 1 AS days_in_maintenance,
    CASE WHEN m.end_date IS NULL THEN 'В работе' ELSE 'Завершено' END AS maintenance_status,
    COALESCE(m.reason, '')                                             AS reason,
    m.assigned_staff_id,
    CASE
        WHEN s.id_Staff IS NOT NULL
        THEN CONCAT(s.last_name_staff, ' ', s.first_name_staff)
        ELSE 'Не назначено'
    END AS assigned_staff_name
FROM Maintenance m
LEFT JOIN Staff s ON m.assigned_staff_id = s.id_Staff;
/*******************************************************************/ 

