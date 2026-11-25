-- =====================================================================
--  SQL CLASS 10  |  Every query from the class, in order, with explanations
--  Topics: the ER diagram (left over from class 9), then views: a saved
--          query with a name, CREATE VIEW, CREATE OR REPLACE VIEW, DROP
--          VIEW, changing data through a view; then materialized views:
--          a stored result, CREATE MATERIALIZED VIEW, REFRESH. 15-question
--          practice set at the end.
-- =====================================================================
--  HOW TO USE THIS FILE
--  1. Run setup/class10_setup.sql first.
--  2. Open this file in the Query Tool (folder icon -> Open File).
--  3. Highlight ONE statement, from its first word to the semicolon,
--     and press F5. A CREATE VIEW ... AS SELECT ... is ONE statement:
--     highlight from CREATE down to the final semicolon.
--  4. Compare your result with the "Expect" line written above it.
--
--  Today you CREATE things that stay in the database (views). Run the
--  statements in the order written: a later one often uses a view made
--  by an earlier one. If you lose your way, run the setup again (it
--  removes every view and materialized view) and start Part V from V1.
--
--  Do not run the whole file at once. Several statements FAIL ON PURPOSE,
--  and the first failure cancels everything else in the run.
--
--  pgAdmin: after creating a view, right-click Schemas -> public -> Views
--  and choose Refresh to see it in the tree. Materialized views have
--  their own folder, Materialized Views.
--
--  TRY IT YOURSELF  = write the query before looking at the answer below it.
--  EXTRA CHALLENGE  = optional, a little harder.
--  [null]           = how pgAdmin shows an empty box.
-- =====================================================================


-- =====================================================================
--  PART 0  |  Check that the setup worked
-- =====================================================================

-- 0.1  Must show 12 | 6 | 82500.50.
--      Expect: 1 row (12, 6, 82500.50)
SELECT (SELECT COUNT(*) FROM students)              AS students,
       (SELECT COUNT(*) FROM courses)               AS courses,
       (SELECT SUM(amount) FROM payments)            AS total_paid;

-- 0.2  The four tables designed in class 9, now built by the setup.
--      Expect: 1 row (12, 7, 13, 6)
SELECT (SELECT COUNT(*) FROM students_n)    AS students,
       (SELECT COUNT(*) FROM courses_n)     AS courses,
       (SELECT COUNT(*) FROM enrollments_n) AS enrollments,
       (SELECT COUNT(*) FROM instructors_n) AS instructors;


-- =====================================================================
--  PART R  |  The ER diagram: the drawing of a design (from class 9)
--  An ER (entity-relationship) diagram shows one box per table (the
--  entity), the columns inside (attributes), the key marked PK, and a
--  line for each foreign key (relationship) with 1 and N at its ends.
--
--    students_n              enrollments_n             courses_n
--    +--------------+        +-----------------+       +---------------+
--    | roll_no  (PK)|--1---N-| roll_no   (PK,FK)|       | course_id (PK)|
--    | student_name |        | course_id (PK,FK)|-N---1-| course_name   |
--    | city         |        +-----------------+       | instructor_id |--N--+
--    +--------------+                                  +---------------+     |
--                                                                            1
--                                                      instructors_n         |
--                                                      +------------------+  |
--                                                      | instructor_id(PK)|--+
--                                                      | instructor_name  |
--                                                      | phone            |
--                                                      +------------------+
--
--  The 1 sits where the primary key lives, the N where the foreign key
--  lives: a roll number appears once in students_n and any number of
--  times in enrollments_n. Students and courses are linked many-to-many,
--  and SQL always does that through a third table with two foreign keys,
--  here enrollments_n.
--  To see pgAdmin's own drawing: right-click sql_class -> ERD For Database.
-- =====================================================================

-- R1  The original tables (students, courses, enrollments) follow the same drawing.
--     One detail differs: courses carries the instructor's NAME as text instead of an
--     id. No trouble as long as each instructor has a single course and no other
--     detail about them is kept; add a phone column and class 9's third normal form
--     would move it out into an instructors table.
--     Expect: 6 rows (each instructor once)
SELECT instructor, COUNT(*) AS courses
FROM courses
GROUP BY instructor
ORDER BY instructor;

-- R2  EXTRA CHALLENGE: SQL can cut the class-9 spreadsheet into rows by itself.
--     string_to_array cuts the cell at each comma; unnest turns the pieces into
--     rows. Two functions not covered in the course; compare with admissions_1nf.
--     Expect: 13 rows
SELECT roll_no, student_name,
       unnest(string_to_array(courses, ', ')) AS course
FROM admissions_sheet
ORDER BY roll_no;


-- =====================================================================
--  PART V  |  Views: a SELECT with a name
--  A view is a SELECT kept in the database under a name. Nothing else is
--  kept: no rows. Using the name makes the database execute that SELECT
--  on the tables as they are at that moment. So a view cannot fall
--  behind, and it occupies no space. Filter, sort, group and join it as
--  you would a table; from the outside it looks like one.
-- =====================================================================

-- V1  Start from what you know: the four-table join from class 9. Seven lines,
--     every time anybody wants this list.
--     Expect: 13 rows
SELECT s.roll_no, s.student_name, c.course_name, i.instructor_name
FROM enrollments_n e
JOIN students_n    s ON e.roll_no       = s.roll_no
JOIN courses_n     c ON e.course_id     = c.course_id
JOIN instructors_n i ON c.instructor_id = i.instructor_id
ORDER BY s.roll_no, c.course_id;

-- V2  Upgrade: CREATE VIEW name AS on a line above the query. The ORDER BY comes
--     off: a view behaves like a table, and a table carries no order of its own;
--     whoever reads it sorts it. Messages tab: CREATE VIEW. Data Output stays empty:
--     the SELECT was stored, not executed.
--     Expect: CREATE VIEW
CREATE VIEW enrollment_details AS
SELECT s.roll_no, s.student_name, c.course_name, i.instructor_name
FROM enrollments_n e
JOIN students_n    s ON e.roll_no       = s.roll_no
JOIN courses_n     c ON e.course_id     = c.course_id
JOIN instructors_n i ON c.instructor_id = i.instructor_id;

-- V3  Read it like a table. One line instead of seven; the same 13 rows.
--     Expect: 13 rows
SELECT * FROM enrollment_details ORDER BY roll_no, course_name;

-- V4  Filter it like a table.
--     Expect: 4 rows (Anu, Rahul, Priya, Meena)
SELECT student_name, course_name
FROM enrollment_details
WHERE course_name = 'SQL'
ORDER BY roll_no;

-- V5  Group it like a table. Five rows for six instructors: Asha's course has nobody
--     in it, and the stored SELECT starts at enrollments_n with plain JOINs, so a
--     course nobody has joined cannot produce a row. The SELECT inside decides what
--     the view is able to show.
--     Expect: 5 rows (Vikram 5, Neha 3, Anita 2, Suresh 2, Raj 1)
SELECT instructor_name, COUNT(*) AS students
FROM enrollment_details
GROUP BY instructor_name
ORDER BY students DESC, instructor_name;

-- V6  The view keeps up by itself. Change a table, then read the view: the change is
--     already visible, since using the name executed the SELECT afresh. Run V6.1 to
--     V6.4 one at a time.
--     Deepa joins Cloud Computing (nobody touched the view).
--     Expect: INSERT 0 1
INSERT INTO enrollments_n VALUES (12, 106);
--     Expect: 1 row (Deepa, Cloud Computing, Asha)
SELECT * FROM enrollment_details WHERE roll_no = 12;
--     Take it back; the view follows.
--     Expect: DELETE 1
DELETE FROM enrollments_n WHERE roll_no = 12 AND course_id = 106;
--     Expect: 0 rows
SELECT * FROM enrollment_details WHERE roll_no = 12;

-- V7  Where is the query kept? In the database's own catalogue. pgAdmin shows the
--     same text under Schemas -> public -> Views -> enrollment_details -> right-click
--     -> Properties -> Code. (PostgreSQL rewrites the spacing and brackets.)
--     Expect: 1 row (the saved SELECT)
SELECT definition FROM pg_views WHERE viewname = 'enrollment_details';

-- V8  Upgrade: CREATE OR REPLACE VIEW changes a view that already exists. New
--     columns may be ADDED at the end; here city and phone.
--     Expect: CREATE VIEW
CREATE OR REPLACE VIEW enrollment_details AS
SELECT s.roll_no, s.student_name, c.course_name, i.instructor_name,
       s.city, i.phone
FROM enrollments_n e
JOIN students_n    s ON e.roll_no       = s.roll_no
JOIN courses_n     c ON e.course_id     = c.course_id
JOIN instructors_n i ON c.instructor_id = i.instructor_id;

-- V9  Vikram's students, with his phone.
--     Expect: 5 rows (Anu, Rahul, Priya, Meena, Nisha; phone 98400 22222 on each)
SELECT student_name, course_name, phone
FROM enrollment_details
WHERE instructor_name = 'Vikram'
ORDER BY roll_no;

-- V10 Class 9's point, seen through a view: Vikram's phone is stored ONCE, in
--     instructors_n. Change it there; all five rows of the view show the new number.
--     Expect: UPDATE 1
UPDATE instructors_n SET phone = '98400 77777' WHERE instructor_name = 'Vikram';
--     Expect: 5 rows, phone 98400 77777 on each
SELECT student_name, course_name, phone
FROM enrollment_details
WHERE instructor_name = 'Vikram'
ORDER BY roll_no;

-- V11 FAILS ON PURPOSE. CREATE OR REPLACE can add columns but cannot REMOVE one:
--     something else might already be using it. To shrink a view: DROP VIEW, then
--     CREATE VIEW.
--     Expect: ERROR: cannot drop columns from view
CREATE OR REPLACE VIEW enrollment_details AS
SELECT s.roll_no, s.student_name, c.course_name, i.instructor_name
FROM enrollments_n e
JOIN students_n    s ON e.roll_no       = s.roll_no
JOIN courses_n     c ON e.course_id     = c.course_id
JOIN instructors_n i ON c.instructor_id = i.instructor_id;

-- V12 A view that LEAVES OUT a column. A user who is allowed this view and not the
--     table has no way of reaching the phone numbers: they are in nothing that user
--     can read. (Which user gets which view is decided with GRANT, class 13.)
--     Expect: CREATE VIEW
CREATE VIEW instructor_contacts AS
SELECT instructor_id, instructor_name
FROM instructors_n;
--     Expect: 6 rows, no phone column
SELECT * FROM instructor_contacts ORDER BY instructor_id;

-- V13 A view on ONE table, with a WHERE: the Mumbai students.
--     Expect: CREATE VIEW
CREATE VIEW mumbai_students AS
SELECT roll_no, student_name, city
FROM students_n
WHERE city = 'Mumbai';
--     Expect: 3 rows (Sara, Ravi, Nisha)
SELECT * FROM mumbai_students ORDER BY roll_no;

-- V14 Upgrade: a simple one-table view can be CHANGED THROUGH. The UPDATE goes to
--     the table behind it. Nisha moves to Navi Mumbai. Run one at a time.
--     Expect: UPDATE 1
UPDATE mumbai_students SET city = 'Navi Mumbai' WHERE roll_no = 11;
--     The table changed.
--     Expect: 1 row (Nisha, Navi Mumbai)
SELECT roll_no, student_name, city FROM students_n WHERE roll_no = 11;
--     And Nisha has left the view: 'Navi Mumbai' is not 'Mumbai'.
--     Expect: 2 rows (Sara, Ravi)
SELECT * FROM mumbai_students ORDER BY roll_no;
--     Put her back (through the table this time) and she is in the view again.
--     Expect: UPDATE 1
UPDATE students_n SET city = 'Mumbai' WHERE roll_no = 11;
--     Expect: 3 rows
SELECT * FROM mumbai_students ORDER BY roll_no;

-- V15 FAILS ON PURPOSE. A view over a JOIN cannot be changed through: the database
--     does not know which table the change belongs to.
--     Expect: ERROR: cannot update view "enrollment_details"
--             DETAIL: Views that do not select from a single table or view are not
--             automatically updatable.
UPDATE enrollment_details SET city = 'Pune' WHERE roll_no = 1;

-- V16 FAILS ON PURPOSE. A view DEPENDS on its tables. The database refuses to drop a
--     table while a view needs it, and lists what depends on it.
--     Expect: ERROR: cannot drop table instructors_n because other objects depend on it
--             DETAIL: ... view enrollment_details depends on table instructors_n ...
--             HINT: Use DROP ... CASCADE to drop the dependent objects too.
DROP TABLE instructors_n;

-- V17 Counting WITH the empty courses: a view whose query uses LEFT JOIN (the fix for
--     V5). Cloud Computing shows 0.
--     Expect: CREATE VIEW
CREATE VIEW students_per_course AS
SELECT c.course_id, c.course_name, COUNT(e.roll_no) AS students
FROM courses_n c
LEFT JOIN enrollments_n e ON e.course_id = c.course_id
GROUP BY c.course_id, c.course_name;
--     Expect: 7 rows (Python 2, SQL 4, Java 2, Data Science 3, Machine Learning 1,
--             Cloud Computing 0, MySQL 1)
SELECT * FROM students_per_course ORDER BY course_id;

-- V18 TRY IT YOURSELF: a view chennai_students with roll_no and student_name of the
--     Chennai students; then read it.
--     Expect: CREATE VIEW, then 3 rows (Anu, John, Meena)
CREATE VIEW chennai_students AS
SELECT roll_no, student_name
FROM students_n
WHERE city = 'Chennai';
SELECT * FROM chennai_students ORDER BY roll_no;

-- V19 Removing a view: DROP VIEW. The table behind it is untouched.
--     Expect: DROP VIEW
DROP VIEW chennai_students;
--     Expect: 1 row (12)
SELECT COUNT(*) AS students_still_there FROM students_n;

-- V20 EXTRA CHALLENGE: a view can be built on another view. sql_students reads
--     enrollment_details. Then enrollment_details cannot be dropped until
--     sql_students goes. Run one at a time.
--     Expect: CREATE VIEW
CREATE VIEW sql_students AS
SELECT roll_no, student_name, city
FROM enrollment_details
WHERE course_name = 'SQL';
--     Expect: 4 rows
SELECT * FROM sql_students ORDER BY roll_no;
--     FAILS ON PURPOSE: a view depends on this view.
--     Expect: ERROR: cannot drop view enrollment_details because other objects depend on it
DROP VIEW enrollment_details;
--     Remove the dependent view first. (enrollment_details stays; it is used later.)
--     Expect: DROP VIEW
DROP VIEW sql_students;

-- V21 EXTRA CHALLENGE: a row inserted THROUGH mumbai_students that is not in Mumbai
--     goes into the table and is invisible in the view. WITH CHECK OPTION stops that.
--     Run one at a time.
--     Expect: INSERT 0 1
INSERT INTO mumbai_students VALUES (13, 'Test', 'Delhi');
--     Expect: 3 rows (Test is not among them)
SELECT * FROM mumbai_students ORDER BY roll_no;
--     Expect: 1 row (Test, Delhi): it went into the table
SELECT * FROM students_n WHERE roll_no = 13;
--     Expect: DELETE 1
DELETE FROM students_n WHERE roll_no = 13;
--     Expect: CREATE VIEW
CREATE OR REPLACE VIEW mumbai_students AS
SELECT roll_no, student_name, city
FROM students_n
WHERE city = 'Mumbai'
WITH CHECK OPTION;
--     FAILS ON PURPOSE: with the option, the view tests each new row against its
--     own WHERE and turns away the ones it would lose sight of.
--     Expect: ERROR: new row violates check option for view "mumbai_students"
INSERT INTO mumbai_students VALUES (13, 'Test', 'Delhi');


-- =====================================================================
--  PART M  |  Materialized views: a SELECT with its result written down
--  With a view, every read executes the SELECT. A MATERIALIZED view
--  executes it once, at creation, and writes the rows to disk. Reading
--  those rows costs nothing, however heavy the SELECT, but they stay as
--  they were until REFRESH MATERIALIZED VIEW executes the SELECT again
--  and overwrites them.
-- =====================================================================

-- M1  Start from what you know: students_per_course (V17) is an ordinary view.
--     Upgrade: the same query with one extra word, MATERIALIZED. Messages tab says
--     SELECT 7: the query ran and 7 rows were stored.
--     Expect: SELECT 7
CREATE MATERIALIZED VIEW students_per_course_mv AS
SELECT c.course_id, c.course_name, COUNT(e.roll_no) AS students
FROM courses_n c
LEFT JOIN enrollments_n e ON e.course_id = c.course_id
GROUP BY c.course_id, c.course_name;

-- M2  Read it: the same 7 rows as the view, for now.
--     Expect: 7 rows (Cloud Computing 0)
SELECT * FROM students_per_course_mv ORDER BY course_id;

-- M3  The difference. Deepa joins Cloud Computing again (as in V6). Then read the
--     VIEW and the MATERIALIZED view, one row each. Run one at a time.
--     Expect: INSERT 0 1
INSERT INTO enrollments_n VALUES (12, 106);
--     The view, whose SELECT was executed afresh: 1.
--     Expect: 1 row (Cloud Computing, 1)
SELECT * FROM students_per_course WHERE course_id = 106;
--     The materialized view shows its stored rows: still 0. It did not look.
--     Expect: 1 row (Cloud Computing, 0)
SELECT * FROM students_per_course_mv WHERE course_id = 106;

-- M4  REFRESH: run the query again and replace the stored rows.
--     Expect: REFRESH MATERIALIZED VIEW
REFRESH MATERIALIZED VIEW students_per_course_mv;
--     Expect: 1 row (Cloud Computing, 1)
SELECT * FROM students_per_course_mv WHERE course_id = 106;

-- M5  FAILS ON PURPOSE. The stored rows cannot be edited by hand: the only way to
--     change a materialized view is REFRESH.
--     Expect: ERROR: cannot change materialized view "students_per_course_mv"
UPDATE students_per_course_mv SET students = 99 WHERE course_id = 106;

-- M6  Where the database lists them (pgAdmin: Schemas -> public -> Materialized Views).
--     Expect: 1 row (students_per_course_mv, true)
SELECT matviewname, ispopulated FROM pg_matviews;

-- M7  A report worth storing: the monthly payments report from class 8 (GROUP BY per
--     month in a CTE, then LAG and a running total). On a real system this runs over
--     millions of rows and is refreshed once a night; everyone reads the stored copy.
--     Expect: SELECT 6
CREATE MATERIALIZED VIEW monthly_report AS
WITH monthly AS (
    SELECT TO_CHAR(paid_on, 'YYYY-MM') AS month,
           SUM(amount)                 AS month_total
    FROM payments
    GROUP BY TO_CHAR(paid_on, 'YYYY-MM')
)
SELECT month, month_total,
       month_total - LAG(month_total) OVER (ORDER BY month) AS change_vs_previous,
       SUM(month_total) OVER (ORDER BY month)               AS running_total
FROM monthly;
--     Expect: 6 rows (2026-11: 10000.00, -1000.00, 82500.50)
SELECT * FROM monthly_report ORDER BY month;

-- M8  A new payment arrives: Deepa pays 15000 on 24 Nov. Read the report before and
--     after REFRESH. Run one at a time.
--     Expect: INSERT 0 1
INSERT INTO payments (payment_id, student_id, amount, paid_on, is_verified, method)
VALUES (9, 12, 15000.00, '2026-11-24', TRUE, 'UPI');
--     Still last night's numbers.
--     Expect: 1 row (2026-11, 10000.00, -1000.00, 82500.50)
SELECT * FROM monthly_report WHERE month = '2026-11';
--     Expect: REFRESH MATERIALIZED VIEW
REFRESH MATERIALIZED VIEW monthly_report;
--     Expect: 1 row (2026-11, 25000.00, 14000.00, 97500.50)
SELECT * FROM monthly_report WHERE month = '2026-11';

-- M9  Removing one: DROP MATERIALIZED VIEW. The tables behind it are untouched.
--     Expect: DROP MATERIALIZED VIEW
DROP MATERIALIZED VIEW students_per_course_mv;

-- M10 TRY IT YOURSELF: a materialized view students_per_city_mv: city and the number
--     of students in it, from students_n. Then read it.
--     Expect: SELECT 6, then 6 rows (Bangalore 2, Chennai 3, Delhi 1, Hyderabad 2,
--             Mumbai 3, [null] 1)
CREATE MATERIALIZED VIEW students_per_city_mv AS
SELECT city, COUNT(*) AS students
FROM students_n
GROUP BY city;
SELECT * FROM students_per_city_mv ORDER BY city;

-- M11 EXTRA CHALLENGE: add a student from a new city, read the materialized view
--     (unchanged), refresh, read again (a new row). Then remove the student and
--     refresh once more. Run one at a time.
--     Expect: INSERT 0 1
INSERT INTO students_n VALUES (13, 'Kavya', 'Pune');
--     Expect: 6 rows (no Pune)
SELECT * FROM students_per_city_mv ORDER BY city;
--     Expect: REFRESH MATERIALIZED VIEW
REFRESH MATERIALIZED VIEW students_per_city_mv;
--     Expect: 7 rows (Pune 1)
SELECT * FROM students_per_city_mv ORDER BY city;
--     Expect: DELETE 1
DELETE FROM students_n WHERE roll_no = 13;
--     Expect: 7 rows (Pune is still there: stored rows do not know)
SELECT * FROM students_per_city_mv ORDER BY city;
--     Expect: REFRESH MATERIALIZED VIEW
REFRESH MATERIALIZED VIEW students_per_city_mv;
--     Expect: 6 rows
SELECT * FROM students_per_city_mv ORDER BY city;


-- =====================================================================
--  PART Z  |  Final question
-- =====================================================================

-- Z1  A view instructor_load: each instructor with the number of students they
--     teach, instructors with none included. Then read it for instructors with more
--     than 2 students.
--     Expect: CREATE VIEW
CREATE VIEW instructor_load AS
SELECT i.instructor_name, COUNT(e.roll_no) AS students
FROM instructors_n i
LEFT JOIN courses_n     c ON c.instructor_id = i.instructor_id
LEFT JOIN enrollments_n e ON e.course_id     = c.course_id
GROUP BY i.instructor_name;
--     Expect: 2 rows (Vikram 5, Neha 3)
SELECT * FROM instructor_load WHERE students > 2 ORDER BY students DESC;


-- =====================================================================
--  PRACTICE SET  |  15 questions with answers
--  RUN THE SETUP AGAIN FIRST (setup/class10_setup.sql): it removes the
--  views made in class and resets the data, so the numbers below match.
--  Cover the answer, write your own, then compare.
--
--  Level 1 - views
--    P1  A view bangalore_students (roll_no, student_name); read it.           (2 rows)
--    P2  A view course_catalog: course_id, course_name, instructor_name, phone. (7 rows)
--    P3  A view city_enrollments: each city with its number of enrollments.    (5 rows)
--    P4  Add instructor_id to course_catalog with CREATE OR REPLACE; read it.  (7 rows)
--        Then: what happens if you try to REMOVE phone the same way?
--    P5  Drop bangalore_students, then try to read it. What error?
--  Level 2 - how views behave
--    P6  Enrol Deepa (12) in Cloud Computing (106); read city_enrollments.      (6 rows)
--    P7  A view delhi_students (roll_no, student_name, city); change Arjun's city
--        to 'New Delhi' THROUGH the view; read the view and the table. Then put
--        'Delhi' back.
--    P8  Spot the error: UPDATE course_catalog SET phone = '98400 99999'
--        WHERE instructor_name = 'Neha';  Why, and how do you change the phone?
--    P9  Spot the error: DROP TABLE courses_n;  Why? What would CASCADE do?
--  Level 3 - materialized views
--    P10 A materialized view students_per_city_mv (city, students); read it.   (6 rows)
--    P11 Add student 13, Kavya, Pune. Read the materialized view, refresh it,
--        read it again.                                               (6 rows, then 7)
--    P12 Spot the error: INSERT INTO students_per_city_mv VALUES ('Goa', 0);
--    P13 View or materialized view? (a) A figure on a screen that must be correct
--        to the second. (b) A monthly sales report over millions of rows, read by
--        hundreds of people every day. (c) Instructor names without phone numbers
--        for the reception desk. (d) Month-end balances that must NOT change when
--        late payments arrive.
--  Level 4 - the ER diagram
--    P14 In the diagram, which table sits between students_n and courses_n, and
--        why is it needed?
--    P15 Describe the ER diagram of our real tables students, courses,
--        enrollments and payments: which lines, and which end is 1 and which is N?
-- =====================================================================

-- P1  Expect: CREATE VIEW, then 2 rows (Rahul, Kiran)
CREATE VIEW bangalore_students AS
SELECT roll_no, student_name
FROM students_n
WHERE city = 'Bangalore';
SELECT * FROM bangalore_students ORDER BY roll_no;

-- P2  Expect: CREATE VIEW, then 7 rows
CREATE VIEW course_catalog AS
SELECT c.course_id, c.course_name, i.instructor_name, i.phone
FROM courses_n c
JOIN instructors_n i ON c.instructor_id = i.instructor_id;
SELECT * FROM course_catalog ORDER BY course_id;

-- P3  Expect: CREATE VIEW, then 5 rows (Bangalore 3, Chennai 4, Delhi 1, Hyderabad 2,
--             Mumbai 3)
CREATE VIEW city_enrollments AS
SELECT s.city, COUNT(*) AS enrollments
FROM enrollments_n e
JOIN students_n s ON e.roll_no = s.roll_no
GROUP BY s.city;
SELECT * FROM city_enrollments ORDER BY city;

-- P4  Expect: CREATE VIEW, then 7 rows with a fifth column instructor_id.
--     Removing phone with CREATE OR REPLACE gives ERROR: cannot drop columns from
--     view. To shrink a view: DROP VIEW, then CREATE VIEW.
CREATE OR REPLACE VIEW course_catalog AS
SELECT c.course_id, c.course_name, i.instructor_name, i.phone, c.instructor_id
FROM courses_n c
JOIN instructors_n i ON c.instructor_id = i.instructor_id;
SELECT * FROM course_catalog ORDER BY course_id;

-- P5  Expect: DROP VIEW, then ERROR: relation "bangalore_students" does not exist
DROP VIEW bangalore_students;
--     FAILS ON PURPOSE
SELECT * FROM bangalore_students;

-- P6  Expect: INSERT 0 1, then 6 rows: a new row [null] 1 (Deepa has no city)
INSERT INTO enrollments_n VALUES (12, 106);
SELECT * FROM city_enrollments ORDER BY city;

-- P7  Run one at a time.
--     Expect: CREATE VIEW
CREATE VIEW delhi_students AS
SELECT roll_no, student_name, city
FROM students_n
WHERE city = 'Delhi';
--     Expect: 1 row (Arjun)
SELECT * FROM delhi_students;
--     Expect: UPDATE 1
UPDATE delhi_students SET city = 'New Delhi' WHERE roll_no = 8;
--     Expect: 0 rows (Arjun has left the view)
SELECT * FROM delhi_students;
--     Expect: 1 row (Arjun, New Delhi): the table was changed
SELECT roll_no, student_name, city FROM students_n WHERE roll_no = 8;
--     Expect: UPDATE 1
UPDATE students_n SET city = 'Delhi' WHERE roll_no = 8;

-- P8  ERROR: cannot update view "course_catalog". The view joins two tables, so the
--     database cannot tell which table the change is for. Change the phone in the
--     table that owns it: UPDATE instructors_n SET phone = ... WHERE instructor_name
--     = 'Neha'; the view shows the new number at once.

-- P9  ERROR: cannot drop table courses_n because other objects depend on it (the view
--     course_catalog, and the foreign key from enrollments_n). DROP TABLE courses_n
--     CASCADE would drop the table AND the view AND the foreign key constraint, all
--     without asking again. Use it only when you mean exactly that.

-- P10 Expect: SELECT 6, then 6 rows (Bangalore 2, Chennai 3, Delhi 1, Hyderabad 2,
--             Mumbai 3, [null] 1)
CREATE MATERIALIZED VIEW students_per_city_mv AS
SELECT city, COUNT(*) AS students
FROM students_n
GROUP BY city;
SELECT * FROM students_per_city_mv ORDER BY city;

-- P11 Run one at a time.
--     Expect: INSERT 0 1
INSERT INTO students_n VALUES (13, 'Kavya', 'Pune');
--     Expect: 6 rows (no Pune yet)
SELECT * FROM students_per_city_mv ORDER BY city;
--     Expect: REFRESH MATERIALIZED VIEW
REFRESH MATERIALIZED VIEW students_per_city_mv;
--     Expect: 7 rows (Pune 1)
SELECT * FROM students_per_city_mv ORDER BY city;

-- P12 ERROR: cannot change materialized view "students_per_city_mv". Stored rows are
--     only changed by REFRESH MATERIALIZED VIEW, which runs the query again.

-- P13 (a) view: it must run the query every time. (b) materialized view, refreshed
--     once a day: heavy query, many readers, yesterday's numbers are acceptable.
--     (c) view: it hides the column and costs nothing. (d) materialized view that is
--     NOT refreshed: a stored snapshot stays as it was.

-- P14 enrollments_n. A student has several courses and a course has several students,
--     so the link is many-to-many, which SQL cannot draw as a single line between two
--     tables. A third table holds one row per student-and-course with a foreign key
--     to each side.

-- P15 Three lines, all 1---N: students 1---N enrollments (one student, many
--     enrollments); courses 1---N enrollments (one course, many enrollments);
--     students 1---N payments (one student, many payments). Students and courses are
--     many-to-many through enrollments. Payment 8 has an empty student_id: a payment
--     may exist without a student, so the payments end of that line can be empty.
