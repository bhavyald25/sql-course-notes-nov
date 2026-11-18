-- =====================================================================
--  SQL CLASS 2  |  Setup for pgAdmin 4 + PostgreSQL 17
--  Builds the three tables (students, courses, enrollments) exactly as
--  they were at the START of class 2: 11 students, no payments table yet.
--  Run it before using class2_inclass_snippets.sql.
-- =====================================================================
--  HOW TO USE (pgAdmin):
--    1. Left tree: click database sql_class -> Tools -> Query Tool.
--    2. Paste this whole file. Press F5.
--    3. Messages tab: "Query returned successfully".
--    4. Right-click Tables -> Refresh. 3 tables appear.
--  Safe to run again any time. It removes and rebuilds these tables,
--  including the payments table that class 2 creates.
--  OneCompiler users: keep this at the TOP, type queries BELOW it.
-- =====================================================================

DROP TABLE IF EXISTS practice_delete;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;

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
(1, 'Anu', 21, 'Chennai', 'anu@example.com', 12000, '2026-01-10'),
(2, 'Rahul', 23, 'Bangalore', 'rahul@example.com', 15000, '2026-01-12'),
(3, 'Priya', 20, 'Hyderabad', 'priya@example.com', 15000, '2026-02-05'),
(4, 'John', 22, 'Chennai', 'john@example.com', 10000, '2026-02-15'),
(5, 'Sara', 24, 'Mumbai', 'sara@example.com', 12000, '2026-03-01'),
(6, 'Kiran', 25, 'Bangalore', 'kiran@example.com', 18000, '2026-03-10'),
(7, 'Meena', 21, 'Chennai', 'meena@example.com', 14000, '2026-04-05'),
(8, 'Arjun', 26, 'Delhi', 'arjun@example.com', 20000, '2026-04-12'),
(9, 'Divya', 22, 'Hyderabad', 'divya@example.com', 16000, '2026-05-01'),
(10, 'Ravi', 23, 'Mumbai', 'ravi@example.com', 11000, '2026-05-15'),
(11, 'nisha', 23, 'Mumbai', 'nisha@example.com', 11000, '2026-05-15');

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
(106, 'Cloud Computing', 3, 'Asha');

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

-- Quick check: 11 rows expected
SELECT * FROM students ORDER BY student_id;
