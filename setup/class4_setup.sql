-- =====================================================================
--  SQL CLASS 4  |  Setup for pgAdmin 4 + PostgreSQL 17
--  Run this before using class4_inclass_snippets.sql, or whenever your
--  tables break. It rebuilds every table exactly as it was at the end
--  of class 3 (same tables as class 3). Safe to run again any time.
-- =====================================================================
--  HOW: click database sql_class -> Tools -> Query Tool -> paste this
--  whole file -> F5. Messages tab: "Query returned successfully".
-- =====================================================================

-- Remove old tables, children before parents
DROP TABLE IF EXISTS orders_bad;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS shirts;
DROP TABLE IF EXISTS trousers;
DROP TABLE IF EXISTS morning_batch;
DROP TABLE IF EXISTS evening_batch;
DROP TABLE IF EXISTS practice_delete;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;

-- ===================== Tables from classes 1 and 2 ====================

CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(50) NOT NULL,
    age INT CHECK (age >= 0),
    city VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    fees INT,
    admission_date DATE
);

INSERT INTO students (student_id, student_name, age, city, email, fees, admission_date) VALUES
(1,  'Anu',   21, 'Chennai',   'anu@example.com',   12000, '2026-01-10'),
(2,  'Rahul', 23, 'Bangalore', 'rahul@example.com', 15000, '2026-01-12'),
(3,  'Priya', 20, 'Hyderabad', 'priya@example.com', 15000, '2026-02-05'),
(4,  'John',  22, 'Chennai',   'john@example.com',  10000, '2026-02-15'),
(5,  'Sara',  24, 'Mumbai',    'sara@example.com',  12000, '2026-03-01'),
(6,  'Kiran', 25, 'Bangalore', 'kiran@example.com', 18000, '2026-03-10'),
(7,  'Meena', 21, 'Chennai',   'meena@example.com', 14000, '2026-04-05'),
(8,  'Arjun', 26, 'Delhi',     'arjun@example.com', 20000, '2026-04-12'),
(9,  'Divya', 22, 'Hyderabad', 'divya@example.com', 16000, '2026-05-01'),
(10, 'Ravi',  23, 'Mumbai',    'ravi@example.com',  11000, '2026-05-15'),
(11, 'Nisha', 23, 'Mumbai',    'nisha@example.com', 11000, '2026-05-15'),
(12, 'Deepa', 24, NULL,        'deepa@example.com', 15000, CURRENT_DATE);   -- added in class 2, city unknown

CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(50) NOT NULL,
    duration_months INT,
    instructor VARCHAR(50)
);

INSERT INTO courses VALUES
(101, 'Python', 3, 'Anita'),
(102, 'SQL', 2, 'Vikram'),
(103, 'Java', 4, 'Suresh'),
(104, 'Data Science', 6, 'Neha'),
(105, 'Machine Learning', 5, 'Raj'),
(106, 'Cloud Computing', 3, 'Asha');          -- nobody enrolled

CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    enrollment_date DATE,
    status VARCHAR(20)
);

INSERT INTO enrollments VALUES
(1, 1, 101, '2026-01-10', 'Active'),
(2, 2, 102, '2026-01-12', 'Active'),
(3, 3, 102, '2026-02-05', 'Active'),
(4, 4, 103, '2026-02-15', 'Completed'),
(5, 5, 101, '2026-03-01', 'Active'),
(6, 6, 104, '2026-03-10', 'Active'),
(7, 7, 102, '2026-04-05', 'Completed'),
(8, 8, 105, '2026-04-12', 'Active'),
(9, 9, 104, '2026-05-01', 'Active'),
(10, 10, 103, '2026-05-15', 'Active'),
(11, 1, 102, '2026-06-01', 'Active'),
(12, 2, 104, '2026-06-05', 'Active');

CREATE TABLE payments (
    payment_id   INT PRIMARY KEY,
    student_id   INT REFERENCES students(student_id),
    amount       NUMERIC(10,2) NOT NULL,
    paid_on      DATE NOT NULL,
    is_verified  BOOLEAN NOT NULL,
    method       VARCHAR(20)                      -- added with ALTER TABLE in class 2
);

INSERT INTO payments (payment_id, student_id, amount, paid_on, is_verified, method) VALUES
(1, 1,    6000.00,  '2026-01-10', TRUE,  NULL),
(2, 1,    6000.00,  '2026-02-10', TRUE,  NULL),
(3, 2,    7500.50,  '2026-01-12', TRUE,  NULL),
(4, 4,    10000.00, '2026-02-15', TRUE,  NULL),
(5, 5,    12000.00, '2026-03-01', FALSE, NULL),
(6, 8,    20000.00, '2026-04-12', TRUE,  NULL),
(7, 10,   11000.00, '2026-05-15', FALSE, NULL),
(8, NULL, 10000.00, '2026-11-10', FALSE, 'Bank transfer');   -- nobody knows who paid

-- ============ Small practice tables (shop, batches, cross join) =========

-- A tiny shop: 4 customers, 4 orders. Built so that every join gives a
-- DIFFERENT number of rows:
--   Anu ordered twice            -> one-to-many (INNER shows her twice)
--   Sara and John never ordered  -> 2 empty rows in LEFT JOIN
--   Order 104 has no customer    -> 1 empty row in RIGHT JOIN
--   INNER 3 rows, LEFT 5, RIGHT 4, FULL 6
CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL
);

INSERT INTO customers VALUES
(1, 'Anu'),
(2, 'Ravi'),
(3, 'Sara'),
(4, 'John');

CREATE TABLE orders (
    order_id    INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),   -- the link; may be empty
    item        VARCHAR(30) NOT NULL,
    amount      INT NOT NULL
);

INSERT INTO orders VALUES
(101, 1,    'Book', 500),
(102, 1,    'Pen',   50),
(103, 2,    'Bag',  900),
(104, NULL, 'Cap',  200);

-- The SAME orders, designed badly: the customer's NAME typed on each
-- order instead of the customer's ID. Order 202 was typed as "anu ".
CREATE TABLE orders_bad (
    order_id      INT PRIMARY KEY,
    customer_name VARCHAR(50),
    item          VARCHAR(30)
);

INSERT INTO orders_bad VALUES
(201, 'Anu',  'Book'),
(202, 'anu ', 'Pen'),
(203, 'Ravi', 'Bag');

-- For CROSS JOIN
CREATE TABLE shirts   (shirt   VARCHAR(20));
CREATE TABLE trousers (trouser VARCHAR(20));
INSERT INTO shirts   VALUES ('White'), ('Blue'), ('Black');
INSERT INTO trousers VALUES ('Jeans'), ('Chinos');

-- For UNION / INTERSECT / EXCEPT. Ravi and Sara attend both batches.
-- Built so that every operation gives a DIFFERENT number of rows:
--   UNION ALL 8, UNION 6, INTERSECT 2, morning EXCEPT evening 3, evening EXCEPT morning 1
CREATE TABLE morning_batch (student_name VARCHAR(50));
CREATE TABLE evening_batch (student_name VARCHAR(50));
INSERT INTO morning_batch VALUES ('Anu'), ('Ravi'), ('Sara'), ('John'), ('Priya');
INSERT INTO evening_batch VALUES ('Ravi'), ('Sara'), ('Meena');

-- Quick check: 4 customers expected
SELECT * FROM customers;
