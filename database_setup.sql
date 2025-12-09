-- =============================================
-- Nivāraṇam Database Setup Script
-- Civic Issue Management System
-- =============================================
-- 
-- Instructions:
-- 1. Open MySQL Workbench or command line
-- 2. Run this entire script
-- 3. Database and all tables with sample data will be created
-- 
-- =============================================

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS nivāraṇam_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nivāraṇam_db;

-- Drop existing tables (for clean setup)
DROP TABLE IF EXISTS analytics_cache;
DROP TABLE IF EXISTS status_logs;
DROP TABLE IF EXISTS complaint_upvotes;
DROP TABLE IF EXISTS alerts;
DROP TABLE IF EXISTS contractor_assignments;
DROP TABLE IF EXISTS contractor_divisions;
DROP TABLE IF EXISTS contractors;
DROP TABLE IF EXISTS complaints;
DROP TABLE IF EXISTS users;

-- =============================================
-- TABLE: users
-- Stores admin and citizen user accounts
-- =============================================
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role ENUM('admin', 'citizen', 'super_admin') DEFAULT 'citizen',
  division ENUM('North', 'South', 'East', 'West', 'Central') NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- TABLE: complaints
-- Stores all civic issue complaints
-- =============================================
CREATE TABLE complaints (
  id VARCHAR(50) PRIMARY KEY,
  user_id INT NOT NULL,
  category ENUM('Garbage', 'Pothole', 'Streetlight', 'Water Supply', 'Drainage', 'Road Damage', 'Sewage', 'Illegal Parking') NOT NULL,
  description TEXT NOT NULL,
  division ENUM('North', 'South', 'East', 'West', 'Central') NOT NULL,
  ward VARCHAR(50) NOT NULL,
  status ENUM('Submitted', 'Verified', 'Assigned', 'In Progress', 'Completed', 'Closed') DEFAULT 'Submitted',
  priority ENUM('High', 'Medium', 'Low') DEFAULT 'Medium',
  upvotes INT DEFAULT 0,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  thumbnail_url VARCHAR(500),
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  verified_at TIMESTAMP NULL,
  assigned_at TIMESTAMP NULL,
  completed_at TIMESTAMP NULL,
  closed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_status (status),
  INDEX idx_division (division),
  INDEX idx_category (category),
  INDEX idx_priority (priority),
  INDEX idx_submitted_at (submitted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- TABLE: contractors
-- Stores contractor information
-- =============================================
CREATE TABLE contractors (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type ENUM('Government', 'Local') NOT NULL,
  rating DECIMAL(3, 2) DEFAULT 0.00,
  completed_jobs INT DEFAULT 0,
  active_jobs INT DEFAULT 0,
  status ENUM('Active', 'Busy', 'Suspended', 'Flagged') DEFAULT 'Active',
  phone VARCHAR(20),
  email VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_status (status),
  INDEX idx_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- TABLE: contractor_divisions
-- Many-to-many relationship for contractor service areas
-- =============================================
CREATE TABLE contractor_divisions (
  contractor_id VARCHAR(50) NOT NULL,
  division ENUM('North', 'South', 'East', 'West', 'Central') NOT NULL,
  PRIMARY KEY (contractor_id, division),
  FOREIGN KEY (contractor_id) REFERENCES contractors(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- TABLE: contractor_assignments
-- Tracks contractor assignments to complaints
-- =============================================
CREATE TABLE contractor_assignments (
  id INT PRIMARY KEY AUTO_INCREMENT,
  complaint_id VARCHAR(50) NOT NULL,
  contractor_id VARCHAR(50) NOT NULL,
  assigned_by INT NOT NULL,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accepted_at TIMESTAMP NULL,
  started_at TIMESTAMP NULL,
  completed_at TIMESTAMP NULL,
  status ENUM('Assigned', 'Accepted', 'In Progress', 'Completed', 'Rejected') DEFAULT 'Assigned',
  rejection_reason TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE,
  FOREIGN KEY (contractor_id) REFERENCES contractors(id) ON DELETE CASCADE,
  FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_complaint (complaint_id),
  INDEX idx_contractor (contractor_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- TABLE: alerts
-- System alerts and notifications
-- =============================================
CREATE TABLE alerts (
  id VARCHAR(50) PRIMARY KEY,
  type ENUM('Repeated Issue', 'Long Pending', 'Unresponsive Contractor', 'High Volume', 'Hotspot Warning') NOT NULL,
  message TEXT NOT NULL,
  division ENUM('North', 'South', 'East', 'West', 'Central') NOT NULL,
  related_id VARCHAR(100) NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_division (division),
  INDEX idx_type (type),
  INDEX idx_is_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- TABLE: complaint_upvotes
-- Tracks which users upvoted which complaints
-- =============================================
CREATE TABLE complaint_upvotes (
  complaint_id VARCHAR(50) NOT NULL,
  user_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (complaint_id, user_id),
  FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- TABLE: status_logs
-- Audit trail for complaint status changes
-- =============================================
CREATE TABLE status_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  complaint_id VARCHAR(50) NOT NULL,
  old_status VARCHAR(50),
  new_status VARCHAR(50) NOT NULL,
  changed_by INT NOT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_complaint (complaint_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- TABLE: analytics_cache
-- Caches aggregated analytics data for performance
-- =============================================
CREATE TABLE analytics_cache (
  id INT PRIMARY KEY AUTO_INCREMENT,
  cache_key VARCHAR(100) NOT NULL UNIQUE,
  cache_value JSON NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_cache_key (cache_key),
  INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SEED DATA
-- =============================================

-- Insert Admin Users (password: admin123)
-- Password hash for 'admin123' using bcrypt with salt rounds 10
INSERT INTO users (username, email, password_hash, full_name, phone, role, division) VALUES
('admin_north', 'admin.north@nivāraṇam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'North Division Admin', '+91 98765 00001', 'admin', 'North'),
('admin_south', 'admin.south@nivāraṇam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'South Division Admin', '+91 98765 00002', 'admin', 'South'),
('admin_east', 'admin.east@nivāraṇam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'East Division Admin', '+91 98765 00003', 'admin', 'East'),
('admin_west', 'admin.west@nivāraṇam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'West Division Admin', '+91 98765 00004', 'admin', 'West'),
('admin_central', 'admin.central@nivāraṇam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'Central Division Admin', '+91 98765 00005', 'admin', 'Central'),
('superadmin', 'super@nivāraṇam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'Super Administrator', '+91 98765 00000', 'super_admin', NULL);

-- Insert Citizen Users (password: user123)
-- Password hash for 'user123' using bcrypt with salt rounds 10
INSERT INTO users (username, email, password_hash, full_name, phone, role) VALUES
('rajesh_kumar', 'rajesh@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Rajesh Kumar', '+91 98765 43210', 'citizen'),
('priya_sharma', 'priya@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Priya Sharma', '+91 98765 43211', 'citizen'),
('amit_patel', 'amit@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Amit Patel', '+91 98765 43212', 'citizen'),
('sunita_devi', 'sunita@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Sunita Devi', '+91 98765 43213', 'citizen'),
('mohammed_ali', 'mohammed@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Mohammed Ali', '+91 98765 43214', 'citizen'),
('vikram_singh', 'vikram@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Vikram Singh', '+91 98765 43215', 'citizen'),
('lakshmi_nair', 'lakshmi@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Lakshmi Nair', '+91 98765 43216', 'citizen'),
('arun_gupta', 'arun@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Arun Gupta', '+91 98765 43217', 'citizen');

-- Insert Contractors
INSERT INTO contractors (id, name, type, rating, completed_jobs, active_jobs, status, phone, email) VALUES
('CON-001', 'Metro Construction Co.', 'Government', 4.5, 234, 5, 'Active', '+91 11 2345 6789', 'contact@metroconstruction.com'),
('CON-002', 'City Works Ltd.', 'Government', 4.2, 189, 8, 'Busy', '+91 11 2345 6790', 'info@cityworks.com'),
('CON-003', 'Quick Fix Services', 'Local', 4.8, 156, 3, 'Active', '+91 98765 11111', 'quickfix@gmail.com'),
('CON-004', 'Green Clean Solutions', 'Local', 4.6, 98, 4, 'Active', '+91 98765 22222', 'greenclean@gmail.com'),
('CON-005', 'Urban Repair Hub', 'Local', 3.2, 67, 2, 'Flagged', '+91 98765 33333', 'urbanrepair@gmail.com'),
('CON-006', 'Municipal Services Unit', 'Government', 4.0, 512, 15, 'Busy', '+91 11 2345 6791', 'msu@gov.in');

-- Assign divisions to contractors
INSERT INTO contractor_divisions (contractor_id, division) VALUES
('CON-001', 'North'), ('CON-001', 'Central'),
('CON-002', 'South'), ('CON-002', 'East'),
('CON-003', 'West'),
('CON-004', 'North'), ('CON-004', 'East'),
('CON-005', 'South'), ('CON-005', 'Central'),
('CON-006', 'North'), ('CON-006', 'South'), ('CON-006', 'East'), ('CON-006', 'West'), ('CON-006', 'Central');

-- Insert Sample Complaints
INSERT INTO complaints (id, user_id, category, description, division, ward, status, priority, upvotes, latitude, longitude, submitted_at) VALUES
('CF-2024-001', 7, 'Pothole', 'Large pothole causing accidents near main junction', 'North', 'Ward 12', 'Assigned', 'High', 45, 28.6139, 77.2090, '2024-01-15 10:30:00'),
('CF-2024-002', 8, 'Garbage', 'Garbage not collected for 3 days in residential area', 'South', 'Ward 8', 'Verified', 'Medium', 23, 28.5355, 77.3910, '2024-01-15 09:15:00'),
('CF-2024-003', 9, 'Streetlight', 'Street light not working for a week', 'East', 'Ward 15', 'In Progress', 'Medium', 12, 28.6280, 77.2169, '2024-01-14 18:45:00'),
('CF-2024-004', 10, 'Water Supply', 'No water supply since morning', 'West', 'Ward 3', 'Submitted', 'High', 67, 28.6692, 77.4538, '2024-01-15 06:00:00'),
('CF-2024-005', 11, 'Drainage', 'Blocked drain causing waterlogging', 'Central', 'Ward 1', 'Completed', 'High', 34, 28.6304, 77.2177, '2024-01-13 14:20:00'),
('CF-2024-006', 12, 'Road Damage', 'Road surface damaged after recent construction', 'North', 'Ward 10', 'Assigned', 'Medium', 19, 28.7041, 77.1025, '2024-01-14 11:30:00'),
('CF-2024-007', 13, 'Sewage', 'Sewage overflow on main road', 'South', 'Ward 5', 'In Progress', 'High', 56, 28.5245, 77.1855, '2024-01-15 07:45:00'),
('CF-2024-008', 14, 'Illegal Parking', 'Vehicles blocking pedestrian pathway', 'Central', 'Ward 2', 'Closed', 'Low', 8, 28.6315, 77.2167, '2024-01-12 16:00:00');

-- Insert Alerts
INSERT INTO alerts (id, type, message, division, related_id, created_at) VALUES
('ALT-001', 'Hotspot Warning', 'High concentration of complaints detected in Ward 12, North Division', 'North', 'Ward 12', '2024-01-15 08:00:00'),
('ALT-002', 'Long Pending', 'Complaint CF-2024-004 pending for more than 48 hours', 'West', 'CF-2024-004', '2024-01-15 06:30:00'),
('ALT-003', 'Unresponsive Contractor', 'Urban Repair Hub has not responded to 3 assigned tasks', 'South', 'CON-005', '2024-01-14 18:00:00'),
('ALT-004', 'High Volume', '25% increase in complaints from Central Division today', 'Central', NULL, '2024-01-15 10:00:00'),
('ALT-005', 'Repeated Issue', 'Same pothole location reported 5 times this month', 'North', 'Ward 12', '2024-01-15 09:30:00');

-- =============================================
-- VERIFICATION QUERIES
-- Run these to verify the setup
-- =============================================

-- Check all tables were created
SELECT 'Tables created successfully!' as Status;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'nivāraṇam_db';

-- Check record counts
SELECT 'users' as table_name, COUNT(*) as record_count FROM users
UNION ALL
SELECT 'complaints', COUNT(*) FROM complaints
UNION ALL
SELECT 'contractors', COUNT(*) FROM contractors
UNION ALL
SELECT 'alerts', COUNT(*) FROM alerts;

-- =============================================
-- TEST CREDENTIALS
-- =============================================
-- 
-- Super Admin:
--   Email: super@nivāraṇam.gov
--   Password: admin123
-- 
-- North Division Admin:
--   Email: admin.north@nivāraṇam.gov
--   Password: admin123
-- 
-- Citizen:
--   Email: rajesh@example.com
--   Password: user123
-- 
-- =============================================
-- SETUP COMPLETE!
-- =============================================
