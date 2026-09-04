DROP DATABASE IF EXISTS analytics_lab;

CREATE DATABASE analytics_lab;

USE analytics_lab;


CREATE TABLE departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100) NOT NULL,
    budget DECIMAL(12, 2) NOT NULL
);


CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    department_id INT NOT NULL,
    manager_id INT NULL,
    position VARCHAR(100) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    hire_date DATE NOT NULL,
    employment_status VARCHAR(30) NOT NULL,

    FOREIGN KEY (department_id)
        REFERENCES departments(id),

    FOREIGN KEY (manager_id)
        REFERENCES employees(id)
);


CREATE TABLE clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    client_type VARCHAR(50) NOT NULL,
    created_at DATE NOT NULL
);


CREATE TABLE projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    client_id INT NOT NULL,
    manager_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    budget DECIMAL(12, 2) NOT NULL,
    status VARCHAR(40) NOT NULL,

    FOREIGN KEY (client_id)
        REFERENCES clients(id),

    FOREIGN KEY (manager_id)
        REFERENCES employees(id)
);


CREATE TABLE project_members (
    project_id INT NOT NULL,
    employee_id INT NOT NULL,
    role VARCHAR(100) NOT NULL,
    assigned_date DATE NOT NULL,

    PRIMARY KEY (project_id, employee_id),

    FOREIGN KEY (project_id)
        REFERENCES projects(id),

    FOREIGN KEY (employee_id)
        REFERENCES employees(id)
);


CREATE TABLE tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    assigned_employee_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority VARCHAR(30) NOT NULL,
    status VARCHAR(40) NOT NULL,
    estimated_hours DECIMAL(8, 2) NOT NULL,
    due_date DATE NOT NULL,

    FOREIGN KEY (project_id)
        REFERENCES projects(id),

    FOREIGN KEY (assigned_employee_id)
        REFERENCES employees(id)
);


CREATE TABLE time_entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    project_id INT NOT NULL,
    task_id INT NULL,
    work_date DATE NOT NULL,
    hours DECIMAL(6, 2) NOT NULL,
    description VARCHAR(255),

    FOREIGN KEY (employee_id)
        REFERENCES employees(id),

    FOREIGN KEY (project_id)
        REFERENCES projects(id),

    FOREIGN KEY (task_id)
        REFERENCES tasks(id)
);


CREATE TABLE suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    contact_person VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    rating DECIMAL(3, 2) NOT NULL
);


CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(100) NOT NULL,
    supplier_id INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL,
    minimum_stock INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,

    FOREIGN KEY (supplier_id)
        REFERENCES suppliers(id)
);


CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(40) NOT NULL,
    shipping_city VARCHAR(100) NOT NULL,
    shipping_country VARCHAR(100) NOT NULL,

    FOREIGN KEY (client_id)
        REFERENCES clients(id)
);


CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,

    FOREIGN KEY (order_id)
        REFERENCES orders(id),

    FOREIGN KEY (product_id)
        REFERENCES products(id)
);


CREATE TABLE shipments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    carrier VARCHAR(100) NOT NULL,
    tracking_number VARCHAR(100) NOT NULL,
    shipped_date DATE NULL,
    delivery_date DATE NULL,
    status VARCHAR(40) NOT NULL,

    FOREIGN KEY (order_id)
        REFERENCES orders(id)
);


CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_date DATE NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    status VARCHAR(40) NOT NULL,

    FOREIGN KEY (order_id)
        REFERENCES orders(id)
);


INSERT INTO departments
(name, location, budget)
VALUES
('IT', 'Warsaw', 850000.00),
('Sales', 'Krakow', 600000.00),
('Marketing', 'Warsaw', 450000.00),
('Finance', 'Gdansk', 500000.00),
('Customer Support', 'Wroclaw', 400000.00);


INSERT INTO employees
(first_name, last_name, email, department_id, manager_id, position, salary, hire_date, employment_status)
VALUES
('Adam', 'Kowalski', 'adam.kowalski@example.com', 1, NULL, 'IT Director', 18500.00, '2018-03-12', 'Active'),
('Anna', 'Nowak', 'anna.nowak@example.com', 2, NULL, 'Sales Director', 17200.00, '2019-06-01', 'Active'),
('Piotr', 'Wisniewski', 'piotr.wisniewski@example.com', 3, NULL, 'Marketing Director', 16000.00, '2020-01-15', 'Active'),
('Maria', 'Wojcik', 'maria.wojcik@example.com', 4, NULL, 'Finance Manager', 15500.00, '2017-09-20', 'Active'),
('Tomasz', 'Kaminski', 'tomasz.kaminski@example.com', 5, NULL, 'Support Manager', 12800.00, '2021-02-10', 'Active');


INSERT INTO employees
(first_name, last_name, email, department_id, manager_id, position, salary, hire_date, employment_status)
VALUES
('Katarzyna', 'Lewandowska', 'katarzyna.lewandowska@example.com', 1, 1, 'Senior Developer', 14500.00, '2020-04-06', 'Active'),
('Michal', 'Zielinski', 'michal.zielinski@example.com', 1, 1, 'Database Administrator', 13800.00, '2021-08-16', 'Active'),
('Karolina', 'Szymanska', 'karolina.szymanska@example.com', 2, 2, 'Account Manager', 11200.00, '2022-01-10', 'Active'),
('Pawel', 'Dabrowski', 'pawel.dabrowski@example.com', 2, 2, 'Sales Specialist', 9800.00, '2022-11-02', 'Active'),
('Oliwia', 'Kozlowska', 'oliwia.kozlowska@example.com', 3, 3, 'Marketing Specialist', 9700.00, '2021-05-17', 'Active'),
('Jakub', 'Jankowski', 'jakub.jankowski@example.com', 4, 4, 'Financial Analyst', 10800.00, '2022-03-14', 'Active'),
('Natalia', 'Mazur', 'natalia.mazur@example.com', 5, 5, 'Support Specialist', 8500.00, '2023-07-03', 'Active'),
('Robert', 'Krawczyk', 'robert.krawczyk@example.com', 1, 1, 'Junior Developer', 7600.00, '2024-01-08', 'Active'),
('Zuzanna', 'Piotrowska', 'zuzanna.piotrowska@example.com', 5, 5, 'Support Specialist', 8200.00, '2023-10-09', 'Active'),
('Lukasz', 'Grabowski', 'lukasz.grabowski@example.com', 3, 3, 'Content Specialist', 8900.00, '2024-02-12', 'Active');


INSERT INTO clients
(company_name, contact_person, email, city, country, client_type, created_at)
VALUES
('Nordic Solutions', 'Erik Hansen', 'erik@nordic.example.com', 'Oslo', 'Norway', 'Enterprise', '2021-02-10'),
('Green Market Sp. z o.o.', 'Alicja Zielona', 'alicja@greenmarket.example.com', 'Warsaw', 'Poland', 'SMB', '2022-05-18'),
('Baltic Logistics', 'Marek Portowy', 'marek@baltic.example.com', 'Gdansk', 'Poland', 'Enterprise', '2020-11-03'),
('Euro Construction', 'Thomas Muller', 'thomas@eurobuild.example.com', 'Berlin', 'Germany', 'Enterprise', '2021-08-25'),
('Cloud Factory', 'Sofia Rossi', 'sofia@cloudfactory.example.com', 'Milan', 'Italy', 'Technology', '2023-01-14'),
('Health Plus', 'Monika Zdrowa', 'monika@healthplus.example.com', 'Krakow', 'Poland', 'Healthcare', '2022-09-12'),
('Urban Energy', 'David Brown', 'david@urbanenergy.example.com', 'London', 'United Kingdom', 'Energy', '2019-04-21'),
('Smart Education', 'Ewa Edukacja', 'ewa@smartedu.example.com', 'Wroclaw', 'Poland', 'Education', '2023-06-30');


INSERT INTO projects
(name, client_id, manager_id, start_date, end_date, budget, status)
VALUES
('Nordic E-commerce Platform', 1, 1, '2024-01-10', NULL, 420000.00, 'In progress'),
('Green Market Mobile App', 2, 6, '2024-02-15', '2024-09-30', 180000.00, 'Completed'),
('Baltic Warehouse System', 3, 7, '2024-03-01', NULL, 350000.00, 'In progress'),
('Euro Construction CRM', 4, 1, '2024-04-10', NULL, 275000.00, 'In progress'),
('Cloud Factory Analytics', 5, 7, '2024-05-05', '2024-11-30', 210000.00, 'Completed'),
('Health Plus Portal', 6, 6, '2024-06-20', NULL, 320000.00, 'In progress'),
('Urban Energy Dashboard', 7, 1, '2024-07-01', NULL, 290000.00, 'Planning'),
('Smart Education Platform', 8, 6, '2024-08-15', NULL, 240000.00, 'In progress');


INSERT INTO project_members
(project_id, employee_id, role, assigned_date)
VALUES
(1, 1, 'Project Manager', '2024-01-10'),
(1, 6, 'Senior Developer', '2024-01-10'),
(1, 7, 'Database Administrator', '2024-01-15'),
(1, 13, 'Junior Developer', '2024-02-01'),
(2, 6, 'Technical Lead', '2024-02-15'),
(2, 10, 'Marketing Consultant', '2024-02-15'),
(2, 13, 'Developer', '2024-03-01'),
(3, 7, 'Project Manager', '2024-03-01'),
(3, 6, 'Technical Consultant', '2024-03-10'),
(3, 9, 'Account Manager', '2024-03-01'),
(4, 1, 'Project Manager', '2024-04-10'),
(4, 8, 'Account Manager', '2024-04-10'),
(5, 7, 'Technical Lead', '2024-05-05'),
(5, 11, 'Financial Analyst', '2024-05-10'),
(6, 6, 'Project Manager', '2024-06-20'),
(6, 12, 'Support Consultant', '2024-06-20'),
(7, 1, 'Project Manager', '2024-07-01'),
(7, 14, 'Developer', '2024-07-15'),
(8, 6, 'Project Manager', '2024-08-15'),
(8, 15, 'Support Consultant', '2024-08-20');


INSERT INTO tasks
(project_id, assigned_employee_id, title, description, priority, status, estimated_hours, due_date)
VALUES
(1, 6, 'Design product catalogue', 'Prepare catalogue structure and product search.', 'High', 'Completed', 80.00, '2024-02-15'),
(1, 7, 'Design database schema', 'Create database tables and relations.', 'High', 'Completed', 65.00, '2024-02-28'),
(1, 13, 'Create login module', 'Implement customer authentication.', 'Medium', 'In progress', 55.00, '2024-04-15'),
(2, 13, 'Mobile application frontend', 'Create the main mobile screens.', 'High', 'Completed', 120.00, '2024-06-30'),
(2, 10, 'Prepare marketing campaign', 'Create campaign for application launch.', 'Medium', 'Completed', 45.00, '2024-07-15'),
(3, 7, 'Warehouse data model', 'Prepare data model for warehouse operations.', 'High', 'In progress', 90.00, '2024-05-20'),
(3, 9, 'Customer requirements', 'Collect and document business requirements.', 'High', 'Completed', 40.00, '2024-04-10'),
(4, 8, 'CRM sales workflow', 'Design sales pipeline and workflow.', 'Medium', 'In progress', 60.00, '2024-06-30'),
(4, 1, 'System architecture', 'Prepare technical architecture.', 'High', 'Completed', 70.00, '2024-05-30'),
(5, 7, 'Analytics database', 'Create reporting database.', 'High', 'Completed', 75.00, '2024-08-20'),
(5, 11, 'Financial reports', 'Prepare financial KPI reports.', 'Medium', 'Completed', 50.00, '2024-09-15'),
(6, 6, 'Patient portal backend', 'Implement portal backend services.', 'High', 'In progress', 140.00, '2024-10-30'),
(6, 12, 'Support process documentation', 'Prepare customer support procedures.', 'Low', 'In progress', 35.00, '2024-09-30'),
(7, 14, 'Dashboard interface', 'Create energy consumption dashboard.', 'Medium', 'Open', 100.00, '2024-11-15'),
(8, 15, 'User support module', 'Create support section for students.', 'Low', 'Open', 50.00, '2024-12-15');


INSERT INTO time_entries
(employee_id, project_id, task_id, work_date, hours, description)
VALUES
(6, 1, 1, '2024-01-15', 8.00, 'Catalogue planning'),
(6, 1, 1, '2024-01-16', 7.50, 'Catalogue structure'),
(7, 1, 2, '2024-01-18', 8.00, 'Database analysis'),
(7, 1, 2, '2024-01-19', 8.50, 'Database relations'),
(13, 1, 3, '2024-02-05', 7.00, 'Login module development'),
(13, 1, 3, '2024-02-06', 8.00, 'Authentication tests'),
(13, 2, 4, '2024-03-12', 8.00, 'Mobile frontend'),
(10, 2, 5, '2024-03-15', 6.50, 'Marketing campaign'),
(7, 3, 6, '2024-03-20', 8.00, 'Warehouse model'),
(9, 3, 7, '2024-03-21', 7.50, 'Customer workshop'),
(1, 4, 9, '2024-04-12', 8.00, 'Architecture planning'),
(8, 4, 8, '2024-04-15', 7.00, 'Sales process analysis'),
(7, 5, 10, '2024-05-10', 8.00, 'Analytics database'),
(11, 5, 11, '2024-05-15', 6.00, 'Financial KPI analysis'),
(6, 6, 12, '2024-06-25', 8.00, 'Backend development'),
(12, 6, 13, '2024-06-28', 5.50, 'Support documentation'),
(14, 7, 14, '2024-07-20', 8.00, 'Dashboard interface'),
(6, 8, NULL, '2024-08-20', 7.00, 'Platform planning'),
(15, 8, 15, '2024-08-22', 5.00, 'Support module planning'),
(1, 1, NULL, '2024-09-01', 4.00, 'Project management');


INSERT INTO suppliers
(company_name, contact_person, email, city, country, rating)
VALUES
('Tech Supply Poland', 'Andrzej Techniczny', 'contact@techsupply.example.com', 'Warsaw', 'Poland', 4.80),
('Global Electronics', 'Laura Smith', 'laura@globalelectronics.example.com', 'London', 'United Kingdom', 4.50),
('Office World', 'Peter Office', 'peter@officeworld.example.com', 'Berlin', 'Germany', 4.20),
('Home Solutions', 'Kamil Domowy', 'kamil@homesolutions.example.com', 'Poznan', 'Poland', 4.60),
('Book Distribution', 'Joanna Czyta', 'joanna@bookdistribution.example.com', 'Krakow', 'Poland', 4.70);


INSERT INTO products
(name, category, supplier_id, price, stock_quantity, minimum_stock, active)
VALUES
('Business Laptop Pro', 'Electronics', 1, 5499.99, 12, 5, TRUE),
('Wireless Mouse', 'Electronics', 2, 119.99, 85, 20, TRUE),
('Mechanical Keyboard', 'Electronics', 2, 349.99, 34, 10, TRUE),
('Office Monitor 27', 'Electronics', 1, 1299.00, 18, 5, TRUE),
('USB-C Docking Station', 'Electronics', 1, 499.99, 7, 10, TRUE),
('Ergonomic Office Chair', 'Office', 3, 899.00, 22, 5, TRUE),
('Standing Desk', 'Office', 3, 1499.00, 9, 3, TRUE),
('Desk Lamp', 'Office', 4, 159.99, 45, 10, TRUE),
('Coffee Machine Office', 'Office', 4, 799.00, 6, 8, TRUE),
('SQL Database Handbook', 'Books', 5, 89.99, 40, 10, TRUE),
('Project Management Guide', 'Books', 5, 74.99, 28, 8, TRUE),
('Data Analysis Handbook', 'Books', 5, 109.99, 16, 5, TRUE),
('Old Monitor Model', 'Electronics', 2, 399.00, 0, 3, FALSE),
('Notebook Premium', 'Office', 4, 29.99, 120, 30, TRUE);


INSERT INTO orders
(client_id, order_date, status, shipping_city, shipping_country)
VALUES
(1, '2024-09-01', 'Completed', 'Oslo', 'Norway'),
(2, '2024-09-03', 'Completed', 'Warsaw', 'Poland'),
(3, '2024-09-05', 'Shipped', 'Gdansk', 'Poland'),
(4, '2024-09-07', 'Processing', 'Berlin', 'Germany'),
(5, '2024-09-10', 'Completed', 'Milan', 'Italy'),
(6, '2024-09-12', 'Cancelled', 'Krakow', 'Poland'),
(7, '2024-09-15', 'Shipped', 'London', 'United Kingdom'),
(8, '2024-09-18', 'Processing', 'Wroclaw', 'Poland'),
(2, '2024-09-20', 'Completed', 'Warsaw', 'Poland'),
(3, '2024-09-22', 'Shipped', 'Gdansk', 'Poland'),
(1, '2024-09-25', 'Processing', 'Oslo', 'Norway'),
(4, '2024-09-28', 'Completed', 'Berlin', 'Germany');


INSERT INTO order_items
(order_id, product_id, quantity, unit_price)
VALUES
(1, 1, 2, 5499.99),
(1, 2, 5, 119.99),
(2, 6, 3, 899.00),
(2, 8, 5, 159.99),
(2, 14, 20, 29.99),
(3, 4, 4, 1299.00),
(3, 5, 2, 499.99),
(4, 7, 2, 1499.00),
(4, 9, 1, 799.00),
(5, 3, 10, 349.99),
(5, 10, 15, 89.99),
(6, 1, 1, 5499.99),
(7, 4, 3, 1299.00),
(7, 6, 4, 899.00),
(8, 12, 5, 109.99),
(8, 11, 8, 74.99),
(9, 2, 12, 119.99),
(9, 3, 8, 349.99),
(10, 10, 25, 89.99),
(10, 12, 10, 109.99),
(11, 1, 1, 5499.99),
(11, 4, 2, 1299.00),
(12, 7, 1, 1499.00),
(12, 9, 2, 799.00);


INSERT INTO shipments
(order_id, carrier, tracking_number, shipped_date, delivery_date, status)
VALUES
(1, 'DHL', 'DHL-100001', '2024-09-02', '2024-09-05', 'Delivered'),
(2, 'InPost', 'INP-100002', '2024-09-04', '2024-09-06', 'Delivered'),
(3, 'DPD', 'DPD-100003', '2024-09-06', NULL, 'In transit'),
(4, 'DHL', 'DHL-100004', NULL, NULL, 'Preparing'),
(5, 'UPS', 'UPS-100005', '2024-09-11', '2024-09-15', 'Delivered'),
(7, 'FedEx', 'FED-100007', '2024-09-16', NULL, 'In transit'),
(8, 'InPost', 'INP-100008', NULL, NULL, 'Preparing'),
(9, 'DPD', 'DPD-100009', '2024-09-21', '2024-09-23', 'Delivered'),
(10, 'DHL', 'DHL-100010', '2024-09-23', NULL, 'In transit'),
(11, 'UPS', 'UPS-100011', NULL, NULL, 'Preparing'),
(12, 'FedEx', 'FED-100012', '2024-09-29', '2024-10-02', 'Delivered');


INSERT INTO payments
(order_id, payment_date, amount, payment_method, status)
VALUES
(1, '2024-09-01', 11699.95, 'Bank transfer', 'Paid'),
(2, '2024-09-03', 3608.75, 'Credit card', 'Paid'),
(3, '2024-09-05', 6195.98, 'Bank transfer', 'Paid'),
(4, NULL, 3797.00, 'Credit card', 'Pending'),
(5, '2024-09-10', 4848.80, 'Credit card', 'Paid'),
(6, NULL, 5499.99, 'Credit card', 'Refunded'),
(7, '2024-09-15', 7493.00, 'Bank transfer', 'Paid'),
(8, NULL, 1149.87, 'Credit card', 'Pending'),
(9, '2024-09-20', 4238.80, 'Bank transfer', 'Paid'),
(10, '2024-09-22', 3334.65, 'Credit card', 'Paid'),
(11, NULL, 8097.99, 'Bank transfer', 'Pending'),
(12, '2024-09-28', 3097.00, 'Credit card', 'Paid');