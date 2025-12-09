-- =============================================
-- Nivāraṇam Supabase Database Schema
-- (PostgreSQL for Supabase)
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- TABLE: users
-- Stores admin and citizen user accounts
-- =============================================
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(20) DEFAULT 'citizen' CHECK (role IN ('admin', 'citizen', 'super_admin')),
  city VARCHAR(100),
  division VARCHAR(20) CHECK (division IN ('North', 'South', 'East', 'West', 'Central')),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- =============================================
-- TABLE: complaints
-- Stores all civic issue complaints
-- =============================================
CREATE TABLE IF NOT EXISTS complaints (
  id VARCHAR(50) PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(50) NOT NULL CHECK (category IN ('Garbage', 'Pothole', 'Streetlight', 'Water Supply', 'Drainage', 'Road Damage', 'Sewage', 'Illegal Parking')),
  description TEXT NOT NULL,
  city VARCHAR(100) NOT NULL DEFAULT 'Unknown',
  division VARCHAR(20) NOT NULL CHECK (division IN ('North', 'South', 'East', 'West', 'Central')),
  ward VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'Submitted' CHECK (status IN ('Submitted', 'Verified', 'Assigned', 'In Progress', 'Completed', 'Closed')),
  priority VARCHAR(20) DEFAULT 'Medium' CHECK (priority IN ('High', 'Medium', 'Low')),
  upvotes INTEGER DEFAULT 0,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  thumbnail_url VARCHAR(500),
  image_uri TEXT,
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  verified_at TIMESTAMP,
  assigned_at TIMESTAMP,
  completed_at TIMESTAMP,
  closed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_division ON complaints(division);
CREATE INDEX IF NOT EXISTS idx_complaints_city ON complaints(city);
CREATE INDEX IF NOT EXISTS idx_complaints_category ON complaints(category);
CREATE INDEX IF NOT EXISTS idx_complaints_priority ON complaints(priority);
CREATE INDEX IF NOT EXISTS idx_complaints_submitted_at ON complaints(submitted_at);
CREATE INDEX IF NOT EXISTS idx_complaints_user_id ON complaints(user_id);

-- =============================================
-- TABLE: contractors
-- Stores contractor information
-- =============================================
CREATE TABLE IF NOT EXISTS contractors (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('Government', 'Local')),
  rating DECIMAL(3, 2) DEFAULT 0.00,
  completed_jobs INTEGER DEFAULT 0,
  active_jobs INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Busy', 'Suspended', 'Flagged')),
  phone VARCHAR(20),
  email VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_contractors_status ON contractors(status);
CREATE INDEX IF NOT EXISTS idx_contractors_type ON contractors(type);

-- =============================================
-- TABLE: contractor_divisions
-- Many-to-many relationship for contractor service areas
-- =============================================
CREATE TABLE IF NOT EXISTS contractor_divisions (
  contractor_id VARCHAR(50) NOT NULL REFERENCES contractors(id) ON DELETE CASCADE,
  division VARCHAR(20) NOT NULL CHECK (division IN ('North', 'South', 'East', 'West', 'Central')),
  PRIMARY KEY (contractor_id, division)
);

-- =============================================
-- TABLE: contractor_assignments
-- Tracks contractor assignments to complaints
-- =============================================
CREATE TABLE IF NOT EXISTS contractor_assignments (
  id SERIAL PRIMARY KEY,
  complaint_id VARCHAR(50) NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  contractor_id VARCHAR(50) NOT NULL REFERENCES contractors(id) ON DELETE CASCADE,
  assigned_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accepted_at TIMESTAMP,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'Assigned' CHECK (status IN ('Assigned', 'Accepted', 'In Progress', 'Completed', 'Rejected')),
  rejection_reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_contractor_assignments_complaint ON contractor_assignments(complaint_id);
CREATE INDEX IF NOT EXISTS idx_contractor_assignments_contractor ON contractor_assignments(contractor_id);
CREATE INDEX IF NOT EXISTS idx_contractor_assignments_status ON contractor_assignments(status);

-- =============================================
-- TABLE: alerts
-- System alerts and notifications
-- =============================================
CREATE TABLE IF NOT EXISTS alerts (
  id VARCHAR(50) PRIMARY KEY,
  type VARCHAR(50) NOT NULL CHECK (type IN ('Repeated Issue', 'Long Pending', 'Unresponsive Contractor', 'High Volume', 'Hotspot Warning')),
  message TEXT NOT NULL,
  division VARCHAR(20) NOT NULL CHECK (division IN ('North', 'South', 'East', 'West', 'Central')),
  related_id VARCHAR(100),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_alerts_division ON alerts(division);
CREATE INDEX IF NOT EXISTS idx_alerts_type ON alerts(type);
CREATE INDEX IF NOT EXISTS idx_alerts_is_read ON alerts(is_read);

-- =============================================
-- TABLE: complaint_upvotes
-- Tracks which users upvoted which complaints
-- =============================================
CREATE TABLE IF NOT EXISTS complaint_upvotes (
  complaint_id VARCHAR(50) NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (complaint_id, user_id)
);

-- =============================================
-- TABLE: status_logs
-- Audit trail for complaint status changes
-- =============================================
CREATE TABLE IF NOT EXISTS status_logs (
  id SERIAL PRIMARY KEY,
  complaint_id VARCHAR(50) NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  old_status VARCHAR(50),
  new_status VARCHAR(50) NOT NULL,
  changed_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_status_logs_complaint ON status_logs(complaint_id);

-- =============================================
-- TABLE: analytics_cache
-- Caches aggregated analytics data for performance
-- =============================================
CREATE TABLE IF NOT EXISTS analytics_cache (
  id SERIAL PRIMARY KEY,
  cache_key VARCHAR(100) NOT NULL UNIQUE,
  cache_value JSONB NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_analytics_cache_key ON analytics_cache(cache_key);
CREATE INDEX IF NOT EXISTS idx_analytics_cache_expires_at ON analytics_cache(expires_at);

-- =============================================
-- FUNCTION: Update updated_at timestamp
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_complaints_updated_at BEFORE UPDATE ON complaints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contractors_updated_at BEFORE UPDATE ON contractors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contractor_assignments_updated_at BEFORE UPDATE ON contractor_assignments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alerts_updated_at BEFORE UPDATE ON alerts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_analytics_cache_updated_at BEFORE UPDATE ON analytics_cache
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- SEED DATA
-- =============================================

-- Insert Admin Users (password: admin123)
-- Note: In production, use Supabase Auth. These are for testing.
INSERT INTO users (username, email, password_hash, full_name, phone, role, city, division) VALUES
('admin_north', 'admin.north@nivaranam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'North Division Admin', '+91 98765 00001', 'admin', 'Nagpur', 'North'),
('admin_south', 'admin.south@nivaranam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'South Division Admin', '+91 98765 00002', 'admin', 'Nagpur', 'South'),
('admin_east', 'admin.east@nivaranam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'East Division Admin', '+91 98765 00003', 'admin', 'Nagpur', 'East'),
('admin_west', 'admin.west@nivaranam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'West Division Admin', '+91 98765 00004', 'admin', 'Nagpur', 'West'),
('admin_central', 'admin.central@nivaranam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'Central Division Admin', '+91 98765 00005', 'admin', 'Nagpur', 'Central'),
('superadmin', 'super@nivaranam.gov', '$2a$10$XZPaE3zZ0qN7yqK5L8JxT.YHZxR4fWKQJ5mXV9N2LH8zJKxQ5F5Fy', 'Super Administrator', '+91 98765 00000', 'super_admin', 'Nagpur', NULL)
ON CONFLICT (username) DO NOTHING;

-- Insert Citizen Users (password: user123)
INSERT INTO users (username, email, password_hash, full_name, phone, role) VALUES
('rajesh_kumar', 'rajesh@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Rajesh Kumar', '+91 98765 43210', 'citizen'),
('priya_sharma', 'priya@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Priya Sharma', '+91 98765 43211', 'citizen'),
('amit_patel', 'amit@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Amit Patel', '+91 98765 43212', 'citizen'),
('sunita_devi', 'sunita@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Sunita Devi', '+91 98765 43213', 'citizen'),
('mohammed_ali', 'mohammed@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Mohammed Ali', '+91 98765 43214', 'citizen'),
('vikram_singh', 'vikram@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Vikram Singh', '+91 98765 43215', 'citizen'),
('lakshmi_nair', 'lakshmi@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Lakshmi Nair', '+91 98765 43216', 'citizen'),
('arun_gupta', 'arun@example.com', '$2a$10$8E9F0H1I2J3K4L5M6N7O8P.9Q0R1S2T3U4V5W6X7Y8Z9A0B1C2D3E', 'Arun Gupta', '+91 98765 43217', 'citizen')
ON CONFLICT (username) DO NOTHING;

-- Insert Contractors
INSERT INTO contractors (id, name, type, rating, completed_jobs, active_jobs, status, phone, email) VALUES
('CON-001', 'Metro Construction Co.', 'Government', 4.5, 234, 5, 'Active', '+91 11 2345 6789', 'contact@metroconstruction.com'),
('CON-002', 'City Works Ltd.', 'Government', 4.2, 189, 8, 'Busy', '+91 11 2345 6790', 'info@cityworks.com'),
('CON-003', 'Quick Fix Services', 'Local', 4.8, 156, 3, 'Active', '+91 98765 11111', 'quickfix@gmail.com'),
('CON-004', 'Green Clean Solutions', 'Local', 4.6, 98, 4, 'Active', '+91 98765 22222', 'greenclean@gmail.com'),
('CON-005', 'Urban Repair Hub', 'Local', 3.2, 67, 2, 'Flagged', '+91 98765 33333', 'urbanrepair@gmail.com'),
('CON-006', 'Municipal Services Unit', 'Government', 4.0, 512, 15, 'Busy', '+91 11 2345 6791', 'msu@gov.in')
ON CONFLICT (id) DO NOTHING;

-- Assign divisions to contractors
INSERT INTO contractor_divisions (contractor_id, division) VALUES
('CON-001', 'North'), ('CON-001', 'Central'),
('CON-002', 'South'), ('CON-002', 'East'),
('CON-003', 'West'),
('CON-004', 'North'), ('CON-004', 'East'),
('CON-005', 'South'), ('CON-005', 'Central'),
('CON-006', 'North'), ('CON-006', 'South'), ('CON-006', 'East'), ('CON-006', 'West'), ('CON-006', 'Central')
ON CONFLICT (contractor_id, division) DO NOTHING;

-- Insert Sample Complaints
INSERT INTO complaints (id, user_id, category, description, city, division, ward, status, priority, upvotes, latitude, longitude, submitted_at) VALUES
('CF-2024-001', 7, 'Pothole', 'Large pothole causing accidents near main junction', 'Nagpur', 'North', 'Ward 12', 'Assigned', 'High', 45, 21.1458, 79.0882, '2024-01-15 10:30:00'),
('CF-2024-002', 8, 'Garbage', 'Garbage not collected for 3 days in residential area', 'Nagpur', 'South', 'Ward 8', 'Verified', 'Medium', 23, 21.1200, 79.0600, '2024-01-15 09:15:00'),
('CF-2024-003', 9, 'Streetlight', 'Street light not working for a week', 'Nagpur', 'East', 'Ward 15', 'In Progress', 'Medium', 12, 21.1600, 79.1100, '2024-01-14 18:45:00'),
('CF-2024-004', 10, 'Water Supply', 'No water supply since morning', 'Nagpur', 'West', 'Ward 3', 'Submitted', 'High', 67, 21.1300, 79.0800, '2024-01-15 06:00:00'),
('CF-2024-005', 11, 'Drainage', 'Blocked drain causing waterlogging', 'Nagpur', 'Central', 'Ward 1', 'Completed', 'High', 34, 21.1500, 79.0900, '2024-01-13 14:20:00'),
('CF-2024-006', 12, 'Road Damage', 'Road surface damaged after recent construction', 'Nagpur', 'North', 'Ward 10', 'Assigned', 'Medium', 19, 21.1550, 79.0950, '2024-01-14 11:30:00'),
('CF-2024-007', 13, 'Sewage', 'Sewage overflow on main road', 'Nagpur', 'South', 'Ward 5', 'In Progress', 'High', 56, 21.1250, 79.0650, '2024-01-15 07:45:00'),
('CF-2024-008', 14, 'Illegal Parking', 'Vehicles blocking pedestrian pathway', 'Nagpur', 'Central', 'Ward 2', 'Closed', 'Low', 8, 21.1480, 79.0885, '2024-01-12 16:00:00')
ON CONFLICT (id) DO NOTHING;

-- Insert Alerts
INSERT INTO alerts (id, type, message, division, related_id, created_at) VALUES
('ALT-001', 'Hotspot Warning', 'High concentration of complaints detected in Ward 12, North Division', 'North', 'Ward 12', '2024-01-15 08:00:00'),
('ALT-002', 'Long Pending', 'Complaint CF-2024-004 pending for more than 48 hours', 'West', 'CF-2024-004', '2024-01-15 06:30:00'),
('ALT-003', 'Unresponsive Contractor', 'Urban Repair Hub has not responded to 3 assigned tasks', 'South', 'CON-005', '2024-01-14 18:00:00'),
('ALT-004', 'High Volume', '25% increase in complaints from Central Division today', 'Central', NULL, '2024-01-15 10:00:00'),
('ALT-005', 'Repeated Issue', 'Same pothole location reported 5 times this month', 'North', 'Ward 12', '2024-01-15 09:30:00')
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- Supabase Storage (photos bucket)
-- =============================================
-- Bucket created via Supabase dashboard: "photos" (public)
-- The app uploads images to paths like: complaints/{timestamp}-{rand}.jpg
-- Ensure RLS is disabled for storage bucket or proper policies are set.

