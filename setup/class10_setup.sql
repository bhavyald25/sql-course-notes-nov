-- =====================================================================
--  SQL CLASS 10  |  Setup for pgAdmin 4 + PostgreSQL 17
--  Run this before using class10_inclass_snippets.sql, or whenever your
--  tables break. It rebuilds every table from classes 3 to 9, including
--  the four tables designed in class 9 (students_n, courses_n,
--  enrollments_n, instructors_n) in their finished form, and removes any
--  view or materialized view built on them. Safe to run again any time.
-- =====================================================================
--  HOW: click database sql_class -> Tools -> Query Tool -> paste this
--  whole file -> F5. Messages tab: "Query returned successfully".
--  (A "WARNING: there is no transaction in progress" first is fine: the
--  ROLLBACK on the next line only closes a transaction left open in
--  this tab.)
-- =====================================================================

ROLLBACK;

-- Views built in class 10. A view depends on its tables, so views go first.
-- CASCADE on the table drops below also removes any view YOU created with
-- a different name.
DROP VIEW IF EXISTS sql_students, enrollment_details, students_per_course,
                    instructor_contacts, mumbai_students, chennai_students, instructor_load,
                    bangalore_students, course_catalog, city_enrollments, delhi_students;
DROP MATERIALIZED VIEW IF EXISTS students_per_course_mv, monthly_report, students_per_city_mv;

-- Remove old tables, children before parents
DROP TABLE IF EXISTS enrollments_n CASCADE;
DROP TABLE IF EXISTS courses_n CASCADE;
DROP TABLE IF EXISTS instructors_n CASCADE;
DROP TABLE IF EXISTS students_n CASCADE;
DROP TABLE IF EXISTS admissions_1nf CASCADE;
DROP TABLE IF EXISTS admissions_sheet CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS orders_bad CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS shirts CASCADE;
DROP TABLE IF EXISTS trousers CASCADE;
DROP TABLE IF EXISTS morning_batch CASCADE;
DROP TABLE IF EXISTS evening_batch CASCADE;
DROP TABLE IF EXISTS practice_delete CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS students CASCADE;

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


-- ============ Three bank accounts (class 8, kept for today's Part E) ====
-- Arjun 30000, Priya 8000, the institute 50000: total 88000.
-- CHECK (balance >= 0) means a payment larger than the balance FAILS,
-- which is how we will see a transaction protect the data.
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    holder     VARCHAR(50) NOT NULL,
    balance    NUMERIC(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES
(1, 'Arjun',     30000.00),
(2, 'Priya',      8000.00),
(3, 'Institute', 50000.00);


-- ============ Class 9: the admissions spreadsheet (kept for reference) ====
-- admissions_sheet is the office's spreadsheet exactly as it was typed:
-- one row per student, several courses crammed into one cell, and the
-- instructors' phone numbers copied by hand onto every row.
-- Two typing mistakes are in it on purpose, because that is what happens
-- when the same fact is typed many times:
--   Kiran's course is typed 'Data science' (small s), everyone else's
--   'Data Science'.
--   Vikram's phone is 98400 22222 on four rows and 98400 22223 on Nisha's.
-- Deepa has been admitted but has not chosen a course yet.
CREATE TABLE admissions_sheet (
    roll_no           INT,
    student_name      VARCHAR(50),
    city              VARCHAR(50),
    courses           VARCHAR(100),
    instructors       VARCHAR(100),
    instructor_phones VARCHAR(100)
);

INSERT INTO admissions_sheet VALUES
(1,  'Anu',   'Chennai',   'Python, SQL',        'Anita, Vikram', '98400 11111, 98400 22222'),
(2,  'Rahul', 'Bangalore', 'SQL, Data Science',  'Vikram, Neha',  '98400 22222, 98400 44444'),
(3,  'Priya', 'Hyderabad', 'SQL',                'Vikram',        '98400 22222'),
(4,  'John',  'Chennai',   'Java',               'Suresh',        '98400 33333'),
(5,  'Sara',  'Mumbai',    'Python',             'Anita',         '98400 11111'),
(6,  'Kiran', 'Bangalore', 'Data science',       'Neha',          '98400 44444'),
(7,  'Meena', 'Chennai',   'SQL',                'Vikram',        '98400 22222'),
(8,  'Arjun', 'Delhi',     'Machine Learning',   'Raj',           '98400 55555'),
(9,  'Divya', 'Hyderabad', 'Data Science',       'Neha',          '98400 44444'),
(10, 'Ravi',  'Mumbai',    'Java',               'Suresh',        '98400 33333'),
(11, 'Nisha', 'Mumbai',    'MySQL',              'Vikram',        '98400 22223'),
(12, 'Deepa', NULL,        NULL,                 NULL,            NULL);

-- admissions_1nf: the same sheet retyped by the office with ONE course per
-- row (first normal form) and a code for each course. Same two typing
-- mistakes. Deepa cannot appear: a row needs a course.
CREATE TABLE admissions_1nf (
    roll_no          INT,
    student_name     VARCHAR(50),
    city             VARCHAR(50),
    course_id        INT,
    course_name      VARCHAR(50),
    instructor       VARCHAR(50),
    instructor_phone VARCHAR(20),
    PRIMARY KEY (roll_no, course_id)
);

INSERT INTO admissions_1nf VALUES
(1,  'Anu',   'Chennai',   101, 'Python',           'Anita',  '98400 11111'),
(1,  'Anu',   'Chennai',   102, 'SQL',              'Vikram', '98400 22222'),
(2,  'Rahul', 'Bangalore', 102, 'SQL',              'Vikram', '98400 22222'),
(2,  'Rahul', 'Bangalore', 104, 'Data Science',     'Neha',   '98400 44444'),
(3,  'Priya', 'Hyderabad', 102, 'SQL',              'Vikram', '98400 22222'),
(4,  'John',  'Chennai',   103, 'Java',             'Suresh', '98400 33333'),
(5,  'Sara',  'Mumbai',    101, 'Python',           'Anita',  '98400 11111'),
(6,  'Kiran', 'Bangalore', 104, 'Data science',     'Neha',   '98400 44444'),
(7,  'Meena', 'Chennai',   102, 'SQL',              'Vikram', '98400 22222'),
(8,  'Arjun', 'Delhi',     105, 'Machine Learning', 'Raj',    '98400 55555'),
(9,  'Divya', 'Hyderabad', 104, 'Data Science',     'Neha',   '98400 44444'),
(10, 'Ravi',  'Mumbai',    103, 'Java',             'Suresh', '98400 33333'),
(11, 'Nisha', 'Mumbai',    107, 'MySQL',            'Vikram', '98400 22223');


-- ============ The four tables designed in class 9, finished form ==========
-- One fact in one place: a student's city in students_n, a course's name in
-- courses_n, an instructor's phone in instructors_n, and who-takes-what in
-- enrollments_n. Kiran's typo is fixed, Vikram has one phone number, Deepa
-- is a student with no course, Cloud Computing is a course with no students.
CREATE TABLE students_n (
    roll_no      INT PRIMARY KEY,
    student_name VARCHAR(50) NOT NULL,
    city         VARCHAR(50)
);

INSERT INTO students_n VALUES
(1,  'Anu',   'Chennai'),
(2,  'Rahul', 'Bangalore'),
(3,  'Priya', 'Hyderabad'),
(4,  'John',  'Chennai'),
(5,  'Sara',  'Mumbai'),
(6,  'Kiran', 'Bangalore'),
(7,  'Meena', 'Chennai'),
(8,  'Arjun', 'Delhi'),
(9,  'Divya', 'Hyderabad'),
(10, 'Ravi',  'Mumbai'),
(11, 'Nisha', 'Mumbai'),
(12, 'Deepa', NULL);

CREATE TABLE instructors_n (
    instructor_id   INT PRIMARY KEY,
    instructor_name VARCHAR(50) NOT NULL UNIQUE,
    phone           VARCHAR(20)
);

INSERT INTO instructors_n VALUES
(1, 'Anita',  '98400 11111'),
(2, 'Vikram', '98400 22222'),
(3, 'Suresh', '98400 33333'),
(4, 'Neha',   '98400 44444'),
(5, 'Raj',    '98400 55555'),
(6, 'Asha',   '98400 66666');

CREATE TABLE courses_n (
    course_id     INT PRIMARY KEY,
    course_name   VARCHAR(50) NOT NULL,
    instructor_id INT REFERENCES instructors_n (instructor_id)
);

INSERT INTO courses_n VALUES
(101, 'Python',           1),
(102, 'SQL',              2),
(103, 'Java',             3),
(104, 'Data Science',     4),
(105, 'Machine Learning', 5),
(106, 'Cloud Computing',  6),      -- no students yet
(107, 'MySQL',            2);      -- Vikram's second course

CREATE TABLE enrollments_n (
    roll_no   INT REFERENCES students_n (roll_no),
    course_id INT REFERENCES courses_n (course_id),
    PRIMARY KEY (roll_no, course_id)
);

INSERT INTO enrollments_n VALUES
(1, 101), (1, 102),
(2, 102), (2, 104),
(3, 102),
(4, 103),
(5, 101),
(6, 104),
(7, 102),
(8, 105),
(9, 104),
(10, 103),
(11, 107);

-- Quick check: 12 | 7 | 13 | 6
SELECT (SELECT COUNT(*) FROM students_n)    AS students,
       (SELECT COUNT(*) FROM courses_n)     AS courses,
       (SELECT COUNT(*) FROM enrollments_n) AS enrollments,
       (SELECT COUNT(*) FROM instructors_n) AS instructors;
