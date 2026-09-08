CREATE DATABASE IF NOT EXISTS company_test
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE company_test;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS time_entries;
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS project_tasks;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS warehouses;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    division VARCHAR(100) NOT NULL,
    budget DECIMAL(14,2) NOT NULL,
    created_at DATE NOT NULL
);

CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(180) NOT NULL UNIQUE,
    department_id INT NOT NULL,
    position VARCHAR(120) NOT NULL,
    salary DECIMAL(12,2) NOT NULL,
    hire_date DATE NOT NULL,
    employment_status ENUM('Active', 'On Leave', 'Inactive') NOT NULL DEFAULT 'Active',
    manager_id INT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

CREATE TABLE clients (
    client_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(180) NOT NULL,
    contact_person VARCHAR(150) NOT NULL,
    email VARCHAR(180) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    industry VARCHAR(100) NOT NULL,
    client_type ENUM('Enterprise', 'SMB', 'Startup', 'Public Sector') NOT NULL,
    annual_revenue DECIMAL(15,2) NULL,
    created_at DATE NOT NULL,
    account_manager_id INT NULL,
    FOREIGN KEY (account_manager_id) REFERENCES employees(employee_id)
);

CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(180) NOT NULL,
    contact_person VARCHAR(150) NOT NULL,
    email VARCHAR(180) NOT NULL,
    country VARCHAR(100) NOT NULL,
    rating DECIMAL(3,2) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(180) NOT NULL,
    category VARCHAR(100) NOT NULL,
    supplier_id INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    unit_cost DECIMAL(12,2) NOT NULL,
    stock_status ENUM('Available', 'Low Stock', 'Out of Stock', 'Discontinued') NOT NULL,
    created_at DATE NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

CREATE TABLE warehouses (
    warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_name VARCHAR(120) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    capacity INT NOT NULL,
    manager_id INT NULL,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    reserved_quantity INT NOT NULL DEFAULT 0,
    reorder_level INT NOT NULL,
    last_restock_date DATE NOT NULL,
    UNIQUE (warehouse_id, product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    project_name VARCHAR(180) NOT NULL,
    project_type VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    budget DECIMAL(14,2) NOT NULL,
    project_status ENUM('Planned', 'Active', 'Completed', 'Cancelled') NOT NULL,
    project_manager_id INT NOT NULL,
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (project_manager_id) REFERENCES employees(employee_id)
);

CREATE TABLE project_tasks (
    task_id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    assigned_employee_id INT NOT NULL,
    task_name VARCHAR(200) NOT NULL,
    priority ENUM('Low', 'Medium', 'High', 'Critical') NOT NULL,
    estimated_hours DECIMAL(8,2) NOT NULL,
    actual_hours DECIMAL(8,2) NOT NULL DEFAULT 0,
    task_status ENUM('Open', 'In Progress', 'Blocked', 'Completed') NOT NULL,
    due_date DATE NOT NULL,
    completed_at DATE NULL,
    FOREIGN KEY (project_id) REFERENCES projects(project_id),
    FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    order_date DATE NOT NULL,
    required_date DATE NOT NULL,
    order_status ENUM('New', 'Processing', 'Shipped', 'Delivered', 'Cancelled') NOT NULL,
    shipping_country VARCHAR(100) NOT NULL,
    total_value DECIMAL(14,2) NOT NULL,
    sales_employee_id INT NULL,
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (sales_employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(14,2) NOT NULL,
    payment_method ENUM('Bank Transfer', 'Credit Card', 'PayPal', 'Cash') NOT NULL,
    payment_status ENUM('Pending', 'Completed', 'Failed', 'Refunded') NOT NULL,
    transaction_reference VARCHAR(100) NOT NULL UNIQUE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE shipments (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    shipment_date DATE NULL,
    delivery_date DATE NULL,
    carrier VARCHAR(100) NOT NULL,
    tracking_number VARCHAR(120) NOT NULL UNIQUE,
    shipment_status ENUM('Preparing', 'Shipped', 'In Transit', 'Delivered', 'Returned') NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

CREATE TABLE time_entries (
    time_entry_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    project_id INT NULL,
    work_date DATE NOT NULL,
    hours DECIMAL(6,2) NOT NULL,
    billable BOOLEAN NOT NULL DEFAULT TRUE,
    hourly_rate DECIMAL(10,2) NOT NULL,
    description VARCHAR(255) NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

CREATE TABLE support_tickets (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    assigned_employee_id INT NULL,
    created_at DATETIME NOT NULL,
    resolved_at DATETIME NULL,
    category VARCHAR(100) NOT NULL,
    priority ENUM('Low', 'Medium', 'High', 'Critical') NOT NULL,
    ticket_status ENUM('Open', 'In Progress', 'Resolved', 'Closed') NOT NULL,
    satisfaction_score INT NULL,
    subject VARCHAR(255) NOT NULL,
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (assigned_employee_id) REFERENCES employees(employee_id)
);

INSERT INTO departments
(department_id, name, division, budget, created_at)
VALUES
(1, 'IT', 'Technology', 950000.00, '2018-01-10'),
(2, 'Sales', 'Commercial', 780000.00, '2018-01-10'),
(3, 'Marketing', 'Commercial', 420000.00, '2018-01-10'),
(4, 'Finance', 'Administration', 360000.00, '2018-01-10'),
(5, 'HR', 'Administration', 280000.00, '2018-01-10'),
(6, 'Support', 'Operations', 510000.00, '2018-01-10'),
(7, 'Operations', 'Operations', 690000.00, '2018-01-10'),
(8, 'Legal', 'Administration', 310000.00, '2018-01-10');

INSERT INTO employees
(employee_id, first_name, last_name, email, department_id, position,
 salary, hire_date, employment_status, manager_id)
VALUES
(1, 'Adam', 'Kowalski', 'adam.kowalski@example.com', 1, 'IT Director', 18500.00, '2018-03-12', 'Active', NULL),
(2, 'Anna', 'Nowak', 'anna.nowak@example.com', 2, 'Sales Director', 17200.00, '2019-06-01', 'Active', NULL),
(3, 'Piotr', 'Wisniewski', 'piotr.wisniewski@example.com', 3, 'Marketing Director', 16000.00, '2020-01-15', 'Active', NULL),
(4, 'Maria', 'Wojcik', 'maria.wojcik@example.com', 4, 'Finance Manager', 15500.00, '2017-09-20', 'Active', NULL),
(5, 'Tomasz', 'Kaminski', 'tomasz.kaminski@example.com', 6, 'Support Manager', 12800.00, '2021-02-10', 'Active', NULL),
(6, 'Katarzyna', 'Lewandowska', 'katarzyna.lewandowska@example.com', 1, 'Senior Developer', 14500.00, '2020-04-06', 'Active', 1),
(7, 'Michal', 'Zielinski', 'michal.zielinski@example.com', 1, 'Database Administrator', 13800.00, '2021-08-16', 'Active', 1),
(8, 'Karolina', 'Szymanska', 'karolina.szymanska@example.com', 2, 'Account Manager', 11200.00, '2022-01-10', 'Active', 2),
(9, 'Pawel', 'Dabrowski', 'pawel.dabrowski@example.com', 2, 'Sales Specialist', 9800.00, '2022-11-02', 'Active', 2),
(10, 'Olivia', 'Kozlowska', 'olivia.kozlowska@example.com', 3, 'Marketing Specialist', 9700.00, '2021-05-17', 'Active', 3),
(11, 'Jakub', 'Jankowski', 'jakub.jankowski@example.com', 4, 'Financial Analyst', 10800.00, '2022-03-14', 'Active', 4),
(12, 'Natalia', 'Mazur', 'natalia.mazur@example.com', 6, 'Support Specialist', 8500.00, '2023-07-03', 'Active', 5),
(13, 'Robert', 'Krawczyk', 'robert.krawczyk@example.com', 1, 'Junior Developer', 7600.00, '2024-01-08', 'Active', 1),
(14, 'Zuzanna', 'Piotrowska', 'zuzanna.piotrowska@example.com', 6, 'Support Specialist', 8200.00, '2023-10-09', 'Active', 5),
(15, 'Lukasz', 'Grabowski', 'lukasz.grabowski@example.com', 3, 'Content Specialist', 8900.00, '2024-02-12', 'Active', 3);

INSERT INTO clients
(client_id, company_name, contact_person, email, city, country, industry,
 client_type, annual_revenue, created_at, account_manager_id)
VALUES
(1, 'Nordic Solutions', 'Erik Hansen', 'erik@nordic.example.com', 'Oslo', 'Norway', 'Technology', 'Enterprise', 18500000.00, '2021-02-10', 8),
(2, 'Green Market Sp. z o.o.', 'Alicja Zielona', 'alicja@greenmarket.example.com', 'Warsaw', 'Poland', 'Retail', 'SMB', 4200000.00, '2022-05-18', 9),
(3, 'Baltic Logistics', 'Marek Portowy', 'marek@baltic.example.com', 'Gdansk', 'Poland', 'Logistics', 'Enterprise', 12700000.00, '2020-11-03', 8),
(4, 'Euro Construction', 'Thomas Muller', 'thomas@eurobuild.example.com', 'Berlin', 'Germany', 'Construction', 'Enterprise', 35600000.00, '2021-08-25', 2),
(5, 'Cloud Factory', 'Sofia Rossi', 'sofia@cloudfactory.example.com', 'Milan', 'Italy', 'Technology', 'Startup', 2800000.00, '2023-01-14', 9),
(6, 'Health Plus', 'Monika Zdrowa', 'monika@healthplus.example.com', 'Krakow', 'Poland', 'Healthcare', 'Enterprise', 21900000.00, '2022-09-12', 8),
(7, 'Urban Energy', 'David Brown', 'david@urbanenergy.example.com', 'London', 'United Kingdom', 'Energy', 'Enterprise', 48200000.00, '2019-04-21', 2),
(8, 'Smart Education', 'Ewa Edukacja', 'ewa@smartedu.example.com', 'Wroclaw', 'Poland', 'Education', 'Public Sector', 8700000.00, '2023-06-30', 9),
(9, 'Fresh Food Group', 'Jan Kowalczyk', 'jan@freshfood.example.com', 'Poznan', 'Poland', 'Food', 'SMB', 3600000.00, '2022-12-01', 8),
(10, 'Oceanic Telecom', 'Liam Smith', 'liam@oceanic.example.com', 'Dublin', 'Ireland', 'Telecommunications', 'Enterprise', 29400000.00, '2020-02-17', 2);

INSERT INTO suppliers
(supplier_id, company_name, contact_person, email, country, rating, active)
VALUES
(1, 'Tech Components Ltd', 'Robert Green', 'contact@techcomponents.example.com', 'Germany', 4.80, TRUE),
(2, 'Office World Sp. z o.o.', 'Marta Office', 'sales@officeworld.example.com', 'Poland', 4.40, TRUE),
(3, 'Secure Systems Inc.', 'John Carter', 'orders@securesystems.example.com', 'United States', 4.70, TRUE),
(4, 'Nordic Hardware AS', 'Ola Jensen', 'sales@nordichardware.example.com', 'Norway', 4.20, TRUE),
(5, 'Global Software House', 'Emily Stone', 'support@globalsoftware.example.com', 'United Kingdom', 4.90, TRUE),
(6, 'Eco Packaging GmbH', 'Hans Muller', 'orders@ecopackaging.example.com', 'Germany', 3.90, TRUE);

INSERT INTO products
(product_id, sku, product_name, category, supplier_id, unit_price,
 unit_cost, stock_status, created_at)
VALUES
(1, 'LAP-001', 'Business Laptop Pro', 'Computers', 1, 1450.00, 980.00, 'Available', '2022-01-10'),
(2, 'MON-002', 'UltraWide Monitor 34', 'Monitors', 1, 620.00, 390.00, 'Available', '2022-02-15'),
(3, 'SEC-003', 'Enterprise Security Suite', 'Software', 3, 890.00, 180.00, 'Available', '2022-04-20'),
(4, 'CRM-004', 'CRM Business License', 'Software', 5, 1250.00, 310.00, 'Low Stock', '2022-05-11'),
(5, 'KEY-005', 'Mechanical Keyboard', 'Accessories', 2, 145.00, 82.00, 'Available', '2022-06-03'),
(6, 'DOCK-006', 'USB-C Docking Station', 'Accessories', 4, 210.00, 120.00, 'Available', '2022-07-19'),
(7, 'SRV-007', 'Cloud Server Package', 'Cloud Services', 5, 2400.00, 740.00, 'Available', '2022-08-12'),
(8, 'NET-008', 'Enterprise Router', 'Networking', 4, 980.00, 610.00, 'Low Stock', '2022-09-08'),
(9, 'CAM-009', 'Security Camera Set', 'Security', 3, 760.00, 420.00, 'Available', '2022-10-15'),
(10, 'CHA-010', 'Ergonomic Office Chair', 'Office', 2, 440.00, 260.00, 'Available', '2022-11-21'),
(11, 'TAB-011', 'Business Tablet', 'Computers', 1, 780.00, 520.00, 'Out of Stock', '2023-01-09'),
(12, 'UPS-012', 'Power Backup Unit', 'Networking', 4, 350.00, 210.00, 'Available', '2023-02-14');

INSERT INTO warehouses
(warehouse_id, warehouse_name, city, country, capacity, manager_id)
VALUES
(1, 'Central Warehouse', 'Warsaw', 'Poland', 25000, 7),
(2, 'Northern Warehouse', 'Gdansk', 'Poland', 12000, 5),
(3, 'Western Warehouse', 'Berlin', 'Germany', 18000, 6);

INSERT INTO inventory
(warehouse_id, product_id, quantity, reserved_quantity, reorder_level, last_restock_date)
VALUES
(1, 1, 84, 12, 20, '2024-01-15'),
(1, 2, 46, 8, 15, '2024-02-08'),
(1, 3, 120, 25, 30, '2024-02-20'),
(1, 4, 18, 5, 20, '2024-03-01'),
(1, 5, 210, 32, 50, '2024-03-10'),
(1, 6, 76, 14, 20, '2024-03-16'),
(2, 7, 34, 7, 10, '2024-02-11'),
(2, 8, 12, 5, 15, '2024-02-28'),
(2, 9, 41, 9, 12, '2024-03-04'),
(3, 10, 92, 10, 20, '2024-01-27'),
(3, 11, 0, 0, 10, '2024-01-03'),
(3, 12, 28, 6, 10, '2024-03-18');

INSERT INTO projects
(project_id, client_id, project_name, project_type, start_date, end_date,
 budget, project_status, project_manager_id)
VALUES
(1, 1, 'Cloud Migration 2024', 'Cloud Migration', '2024-01-08', NULL, 420000.00, 'Active', 6),
(2, 2, 'Retail Analytics Platform', 'Data Analytics', '2024-02-12', NULL, 185000.00, 'Active', 13),
(3, 3, 'Warehouse Automation', 'Automation', '2023-09-01', '2024-03-15', 310000.00, 'Completed', 7),
(4, 4, 'Infrastructure Security Audit', 'Security', '2024-03-01', NULL, 120000.00, 'Active', 7),
(5, 6, 'Healthcare Portal', 'Web Application', '2023-11-20', NULL, 275000.00, 'Active', 6),
(6, 8, 'Digital Learning Platform', 'Education Technology', '2024-04-10', NULL, 390000.00, 'Planned', 13);

INSERT INTO project_tasks
(task_id, project_id, assigned_employee_id, task_name, priority,
 estimated_hours, actual_hours, task_status, due_date, completed_at)
VALUES
(1, 1, 6, 'Cloud architecture design', 'High', 80.00, 76.50, 'Completed', '2024-02-15', '2024-02-12'),
(2, 1, 7, 'Database migration', 'Critical', 120.00, 98.00, 'In Progress', '2024-05-30', NULL),
(3, 1, 13, 'Automated deployment pipeline', 'High', 60.00, 41.50, 'In Progress', '2024-05-20', NULL),
(4, 2, 13, 'Data model preparation', 'High', 72.00, 69.00, 'Completed', '2024-03-20', '2024-03-18'),
(5, 2, 10, 'Dashboard design', 'Medium', 45.00, 28.00, 'In Progress', '2024-05-12', NULL),
(6, 3, 7, 'Warehouse sensor integration', 'Critical', 90.00, 105.00, 'Completed', '2024-02-20', '2024-02-27'),
(7, 4, 7, 'Security vulnerability assessment', 'Critical', 55.00, 30.00, 'In Progress', '2024-05-05', NULL),
(8, 5, 6, 'API implementation', 'High', 110.00, 82.00, 'In Progress', '2024-06-15', NULL),
(9, 5, 13, 'Frontend development', 'Medium', 95.00, 46.00, 'In Progress', '2024-06-30', NULL),
(10, 6, 10, 'UX research', 'Medium', 40.00, 0.00, 'Open', '2024-06-10', NULL);

INSERT INTO orders
(order_id, client_id, order_date, required_date, order_status,
 shipping_country, total_value, sales_employee_id)
VALUES
(1, 1, '2024-01-12', '2024-01-22', 'Delivered', 'Norway', 14500.00, 8),
(2, 2, '2024-01-18', '2024-01-29', 'Delivered', 'Poland', 6240.00, 9),
(3, 3, '2024-02-03', '2024-02-14', 'Delivered', 'Poland', 18700.00, 8),
(4, 4, '2024-02-14', '2024-02-28', 'Shipped', 'Germany', 31200.00, 2),
(5, 5, '2024-02-22', '2024-03-05', 'Delivered', 'Italy', 9600.00, 9),
(6, 6, '2024-03-01', '2024-03-15', 'Processing', 'Poland', 22400.00, 8),
(7, 7, '2024-03-12', '2024-03-25', 'Delivered', 'United Kingdom', 48600.00, 2),
(8, 8, '2024-03-28', '2024-04-10', 'New', 'Poland', 7400.00, 9),
(9, 9, '2024-04-05', '2024-04-15', 'Cancelled', 'Poland', 3100.00, 8),
(10, 10, '2024-04-15', '2024-04-29', 'Delivered', 'Ireland', 27800.00, 2),
(11, 1, '2024-04-22', '2024-05-03', 'Processing', 'Norway', 19400.00, 8),
(12, 3, '2024-05-02', '2024-05-14', 'New', 'Poland', 8300.00, 9);

INSERT INTO order_items
(order_item_id, order_id, product_id, quantity, unit_price, discount_percent)
VALUES
(1, 1, 1, 5, 1450.00, 5.00),
(2, 1, 3, 4, 890.00, 0.00),
(3, 1, 6, 3, 210.00, 0.00),
(4, 2, 2, 4, 620.00, 5.00),
(5, 2, 5, 12, 145.00, 10.00),
(6, 2, 10, 3, 440.00, 0.00),
(7, 3, 7, 5, 2400.00, 8.00),
(8, 3, 8, 7, 980.00, 5.00),
(9, 4, 1, 12, 1450.00, 10.00),
(10, 4, 2, 8, 620.00, 8.00),
(11, 4, 9, 6, 760.00, 5.00),
(12, 5, 4, 6, 1250.00, 10.00),
(13, 5, 3, 4, 890.00, 5.00),
(14, 6, 6, 15, 210.00, 5.00),
(15, 6, 5, 20, 145.00, 8.00),
(16, 7, 7, 14, 2400.00, 12.00),
(17, 7, 3, 10, 890.00, 5.00),
(18, 8, 10, 8, 440.00, 0.00),
(19, 8, 5, 10, 145.00, 0.00),
(20, 9, 11, 4, 780.00, 0.00),
(21, 10, 1, 10, 1450.00, 7.00),
(22, 10, 4, 5, 1250.00, 5.00),
(23, 11, 8, 6, 980.00, 3.00),
(24, 11, 9, 8, 760.00, 5.00),
(25, 12, 3, 5, 890.00, 0.00),
(26, 12, 6, 4, 210.00, 0.00);

INSERT INTO payments
(payment_id, order_id, payment_date, amount, payment_method,
 payment_status, transaction_reference)
VALUES
(1, 1, '2024-01-13', 14500.00, 'Bank Transfer', 'Completed', 'TXN-10001'),
(2, 2, '2024-01-19', 6240.00, 'Credit Card', 'Completed', 'TXN-10002'),
(3, 3, '2024-02-04', 18700.00, 'Bank Transfer', 'Completed', 'TXN-10003'),
(4, 4, '2024-02-15', 31200.00, 'Bank Transfer', 'Completed', 'TXN-10004'),
(5, 5, '2024-02-23', 9600.00, 'PayPal', 'Completed', 'TXN-10005'),
(6, 6, '2024-03-02', 11200.00, 'Credit Card', 'Completed', 'TXN-10006'),
(7, 7, '2024-03-13', 48600.00, 'Bank Transfer', 'Completed', 'TXN-10007'),
(8, 8, '2024-03-29', 7400.00, 'Credit Card', 'Pending', 'TXN-10008'),
(9, 10, '2024-04-16', 27800.00, 'Bank Transfer', 'Completed', 'TXN-10009'),
(10, 11, '2024-04-23', 9700.00, 'Credit Card', 'Pending', 'TXN-10010'),
(11, 12, '2024-05-03', 8300.00, 'PayPal', 'Pending', 'TXN-10011');

INSERT INTO shipments
(shipment_id, order_id, warehouse_id, shipment_date, delivery_date,
 carrier, tracking_number, shipment_status)
VALUES
(1, 1, 1, '2024-01-15', '2024-01-21', 'DHL', 'DHL-PL-00001', 'Delivered'),
(2, 2, 1, '2024-01-20', '2024-01-27', 'DPD', 'DPD-PL-00002', 'Delivered'),
(3, 3, 2, '2024-02-05', '2024-02-12', 'InPost', 'INP-PL-00003', 'Delivered'),
(4, 4, 3, '2024-02-17', NULL, 'DHL', 'DHL-DE-00004', 'In Transit'),
(5, 5, 3, '2024-02-25', '2024-03-03', 'UPS', 'UPS-IT-00005', 'Delivered'),
(6, 7, 2, '2024-03-15', '2024-03-23', 'FedEx', 'FDX-UK-00006', 'Delivered'),
(7, 10, 3, '2024-04-18', '2024-04-27', 'DHL', 'DHL-IE-00007', 'Delivered');

INSERT INTO time_entries
(time_entry_id, employee_id, project_id, work_date, hours,
 billable, hourly_rate, description)
VALUES
(1, 6, 1, '2024-01-10', 7.50, TRUE, 145.00, 'Cloud architecture'),
(2, 7, 1, '2024-01-12', 8.00, TRUE, 138.00, 'Database migration planning'),
(3, 13, 1, '2024-01-15', 6.50, TRUE, 95.00, 'Deployment pipeline'),
(4, 10, 2, '2024-02-14', 7.00, TRUE, 105.00, 'Analytics dashboard'),
(5, 13, 2, '2024-02-16', 8.00, TRUE, 95.00, 'Data model'),
(6, 7, 3, '2024-02-20', 9.00, TRUE, 138.00, 'Sensor integration'),
(7, 6, 5, '2024-03-01', 8.00, TRUE, 145.00, 'API development'),
(8, 13, 5, '2024-03-04', 7.50, TRUE, 95.00, 'Frontend development'),
(9, 7, 4, '2024-03-12', 6.00, TRUE, 138.00, 'Security audit'),
(10, 10, 6, '2024-04-15', 5.50, TRUE, 105.00, 'User research'),
(11, 6, NULL, '2024-04-20', 3.00, FALSE, 145.00, 'Internal technical meeting'),
(12, 12, NULL, '2024-04-22', 7.00, FALSE, 85.00, 'Customer support training');

INSERT INTO support_tickets
(ticket_id, client_id, assigned_employee_id, created_at, resolved_at,
 category, priority, ticket_status, satisfaction_score, subject)
VALUES
(1, 1, 12, '2024-01-15 09:20:00', '2024-01-16 14:00:00', 'Cloud', 'High', 'Resolved', 5, 'Cloud access issue'),
(2, 2, 14, '2024-01-21 11:10:00', '2024-01-22 16:30:00', 'Hardware', 'Medium', 'Closed', 4, 'Monitor replacement'),
(3, 3, 12, '2024-02-04 08:45:00', NULL, 'Networking', 'Critical', 'In Progress', NULL, 'Warehouse router failure'),
(4, 4, 14, '2024-02-17 13:15:00', '2024-02-19 10:00:00', 'Security', 'High', 'Closed', 5, 'Security alert investigation'),
(5, 5, 12, '2024-02-25 15:40:00', '2024-02-27 12:20:00', 'Software', 'Low', 'Closed', 4, 'License activation'),
(6, 6, 14, '2024-03-04 10:00:00', NULL, 'Portal', 'High', 'Open', NULL, 'Healthcare portal error'),
(7, 7, 12, '2024-03-17 09:30:00', '2024-03-20 11:00:00', 'Cloud', 'Medium', 'Closed', 3, 'Cloud invoice question'),
(8, 8, 14, '2024-04-16 12:20:00', NULL, 'Application', 'Medium', 'In Progress', NULL, 'Login problems');