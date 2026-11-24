-- =====================================================================
--  SQL CLASS 9  |  Every query from the class, in order, with explanations
--  Topics: a five-minute recap of COMMIT, ROLLBACK and SAVEPOINT; catching
--          errors in a DO block (left over from class 8); then normalization:
--          why one big sheet goes wrong, first normal form, second normal
--          form, third normal form, and checking that nothing was lost.
--          15-question practice set at the end.
-- =====================================================================
--  HOW TO USE THIS FILE
--  1. Run setup/class9_setup.sql first.
--  2. Open this file in the Query Tool (folder icon -> Open File).
--  3. Highlight ONE statement, from its first word to the semicolon,
--     and press F5. A WITH query is ONE statement. A DO block is ONE
--     statement: highlight from DO down to the final $$;
--  4. Compare your result with the "Expect" line written above it.
--
--  Today you BUILD tables step by step (Parts S and T). Run those
--  statements in the order written; each one depends on the one before.
--  If you lose your way, run the setup again and start Part S from S1.
--
--  Do not run the whole file at once. Several statements FAIL ON PURPOSE,
--  and the first failure cancels everything else in the run.
--  If you see "current transaction is aborted": run  ROLLBACK;  and go on.
--
--  Messages from DO blocks appear in the MESSAGES tab, not Data Output.
--
--  TRY IT YOURSELF  = write the query before looking at the answer below it.
--  EXTRA CHALLENGE  = optional, a little harder.
--  [null]           = how pgAdmin shows an empty box.
-- =====================================================================


-- =====================================================================
--  PART 0  |  Check that the setup worked
-- =====================================================================

-- 0.1  Must show 12 | 5 | 82500.50.
--      Expect: 1 row (12, 5, 82500.50)
SELECT (SELECT COUNT(*) FROM students)              AS students,
       (SELECT COUNT(*) FROM courses)               AS courses,
       (SELECT SUM(amount) FROM payments)            AS total_paid;

-- 0.2  Today's two tables: the office spreadsheet (12 rows, one per student)
--      and the same data with one course per row (13 rows).
--      Expect: 1 row (12, 13)
SELECT (SELECT COUNT(*) FROM admissions_sheet) AS sheet_rows,
       (SELECT COUNT(*) FROM admissions_1nf)   AS one_course_per_row;


-- =====================================================================
--  PART Q  |  Five-minute recap of class 8: SAVEPOINT, ROLLBACK, COMMIT
--  BEGIN opens a group of changes. Nothing in the group is final until
--  you close it with ONE of these two:
--    COMMIT      you looked at the result and it is right: keep it all.
--    ROLLBACK    something is wrong, or you are not sure about any part
--                of it: throw the whole group away.
--  And inside the group, before a risky step:
--    SAVEPOINT name               put a marker here.
--    ROLLBACK TO SAVEPOINT name   undo only what came after the marker;
--                                 keep the rest. The group STAYS OPEN, so
--                                 you still end it with COMMIT or ROLLBACK.
--  The transfer below uses all of them. Run the statements in order, in
--  this tab. The thing to look at before every decision is the total:
--  88000 means no money appeared or disappeared.
-- =====================================================================

-- Q1  Where we start.
--     Expect: 3 rows (Arjun 30000.00, Priya 8000.00, Institute 50000.00; total 88000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- Q2  Open the group, do step 1 (money out of Arjun), and put a marker after it.
--     Highlight the three lines and press F5 once (pgAdmin reports the last one:
--     SAVEPOINT), or run them one at a time.
BEGIN;
UPDATE accounts SET balance = balance - 1000 WHERE holder = 'Arjun';
SAVEPOINT money_out;

-- Q3  Step 2 with a typing mistake: an extra zero, 10000 instead of 1000. No error:
--     10000 is a legal amount, and the database cannot know what you meant.
--     Expect: UPDATE 1
UPDATE accounts SET balance = balance + 10000 WHERE holder = 'Priya';

-- Q4  Look before deciding. Total 97000: 9000 appeared from nowhere. Step 1 was
--     right, step 2 was wrong.
--     Expect: 3 rows (Arjun 29000.00, Priya 18000.00, Institute 50000.00; total 97000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- Q5  Only the step after the marker is wrong, so: back to the marker. pgAdmin
--     prints the same word as for a full rollback; Q6 shows the difference.
--     Expect: ROLLBACK
ROLLBACK TO SAVEPOINT money_out;

-- Q6  Proof. Arjun still 29000: step 1 kept. Priya back to 8000: step 2 gone.
--     Total 87000: money out, not yet in. The group is still open.
--     Expect: 3 rows (Arjun 29000.00, Priya 8000.00, Institute 50000.00; total 87000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- Q7  Step 2 again, correctly.
--     Expect: UPDATE 1
UPDATE accounts SET balance = balance + 1000 WHERE holder = 'Priya';

-- Q8  Look again. Total 88000: everything in the group is right now.
--     Expect: 3 rows (Arjun 29000.00, Priya 9000.00, Institute 50000.00; total 88000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- Q9  Right: COMMIT. Final; no ROLLBACK can undo it now.
--     (Had the total still been wrong, or had you lost track of what you did, the
--     word would be ROLLBACK: the whole group gone, Arjun back to 30000, start the
--     transfer again from BEGIN.)
--     Expect: COMMIT
COMMIT;

-- Q10 Put the 1000 back so Part E starts from round numbers. No BEGIN, so this is
--     saved the moment it runs (autocommit, class 8). CASE picks each row's value.
--     Expect: UPDATE 3
UPDATE accounts
SET balance = CASE holder WHEN 'Arjun' THEN 30000
                          WHEN 'Priya' THEN 8000
                          ELSE 50000 END;


-- =====================================================================
--  PART E  |  Catching errors: a DO block with EXCEPTION (from class 8)
--  DO $$ ... $$;  runs a small program once. Inside it, BEGIN and END
--  mark where the program starts and stops (a different BEGIN from the
--  transaction one; same word, unlucky). An EXCEPTION section says what
--  to do if a statement in the program fails: instead of a red error,
--  you get a message you wrote yourself, and the work in the block is
--  undone cleanly. This is a first look at PL/pgSQL; class 11 continues it.
--  The accounts table (Arjun 30000, Priya 8000, Institute 50000) is used.
-- =====================================================================

-- E1  The smallest block that runs: it only prints a message. Look at the
--     Messages tab.
--     Expect: NOTICE: Hello from a block, then DO
DO $$
BEGIN
    RAISE NOTICE 'Hello from a block';
END $$;

-- E2  FAILS ON PURPOSE. A block that does something impossible: insert student 1
--     again. A block does not protect you by itself.
--     Expect: ERROR: duplicate key value violates unique constraint "students_pkey"
DO $$
BEGIN
    INSERT INTO students (student_id, student_name, email)
    VALUES (1, 'Twin Anu', 'twin@example.com');
END $$;

-- E3  Upgrade: add an EXCEPTION section. The same mistake, but now it is caught:
--     no red error, a friendly NOTICE instead, and nothing was inserted.
--     Expect: NOTICE: Student 1 already exists; nothing inserted. then DO
DO $$
BEGIN
    INSERT INTO students (student_id, student_name, email)
    VALUES (1, 'Twin Anu', 'twin@example.com');
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Student 1 already exists; nothing inserted.';
END $$;

-- E4  Still 12 students.
--     Expect: 1 row (12)
SELECT COUNT(*) AS students FROM students;

-- E5  A different error name: the foreign key mistake from class 8, caught.
--     Expect: NOTICE: Course 999 does not exist; nothing inserted. then DO
DO $$
BEGIN
    INSERT INTO enrollments VALUES (99, 1, 999, CURRENT_DATE, 'Active');
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Course 999 does not exist; nothing inserted.';
END $$;

-- E6  Upgrade: WHEN OTHERS catches ANY error, and SQLERRM is the database's own
--     message. The failing transfer from class 8, inside a block. Both UPDATEs are
--     undone, including the first one that worked.
--     Expect: NOTICE: Transfer cancelled: new row for relation "accounts" violates
--             check constraint "accounts_balance_check"   then DO
DO $$
BEGIN
    UPDATE accounts SET balance = balance + 100000 WHERE holder = 'Institute';
    UPDATE accounts SET balance = balance - 100000 WHERE holder = 'Priya';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Transfer cancelled: %', SQLERRM;
END $$;

-- E7  The Institute is still 50000: the block undid its own first UPDATE.
--     Expect: 3 rows (Arjun 30000.00, Priya 8000.00, Institute 50000.00; total 88000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- E8  TRY IT YOURSELF: a block that inserts course 101 again and prints
--     "Course 101 already exists." instead of failing.
--     Expect: NOTICE: Course 101 already exists. then DO
DO $$
BEGIN
    INSERT INTO courses VALUES (101, 'Python again', 3, 'Nobody');
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Course 101 already exists.';
END $$;

-- E9  EXTRA CHALLENGE: a block that enrols student 99 (who does not exist) in
--     course 101, and prints the database's own message after "Problem: ".
--     Expect: NOTICE: Problem: insert or update on table "enrollments" violates
--             foreign key constraint "enrollments_student_id_fkey"   then DO
DO $$
BEGIN
    INSERT INTO enrollments VALUES (99, 99, 101, CURRENT_DATE, 'Active');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Problem: %', SQLERRM;
END $$;


-- =====================================================================
--  PART N  |  The spreadsheet, and why it gives wrong answers
--  admissions_sheet is the office's spreadsheet exactly as typed: one row
--  per student, and when a student takes two courses, both are typed in
--  the same cell, with both instructors and both phone numbers.
-- =====================================================================

-- N1  Look at it. Notice Anu's and Rahul's cells, Kiran's 'Data science',
--     Nisha's phone for Vikram, and Deepa's empty row.
--     Expect: 12 rows
SELECT * FROM admissions_sheet ORDER BY roll_no;

-- N2  Question: who studies SQL? The obvious query finds 2 students. The true
--     answer is 4: Anu and Rahul are missed because their cell says more than 'SQL'.
--     Expect: 2 rows (Priya, Meena)
SELECT roll_no, student_name, courses
FROM admissions_sheet
WHERE courses = 'SQL'
ORDER BY roll_no;

-- N3  Try to repair it with LIKE. Now 5 students: Nisha is in, but she studies MySQL.
--     Still wrong.
--     Expect: 5 rows (Anu, Rahul, Priya, Meena, Nisha)
SELECT roll_no, student_name, courses
FROM admissions_sheet
WHERE courses LIKE '%SQL%'
ORDER BY roll_no;

-- N4  Question: how many students per course? GROUP BY can only group by the whole
--     cell, so 'Python, SQL' becomes a "course" of its own. Ten groups of nonsense.
--     Expect: 10 rows
SELECT courses, COUNT(*) AS students
FROM admissions_sheet
GROUP BY courses
ORDER BY courses;

-- N5  TRY IT YOURSELF: how many students study Data Science? (The true answer is 3.)
--     Expect: 1 row (2): Kiran's 'Data science' with a small s is not matched
SELECT COUNT(*) AS data_science_students
FROM admissions_sheet
WHERE courses LIKE '%Data Science%';


-- =====================================================================
--  PART F  |  First normal form: one fact per cell, one row per fact
--  admissions_1nf is the same sheet retyped so that each row holds ONE
--  student and ONE course, with a code for the course. The key is the
--  pair (roll_no, course_id): no two rows share the same pair.
--  Questions work now. But every repeated fact is a chance for a mistake.
-- =====================================================================

-- F1  Look at it: 13 rows, one per student-and-course. Anu and Rahul have two.
--     Expect: 13 rows
SELECT * FROM admissions_1nf ORDER BY roll_no, course_id;

-- F2  Who studies SQL? Now the true answer: 4.
--     Expect: 4 rows (Anu, Rahul, Priya, Meena)
SELECT roll_no, student_name
FROM admissions_1nf
WHERE course_name = 'SQL'
ORDER BY roll_no;

-- F3  Students per course. It works, but look at Data Science: the typo has split
--     one course into two groups.
--     Expect: 7 rows (Data science 1, Data Science 2, Java 2, Machine Learning 1,
--             MySQL 1, Python 2, SQL 4)
SELECT course_name, COUNT(*) AS students
FROM admissions_1nf
GROUP BY course_name
ORDER BY course_name;

-- F4  Redundancy: how many times is each instructor's phone stored? Neha's three
--     times, Vikram's five times, and Vikram has TWO different numbers.
--     Expect: 6 rows (Anita 2, Neha 3, Raj 1, Suresh 2, Vikram 98400 22222 4,
--             Vikram 98400 22223 1)
SELECT instructor, instructor_phone, COUNT(*) AS times_stored
FROM admissions_1nf
GROUP BY instructor, instructor_phone
ORDER BY instructor, instructor_phone;

-- F5  UPDATE ANOMALY. Neha changes her number. The clerk corrects Kiran's row and
--     forgets the other two. Now Neha has two numbers and nobody knows which is
--     right. (Inside a transaction, so ROLLBACK undoes the demonstration.)
--     Run F5.1 to F5.4 one at a time.
BEGIN;
--     Expect: UPDATE 1
UPDATE admissions_1nf
SET instructor_phone = '98400 99999'
WHERE instructor = 'Neha' AND roll_no = 6;
--     Expect: 2 rows (98400 44444 and 98400 99999)
SELECT DISTINCT instructor, instructor_phone
FROM admissions_1nf
WHERE instructor = 'Neha';
ROLLBACK;

-- F6  INSERTION ANOMALY. Deepa has been admitted but has no course yet. She cannot
--     be stored: course_id is part of the key, and a key cannot be empty.
--     FAILS ON PURPOSE.
--     Expect: ERROR: null value in column "course_id" ... violates not-null constraint
INSERT INTO admissions_1nf (roll_no, student_name, city)
VALUES (12, 'Deepa', NULL);

-- F7  The same the other way round: a new course, Cloud Computing, has no students
--     yet, so it cannot be recorded either. FAILS ON PURPOSE.
--     Expect: ERROR: null value in column "roll_no" ... violates not-null constraint
INSERT INTO admissions_1nf (course_id, course_name, instructor, instructor_phone)
VALUES (106, 'Cloud Computing', 'Asha', '98400 66666');

-- F8  DELETION ANOMALY. Arjun leaves. Deleting his row also deletes the only record
--     that a Machine Learning course exists, with Raj and his phone number.
--     (Inside a transaction; ROLLBACK brings Arjun back.) Run one at a time.
BEGIN;
--     Expect: DELETE 1
DELETE FROM admissions_1nf WHERE roll_no = 8;
--     Expect: 6 rows (no 105 Machine Learning any more)
SELECT DISTINCT course_id, course_name
FROM admissions_1nf
ORDER BY course_id;
ROLLBACK;
--     Expect: 1 row (13)
SELECT COUNT(*) AS rows_after_rollback FROM admissions_1nf;


-- =====================================================================
--  PART S  |  Second normal form: split off what depends on PART of the key
--  The key is (roll_no, course_id). student_name and city depend on
--  roll_no alone. course_name, instructor and instructor_phone depend on
--  course_id alone. Each of those groups becomes its own table, with its
--  own key. What is left, (roll_no, course_id), is the enrollment table.
--  CREATE TABLE ... AS SELECT DISTINCT ... builds a table from a query,
--  keeping each different row once.
-- =====================================================================

-- S1  The students table: one row per roll number. Messages tab: SELECT 11.
--     Expect: SELECT 11
CREATE TABLE students_n AS
SELECT DISTINCT roll_no, student_name, city
FROM admissions_1nf;

-- S2  Look: 11 students. Anu and Rahul appear once each now. Deepa is missing,
--     because she had no row in admissions_1nf (F6).
--     Expect: 11 rows
SELECT * FROM students_n ORDER BY roll_no;

-- S3  Give it a key. roll_no is unique here, so this works.
--     Expect: ALTER TABLE
ALTER TABLE students_n ADD PRIMARY KEY (roll_no);

-- S4  Now Deepa CAN be stored: a student does not need a course any more.
--     Expect: INSERT 0 1
INSERT INTO students_n VALUES (12, 'Deepa', NULL);

-- S5  The courses table: one row per course code.
--     Expect: SELECT 7
CREATE TABLE courses_n AS
SELECT DISTINCT course_id, course_name, instructor, instructor_phone
FROM admissions_1nf;

-- S6  Look: 7 rows for 6 courses. Code 104 appears twice, once per spelling.
--     Expect: 7 rows (104 twice: 'Data science' and 'Data Science')
SELECT * FROM courses_n ORDER BY course_id, course_name;

-- S7  FAILS ON PURPOSE. The database refuses to make course_id the key while 104
--     is there twice. Redundant data has already turned into inconsistent data.
--     Expect: ERROR: could not create unique index "courses_n_pkey"
--             DETAIL: Key (course_id)=(104) is duplicated.
ALTER TABLE courses_n ADD PRIMARY KEY (course_id);

-- S8  Fix the source data, then rebuild the table. Run S8.1 to S8.4 one at a time.
--     Expect: UPDATE 1
UPDATE admissions_1nf
SET course_name = 'Data Science'
WHERE course_name = 'Data science';
--     Expect: DROP TABLE
DROP TABLE courses_n;
--     Expect: SELECT 6
CREATE TABLE courses_n AS
SELECT DISTINCT course_id, course_name, instructor, instructor_phone
FROM admissions_1nf;
--     Expect: ALTER TABLE
ALTER TABLE courses_n ADD PRIMARY KEY (course_id);

-- S9  Look: 6 courses, each once.
--     Expect: 6 rows (101 Python, 102 SQL, 103 Java, 104 Data Science,
--             105 Machine Learning, 107 MySQL)
SELECT * FROM courses_n ORDER BY course_id;

-- S10 The enrollments table: what is left, the pairs. Then its key (both columns
--     together) and two foreign keys back to the tables the pairs point at.
--     Run S10.1 to S10.4 one at a time.
--     Expect: SELECT 13
CREATE TABLE enrollments_n AS
SELECT roll_no, course_id
FROM admissions_1nf;
--     Expect: ALTER TABLE
ALTER TABLE enrollments_n ADD PRIMARY KEY (roll_no, course_id);
--     Expect: ALTER TABLE
ALTER TABLE enrollments_n ADD FOREIGN KEY (roll_no)   REFERENCES students_n (roll_no);
--     Expect: ALTER TABLE
ALTER TABLE enrollments_n ADD FOREIGN KEY (course_id) REFERENCES courses_n (course_id);

-- S11 Three tables instead of one: 12 students, 6 courses, 13 enrollments.
--     Expect: 1 row (12, 6, 13)
SELECT (SELECT COUNT(*) FROM students_n)    AS students,
       (SELECT COUNT(*) FROM courses_n)     AS courses,
       (SELECT COUNT(*) FROM enrollments_n) AS enrollments;


-- =====================================================================
--  PART T  |  Third normal form: split off what depends on a NON-key column
--  In courses_n, instructor_phone does not depend on the course. It
--  depends on the instructor. Vikram teaches two courses, so his phone is
--  stored twice, and the two copies already disagree. The instructor
--  becomes a table of their own; courses point at it with an id.
-- =====================================================================

-- T1  Look at the problem: Vikram, two courses, two phones.
--     Expect: 6 rows (Vikram twice: 98400 22222 and 98400 22223)
SELECT instructor, instructor_phone, COUNT(*) AS courses
FROM courses_n
GROUP BY instructor, instructor_phone
ORDER BY instructor, instructor_phone;

-- T2  The instructors table, typed by hand with the phone numbers checked against
--     the office records (Vikram's correct number ends in 22222).
--     Run T2.1 and T2.2 one at a time.
--     Expect: CREATE TABLE
CREATE TABLE instructors_n (
    instructor_id   INT PRIMARY KEY,
    instructor_name VARCHAR(50) NOT NULL UNIQUE,
    phone           VARCHAR(20)
);
--     Expect: INSERT 0 5
INSERT INTO instructors_n VALUES
(1, 'Anita',  '98400 11111'),
(2, 'Vikram', '98400 22222'),
(3, 'Suresh', '98400 33333'),
(4, 'Neha',   '98400 44444'),
(5, 'Raj',    '98400 55555');

-- T3  Link each course to its instructor by id: add the column, then fill it by
--     looking the name up (a subquery from class 4). Run one at a time.
--     Expect: ALTER TABLE
ALTER TABLE courses_n ADD COLUMN instructor_id INT;
--     Expect: UPDATE 6
UPDATE courses_n
SET instructor_id = (SELECT instructor_id
                     FROM instructors_n
                     WHERE instructor_name = courses_n.instructor);
--     Expect: 6 rows (instructor_id 1, 2, 3, 4, 5, 2)
SELECT * FROM courses_n ORDER BY course_id;

-- T4  Remove the two columns that now live in instructors_n, and make the id a
--     foreign key. Run one at a time.
--     Expect: ALTER TABLE
ALTER TABLE courses_n DROP COLUMN instructor, DROP COLUMN instructor_phone;
--     Expect: ALTER TABLE
ALTER TABLE courses_n ADD FOREIGN KEY (instructor_id) REFERENCES instructors_n (instructor_id);

-- T5  Look: a course is now a code, a name and an instructor id. Nothing repeated.
--     Expect: 6 rows
SELECT * FROM courses_n ORDER BY course_id;


-- =====================================================================
--  PART V  |  Check that nothing was lost, and that the problems are gone
-- =====================================================================

-- V1  Join the four tables back together: the original 13 rows reappear.
--     Expect: 13 rows
SELECT s.roll_no, s.student_name, s.city,
       c.course_id, c.course_name,
       i.instructor_name, i.phone
FROM enrollments_n e
JOIN students_n    s ON e.roll_no       = s.roll_no
JOIN courses_n     c ON e.course_id     = c.course_id
JOIN instructors_n i ON c.instructor_id = i.instructor_id
ORDER BY s.roll_no, c.course_id;

-- V2  EXCEPT (class 3): rows in the old table that the new tables do not produce.
--     Exactly one: Nisha's row with the wrong phone, which the new design corrected.
--     Expect: 1 row (Nisha, MySQL, Vikram, 98400 22223)
SELECT roll_no, student_name, city, course_id, course_name, instructor, instructor_phone
FROM admissions_1nf
EXCEPT
SELECT s.roll_no, s.student_name, s.city, c.course_id, c.course_name,
       i.instructor_name, i.phone
FROM enrollments_n e
JOIN students_n    s ON e.roll_no       = s.roll_no
JOIN courses_n     c ON e.course_id     = c.course_id
JOIN instructors_n i ON c.instructor_id = i.instructor_id;

-- V3  The update anomaly is gone: Vikram's new number is ONE change, and every
--     student of his sees it. Run one at a time.
--     Expect: UPDATE 1
UPDATE instructors_n SET phone = '98400 77777' WHERE instructor_name = 'Vikram';
--     Expect: 5 rows, all showing 98400 77777
SELECT s.student_name, c.course_name, i.instructor_name, i.phone
FROM enrollments_n e
JOIN students_n    s ON e.roll_no       = s.roll_no
JOIN courses_n     c ON e.course_id     = c.course_id
JOIN instructors_n i ON c.instructor_id = i.instructor_id
WHERE i.instructor_name = 'Vikram'
ORDER BY s.roll_no, c.course_id;

-- V4  The insertion anomaly is gone: a course with no students yet. Run one at a time.
--     Expect: INSERT 0 1
INSERT INTO instructors_n VALUES (6, 'Asha', '98400 66666');
--     Expect: INSERT 0 1
INSERT INTO courses_n VALUES (106, 'Cloud Computing', 6);
--     Students per course, zero included (LEFT JOIN, class 3).
--     Expect: 7 rows (Python 2, SQL 4, Java 2, Data Science 3, Machine Learning 1,
--             Cloud Computing 0, MySQL 1)
SELECT c.course_id, c.course_name, i.instructor_name, COUNT(e.roll_no) AS students
FROM courses_n c
JOIN instructors_n i      ON c.instructor_id = i.instructor_id
LEFT JOIN enrollments_n e ON e.course_id     = c.course_id
GROUP BY c.course_id, c.course_name, i.instructor_name
ORDER BY c.course_id;

-- V5  And a student with no course: Deepa exists.
--     Expect: 1 row (Deepa, [null])
SELECT s.roll_no, s.student_name, c.course_name
FROM students_n s
LEFT JOIN enrollments_n e ON s.roll_no   = e.roll_no
LEFT JOIN courses_n     c ON e.course_id = c.course_id
WHERE c.course_name IS NULL;

-- V6  The deletion anomaly is gone, the other way round: the database now REFUSES
--     to delete a course that still has students. FAILS ON PURPOSE.
--     Expect: ERROR: update or delete on table "courses_n" violates foreign key
--             constraint "enrollments_n_course_id_fkey" on table "enrollments_n"
DELETE FROM courses_n WHERE course_id = 105;

-- V7  And it refuses an enrollment in a course that does not exist. FAILS ON PURPOSE.
--     Expect: ERROR: insert or update on table "enrollments_n" violates foreign key
--             constraint "enrollments_n_course_id_fkey"
INSERT INTO enrollments_n VALUES (12, 999);

-- V8  EXTRA CHALLENGE: students per instructor, instructors with none included.
--     Expect: 6 rows (Vikram 5, Neha 3, Anita 2, Suresh 2, Raj 1, Asha 0)
SELECT i.instructor_name, COUNT(e.roll_no) AS students
FROM instructors_n i
LEFT JOIN courses_n     c ON c.instructor_id = i.instructor_id
LEFT JOIN enrollments_n e ON e.course_id     = c.course_id
GROUP BY i.instructor_name
ORDER BY students DESC, i.instructor_name;


-- =====================================================================
--  PART Z  |  Final question
-- =====================================================================

-- Z1  From the normalized tables: each course with its instructor's name and phone
--     and the number of students, including courses with none.
--     Expect: 7 rows (Cloud Computing 0; Vikram's rows show 98400 77777)
SELECT c.course_name, i.instructor_name, i.phone, COUNT(e.roll_no) AS students
FROM courses_n c
JOIN instructors_n i      ON c.instructor_id = i.instructor_id
LEFT JOIN enrollments_n e ON e.course_id     = c.course_id
GROUP BY c.course_name, i.instructor_name, i.phone
ORDER BY c.course_name;


-- =====================================================================
--  PRACTICE SET  |  15 questions with answers
--  The query questions use the four tables built in class: students_n,
--  courses_n, enrollments_n, instructors_n. If you RAN THE SETUP AGAIN
--  after class, those tables are gone: run the REBUILD block first.
--  Cover the answer, write your own, then compare.
--
--  Level 1 - spot the problem (no query needed)
--    P1  A table has a column phones with values like '98400 11111, 98400 22222'.
--        Which normal form does it break, and how do you fix it?
--    P2  order_items (order_id, product_id, product_name, quantity), key
--        (order_id, product_id). Which column breaks second normal form? Why?
--    P3  students (student_id, student_name, city, state): the state is decided by
--        the city. Which normal form does that break? What is the fix?
--    P4  Name the anomaly: (a) Arjun leaves and Machine Learning disappears;
--        (b) Neha's phone corrected on one row only; (c) Deepa cannot be stored
--        without a course.
--  Level 2 - queries on the normalized tables
--    P5  Students per course, courses with none included.                      (7 rows)
--    P6  Students per instructor, instructors with none included.              (6 rows)
--    P7  Students who are not in any course.                                   (1 row)
--    P8  Courses with no students.                                             (1 row)
--    P9  The students Vikram teaches, with the course name.                    (5 rows)
--    P10 Change Neha's phone with ONE statement, then show her students with the
--        new phone.                                                            (3 rows)
--  Level 3 - catching errors (Part E)
--    P11 A block that inserts course 101 into courses again and prints a friendly
--        message instead of failing.
--    P12 A block that enrols student 99 in course 101 and prints "Problem: " and the
--        database's own message.
--  Level 4 - design (no query needed)
--    P13 A library records: book title, author, member name, member phone, date
--        borrowed, date returned, all in one sheet. Draw the tables you would make.
--    P14 Our real courses table stores the instructor's name as text. What would you
--        add to bring it to third normal form?
--    P15 Why did ALTER TABLE courses_n ADD PRIMARY KEY (course_id) fail the first
--        time in class, and what does that teach about repeated data?
-- =====================================================================

-- REBUILD  Only if you re-ran the setup and the four tables are missing.
--          Highlight from the first UPDATE to the last ALTER TABLE and press F5.
UPDATE admissions_1nf SET course_name = 'Data Science' WHERE course_name = 'Data science';
CREATE TABLE students_n AS SELECT DISTINCT roll_no, student_name, city FROM admissions_1nf;
ALTER TABLE students_n ADD PRIMARY KEY (roll_no);
INSERT INTO students_n VALUES (12, 'Deepa', NULL);
CREATE TABLE instructors_n (
    instructor_id   INT PRIMARY KEY,
    instructor_name VARCHAR(50) NOT NULL UNIQUE,
    phone           VARCHAR(20)
);
INSERT INTO instructors_n VALUES
(1, 'Anita', '98400 11111'), (2, 'Vikram', '98400 22222'), (3, 'Suresh', '98400 33333'),
(4, 'Neha',  '98400 44444'), (5, 'Raj',    '98400 55555'), (6, 'Asha',   '98400 66666');
CREATE TABLE courses_n (
    course_id     INT PRIMARY KEY,
    course_name   VARCHAR(50) NOT NULL,
    instructor_id INT REFERENCES instructors_n (instructor_id)
);
INSERT INTO courses_n VALUES
(101, 'Python', 1), (102, 'SQL', 2), (103, 'Java', 3), (104, 'Data Science', 4),
(105, 'Machine Learning', 5), (106, 'Cloud Computing', 6), (107, 'MySQL', 2);
CREATE TABLE enrollments_n AS SELECT roll_no, course_id FROM admissions_1nf;
ALTER TABLE enrollments_n ADD PRIMARY KEY (roll_no, course_id);
ALTER TABLE enrollments_n ADD FOREIGN KEY (roll_no)   REFERENCES students_n (roll_no);
ALTER TABLE enrollments_n ADD FOREIGN KEY (course_id) REFERENCES courses_n (course_id);

-- P1  First normal form: a cell holds more than one value. Fix: one phone per row,
--     in a separate table phones (roll_no, phone) with both columns as the key.

-- P2  product_name. It depends on product_id alone, not on the whole key
--     (order_id, product_id). Move it to a products table (product_id, product_name).

-- P3  Third normal form: state depends on city, a non-key column, not on student_id.
--     Fix: a cities table (city, state); students keep only the city.

-- P4  (a) deletion anomaly, (b) update anomaly, (c) insertion anomaly.

-- P5  Expect: 7 rows (Python 2, SQL 4, Java 2, Data Science 3, Machine Learning 1,
--             Cloud Computing 0, MySQL 1)
SELECT c.course_name, COUNT(e.roll_no) AS students
FROM courses_n c
LEFT JOIN enrollments_n e ON e.course_id = c.course_id
GROUP BY c.course_id, c.course_name
ORDER BY c.course_id;

-- P6  Expect: 6 rows (Vikram 5, Neha 3, Anita 2, Suresh 2, Raj 1, Asha 0)
SELECT i.instructor_name, COUNT(e.roll_no) AS students
FROM instructors_n i
LEFT JOIN courses_n     c ON c.instructor_id = i.instructor_id
LEFT JOIN enrollments_n e ON e.course_id     = c.course_id
GROUP BY i.instructor_name
ORDER BY students DESC, i.instructor_name;

-- P7  Expect: 1 row (Deepa)
SELECT s.roll_no, s.student_name
FROM students_n s
LEFT JOIN enrollments_n e ON s.roll_no = e.roll_no
WHERE e.roll_no IS NULL;

-- P8  Expect: 1 row (Cloud Computing)
SELECT c.course_id, c.course_name
FROM courses_n c
LEFT JOIN enrollments_n e ON e.course_id = c.course_id
WHERE e.course_id IS NULL;

-- P9  Expect: 5 rows (Anu SQL, Rahul SQL, Priya SQL, Meena SQL, Nisha MySQL)
SELECT s.student_name, c.course_name
FROM enrollments_n e
JOIN students_n    s ON e.roll_no       = s.roll_no
JOIN courses_n     c ON e.course_id     = c.course_id
JOIN instructors_n i ON c.instructor_id = i.instructor_id
WHERE i.instructor_name = 'Vikram'
ORDER BY s.roll_no, c.course_id;

-- P10 Run one at a time.
--     Expect: UPDATE 1
UPDATE instructors_n SET phone = '98400 88888' WHERE instructor_name = 'Neha';
--     Expect: 3 rows (Rahul, Kiran, Divya; phone 98400 88888 on each)
SELECT s.student_name, c.course_name, i.phone
FROM enrollments_n e
JOIN students_n    s ON e.roll_no       = s.roll_no
JOIN courses_n     c ON e.course_id     = c.course_id
JOIN instructors_n i ON c.instructor_id = i.instructor_id
WHERE i.instructor_name = 'Neha'
ORDER BY s.roll_no;

-- P11 Expect: NOTICE: Course 101 already exists. then DO
DO $$
BEGIN
    INSERT INTO courses VALUES (101, 'Python again', 3, 'Nobody');
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Course 101 already exists.';
END $$;

-- P12 Expect: NOTICE: Problem: insert or update on table "enrollments" violates
--             foreign key constraint "enrollments_student_id_fkey"   then DO
DO $$
BEGIN
    INSERT INTO enrollments VALUES (99, 99, 101, CURRENT_DATE, 'Active');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Problem: %', SQLERRM;
END $$;

-- P13 Four tables. books (book_id, title, author_id); authors (author_id, author_name);
--     members (member_id, member_name, phone); loans (loan_id, book_id, member_id,
--     borrowed_on, returned_on). A member's phone is stored once; a book's title once;
--     a loan is one row that points at a book and a member.

-- P14 An instructors table (instructor_id, instructor_name, phone, ...) and an
--     instructor_id column in courses as a foreign key, replacing the name.
--     Exactly what Part T did for courses_n.

-- P15 Because course 104 appeared twice, as 'Data Science' and 'Data science'. The
--     same fact had been typed 13 times in the sheet, and one copy differed. Repeated
--     data drifts apart; a design where each fact is stored once cannot drift.
