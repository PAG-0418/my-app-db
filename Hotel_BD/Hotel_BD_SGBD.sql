use hotel_bd;

DELIMITER //
CREATE PROCEDURE AddClient (
    IN p_last_name          VARCHAR(100),
    IN p_first_name         VARCHAR(100),
    IN p_middle_name        VARCHAR(100),
    IN p_birth_date         DATE,
    IN p_gender             CHAR(1),
    IN p_citizenship        VARCHAR(100),
    IN p_document_type      VARCHAR(50),
    IN p_document_number    VARCHAR(50),
    IN p_document_issued_by VARCHAR(150),
    IN p_document_issue_date DATE,
    IN p_address            TEXT,
    IN p_phone              VARCHAR(20),
    IN p_email              VARCHAR(100)
)
BEGIN
    DECLARE v_doc_active    INT DEFAULT 0;
    DECLARE v_doc_deleted   INT DEFAULT 0;
    DECLARE v_phone_active  INT DEFAULT 0;
    DECLARE v_email_active  INT DEFAULT 0;

    -- Проверяем активные дубли
    SELECT COUNT(*) INTO v_doc_active
    FROM Clients WHERE document_number = p_document_number AND is_deleted = 0;

    SELECT COUNT(*) INTO v_phone_active
    FROM Clients WHERE phone = p_phone AND is_deleted = 0;

    SELECT COUNT(*) INTO v_email_active
    FROM Clients
    WHERE email = p_email
      AND email IS NOT NULL AND email != ''
      AND is_deleted = 0;

    -- Проверяем удалённую запись по номеру документа
    SELECT COUNT(*) INTO v_doc_deleted
    FROM Clients WHERE document_number = p_document_number AND is_deleted = 1;

    IF v_doc_active > 0 THEN
        SELECT 'Client with this document number already exists.' AS ErrorMessage;

    ELSEIF v_phone_active > 0 THEN
        SELECT 'Client with this phone already exists.' AS ErrorMessage;

    ELSEIF v_email_active > 0 THEN
        SELECT 'Client with this email already exists.' AS ErrorMessage;

    ELSEIF v_doc_deleted > 0 THEN
        -- Восстанавливаем удалённого клиента с новыми данными
        START TRANSACTION;
        UPDATE Clients SET
            last_name           = p_last_name,
            first_name          = p_first_name,
            middle_name         = p_middle_name,
            birth_date          = p_birth_date,
            gender              = p_gender,
            citizenship         = p_citizenship,
            document_type       = p_document_type,
            document_number     = p_document_number,
            document_issued_by  = p_document_issued_by,
            document_issue_date = p_document_issue_date,
            address             = p_address,
            phone               = p_phone,
            email               = p_email,
            is_deleted          = 0,
            deleted_at          = NULL
        WHERE document_number = p_document_number AND is_deleted = 1;
        COMMIT;
        SELECT 'Client successfully restored.' AS Message;

    ELSE
        -- Создаём нового клиента
        START TRANSACTION;
        INSERT INTO Clients (
            last_name, first_name, middle_name, birth_date, gender, citizenship,
            document_type, document_number, document_issued_by, document_issue_date,
            address, phone, email
        )
        VALUES (
            p_last_name, p_first_name, p_middle_name, p_birth_date, p_gender, p_citizenship,
            p_document_type, p_document_number, p_document_issued_by, p_document_issue_date,
            p_address, p_phone, p_email
        );
        COMMIT;
        SELECT 'Client successfully added.' AS Message;
    END IF;

END //
DELIMITER ;

/*******************************************************************/

DELIMITER //
CREATE PROCEDURE AddStaff (
    IN p_last_name_staff    VARCHAR(100),
    IN p_first_name_staff   VARCHAR(100),
    IN p_middle_name_staff  VARCHAR(100),
    IN p_job_title          ENUM('admin','receptionist','cleaner','manager'),
    IN p_phone              VARCHAR(20),
    IN p_home_address       TEXT,
    IN p_login              VARCHAR(100),
    IN p_password_hash      VARCHAR(255)
)
BEGIN
    DECLARE v_phone_active  INT DEFAULT 0;
    DECLARE v_login_active  INT DEFAULT 0;
    DECLARE v_login_deleted INT DEFAULT 0;

    -- Проверяем активные дубли
    SELECT COUNT(*) INTO v_phone_active
    FROM Staff WHERE phone = p_phone AND is_deleted = 0;

    SELECT COUNT(*) INTO v_login_active
    FROM Staff WHERE login = p_login AND is_deleted = 0;

    -- Проверяем удалённую запись по логину
    SELECT COUNT(*) INTO v_login_deleted
    FROM Staff WHERE login = p_login AND is_deleted = 1;

    IF v_phone_active > 0 THEN
        SELECT 'Staff member with this phone already exists.' AS ErrorMessage;

    ELSEIF v_login_active > 0 THEN
        SELECT 'Staff member with this login already exists.' AS ErrorMessage;

    ELSEIF v_login_deleted > 0 THEN
        -- Восстанавливаем удалённого сотрудника с новыми данными
        START TRANSACTION;
        UPDATE Staff SET
            last_name_staff   = p_last_name_staff,
            first_name_staff  = p_first_name_staff,
            middle_name_staff = p_middle_name_staff,
            job_title         = p_job_title,
            phone             = p_phone,
            home_address      = p_home_address,
            password_hash     = p_password_hash,
            is_deleted        = 0,
            deleted_at        = NULL,
            fired_reason      = NULL
        WHERE login = p_login AND is_deleted = 1;
        COMMIT;
        SELECT 'Staff member successfully restored.' AS Message;

    ELSE
        -- Создаём нового сотрудника
        START TRANSACTION;
        INSERT INTO Staff (
            last_name_staff, first_name_staff, middle_name_staff,
            job_title, phone, home_address, login, password_hash
        )
        VALUES (
            p_last_name_staff, p_first_name_staff, p_middle_name_staff,
            p_job_title, p_phone, p_home_address, p_login, p_password_hash
        );
        COMMIT;
        SELECT 'Staff member successfully added.' AS Message;
    END IF;

END //
DELIMITER ;

/*******************************************************************/

DELIMITER //
CREATE PROCEDURE AddRoom (
    IN p_number_room    VARCHAR(10),
    IN p_price_room     DECIMAL(10,2),
    IN p_capacity       SMALLINT,
    IN p_status_room    ENUM('free', 'occupied', 'maintenance'),
    IN p_comfort_level  ENUM('standard', 'deluxe', 'suite')
)
BEGIN
    DECLARE v_room_active   INT DEFAULT 0;
    DECLARE v_room_deleted  INT DEFAULT 0;

    -- Проверяем активную запись
    SELECT COUNT(*) INTO v_room_active
    FROM Room
    WHERE number_room = p_number_room AND is_deleted = 0;

    -- Проверяем удалённую запись
    SELECT COUNT(*) INTO v_room_deleted
    FROM Room
    WHERE number_room = p_number_room AND is_deleted = 1;

    IF v_room_active > 0 THEN
        SELECT 'Room with this number already exists.' AS ErrorMessage;

    ELSEIF p_price_room <= 0 THEN
        SELECT 'Room price must be greater than zero.' AS ErrorMessage;

    ELSEIF p_capacity <= 0 OR p_capacity > 10 THEN
        SELECT 'Room capacity must be between 1 and 10.' AS ErrorMessage;

    ELSEIF v_room_deleted > 0 THEN
        -- Восстанавливаем с новыми данными
        START TRANSACTION;
        UPDATE Room SET
            price_room    = p_price_room,
            capacity      = p_capacity,
            status_room   = p_status_room,
            comfort_level = p_comfort_level,
            is_deleted    = 0,
            deleted_at    = NULL
        WHERE number_room = p_number_room;
        COMMIT;
        SELECT 'Room successfully restored.' AS Message;

    ELSE
        -- Создаём новую
        START TRANSACTION;
        INSERT INTO Room (number_room, price_room, capacity, status_room, comfort_level)
        VALUES (p_number_room, p_price_room, p_capacity, p_status_room, p_comfort_level);
        COMMIT;
        SELECT 'Room successfully added.' AS Message;
    END IF;

END //
DELIMITER ;

/*******************************************************************/
DROP PROCEDURE IF EXISTS AddBooking;

DELIMITER $$

CREATE PROCEDURE AddBooking (
    IN p_document_number VARCHAR(20),
    IN p_room_number VARCHAR(10),
    IN p_date_check_in DATE,
    IN p_date_check_out DATE
)
BEGIN
    DECLARE v_id_client INT DEFAULT NULL;
    DECLARE v_room_price DECIMAL(10,2) DEFAULT NULL;
    DECLARE v_days INT DEFAULT 0;
    DECLARE v_total_price DECIMAL(10,2) DEFAULT 0;
    DECLARE v_room_exists INT DEFAULT 0;
    DECLARE v_maintenance_conflict INT DEFAULT 0;
    DECLARE v_dates_conflict INT DEFAULT 0;

    SELECT id_client INTO v_id_client
    FROM Clients
    WHERE document_number = p_document_number
      AND is_deleted = 0
    LIMIT 1;

    SELECT COUNT(*), MAX(price_room)
    INTO v_room_exists, v_room_price
    FROM Room
    WHERE number_room = p_room_number
      AND is_deleted = 0;

    SELECT COUNT(*)
    INTO v_maintenance_conflict
    FROM Maintenance
    WHERE number_room = p_room_number
      AND p_date_check_in <= COALESCE(end_date, DATE '9999-12-31')
      AND p_date_check_out > start_date;

    SELECT COUNT(*)
    INTO v_dates_conflict
    FROM Booking
    WHERE number_room = p_room_number
      AND status_booking = 'reservat'
      AND p_date_check_in < date_check_out
      AND p_date_check_out > date_check_in;

    IF p_date_check_in IS NULL OR p_date_check_out IS NULL THEN
        SELECT 'Check-in and check-out dates are required.' AS ErrorMessage;

    ELSEIF p_date_check_in >= p_date_check_out THEN
        SELECT 'Check-out date must be after check-in date.' AS ErrorMessage;

    ELSEIF p_date_check_in < CURRENT_DATE THEN
        SELECT 'Check-in date cannot be in the past.' AS ErrorMessage;

    ELSEIF v_id_client IS NULL THEN
        SELECT 'Client with this document number was not found.' AS ErrorMessage;

    ELSEIF v_room_exists = 0 THEN
        SELECT 'Room not found.' AS ErrorMessage;

    ELSEIF v_maintenance_conflict > 0 THEN
        SELECT 'Room has maintenance for the selected dates.' AS ErrorMessage;

    ELSEIF v_dates_conflict > 0 THEN
        SELECT 'Room is already booked for the selected dates.' AS ErrorMessage;

    ELSE
        SET v_days = DATEDIFF(p_date_check_out, p_date_check_in);
        SET v_total_price = v_days * v_room_price;

        START TRANSACTION;

        INSERT INTO Booking (
            id_client,
            number_room,
            date_reservation,
            date_check_in,
            date_check_out,
            status_booking,
            total_price
        )
        VALUES (
            v_id_client,
            p_room_number,
            CURRENT_DATE,
            p_date_check_in,
            p_date_check_out,
            'reservat',
            v_total_price
        );

        UPDATE Room
        SET status_room = 'occupied'
        WHERE number_room = p_room_number
          AND p_date_check_in = CURRENT_DATE;

        COMMIT;

        SELECT
            'Booking successfully created.' AS Message,
            v_total_price AS TotalPrice,
            v_days AS NightsCount;
    END IF;
END$$

DELIMITER ;



/*******************************************************************/
DELIMITER $$
DROP PROCEDURE IF EXISTS AddMaintenance$$
CREATE PROCEDURE AddMaintenance(
    IN p_number_room      VARCHAR(10),
    IN p_start_date       DATE,
    IN p_end_date         DATE,
    IN p_reason           TEXT,
    IN p_assigned_staff_id INT   -- NULL — задача без назначения (для admin/manager)
)
BEGIN
    DECLARE v_room_exists       INT DEFAULT 0;
    DECLARE v_active_bookings   INT DEFAULT 0;
    DECLARE v_active_maint      INT DEFAULT 0;
    DECLARE v_staff_exists      INT DEFAULT 0;
 
    SELECT COUNT(*) INTO v_room_exists
    FROM Room WHERE number_room = p_number_room AND is_deleted = 0;
 
    SELECT COUNT(*) INTO v_active_bookings
    FROM Booking
    WHERE number_room    = p_number_room
      AND status_booking = 'reservat'
      AND p_start_date   < date_check_out
      AND (p_end_date IS NULL OR p_end_date > date_check_in);
 
    SELECT COUNT(*) INTO v_active_maint
    FROM Maintenance
    WHERE number_room = p_number_room AND end_date IS NULL;
 
    IF p_assigned_staff_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_staff_exists
        FROM Staff WHERE id_Staff = p_assigned_staff_id AND is_deleted = 0;
    END IF;
 
    IF v_room_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room not found.';
 
    ELSEIF p_start_date IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Start date is required.';
 
    ELSEIF p_end_date IS NOT NULL AND p_end_date <= p_start_date THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'End date must be after start date.';
 
    ELSEIF v_active_bookings > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Room has active bookings for the selected period.';
 
    ELSEIF v_active_maint > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Room already has an open maintenance record.';
 
    ELSEIF p_assigned_staff_id IS NOT NULL AND v_staff_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assigned staff member not found or is deleted.';
 
    ELSE
        START TRANSACTION;
 
        INSERT INTO Maintenance (number_room, start_date, end_date, reason, assigned_staff_id)
        VALUES (p_number_room, p_start_date, p_end_date, p_reason, p_assigned_staff_id);
 
        UPDATE Room SET status_room = 'maintenance'
        WHERE number_room = p_number_room;
 
        COMMIT;
        SELECT 'Maintenance record successfully added.' AS Message;
    END IF;
END$$
 
/*******************************************************************/

DELIMITER //
CREATE PROCEDURE AddService (
    IN p_name_services          VARCHAR(255),
    IN p_description_services   TEXT,
    IN p_price_services         DECIMAL(10,2)
)
BEGIN
    DECLARE v_name_active   INT DEFAULT 0;
    DECLARE v_name_deleted  INT DEFAULT 0;

    -- Проверяем активные дубли по названию
    SELECT COUNT(*) INTO v_name_active
    FROM Servicess WHERE name_services = p_name_services AND is_deleted = 0;

    -- Проверяем удалённую запись по названию
    SELECT COUNT(*) INTO v_name_deleted
    FROM Servicess WHERE name_services = p_name_services AND is_deleted = 1;

    IF TRIM(p_name_services) = '' OR p_name_services IS NULL THEN
        SELECT 'Service name is required.' AS ErrorMessage;

    ELSEIF p_price_services <= 0 THEN
        SELECT 'Service price must be greater than zero.' AS ErrorMessage;

    ELSEIF v_name_active > 0 THEN
        SELECT 'Service with this name already exists.' AS ErrorMessage;

    ELSEIF v_name_deleted > 0 THEN
        -- Восстанавливаем удалённую услугу с новыми данными
        START TRANSACTION;
        UPDATE Servicess SET
            description_services = p_description_services,
            price_services       = p_price_services,
            is_deleted           = 0,
            deleted_at           = NULL
        WHERE name_services = p_name_services AND is_deleted = 1;
        COMMIT;
        SELECT 'Service successfully restored.' AS Message;

    ELSE
        -- Создаём новую услугу
        START TRANSACTION;
        INSERT INTO Servicess (name_services, description_services, price_services)
        VALUES (p_name_services, p_description_services, p_price_services);
        COMMIT;
        SELECT 'Service successfully added.' AS Message;
    END IF;

END //
DELIMITER ;

/*******************************************************************/
DROP PROCEDURE IF EXISTS AddBookingService;

DELIMITER $$
CREATE PROCEDURE AddBookingService(
    IN p_id_booking        INT,
    IN p_id_services       SMALLINT,
    IN p_quantity          SMALLINT,
    IN p_assigned_staff_id INT
)
BEGIN
    DECLARE v_booking_exists INT DEFAULT 0;
    DECLARE v_service_exists INT DEFAULT 0;
    DECLARE v_already_added  INT DEFAULT 0;
    DECLARE v_staff_exists   INT DEFAULT 0;

    SELECT COUNT(*) INTO v_booking_exists
    FROM Booking WHERE id_booking = p_id_booking AND status_booking = 'reservat';

    SELECT COUNT(*) INTO v_service_exists
    FROM Servicess WHERE id_services = p_id_services AND is_deleted = 0;

    SELECT COUNT(*) INTO v_already_added
    FROM Booking_services
    WHERE id_booking = p_id_booking AND id_services = p_id_services AND is_deleted = 0;

    IF p_assigned_staff_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_staff_exists
        FROM Staff WHERE id_Staff = p_assigned_staff_id AND is_deleted = 0;
    END IF;

    IF v_booking_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Бронирование не найдено или уже завершено.';
    ELSEIF v_service_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Услуга не найдена.';
    ELSEIF v_already_added > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Эта услуга уже добавлена к данному бронированию.';
    ELSEIF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Количество должно быть больше нуля.';
    ELSEIF p_assigned_staff_id IS NOT NULL AND v_staff_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Назначенный сотрудник не найден или удалён.';
    ELSE
        INSERT INTO Booking_services
            (id_booking, id_services, quantity, is_deleted, assigned_staff_id)
        VALUES
            (p_id_booking, p_id_services, p_quantity, 0, p_assigned_staff_id);

        SELECT 'Услуга успешно добавлена к бронированию.' AS Message;
    END IF;
END$$
DELIMITER ;
/*******************************************************************/



DELIMITER //
CREATE PROCEDURE DeleteClient (
    IN p_id_client INT
)
BEGIN
    DECLARE v_client_exists     INT DEFAULT 0;
    DECLARE v_active_bookings   INT DEFAULT 0;

    SELECT COUNT(*) INTO v_client_exists
    FROM Clients 
    WHERE id_client = p_id_client AND is_deleted = 0;

    SELECT COUNT(*) INTO v_active_bookings
    FROM Booking
    WHERE id_client = p_id_client 
      AND status_booking = 'reservat';

    IF v_client_exists = 0 THEN
        SELECT 'Client not found.' AS ErrorMessage;

    ELSEIF v_active_bookings > 0 THEN
        SELECT 'Cannot delete client with active bookings.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        UPDATE Clients 
        SET is_deleted = 1,
            deleted_at = NOW()
        WHERE id_client = p_id_client;

        COMMIT;
        SELECT 'Client successfully deleted.' AS Message;
    END IF;

END //
DELIMITER ;
/*******************************************************************/

DELIMITER //
CREATE PROCEDURE DeleteRoom (
    IN p_number_room VARCHAR(10)
)
BEGIN
    DECLARE v_room_exists       INT DEFAULT 0;
    DECLARE v_active_bookings   INT DEFAULT 0;
    DECLARE v_active_maintenance INT DEFAULT 0;

    SELECT COUNT(*) INTO v_room_exists
    FROM Room 
    WHERE number_room = p_number_room AND is_deleted = 0;

    SELECT COUNT(*) INTO v_active_bookings
    FROM Booking
    WHERE number_room = p_number_room 
      AND status_booking = 'reservat';

    SELECT COUNT(*) INTO v_active_maintenance
    FROM Maintenance
    WHERE number_room = p_number_room
      AND end_date IS NULL;

    IF v_room_exists = 0 THEN
        SELECT 'Room not found.' AS ErrorMessage;

    ELSEIF v_active_bookings > 0 THEN
        SELECT 'Cannot delete room with active bookings.' AS ErrorMessage;

    ELSEIF v_active_maintenance > 0 THEN
        SELECT 'Cannot delete room that is under active maintenance.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        UPDATE Room
        SET is_deleted  = 1,
            deleted_at  = NOW(),
            status_room = 'maintenance'
        WHERE number_room = p_number_room;

        COMMIT;
        SELECT 'Room successfully deleted.' AS Message;
    END IF;

END //
DELIMITER ;
/*******************************************************************/

DELIMITER //
CREATE PROCEDURE DeleteStaff (
    IN p_id_staff   INT
)
BEGIN
    DECLARE v_staff_exists  INT DEFAULT 0;
    DECLARE v_is_last_admin INT DEFAULT 0;
    DECLARE v_job_title     VARCHAR(50) DEFAULT NULL;

    SELECT COUNT(*) INTO v_staff_exists
    FROM Staff
    WHERE id_Staff = p_id_staff AND is_deleted = 0;

    SELECT job_title INTO v_job_title
    FROM Staff
    WHERE id_Staff = p_id_staff;

    -- Проверяем что не удаляем последнего админа
    SELECT COUNT(*) INTO v_is_last_admin
    FROM Staff
    WHERE job_title = 'admin' AND is_deleted = 0;

    IF v_staff_exists = 0 THEN
        SELECT 'Staff member not found.' AS ErrorMessage;

    ELSEIF v_job_title = 'admin' AND v_is_last_admin <= 1 THEN
        SELECT 'Cannot delete the last admin in the system.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        UPDATE Staff
        SET is_deleted   = 1,
            deleted_at   = NOW()
        WHERE id_Staff = p_id_staff;

        COMMIT;
        SELECT 'Staff member successfully deleted.' AS Message;
    END IF;

END //
DELIMITER ;
/*******************************************************************/
DELIMITER //
CREATE PROCEDURE DeleteMaintenance (
    IN p_id_maintenance INT
)
BEGIN
    DECLARE v_maint_exists    INT DEFAULT 0;
    DECLARE v_number_room     VARCHAR(10) DEFAULT NULL;
    DECLARE v_end_date        DATE DEFAULT NULL;
    DECLARE v_active_bookings INT DEFAULT 0;

    SELECT COUNT(*) INTO v_maint_exists
    FROM Maintenance WHERE id_maintenance = p_id_maintenance;

    SELECT number_room, end_date
    INTO v_number_room, v_end_date
    FROM Maintenance WHERE id_maintenance = p_id_maintenance;

    SELECT COUNT(*) INTO v_active_bookings
    FROM Booking
    WHERE number_room    = v_number_room
      AND status_booking = 'reservat';

    IF v_maint_exists = 0 THEN
        SELECT 'Maintenance record not found.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        DELETE FROM Maintenance WHERE id_maintenance = p_id_maintenance;

        -- Восстанавливаем статус комнаты только если обслуживание было открытым
        IF v_end_date IS NULL THEN
            IF v_active_bookings > 0 THEN
                UPDATE Room SET status_room = 'occupied'
                WHERE number_room = v_number_room;
            ELSE
                UPDATE Room SET status_room = 'free'
                WHERE number_room = v_number_room;
            END IF;
        END IF;

        COMMIT;
        SELECT 'Maintenance record successfully deleted.' AS Message;
    END IF;

END //
DELIMITER ;
/*******************************************************************/
DELIMITER //
CREATE PROCEDURE DeleteBookingService (
    IN p_id_booking INT,
    IN p_id_services SMALLINT
)
BEGIN
    DECLARE v_record_exists   INT DEFAULT 0;
    DECLARE v_booking_status  VARCHAR(20) DEFAULT NULL;

    -- Проверяем наличие активной (не удалённой) записи
    SELECT COUNT(*) INTO v_record_exists
    FROM Booking_services
    WHERE id_booking = p_id_booking 
      AND id_services = p_id_services 
      AND is_deleted = 0;

    -- Получаем статус самого бронирования для проверок
    SELECT status_booking INTO v_booking_status
    FROM Booking
    WHERE id_booking = p_id_booking;

    -- Логика проверок и удаления
    IF v_record_exists = 0 THEN
        SELECT 'Service not found in this booking or already deleted.' AS ErrorMessage;

    -- Если используете статусы, отличные от 'reservat', поменяйте условие (например, IN ('completed', 'canceled'))
    ELSEIF v_booking_status != 'reservat' THEN
        SELECT 'Cannot delete service: it belongs to a completed or canceled booking.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        -- Мягкое удаление (Soft Delete)
        UPDATE Booking_services SET
            is_deleted = 1,
            deleted_at = NOW()
        WHERE id_booking = p_id_booking 
          AND id_services = p_id_services;

        COMMIT;
        SELECT 'Booking service successfully deleted.' AS Message;
    END IF;

END //
DELIMITER ;
/*******************************************************************/

/******************************************************************/
DELIMITER //
CREATE PROCEDURE CancelBooking (
    IN p_id_booking INT
)
BEGIN
    DECLARE v_booking_exists  INT DEFAULT 0;
    DECLARE v_status          VARCHAR(20) DEFAULT NULL;
    DECLARE v_room_number     VARCHAR(10) DEFAULT NULL;
    DECLARE v_check_in        DATE DEFAULT NULL;

    -- Запрос 1 — проверяем существование
    SELECT COUNT(*) INTO v_booking_exists
    FROM Booking
    WHERE id_booking = p_id_booking;

    -- Запрос 2 — получаем данные
    SELECT status_booking, number_room, date_check_in
    INTO v_status, v_room_number, v_check_in
    FROM Booking
    WHERE id_booking = p_id_booking;

    IF v_booking_exists = 0 THEN
        SELECT 'Booking not found.' AS ErrorMessage;

    ELSEIF v_status = 'completed' THEN
        SELECT 'Cannot cancel completed booking.' AS ErrorMessage;

    ELSEIF v_status = 'canceled' THEN
        SELECT 'Booking is already canceled.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        UPDATE Booking
        SET status_booking = 'canceled'
        WHERE id_booking = p_id_booking;

        UPDATE Room
        SET status_room = 'free'
        WHERE number_room = v_room_number
          AND v_check_in >= CURRENT_DATE;

        COMMIT;
        SELECT 'Booking successfully canceled.' AS Message;
    END IF;

END //
DELIMITER ;
/******************************************************************/
DELIMITER //
CREATE PROCEDURE DeleteMaintenance (
    IN p_id_maintenance INT
)
BEGIN
    DECLARE v_maint_exists    INT DEFAULT 0;
    DECLARE v_number_room     VARCHAR(10) DEFAULT NULL;
    DECLARE v_active_bookings INT DEFAULT 0;

    SELECT COUNT(*) INTO v_maint_exists
    FROM Maintenance WHERE id_maintenance = p_id_maintenance;

    SELECT number_room INTO v_number_room
    FROM Maintenance WHERE id_maintenance = p_id_maintenance;

    SELECT COUNT(*) INTO v_active_bookings
    FROM Booking
    WHERE number_room    = v_number_room
      AND status_booking = 'reservat';

    IF v_maint_exists = 0 THEN
        SELECT 'Maintenance record not found.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        DELETE FROM Maintenance
        WHERE id_maintenance = p_id_maintenance;

        -- Всегда обновляем статус комнаты после удаления
        IF v_active_bookings > 0 THEN
            UPDATE Room SET status_room = 'occupied'
            WHERE number_room = v_number_room;
        ELSE
            UPDATE Room SET status_room = 'free'
            WHERE number_room = v_number_room;
        END IF;

        COMMIT;
        SELECT 'Maintenance record successfully deleted.' AS Message;
    END IF;

END //
DELIMITER ;
/******************************************************************/

DELIMITER //

CREATE PROCEDURE UpdateClient (
    IN p_id_client            INT,
    IN p_last_name            VARCHAR(100),
    IN p_first_name           VARCHAR(100),
    IN p_middle_name          VARCHAR(100),
    IN p_birth_date           DATE,
    IN p_gender               CHAR(1),
    IN p_citizenship          VARCHAR(100),
    IN p_document_type        VARCHAR(50),
    IN p_document_number      VARCHAR(50),
    IN p_document_issued_by   VARCHAR(150),
    IN p_document_issue_date  DATE,
    IN p_address              TEXT,
    IN p_phone                VARCHAR(20),
    IN p_email                VARCHAR(100)
)
BEGIN
    DECLARE v_client_exists INT DEFAULT 0;
    DECLARE v_doc_exists INT DEFAULT 0;
    DECLARE v_phone_exists INT DEFAULT 0;
    DECLARE v_email_exists INT DEFAULT 0;

    DECLARE v_email_normalized VARCHAR(100);
    DECLARE v_middle_name_normalized VARCHAR(100);
    DECLARE v_document_issued_by_normalized VARCHAR(150);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Database error while updating client.' AS ErrorMessage;
    END;

    SET v_email_normalized =
        CASE
            WHEN p_email IS NULL OR TRIM(p_email) = '' THEN NULL
            ELSE TRIM(p_email)
        END;

    SET v_middle_name_normalized =
        CASE
            WHEN p_middle_name IS NULL OR TRIM(p_middle_name) = '' THEN NULL
            ELSE TRIM(p_middle_name)
        END;

    SET v_document_issued_by_normalized =
        CASE
            WHEN p_document_issued_by IS NULL OR TRIM(p_document_issued_by) = '' THEN NULL
            ELSE TRIM(p_document_issued_by)
        END;

    SELECT COUNT(*)
      INTO v_client_exists
    FROM Clients
    WHERE id_client = p_id_client
      AND is_deleted = 0;

    SELECT COUNT(*)
      INTO v_doc_exists
    FROM Clients
    WHERE document_number = p_document_number
      AND id_client <> p_id_client
      AND is_deleted = 0;

    SELECT COUNT(*)
      INTO v_phone_exists
    FROM Clients
    WHERE phone = p_phone
      AND id_client <> p_id_client
      AND is_deleted = 0;

    IF v_email_normalized IS NOT NULL THEN
        SELECT COUNT(*)
          INTO v_email_exists
        FROM Clients
        WHERE email = v_email_normalized
          AND id_client <> p_id_client
          AND is_deleted = 0;
    ELSE
        SET v_email_exists = 0;
    END IF;

    IF v_client_exists = 0 THEN
        SELECT 'Client not found.' AS ErrorMessage;

    ELSEIF v_doc_exists > 0 THEN
        SELECT 'Client with this document number already exists.' AS ErrorMessage;

    ELSEIF v_phone_exists > 0 THEN
        SELECT 'Client with this phone already exists.' AS ErrorMessage;

    ELSEIF v_email_exists > 0 THEN
        SELECT 'Client with this email already exists.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        UPDATE Clients
        SET last_name = p_last_name,
            first_name = p_first_name,
            middle_name = v_middle_name_normalized,
            birth_date = p_birth_date,
            gender = p_gender,
            citizenship = p_citizenship,
            document_type = p_document_type,
            document_number = p_document_number,
            document_issued_by = v_document_issued_by_normalized,
            document_issue_date = p_document_issue_date,
            address = p_address,
            phone = p_phone,
            email = v_email_normalized
        WHERE id_client = p_id_client
          AND is_deleted = 0;

        COMMIT;

        SELECT 'Client successfully updated.' AS Message;
    END IF;
END //

DELIMITER ;

/******************************************************************/
DELIMITER $$

CREATE PROCEDURE UpdateBooking (
    IN p_id_booking INT,
    IN p_date_check_in DATE,
    IN p_date_check_out DATE
)
BEGIN
    DECLARE v_status VARCHAR(20) DEFAULT NULL;
    DECLARE v_room_number VARCHAR(10) DEFAULT NULL;
    DECLARE v_room_price DECIMAL(10,2) DEFAULT 0;
    DECLARE v_days INT DEFAULT 0;
    DECLARE v_total_price DECIMAL(10,2) DEFAULT 0;
    DECLARE v_dates_conflict INT DEFAULT 0;
    DECLARE v_maintenance_conflict INT DEFAULT 0;

    SELECT status_booking, number_room
    INTO v_status, v_room_number
    FROM Booking
    WHERE id_booking = p_id_booking;

    IF v_room_number IS NOT NULL THEN
        SELECT price_room
        INTO v_room_price
        FROM Room
        WHERE number_room = v_room_number
        LIMIT 1;

        SELECT COUNT(*)
        INTO v_dates_conflict
        FROM Booking
        WHERE number_room = v_room_number
          AND id_booking <> p_id_booking
          AND status_booking = 'reservat'
          AND p_date_check_in < date_check_out
          AND p_date_check_out > date_check_in;

        SELECT COUNT(*)
        INTO v_maintenance_conflict
        FROM Maintenance
        WHERE number_room = v_room_number
          AND p_date_check_in <= COALESCE(end_date, DATE '9999-12-31')
          AND p_date_check_out > start_date;
    END IF;

    IF v_room_number IS NULL THEN
        SELECT 'Booking not found.' AS ErrorMessage;

    ELSEIF v_status != 'reservat' THEN
        SELECT 'Only active bookings can be updated.' AS ErrorMessage;

    ELSEIF p_date_check_in IS NULL OR p_date_check_out IS NULL THEN
        SELECT 'Check-in and check-out dates are required.' AS ErrorMessage;

    ELSEIF p_date_check_in >= p_date_check_out THEN
        SELECT 'Check-out date must be after check-in date.' AS ErrorMessage;

    ELSEIF p_date_check_in < CURRENT_DATE THEN
        SELECT 'Check-in date cannot be in the past.' AS ErrorMessage;

    ELSEIF v_dates_conflict > 0 THEN
        SELECT 'Room is already booked for the selected dates.' AS ErrorMessage;

    ELSEIF v_maintenance_conflict > 0 THEN
        SELECT 'Room has maintenance for the selected dates.' AS ErrorMessage;

    ELSE
        SET v_days = DATEDIFF(p_date_check_out, p_date_check_in);
        SET v_total_price = v_days * v_room_price;

        UPDATE Booking
        SET date_check_in = p_date_check_in,
            date_check_out = p_date_check_out,
            total_price = v_total_price
        WHERE id_booking = p_id_booking;

        SELECT
            'Booking successfully updated.' AS Message,
            v_total_price AS TotalPrice,
            v_days AS NightsCount;
    END IF;
END$$

DELIMITER ;
/******************************************************************/
DELIMITER //
CREATE PROCEDURE UpdateRoom (
    IN p_number_room    VARCHAR(10),
    IN p_price_room     DECIMAL(10,2),
    IN p_capacity       SMALLINT,
    IN p_status_room    ENUM('free', 'occupied', 'maintenance'),
    IN p_comfort_level  ENUM('standard', 'deluxe', 'suite')
)
BEGIN
    DECLARE v_room_exists       INT DEFAULT 0;
    DECLARE v_active_bookings   INT DEFAULT 0;

    SELECT COUNT(*) INTO v_room_exists
    FROM Room
    WHERE number_room = p_number_room AND is_deleted = 0;

    SELECT COUNT(*) INTO v_active_bookings
    FROM Booking
    WHERE number_room = p_number_room
      AND status_booking = 'reservat';

    IF v_room_exists = 0 THEN
        SELECT 'Room not found.' AS ErrorMessage;

    ELSEIF p_price_room <= 0 THEN
        SELECT 'Room price must be greater than zero.' AS ErrorMessage;

    ELSEIF p_capacity <= 0 THEN
        SELECT 'Room capacity must be greater than zero.' AS ErrorMessage;

    ELSEIF p_capacity > 10 THEN
        SELECT 'Room capacity cannot exceed 10.' AS ErrorMessage;

    -- Нельзя поставить статус free/maintenance если есть активная бронь
    ELSEIF v_active_bookings > 0 AND p_status_room != 'occupied' THEN
        SELECT 'Cannot change status: room has active bookings.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        UPDATE Room SET
            price_room    = p_price_room,
            capacity      = p_capacity,
            status_room   = p_status_room,
            comfort_level = p_comfort_level
        WHERE number_room = p_number_room;

        COMMIT;
        SELECT 'Room successfully updated.' AS Message;
    END IF;

END //
DELIMITER ;
/*******************************************************************/

DELIMITER //
CREATE PROCEDURE UpdateStaff (
    IN p_id_staff           INT,
    IN p_last_name_staff    VARCHAR(100),
    IN p_first_name_staff   VARCHAR(100),
    IN p_middle_name_staff  VARCHAR(100),
    IN p_job_title          ENUM('admin', 'receptionist', 'cleaner', 'manager'),
    IN p_phone              VARCHAR(20),
    IN p_home_address       TEXT,
    IN p_login              VARCHAR(100)
)
BEGIN
    DECLARE v_staff_exists    INT DEFAULT 0;
    DECLARE v_phone_exists    INT DEFAULT 0;
    DECLARE v_login_exists    INT DEFAULT 0;
    DECLARE v_current_role    VARCHAR(20) DEFAULT NULL;
    DECLARE v_admin_count     INT DEFAULT 0;

    SELECT COUNT(*) INTO v_staff_exists
    FROM Staff
    WHERE id_Staff = p_id_staff AND is_deleted = 0;

    -- Проверяем дубли исключая самого сотрудника
    SELECT COUNT(*) INTO v_phone_exists
    FROM Staff
    WHERE phone = p_phone
      AND id_Staff != p_id_staff
      AND is_deleted = 0;

    SELECT COUNT(*) INTO v_login_exists
    FROM Staff
    WHERE login = p_login
      AND id_Staff != p_id_staff
      AND is_deleted = 0;

    -- Текущая должность сотрудника
    SELECT job_title INTO v_current_role
    FROM Staff
    WHERE id_Staff = p_id_staff;

    -- Количество активных админов
    SELECT COUNT(*) INTO v_admin_count
    FROM Staff
    WHERE job_title = 'admin' AND is_deleted = 0;

    IF v_staff_exists = 0 THEN
        SELECT 'Staff member not found.' AS ErrorMessage;

    ELSEIF v_phone_exists > 0 THEN
        SELECT 'Staff member with this phone already exists.' AS ErrorMessage;

    ELSEIF v_login_exists > 0 THEN
        SELECT 'Staff member with this login already exists.' AS ErrorMessage;

    -- Нельзя снять роль admin если он последний
    ELSEIF v_current_role = 'admin' AND p_job_title != 'admin' AND v_admin_count <= 1 THEN
        SELECT 'Cannot change role: this is the last admin in the system.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        UPDATE Staff SET
            last_name_staff   = p_last_name_staff,
            first_name_staff  = p_first_name_staff,
            middle_name_staff = p_middle_name_staff,
            job_title         = p_job_title,
            phone             = p_phone,
            home_address      = p_home_address,
            login             = p_login
        WHERE id_Staff = p_id_staff;

        COMMIT;
        SELECT 'Staff member successfully updated.' AS Message;
    END IF;

END //
DELIMITER ;
/*******************************************************************/

DELIMITER //
CREATE PROCEDURE UpdateService (
    IN p_id_services            SMALLINT,
    IN p_name_services          VARCHAR(255),
    IN p_description_services   TEXT,
    IN p_price_services         DECIMAL(10,2)
)
BEGIN
    DECLARE v_service_exists    INT DEFAULT 0;
    DECLARE v_name_exists       INT DEFAULT 0;

    SELECT COUNT(*) INTO v_service_exists
    FROM Servicess
    WHERE id_services = p_id_services;

    -- Проверяем дубль названия исключая саму услугу
    SELECT COUNT(*) INTO v_name_exists
    FROM Servicess
    WHERE name_services = p_name_services
      AND id_services != p_id_services;

    IF v_service_exists = 0 THEN
        SELECT 'Service not found.' AS ErrorMessage;

    ELSEIF TRIM(p_name_services) = '' OR p_name_services IS NULL THEN
        SELECT 'Service name is required.' AS ErrorMessage;

    ELSEIF v_name_exists > 0 THEN
        SELECT 'Service with this name already exists.' AS ErrorMessage;

    ELSEIF p_price_services <= 0 THEN
        SELECT 'Service price must be greater than zero.' AS ErrorMessage;

    ELSE
        START TRANSACTION;

        UPDATE Servicess SET
            name_services        = p_name_services,
            description_services = p_description_services,
            price_services       = p_price_services
        WHERE id_services = p_id_services;

        COMMIT;
        SELECT 'Service successfully updated.' AS Message;
    END IF;

END //
DELIMITER ;
/*******************************************************************/

/********************************************************************/
DELIMITER //
CREATE PROCEDURE UpdateBooking (
    IN p_id_booking      INT,
    IN p_date_check_in   DATE,
    IN p_date_check_out  DATE
)
BEGIN
    DECLARE v_booking_exists  INT DEFAULT 0;
    DECLARE v_status          VARCHAR(20) DEFAULT NULL;
    DECLARE v_room_number     VARCHAR(10) DEFAULT NULL;
    DECLARE v_room_price      DECIMAL(10,2) DEFAULT 0;
    DECLARE v_days            INT DEFAULT 0;
    DECLARE v_total_price     DECIMAL(10,2) DEFAULT 0;
    DECLARE v_dates_conflict  INT DEFAULT 0;

    -- Запрос 1 — проверяем существование
    SELECT COUNT(*) INTO v_booking_exists
    FROM Booking
    WHERE id_booking = p_id_booking;

    -- Запрос 2 — получаем данные брони
    SELECT status_booking, number_room
    INTO v_status, v_room_number
    FROM Booking
    WHERE id_booking = p_id_booking;

    -- Запрос 3 — цена номера
    SELECT price_room INTO v_room_price
    FROM Room WHERE number_room = v_room_number;

    -- Запрос 4 — пересечение дат
    SELECT COUNT(*) INTO v_dates_conflict
    FROM Booking
    WHERE number_room     = v_room_number
      AND id_booking     != p_id_booking
      AND status_booking  = 'reservat'
      AND p_date_check_in  < date_check_out
      AND p_date_check_out > date_check_in;

    IF v_booking_exists = 0 THEN
        SELECT 'Booking not found.' AS ErrorMessage;

    ELSEIF v_status != 'reservat' THEN
        SELECT 'Only active bookings can be edited.' AS ErrorMessage;

    ELSEIF p_date_check_in >= p_date_check_out THEN
        SELECT 'Check-out date must be after check-in date.' AS ErrorMessage;

    ELSEIF p_date_check_in < CURRENT_DATE THEN
        SELECT 'Check-in date cannot be in the past.' AS ErrorMessage;

    ELSEIF v_dates_conflict > 0 THEN
        SELECT 'Room is already booked for the selected dates.' AS ErrorMessage;

    ELSE
        SET v_days        = DATEDIFF(p_date_check_out, p_date_check_in);
        SET v_total_price = v_days * v_room_price;

        START TRANSACTION;

        UPDATE Booking SET
            date_check_in  = p_date_check_in,
            date_check_out = p_date_check_out,
            total_price    = v_total_price
        WHERE id_booking = p_id_booking;

        COMMIT;

        SELECT 'Booking successfully updated.' AS Message,
               v_total_price                  AS TotalPrice,
               v_days                         AS NightsCount;
    END IF;

END //
DELIMITER ;
/********************************************************************/
DELIMITER $$

CREATE PROCEDURE sp_User_GetForAuthentication(IN p_username VARCHAR(255))
BEGIN
    SELECT
        u.id_user,
        u.username,
        u.password_hash,
        u.role,
        u.last_login,
        u.id_staff,
        CASE
            WHEN s.id_Staff IS NOT NULL
            THEN CONCAT(s.last_name_staff, ' ', s.first_name_staff)
            ELSE ''
        END AS staff_full_name
    FROM users u
    LEFT JOIN Staff s ON u.id_staff = s.id_Staff
    WHERE LOWER(u.username) = LOWER(p_username)
    LIMIT 1;
END$$

DROP PROCEDURE IF EXISTS sp_User_Create;
DELIMITER $$

CREATE PROCEDURE sp_User_Create(
    IN p_username      VARCHAR(100),
    IN p_password_hash VARCHAR(255),
    IN p_role          ENUM('admin', 'manager', 'receptionist', 'housekeeper', 'technician'),
    IN p_id_staff      INT
)
BEGIN
    DECLARE v_username_exists INT DEFAULT 0;
    DECLARE v_staff_exists INT DEFAULT 0;
    DECLARE v_staff_job VARCHAR(50) DEFAULT NULL;
    DECLARE v_staff_has_user INT DEFAULT 0;
    DECLARE v_required_job VARCHAR(50) DEFAULT NULL;

    SET v_required_job = CASE
        WHEN p_role = 'admin' THEN 'admin'
        WHEN p_role = 'manager' THEN 'manager'
        WHEN p_role = 'receptionist' THEN 'receptionist'
        WHEN p_role IN ('housekeeper', 'technician') THEN 'cleaner'
        ELSE NULL
    END;

    SELECT COUNT(*) INTO v_username_exists
    FROM users
    WHERE LOWER(username) = LOWER(p_username);

    IF p_id_staff IS NOT NULL THEN
        SELECT COUNT(*), MAX(job_title)
        INTO v_staff_exists, v_staff_job
        FROM Staff
        WHERE id_Staff = p_id_staff
          AND is_deleted = 0;

        SELECT COUNT(*) INTO v_staff_has_user
        FROM users
        WHERE id_staff = p_id_staff;
    END IF;

    IF v_username_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Пользователь с таким логином уже существует.';
    ELSEIF p_id_staff IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Выберите сотрудника для этой роли.';
    ELSEIF v_staff_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Сотрудник не найден или удалён.';
    ELSEIF v_staff_job <> v_required_job THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Выбранный сотрудник не соответствует роли пользователя.';
    ELSEIF v_staff_has_user > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'У выбранного сотрудника уже есть аккаунт.';
    ELSE
        INSERT INTO users (username, password_hash, role, id_staff)
        VALUES (p_username, p_password_hash, p_role, p_id_staff);

        SELECT LAST_INSERT_ID() AS id_user;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_User_UpdateRole(
    IN p_id_user  INT,
    IN p_new_role ENUM('admin', 'manager', 'receptionist', 'housekeeper', 'technician'),
    IN p_id_staff INT
)
BEGIN
    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_old_role VARCHAR(50) DEFAULT NULL;
    DECLARE v_admin_count INT DEFAULT 0;
    DECLARE v_staff_exists INT DEFAULT 0;
    DECLARE v_staff_job VARCHAR(50) DEFAULT NULL;
    DECLARE v_staff_has_other_user INT DEFAULT 0;
    DECLARE v_required_job VARCHAR(50) DEFAULT NULL;

    SET v_required_job = CASE
        WHEN p_new_role = 'admin' THEN 'admin'
        WHEN p_new_role = 'manager' THEN 'manager'
        WHEN p_new_role = 'receptionist' THEN 'receptionist'
        WHEN p_new_role IN ('housekeeper', 'technician') THEN 'cleaner'
        ELSE NULL
    END;

    SELECT COUNT(*), MAX(role)
    INTO v_user_exists, v_old_role
    FROM users
    WHERE id_user = p_id_user;

    SELECT COUNT(*) INTO v_admin_count
    FROM users
    WHERE role = 'admin';

    IF p_id_staff IS NOT NULL THEN
        SELECT COUNT(*), MAX(job_title)
        INTO v_staff_exists, v_staff_job
        FROM Staff
        WHERE id_Staff = p_id_staff
          AND is_deleted = 0;

        SELECT COUNT(*) INTO v_staff_has_other_user
        FROM users
        WHERE id_staff = p_id_staff
          AND id_user <> p_id_user;
    END IF;

    IF v_user_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Пользователь не найден.';
    ELSEIF v_old_role = 'admin' AND p_new_role <> 'admin' AND v_admin_count <= 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Нельзя понизить последнего администратора.';
    ELSEIF p_id_staff IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Выберите сотрудника для этой роли.';
    ELSEIF v_staff_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Сотрудник не найден или удалён.';
    ELSEIF v_staff_job <> v_required_job THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Выбранный сотрудник не соответствует роли пользователя.';
    ELSEIF v_staff_has_other_user > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'У выбранного сотрудника уже есть аккаунт.';
    ELSE
        UPDATE users
        SET role = p_new_role,
            id_staff = p_id_staff
        WHERE id_user = p_id_user;

        SELECT 'Роль пользователя обновлена.' AS Message;
    END IF;
END$$

DELIMITER ;


DELIMITER ;

DROP PROCEDURE IF EXISTS sp_Maintenance_SearchByStaff;

DELIMITER $$

CREATE PROCEDURE sp_Maintenance_SearchByStaff(
    IN p_id_staff INT,
    IN p_search VARCHAR(255)
)
BEGIN
    SELECT
        m.id_maintenance,
        m.number_room,
        m.start_date,
        m.end_date,
        m.reason,
        m.assigned_staff_id,
        COALESCE(m.maintenance_task_status, 'assigned') AS maintenance_task_status,
        CASE
            WHEN s.id_Staff IS NOT NULL
            THEN CONCAT(s.last_name_staff, ' ', s.first_name_staff)
            ELSE ''
        END AS assigned_staff_name
    FROM Maintenance m
    LEFT JOIN Staff s ON m.assigned_staff_id = s.id_Staff
    WHERE m.assigned_staff_id = p_id_staff
      AND (
          m.number_room LIKE CONCAT(p_search, '%')
          OR m.reason LIKE CONCAT(p_search, '%')
          OR COALESCE(m.maintenance_task_status, 'assigned') LIKE CONCAT(p_search, '%')
      )
    ORDER BY m.start_date DESC, m.id_maintenance DESC;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_Maintenance_Search(IN p_search VARCHAR(255))
BEGIN
    SELECT
        m.id_maintenance,
        m.number_room,
        m.start_date,
        m.end_date,
        m.reason,
        m.assigned_staff_id,
        COALESCE(m.maintenance_task_status, 'assigned') AS maintenance_task_status,
        CASE
            WHEN s.id_Staff IS NOT NULL
            THEN CONCAT(s.last_name_staff, ' ', s.first_name_staff)
            ELSE ''
        END AS assigned_staff_name
    FROM Maintenance m
    LEFT JOIN Staff s ON m.assigned_staff_id = s.id_Staff
    WHERE m.number_room LIKE CONCAT(p_search, '%')
       OR m.reason LIKE CONCAT(p_search, '%')
       OR COALESCE(m.maintenance_task_status, 'assigned') LIKE CONCAT(p_search, '%')
       OR CONCAT(s.last_name_staff, ' ', s.first_name_staff) LIKE CONCAT(p_search, '%')
    ORDER BY m.start_date DESC, m.id_maintenance DESC;
END$$

DELIMITER ;
DROP PROCEDURE IF EXISTS sp_Dashboard_GetSummary;
DELIMITER $$

CREATE PROCEDURE sp_Dashboard_GetSummary(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(50),
    IN p_comfort VARCHAR(50)
)
BEGIN
    WITH booking_amounts AS (
        SELECT
            b.id_booking,
            b.status_booking,
            b.total_price + COALESCE(bs.services_total, 0) AS total_amount
        FROM Booking b
        JOIN Room r ON b.number_room = r.number_room
        LEFT JOIN (
            SELECT id_booking, SUM(subtotal_service_price) AS services_total
            FROM ActiveBookingService
            GROUP BY id_booking
        ) bs ON bs.id_booking = b.id_booking
        WHERE b.date_check_in >= p_date_from
          AND b.date_check_in < DATE_ADD(p_date_to, INTERVAL 1 DAY)
          AND (p_status IS NULL OR b.status_booking = p_status)
          AND (p_comfort IS NULL OR r.comfort_level = p_comfort)
    ),
    room_totals AS (
        SELECT COUNT(*) AS total_rooms
        FROM Room
        WHERE is_deleted = 0
          AND (p_comfort IS NULL OR comfort_level = p_comfort)
    ),
    occupied AS (
        SELECT COUNT(DISTINCT b.number_room) AS occupied_rooms
        FROM Booking b
        JOIN Room r ON b.number_room = r.number_room
        WHERE b.date_check_in <= p_date_to
          AND b.date_check_out > p_date_from
          AND b.status_booking <> 'canceled'
          AND (p_status IS NULL OR b.status_booking = p_status)
          AND (p_comfort IS NULL OR r.comfort_level = p_comfort)
    ),
    maintenance_rooms AS (
        SELECT COUNT(DISTINCT m.number_room) AS maintenance_rooms
        FROM Maintenance m
        JOIN Room r ON m.number_room = r.number_room
        WHERE m.start_date <= p_date_to
          AND COALESCE(m.end_date, '9999-12-31') >= p_date_from
          AND r.is_deleted = 0
          AND (p_comfort IS NULL OR r.comfort_level = p_comfort)
    )
    SELECT
        COALESCE(SUM(CASE WHEN ba.status_booking <> 'canceled' THEN ba.total_amount ELSE 0 END), 0) AS total_revenue,
        COUNT(ba.id_booking) AS total_bookings,
        COALESCE(AVG(CASE WHEN ba.status_booking <> 'canceled' THEN ba.total_amount END), 0) AS avg_price,
        COALESCE(MIN(CASE WHEN ba.status_booking <> 'canceled' THEN ba.total_amount END), 0) AS min_price,
        COALESCE(MAX(CASE WHEN ba.status_booking <> 'canceled' THEN ba.total_amount END), 0) AS max_price,
        COALESCE(SUM(CASE WHEN ba.status_booking = 'reservat' THEN 1 ELSE 0 END), 0) AS active_bookings,
        GREATEST(rt.total_rooms - o.occupied_rooms - m.maintenance_rooms, 0) AS free_rooms,
        o.occupied_rooms,
        m.maintenance_rooms
    FROM room_totals rt
    CROSS JOIN occupied o
    CROSS JOIN maintenance_rooms m
    LEFT JOIN booking_amounts ba ON TRUE
    GROUP BY rt.total_rooms, o.occupied_rooms, m.maintenance_rooms;
END$$

DELIMITER ;


DELIMITER $$ 




DROP PROCEDURE IF EXISTS sp_Dashboard_GetRevenueByMonth;
DELIMITER $$

CREATE PROCEDURE sp_Dashboard_GetRevenueByMonth(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(50),
    IN p_comfort VARCHAR(50)
)
BEGIN
    SELECT
        DATE_FORMAT(b.date_check_in, '%Y-%m') AS label,
        COALESCE(SUM(b.total_price + COALESCE(bs.services_total, 0)), 0) AS value
    FROM Booking b
    JOIN Room r ON b.number_room = r.number_room
    LEFT JOIN (
        SELECT id_booking, SUM(subtotal_service_price) AS services_total
        FROM ActiveBookingService
        GROUP BY id_booking
    ) bs ON bs.id_booking = b.id_booking
    WHERE b.date_check_in >= p_date_from
      AND b.date_check_in < DATE_ADD(p_date_to, INTERVAL 1 DAY)
      AND b.status_booking <> 'canceled'
      AND (p_status IS NULL OR b.status_booking = p_status)
      AND (p_comfort IS NULL OR r.comfort_level = p_comfort)
    GROUP BY DATE_FORMAT(b.date_check_in, '%Y-%m')
    ORDER BY label;
END$$

DELIMITER ;


DROP PROCEDURE IF EXISTS sp_Dashboard_GetBookings;
DELIMITER $$

CREATE PROCEDURE sp_Dashboard_GetBookings(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(50),
    IN p_comfort VARCHAR(50),
    IN p_client VARCHAR(255)
)
BEGIN
    SELECT
        b.id_booking,
        b.number_room,
        r.comfort_level,
        CONCAT_WS(' ', c.last_name, c.first_name, NULLIF(c.middle_name, '')) AS full_name,
        b.date_check_in,
        b.date_check_out,
        DATEDIFF(b.date_check_out, b.date_check_in) AS nights_count,
        b.total_price,
        COALESCE(bs.services_total, 0) AS services_total,
        b.total_price + COALESCE(bs.services_total, 0) AS total_amount,
        b.status_booking
    FROM Booking b
    JOIN Clients c ON b.id_client = c.id_client
    JOIN Room r ON b.number_room = r.number_room
    LEFT JOIN (
        SELECT id_booking, SUM(subtotal_service_price) AS services_total
        FROM ActiveBookingService
        GROUP BY id_booking
    ) bs ON bs.id_booking = b.id_booking
    WHERE b.date_check_in >= p_date_from
      AND b.date_check_in < DATE_ADD(p_date_to, INTERVAL 1 DAY)
      AND (p_status IS NULL OR b.status_booking = p_status)
      AND (p_comfort IS NULL OR r.comfort_level = p_comfort)
      AND (
          p_client IS NULL
          OR TRIM(p_client) = ''
          OR c.last_name LIKE CONCAT('%', TRIM(p_client), '%')
          OR c.first_name LIKE CONCAT('%', TRIM(p_client), '%')
          OR COALESCE(c.middle_name, '') LIKE CONCAT('%', TRIM(p_client), '%')
          OR CONCAT_WS(' ', c.last_name, c.first_name, NULLIF(c.middle_name, '')) LIKE CONCAT('%', TRIM(p_client), '%')
      )
    ORDER BY b.date_check_in DESC, b.id_booking DESC;
END$$

DROP PROCEDURE IF EXISTS sp_Dashboard_GetRevenueByComfort;
DELIMITER $$

CREATE PROCEDURE sp_Dashboard_GetRevenueByComfort(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(50),
    IN p_comfort VARCHAR(50)
)
BEGIN
    SELECT
        r.comfort_level AS label,
        COALESCE(SUM(b.total_price + COALESCE(bs.services_total, 0)), 0) AS value
    FROM Room r
    LEFT JOIN Booking b ON b.number_room = r.number_room
      AND b.date_check_in >= p_date_from
      AND b.date_check_in < DATE_ADD(p_date_to, INTERVAL 1 DAY)
      AND b.status_booking <> 'canceled'
      AND (p_status IS NULL OR b.status_booking = p_status)
    LEFT JOIN (
        SELECT id_booking, SUM(subtotal_service_price) AS services_total
        FROM ActiveBookingService
        GROUP BY id_booking
    ) bs ON bs.id_booking = b.id_booking
    WHERE r.is_deleted = 0
      AND (p_comfort IS NULL OR r.comfort_level = p_comfort)
    GROUP BY r.comfort_level
    ORDER BY value DESC;
END$$

DROP PROCEDURE IF EXISTS sp_Report_GetOccupancy$$
CREATE PROCEDURE sp_Report_GetOccupancy(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(50)
)
BEGIN
    SELECT
        r.number_room,
        r.comfort_level,
        COALESCE(r.capacity, 0) AS capacity,
        COUNT(DISTINCT b.id_booking) AS bookings_count,
        COALESCE(SUM(
            GREATEST(0, DATEDIFF(
                LEAST(b.date_check_out, DATE_ADD(p_date_to, INTERVAL 1 DAY)),
                GREATEST(b.date_check_in, p_date_from)
            ))
        ), 0) AS occupied_nights,
        ROUND(
            COALESCE(SUM(
                GREATEST(0, DATEDIFF(
                    LEAST(b.date_check_out, DATE_ADD(p_date_to, INTERVAL 1 DAY)),
                    GREATEST(b.date_check_in, p_date_from)
                ))
            ), 0) / GREATEST(DATEDIFF(DATE_ADD(p_date_to, INTERVAL 1 DAY), p_date_from), 1) * 100,
            2
        ) AS occupancy_percent,
        COALESCE(SUM(b.total_price), 0) AS revenue
    FROM Room r
    LEFT JOIN Booking b ON b.number_room = r.number_room
        AND b.date_check_in <= p_date_to
        AND b.date_check_out >= p_date_from
        AND b.status_booking <> 'canceled'
        AND (p_status IS NULL OR p_status = '' OR b.status_booking = p_status)
    WHERE r.is_deleted = 0
    GROUP BY r.number_room, r.comfort_level, r.capacity
    ORDER BY occupancy_percent DESC, revenue DESC, r.number_room;
END$$

DROP PROCEDURE IF EXISTS sp_Report_GetMaintenance$$
CREATE PROCEDURE sp_Report_GetMaintenance(
    IN p_date_from DATE,
    IN p_date_to DATE
)
BEGIN
    SELECT
        id_maintenance,
        number_room,
        start_date,
        end_date,
        DATEDIFF(COALESCE(end_date, CURRENT_DATE()), start_date) + 1 AS days_in_maintenance,
        CASE WHEN end_date IS NULL THEN 'В работе' ELSE 'Завершено' END AS maintenance_status,
        COALESCE(reason, '') AS reason
    FROM Maintenance
    WHERE DATE(start_date) BETWEEN p_date_from AND p_date_to
    ORDER BY start_date DESC, id_maintenance DESC;
END$$

DELIMITER ;

/********************************************************************/

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_User_GetForAuthentication$$
CREATE PROCEDURE sp_User_GetForAuthentication(IN p_username VARCHAR(255))
BEGIN
    SELECT id_user, username, password_hash, role, last_login, id_staff
    FROM users
    WHERE LOWER(username) = LOWER(p_username)
    LIMIT 1;
END$$
 

DELIMITER $$

CREATE PROCEDURE sp_Maintenance_GetByStaff(IN p_id_staff INT)
BEGIN
    SELECT
        m.id_maintenance,
        m.number_room,
        m.start_date,
        m.end_date,
        m.reason,
        m.assigned_staff_id,
        COALESCE(m.maintenance_task_status, 'assigned') AS maintenance_task_status,
        CASE
            WHEN s.id_Staff IS NOT NULL
            THEN CONCAT(s.last_name_staff, ' ', s.first_name_staff)
            ELSE ''
        END AS assigned_staff_name
    FROM Maintenance m
    LEFT JOIN Staff s ON m.assigned_staff_id = s.id_Staff
    WHERE m.assigned_staff_id = p_id_staff
    ORDER BY
        CASE COALESCE(m.maintenance_task_status, 'assigned')
            WHEN 'problem' THEN 1
            WHEN 'assigned' THEN 2
            WHEN 'in_progress' THEN 3
            WHEN 'done' THEN 4
            ELSE 5
        END,
        m.start_date DESC,
        m.id_maintenance DESC;
END$$

DELIMITER ;



DELIMITER $$

CREATE PROCEDURE sp_Maintenance_GetAll()
BEGIN
    SELECT
        m.id_maintenance,
        m.number_room,
        m.start_date,
        m.end_date,
        m.reason,
        m.assigned_staff_id,
        COALESCE(m.maintenance_task_status, 'assigned') AS maintenance_task_status,
        CASE
            WHEN s.id_Staff IS NOT NULL
            THEN CONCAT(s.last_name_staff, ' ', s.first_name_staff)
            ELSE ''
        END AS assigned_staff_name
    FROM Maintenance m
    LEFT JOIN Staff s ON m.assigned_staff_id = s.id_Staff
    ORDER BY
        CASE COALESCE(m.maintenance_task_status, 'assigned')
            WHEN 'problem' THEN 1
            WHEN 'assigned' THEN 2
            WHEN 'in_progress' THEN 3
            WHEN 'done' THEN 4
            ELSE 5
        END,
        m.start_date DESC,
        m.id_maintenance DESC;
END$$

DELIMITER ;


DELIMITER $$
CREATE PROCEDURE sp_User_Delete(
    IN p_id_user   BIGINT,
    IN p_caller_id BIGINT
)
BEGIN
    DECLARE v_user_exists  INT DEFAULT 0;
    DECLARE v_admin_count  INT DEFAULT 0;
    DECLARE v_role         VARCHAR(50) DEFAULT NULL;

    -- ИСПРАВЛЕНО: разделяем на два отдельных запроса
    SELECT COUNT(*) INTO v_user_exists
    FROM users WHERE id_user = p_id_user;

    SELECT role INTO v_role
    FROM users WHERE id_user = p_id_user
    LIMIT 1;

    SELECT COUNT(*) INTO v_admin_count
    FROM users WHERE role = 'admin';

    IF v_user_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found.';

    ELSEIF p_id_user = p_caller_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete your own account.';

    ELSEIF v_role = 'admin' AND v_admin_count <= 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete the last admin in the system.';

    ELSE
        DELETE FROM users WHERE id_user = p_id_user;
        SELECT 'User successfully deleted.' AS Message;
    END IF;
END$$

DROP PROCEDURE IF EXISTS sp_User_GetAll;

DELIMITER $$

CREATE PROCEDURE sp_User_GetAll()
BEGIN
    SELECT
        u.id_user,
        u.username,
        u.role,
        u.last_login,
        u.id_staff,
        CASE
            WHEN s.id_Staff IS NOT NULL
            THEN CONCAT(s.last_name_staff, ' ', s.first_name_staff)
            ELSE ''
        END AS staff_full_name
    FROM users u
    LEFT JOIN Staff s ON u.id_staff = s.id_Staff
    ORDER BY u.username;
END$$

DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS sp_Maintenance_UpdateStatus$$
CREATE PROCEDURE sp_Maintenance_UpdateStatus(
    IN p_id_maintenance     INT,
    IN p_end_date           DATE,    -- дата завершения (NULL = ещё в работе)
    IN p_assigned_staff_id  INT,     -- NULL = не менять назначение
    IN p_caller_role        VARCHAR(50),  -- роль вызывающего ('admin','manager','housekeeper','technician')
    IN p_caller_staff_id    INT           -- id_Staff вызывающего (для проверки доступа)
)
BEGIN
    DECLARE v_maint_exists    INT DEFAULT 0;
    DECLARE v_owner_staff_id  INT DEFAULT NULL;
    DECLARE v_number_room     VARCHAR(10) DEFAULT NULL;
    DECLARE v_active_bookings INT DEFAULT 0;
 
    SELECT COUNT(*), assigned_staff_id, number_room
    INTO v_maint_exists, v_owner_staff_id, v_number_room
    FROM Maintenance WHERE id_maintenance = p_id_maintenance;
 
    SELECT COUNT(*) INTO v_active_bookings
    FROM Booking
    WHERE number_room = v_number_room AND status_booking = 'reservat';
 
    -- Горничная/техник могут закрывать только свои задачи
    IF v_maint_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Maintenance record not found.';
 
    ELSEIF p_caller_role IN ('housekeeper', 'technician')
       AND v_owner_staff_id != p_caller_staff_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Access denied: you can only update your own maintenance tasks.';
 
    -- Горничная/техник не может переназначить задачу
    ELSEIF p_caller_role IN ('housekeeper', 'technician')
       AND p_assigned_staff_id IS NOT NULL
       AND p_assigned_staff_id != v_owner_staff_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Access denied: only admin or manager can reassign tasks.';
 
    ELSE
        START TRANSACTION;
 
        UPDATE Maintenance SET
            end_date           = p_end_date,
            assigned_staff_id  = COALESCE(p_assigned_staff_id, assigned_staff_id)
        WHERE id_maintenance = p_id_maintenance;
 
        -- Если задача закрывается — меняем статус комнаты
        IF p_end_date IS NOT NULL THEN
            UPDATE Room SET
                status_room = CASE
                    WHEN v_active_bookings > 0 THEN 'occupied'
                    ELSE 'free'
                END
            WHERE number_room = v_number_room;
        END IF;
 
        COMMIT;
        SELECT 'Maintenance record updated successfully.' AS Message;
    END IF;
END$$

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_Room_UpdateStatus$$
CREATE PROCEDURE sp_Room_UpdateStatus(
    IN p_number_room    VARCHAR(10),
    IN p_status_room    ENUM('free', 'occupied', 'maintenance'),
    IN p_caller_role    VARCHAR(50)
)
BEGIN
    DECLARE v_room_exists       INT DEFAULT 0;
    DECLARE v_active_bookings   INT DEFAULT 0;
 
    SELECT COUNT(*) INTO v_room_exists
    FROM Room WHERE number_room = p_number_room AND is_deleted = 0;
 
    SELECT COUNT(*) INTO v_active_bookings
    FROM Booking
    WHERE number_room = p_number_room AND status_booking = 'reservat';
 
    IF v_room_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room not found.';
 
    -- Горничная не может ставить статус 'occupied' — это делает система автоматически
    ELSEIF p_caller_role IN ('housekeeper', 'technician') AND p_status_room = 'occupied' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Access denied: you cannot set room status to occupied.';
 
    -- Нельзя снять статус occupied если есть активная бронь
    ELSEIF v_active_bookings > 0 AND p_status_room != 'occupied' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot change status: room has active bookings.';
 
    ELSE
        UPDATE Room SET status_room = p_status_room
        WHERE number_room = p_number_room;
 
        SELECT 'Room status updated successfully.' AS Message;
    END IF;
END$$

 DELIMITER $$
 DROP PROCEDURE IF EXISTS sp_Staff_GetAllActive$$
CREATE PROCEDURE sp_Staff_GetAllActive()
BEGIN
    SELECT
        s.id_Staff,
        s.last_name_staff,
        s.first_name_staff,
        s.middle_name_staff,
        s.job_title,
        -- показываем, уже ли есть user для этого сотрудника
        CASE WHEN u.id_staff IS NOT NULL THEN 1 ELSE 0 END AS has_user
    FROM Staff s
    LEFT JOIN users u ON u.id_staff = s.id_Staff
    WHERE s.is_deleted = 0
    ORDER BY s.last_name_staff;
END$$
 DELIMITER ;
 
DELIMITER $$
CREATE PROCEDURE sp_Maintenance_UpdateAssignedStaff(
    IN p_id_maintenance    INT,
    IN p_assigned_staff_id INT    -- NULL = снять назначение
)
BEGIN
    DECLARE v_exists      INT DEFAULT 0;
    DECLARE v_staff_exists INT DEFAULT 0;

    SELECT COUNT(*) INTO v_exists
    FROM Maintenance WHERE id_maintenance = p_id_maintenance;

    IF p_assigned_staff_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_staff_exists
        FROM Staff WHERE id_Staff = p_assigned_staff_id AND is_deleted = 0;
    END IF;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Service record not found.';
    ELSEIF p_assigned_staff_id IS NOT NULL AND v_staff_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The employee was not found or was deleted.';
    ELSE
        UPDATE Maintenance
        SET assigned_staff_id = p_assigned_staff_id
        WHERE id_maintenance = p_id_maintenance;

        SELECT 'The appointment has been updated.' AS Message;
    END IF;
END$$
DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_BookingService_SearchByStaff(
    IN p_id_staff INT,
    IN p_search VARCHAR(255)
)
BEGIN
    SELECT *
    FROM ActiveBookingService
    WHERE assigned_staff_id = p_id_staff
      AND (
          number_room LIKE CONCAT(p_search, '%')
          OR name_services LIKE CONCAT(p_search, '%')
          OR assigned_staff_name LIKE CONCAT(p_search, '%')
          OR service_task_status LIKE CONCAT(p_search, '%')
      )
    ORDER BY date_check_in DESC;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_BookingService_GetByStaff(IN p_id_staff INT)
BEGIN
    SELECT *
    FROM ActiveBookingService
    WHERE assigned_staff_id = p_id_staff
    ORDER BY
        CASE service_task_status
            WHEN 'problem' THEN 1
            WHEN 'assigned' THEN 2
            WHEN 'in_progress' THEN 3
            WHEN 'done' THEN 4
            ELSE 5
        END,
        date_check_in DESC;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE sp_BookingService_UpdateTaskStatus(
    IN p_id_booking INT,
    IN p_id_services SMALLINT,
    IN p_service_task_status VARCHAR(30),
    IN p_caller_staff_id INT
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_assigned_staff_id INT DEFAULT NULL;

    SELECT COUNT(*), MAX(assigned_staff_id)
    INTO v_exists, v_assigned_staff_id
    FROM Booking_services
    WHERE id_booking = p_id_booking
      AND id_services = p_id_services
      AND is_deleted = 0;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Задача услуги бронирования не найдена.';

    ELSEIF v_assigned_staff_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'У этой услуги не назначен исполнитель.';

    ELSEIF v_assigned_staff_id <> p_caller_staff_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Можно менять статус только своих задач.';

    ELSEIF p_service_task_status NOT IN ('assigned', 'in_progress', 'done', 'problem') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Недопустимый статус задачи.';

    ELSE
        UPDATE Booking_services
        SET service_task_status = p_service_task_status
        WHERE id_booking = p_id_booking
          AND id_services = p_id_services
          AND is_deleted = 0;

        SELECT 'Статус задачи обновлен.' AS Message;
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_Maintenance_UpdateTaskStatus;

DELIMITER $$

CREATE PROCEDURE sp_Maintenance_UpdateTaskStatus(
    IN p_id_maintenance INT,
    IN p_maintenance_task_status VARCHAR(30),
    IN p_caller_staff_id INT
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_assigned_staff_id INT DEFAULT NULL;
    DECLARE v_number_room VARCHAR(10) DEFAULT NULL;
    DECLARE v_end_date DATE DEFAULT NULL;
    DECLARE v_status_check_date DATE DEFAULT NULL;
    DECLARE v_booking_exists INT DEFAULT 0;

    SELECT
        COUNT(*),
        MAX(assigned_staff_id),
        MAX(number_room),
        MAX(end_date)
    INTO
        v_exists,
        v_assigned_staff_id,
        v_number_room,
        v_end_date
    FROM Maintenance
    WHERE id_maintenance = p_id_maintenance;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Задача обслуживания не найдена.';

    ELSEIF v_assigned_staff_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'У задачи обслуживания не назначен исполнитель.';

    ELSEIF v_assigned_staff_id <> p_caller_staff_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Можно менять статус только своих задач.';

    ELSEIF p_maintenance_task_status NOT IN ('assigned', 'in_progress', 'done', 'problem') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Недопустимый статус задачи обслуживания.';

    ELSE
        IF p_maintenance_task_status = 'done' THEN
            SET v_end_date = COALESCE(v_end_date, CURRENT_DATE());
            SET v_status_check_date = DATE_ADD(v_end_date, INTERVAL 1 DAY);

            SELECT COUNT(*)
            INTO v_booking_exists
            FROM Booking
            WHERE number_room = v_number_room
              AND status_booking = 'reservat'
              AND date_check_in <= v_status_check_date
              AND date_check_out > v_status_check_date;
        END IF;

        UPDATE Maintenance
        SET
            maintenance_task_status = p_maintenance_task_status,
            end_date = CASE
                WHEN p_maintenance_task_status = 'done'
                THEN v_end_date
                ELSE end_date
            END
        WHERE id_maintenance = p_id_maintenance;

        IF p_maintenance_task_status = 'done' THEN
            UPDATE Room
            SET status_room = CASE
                WHEN v_booking_exists > 0 THEN 'occupied'
                ELSE 'free'
            END
            WHERE number_room = v_number_room;
        END IF;

        SELECT 'Статус задачи обслуживания обновлен.' AS Message;
    END IF;
END$$

DELIMITER ;

USE hotel_bd;


DELIMITER $$

CREATE PROCEDURE sp_Maintenance_UpdateTaskStatusByRole(
    IN p_id_maintenance INT,
    IN p_maintenance_task_status VARCHAR(30),
    IN p_caller_role VARCHAR(50)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_room_number VARCHAR(20);
    DECLARE v_effective_date DATE;
    DECLARE v_has_active_booking INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_exists
    FROM Maintenance
    WHERE id_maintenance = p_id_maintenance;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Запись обслуживания не найдена.';
    ELSEIF p_caller_role NOT IN ('admin', 'manager') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Недостаточно прав для изменения статуса.';
    ELSEIF p_maintenance_task_status NOT IN ('assigned', 'in_progress', 'done', 'problem') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Некорректный статус задачи.';
    ELSE
        UPDATE Maintenance
        SET maintenance_task_status = p_maintenance_task_status,
            end_date = CASE
                WHEN p_maintenance_task_status = 'done' AND end_date IS NULL
                    THEN CURRENT_DATE()
                ELSE end_date
            END
        WHERE id_maintenance = p_id_maintenance;

        IF p_maintenance_task_status = 'done' THEN
            SELECT number_room, DATE_ADD(end_date, INTERVAL 1 DAY)
            INTO v_room_number, v_effective_date
            FROM Maintenance
            WHERE id_maintenance = p_id_maintenance;

            SELECT COUNT(*)
            INTO v_has_active_booking
            FROM Booking
            WHERE number_room = v_room_number
              AND status_booking = 'reservat'
              AND date_check_in <= v_effective_date
              AND date_check_out > v_effective_date;

            UPDATE Room
            SET status_room = CASE
                WHEN v_has_active_booking > 0 THEN 'occupied'
                ELSE 'free'
            END
            WHERE number_room = v_room_number;
        END IF;

        SELECT 'Статус задачи обслуживания обновлён.' AS Message;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_Client_GetAllActive$$
CREATE PROCEDURE sp_Client_GetAllActive()
BEGIN
    SELECT * FROM ActiveClients;
END$$

DROP PROCEDURE IF EXISTS sp_Client_Search;

DELIMITER $$
CREATE PROCEDURE sp_Client_Search(IN p_search VARCHAR(255))
BEGIN
    SET p_search = CONCAT('%', p_search, '%');

    SELECT 
        id_client,
        last_name,
        first_name,
        middle_name,
        birth_date,
        gender,
        citizenship,
        document_type,
        document_number,
        document_issued_by,
        document_issue_date,
        address,
        phone,
        email
    FROM clients
    WHERE 
        is_deleted = 0
        AND (
            CONCAT(last_name, ' ', first_name, ' ', IFNULL(middle_name, '')) LIKE p_search
            OR last_name LIKE p_search
            OR first_name LIKE p_search
            OR phone LIKE p_search
            OR document_number LIKE p_search
        )
    ORDER BY last_name, first_name
    LIMIT 8;
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS sp_Staff_GetAllActiveFull$$
CREATE PROCEDURE sp_Staff_GetAllActiveFull()
BEGIN
    SELECT * FROM ActiveStaff;
END$$

DROP PROCEDURE IF EXISTS sp_Staff_Search$$
CREATE PROCEDURE sp_Staff_Search(IN p_search VARCHAR(255))
BEGIN
    SELECT *
    FROM ActiveStaff
    WHERE last_name_staff LIKE CONCAT(p_search, '%')
       OR phone LIKE CONCAT(p_search, '%')
       OR job_title LIKE CONCAT(p_search, '%')
    ORDER BY last_name_staff
    LIMIT 50;
END$$

DROP PROCEDURE IF EXISTS sp_Service_GetAllActive$$
CREATE PROCEDURE sp_Service_GetAllActive()
BEGIN
    SELECT * FROM ActiveServices;
END$$

DROP PROCEDURE IF EXISTS sp_Service_Search$$
CREATE PROCEDURE sp_Service_Search(IN p_search VARCHAR(255))
BEGIN
    SELECT id_services, name_services, description_services, price_services
    FROM ActiveServices
    WHERE name_services LIKE CONCAT(p_search, '%')
    ORDER BY name_services
    LIMIT 50;
END$$

DROP PROCEDURE IF EXISTS sp_Booking_GetAll$$
CREATE PROCEDURE sp_Booking_GetAll()
BEGIN
    SELECT * FROM vw_Booking;
END$$

DROP PROCEDURE IF EXISTS sp_Booking_Search$$
CREATE PROCEDURE sp_Booking_Search(IN p_search VARCHAR(255))
BEGIN
    SELECT *
    FROM vw_Booking
    WHERE full_name LIKE CONCAT(p_search, '%')
       OR number_room LIKE CONCAT(p_search, '%')
    ORDER BY date_check_in DESC
    LIMIT 50;
END$$

DROP PROCEDURE IF EXISTS sp_BookingService_GetAll$$
CREATE PROCEDURE sp_BookingService_GetAll()
BEGIN
    SELECT * FROM ActiveBookingService;
END$$

DROP PROCEDURE IF EXISTS sp_Report_GetRevenue$$
CREATE PROCEDURE sp_Report_GetRevenue(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(30)
)
BEGIN
    SELECT
        DATE(b.date_reservation) AS report_date,
        COUNT(*) AS bookings_count,
        COALESCE(SUM(CASE WHEN b.status_booking <> 'canceled' THEN b.total_price ELSE 0 END), 0) AS room_revenue,
        COALESCE(SUM(CASE WHEN b.status_booking <> 'canceled' THEN COALESCE(bs.services_total, 0) ELSE 0 END), 0) AS service_revenue,
        COALESCE(SUM(CASE WHEN b.status_booking <> 'canceled' THEN b.total_price + COALESCE(bs.services_total, 0) ELSE 0 END), 0) AS total_revenue,
        COALESCE(AVG(CASE WHEN b.status_booking <> 'canceled' THEN b.total_price + COALESCE(bs.services_total, 0) END), 0) AS average_check
    FROM vw_Booking b
    LEFT JOIN (
        SELECT id_booking, SUM(subtotal_service_price) AS services_total
        FROM ActiveBookingService
        GROUP BY id_booking
    ) bs ON bs.id_booking = b.id_booking
    WHERE DATE(b.date_reservation) BETWEEN p_date_from AND p_date_to
      AND (p_status IS NULL OR b.status_booking = p_status)
    GROUP BY DATE(b.date_reservation)
    ORDER BY report_date;
END$$

DROP PROCEDURE IF EXISTS sp_Report_GetBookings$$
CREATE PROCEDURE sp_Report_GetBookings(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(30)
)
BEGIN
    SELECT
        b.id_booking,
        b.full_name,
        b.number_room,
        b.date_reservation,
        b.date_check_in,
        b.date_check_out,
        DATEDIFF(b.date_check_out, b.date_check_in) AS nights_count,
        b.status_booking,
        b.total_price,
        COALESCE(bs.services_total, 0) AS services_total,
        b.total_price + COALESCE(bs.services_total, 0) AS total_amount
    FROM vw_Booking b
    LEFT JOIN (
        SELECT id_booking, SUM(subtotal_service_price) AS services_total
        FROM ActiveBookingService
        GROUP BY id_booking
    ) bs ON bs.id_booking = b.id_booking
    WHERE DATE(b.date_reservation) BETWEEN p_date_from AND p_date_to
      AND (p_status IS NULL OR b.status_booking = p_status)
    ORDER BY b.date_reservation DESC, b.id_booking DESC;
END$$

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_Report_GetOccupancy$$
CREATE PROCEDURE sp_Report_GetOccupancy(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(30)
)
BEGIN
    SELECT
        r.number_room,
        r.comfort_level,
        COALESCE(r.capacity, 0) AS capacity,
        COUNT(DISTINCT b.id_booking) AS bookings_count,
        COALESCE(SUM(GREATEST(0, DATEDIFF(
            LEAST(b.date_check_out, DATE_ADD(p_date_to, INTERVAL 1 DAY)),
            GREATEST(b.date_check_in, p_date_from)
        ))), 0) AS occupied_nights,
        ROUND(
            COALESCE(SUM(GREATEST(0, DATEDIFF(
                LEAST(b.date_check_out, DATE_ADD(p_date_to, INTERVAL 1 DAY)),
                GREATEST(b.date_check_in, p_date_from)
            ))), 0) / GREATEST(DATEDIFF(DATE_ADD(p_date_to, INTERVAL 1 DAY), p_date_from), 1) * 100,
            2
        ) AS occupancy_percent,
        COALESCE(SUM(CASE WHEN b.id_booking IS NULL THEN 0 ELSE b.total_price + COALESCE(bs.services_total, 0) END), 0) AS revenue
    FROM Room r
    LEFT JOIN Booking b ON b.number_room = r.number_room
        AND b.date_check_in <= p_date_to
        AND b.date_check_out > p_date_from
        AND b.status_booking <> 'canceled'
        AND (p_status IS NULL OR b.status_booking = p_status)
    LEFT JOIN (
        SELECT id_booking, SUM(subtotal_service_price) AS services_total
        FROM ActiveBookingService
        GROUP BY id_booking
    ) bs ON bs.id_booking = b.id_booking
    WHERE r.is_deleted = 0
    GROUP BY r.number_room, r.comfort_level, r.capacity
    ORDER BY occupancy_percent DESC, revenue DESC, r.number_room;
END$$

DROP PROCEDURE IF EXISTS sp_Report_GetClients$$
CREATE PROCEDURE sp_Report_GetClients(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(30)
)
BEGIN
    SELECT
        b.full_name,
        b.phone,
        COALESCE(b.email, '') AS email,
        COUNT(*) AS bookings_count,
        COALESCE(SUM(CASE WHEN b.status_booking <> 'canceled' THEN b.total_price + COALESCE(bs.services_total, 0) ELSE 0 END), 0) AS total_spent,
        COALESCE(AVG(CASE WHEN b.status_booking <> 'canceled' THEN b.total_price + COALESCE(bs.services_total, 0) END), 0) AS average_check,
        MAX(b.date_reservation) AS last_booking_date
    FROM vw_Booking b
    LEFT JOIN (
        SELECT id_booking, SUM(subtotal_service_price) AS services_total
        FROM ActiveBookingService
        GROUP BY id_booking
    ) bs ON bs.id_booking = b.id_booking
    WHERE DATE(b.date_reservation) BETWEEN p_date_from AND p_date_to
      AND (p_status IS NULL OR b.status_booking = p_status)
    GROUP BY b.full_name, b.phone, b.email
    ORDER BY total_spent DESC, bookings_count DESC;
END$$

DROP PROCEDURE IF EXISTS sp_Report_GetServiceUsage$$
CREATE PROCEDURE sp_Report_GetServiceUsage(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(30)
)
BEGIN
    SELECT
        name_services,
        COUNT(*) AS usage_count,
        COALESCE(SUM(quantity), 0) AS total_quantity,
        COALESCE(SUM(subtotal_service_price), 0) AS total_revenue,
        COALESCE(AVG(price_services), 0) AS average_price
    FROM ActiveBookingService
    WHERE DATE(date_check_in) BETWEEN p_date_from AND p_date_to
      AND (p_status IS NULL OR status_booking = p_status)
      AND status_booking <> 'canceled'
    GROUP BY name_services
    ORDER BY total_revenue DESC, total_quantity DESC;
END$$

DROP PROCEDURE IF EXISTS sp_Report_GetMaintenance$$
CREATE PROCEDURE sp_Report_GetMaintenance(
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_status VARCHAR(30)
)
BEGIN
    SELECT
        id_maintenance,
        number_room,
        start_date,
        end_date,
        DATEDIFF(COALESCE(end_date, CURRENT_DATE()), start_date) + 1 AS days_in_maintenance,
        CASE WHEN end_date IS NULL THEN 'В работе' ELSE 'Завершено' END AS maintenance_status,
        COALESCE(reason, '') AS reason
    FROM Maintenance
    WHERE start_date <= p_date_to
      AND COALESCE(end_date, '9999-12-31') >= p_date_from
    ORDER BY start_date DESC, id_maintenance DESC;
END$$

DELIMITER ;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_BookingService_Search$$
CREATE PROCEDURE sp_BookingService_Search(IN p_search VARCHAR(255))
BEGIN
    SELECT *
    FROM ActiveBookingService
    WHERE number_room LIKE CONCAT(p_search, '%')
       OR name_services LIKE CONCAT(p_search, '%')
       OR assigned_staff_name LIKE CONCAT(p_search, '%')
       OR service_task_status LIKE CONCAT(p_search, '%')
       OR status_booking LIKE CONCAT(p_search, '%')
    ORDER BY date_check_in DESC
    LIMIT 50;
END$$

DELIMITER ;





