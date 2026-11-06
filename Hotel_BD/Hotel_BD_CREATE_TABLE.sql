CREATE DATABASE HOTEL_BD;

USE HOTEL_BD;

CREATE TABLE Clients (
    id_client INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
	birth_date DATE NOT NULL,
	gender ENUM('M', 'F') NOT NULL,
	citizenship VARCHAR(100) NOT NULL,
	document_type VARCHAR(50) NOT NULL,
	document_number VARCHAR(50) NOT NULL,
    document_issued_by VARCHAR(150),
	document_issue_date DATE,
	address TEXT NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0,
	deleted_at DATETIME NULL
);


CREATE TABLE users (
    id_user INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'manager', 'housekeeper', 'technician')  NOT NULL,
    last_login DATETIME,
    id_staff int DEFAULT NULL
);

SET SQL_SAFE_UPDATES = 0;
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE Maintenance
    ADD COLUMN assigned_staff_id INT NULL DEFAULT NULL,
    ADD CONSTRAINT fk_maintenance_staff
        FOREIGN KEY (assigned_staff_id) REFERENCES Staff(id_Staff)
        ON UPDATE CASCADE ON DELETE SET NULL;
        
CREATE TABLE Room (
    number_room VARCHAR(10) PRIMARY KEY NOT NULL,
    price_room DECIMAL(10,2) NOT NULL,
    capacity SMALLINT NOT NULL,
	status_room ENUM('free', 'occupied', 'maintenance') NOT NULL,
    comfort_level ENUM('standard', 'deluxe', 'suite') NOT NULL,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0,
	deleted_at DATETIME NULL

);

CREATE TABLE Servicess (
    id_services SMALLINT AUTO_INCREMENT PRIMARY KEY,
    name_services VARCHAR(255) NOT NULL,
    description_services TEXT,
    price_services DECIMAL(10,2) NOT NULL,
    is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
	deleted_at  DATETIME NULL
);


CREATE TABLE Staff (
	id_Staff INT AUTO_INCREMENT PRIMARY KEY,
	last_name_staff VARCHAR(100) NOT NULL,
	first_name_staff VARCHAR(100) NOT NULL,
    middle_name_staff VARCHAR(100),
    job_title ENUM('admin', 'receptionist', 'cleaner', 'manager') DEFAULT 'receptionist',
 	phone VARCHAR(20) NOT NULL,
	home_address TEXT NOT NULL,
    login VARCHAR(100) UNIQUE NOT NULL,
	password_hash VARCHAR(255) NOT NULL,
    is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
	deleted_at  DATETIME NULL
);


CREATE TABLE Booking (
    id_booking INT PRIMARY KEY AUTO_INCREMENT,
    id_client INT NOT NULL,
	number_room VARCHAR(10) NOT NULL,
    date_reservation DATE NOT NULL,
    date_check_in DATE NOT NULL,
    date_check_out DATE NOT NULL,
    status_booking ENUM ('reservat','canceled','completed') NOT NULL DEFAULT 'reservat',
    total_price DECIMAL(10,2) NOT NULL,
    
    CONSTRAINT fk_id_client  
			FOREIGN KEY (id_client) REFERENCES Clients(id_client),
            
	CONSTRAINT fk_number_room 
			FOREIGN KEY (number_room) REFERENCES Room(number_room)
);

    
CREATE TABLE Booking_services (
	id_booking INT NOT NULL,
    id_services SMALLINT NOT NULL,
    quantity  SMALLINT NOT NULL CHECK (quantity > 0),
	is_deleted  TINYINT(1) NOT NULL DEFAULT 0,
	deleted_at  DATETIME NULL,
    PRIMARY KEY (id_booking, id_services),
    
	CONSTRAINT fk_id_booking 
		FOREIGN KEY (id_booking) REFERENCES Booking(id_booking),
        
	CONSTRAINT fk_id_services
		FOREIGN KEY (id_services) REFERENCES Servicess(id_services)
);

CREATE TABLE Maintenance (
    id_maintenance INT AUTO_INCREMENT PRIMARY KEY,
    number_room VARCHAR(10) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    reason TEXT,
    
    CONSTRAINT fk_number_room_maintenance
			FOREIGN KEY (number_room) REFERENCES Room(number_room)
);


CREATE INDEX idx_clients_document_number ON Clients(document_number);
CREATE INDEX idx_clients_phone ON Clients(phone);
CREATE INDEX idx_clients_last_name ON Clients(last_name);
CREATE INDEX idx_clients_first_name ON Clients(first_name);

CREATE INDEX idx_room_status ON Room(status_room);                 
CREATE INDEX idx_room_comfort ON Room(comfort_level);
CREATE INDEX idx_room_comfort_status ON Room(comfort_level, status_room);              
CREATE INDEX idx_room_price ON Room(price_room); 

CREATE INDEX idx_booking_room ON Booking(number_room);
CREATE INDEX idx_booking_status ON Booking(status_booking);
CREATE INDEX idx_booking_dates ON Booking(date_check_in, date_check_out);
CREATE INDEX idx_boking_id_client ON Booking(id_client);
CREATE INDEX idx_booking_services_staff ON Booking_services(assigned_staff_id);


CREATE INDEX idx_staff_job ON Staff(job_title);    
CREATE INDEX idx_staff_lastname ON Staff(last_name_staff);             

CREATE INDEX idx_services_name ON Servicess(name_services);

CREATE INDEX idx_maintenance_room ON Maintenance(number_room);
CREATE INDEX idx_maintenance_active ON Maintenance(end_date);


CREATE INDEX idx_booking_report_dates ON Booking(date_reservation, date_check_in, date_check_out, status_booking);
CREATE INDEX idx_booking_room_dates ON Booking(number_room, date_check_in, date_check_out);
CREATE INDEX idx_maintenance_report_start ON Maintenance(start_date);

CREATE INDEX idx_maintenance_staff ON Maintenance(assigned_staff_id);




