-- =====================================================================
--  SQL CLASS 2  |  Every query from the class, in order, with explanations
--  Topics: WHERE toolbox, CREATE TABLE and data types, constraints,
--          ALTER/DROP, NULL and COALESCE, joins, self join
-- =====================================================================
--  HOW TO USE THIS FILE
--  1. Run setup/class2_setup.sql first. It gives you the tables as they
--     were at the start of class 2: 11 students, no payments table yet.
--  2. Open this file in the Query Tool (folder icon -> Open File).
--  3. Highlight ONE statement, from its first word to the semicolon,
--     and press F5.
--  4. Compare your result with the "Expect" line written above it.
--
--  Do not run the whole file at once. Some statements FAIL ON PURPOSE,
--  to show how the database protects data, and the first failure cancels
--  everything else in the run.
--
--  TRY IT YOURSELF  = write the query before looking at the answer below it.
--  EXTRA CHALLENGE  = optional, a little harder.
--  [null]           = how pgAdmin shows an empty box.
-- =====================================================================


-- =====================================================================
--  PART 3  |  The WHERE toolbox
--  WHERE is a filter: the database checks every row and keeps it only
--  if the condition is true. Each word below is one English word.
-- =====================================================================

-- 3.1  DISTINCT shows each different value once. Nothing is deleted.
--      Expect: 5 rows (Bangalore, Chennai, Delhi, Hyderabad, Mumbai)
--      Why: 11 students, but only 5 different cities.
SELECT DISTINCT city FROM students ORDER BY city;

-- 3.2  IN = "any of these". Same as city = 'Chennai' OR city = 'Mumbai', but shorter.
--      Expect: 6 rows (Anu, John, Meena in Chennai; Sara, Ravi, nisha in Mumbai)
SELECT student_name, city FROM students WHERE city IN ('Chennai', 'Mumbai');

-- 3.3  BETWEEN = from ... to ..., BOTH ends included.
--      Expect: 5 rows (Anu 12000, Sara 12000, Meena 14000, Rahul 15000, Priya 15000)
SELECT student_name, fees FROM students WHERE fees BETWEEN 12000 AND 15000 ORDER BY fees;

-- 3.4  LIKE = a pattern. The % sign means "anything". 'A%' = starts with A.
--      Expect: 2 rows (Anu, Arjun)
SELECT student_name FROM students WHERE student_name LIKE 'A%';

-- 3.5  '%a' = ends with a.
--      Expect: 5 rows (Priya, Sara, Meena, Divya, nisha)
--      Note: LIKE is case-sensitive. 'a%' with a small a would find nobody.
SELECT student_name FROM students WHERE student_name LIKE '%a';

-- 3.6  <> means "not equal to".
--      Expect: 8 rows (everyone except the three Chennai students)
SELECT student_name, city FROM students WHERE city <> 'Chennai';

-- 3.7  AND = both conditions must be true.
--      Expect: 2 rows (Anu 12000, Meena 14000)
--      Why: John lives in Chennai but pays 10000, so he fails the second test.
SELECT student_name, city, fees FROM students WHERE city = 'Chennai' AND fees > 11000;

-- 3.8  OR = one true condition is enough.
--      Expect: 2 rows (Kiran in Bangalore 18000, Arjun in Delhi 20000)
--      Why: Kiran is not in Delhi, but his fee is 18000.
SELECT student_name, city, fees FROM students WHERE city = 'Delhi' OR fees >= 18000;

-- 3.9  Text values are case-sensitive. The name was typed as 'nisha' with a small n.
--      Expect: 0 rows
SELECT student_name FROM students WHERE student_name = 'Nisha';

-- 3.10 Keywords (select, from, where) do NOT care about capitals. Values still must match exactly.
--      Expect: 1 row (nisha)
select student_name from students where student_name = 'nisha';

-- 3.11 LOWER() turns the stored name into small letters before comparing. Safe searching.
--      Expect: 1 row
SELECT student_name FROM students WHERE LOWER(student_name) = 'nisha';

-- 3.12 Better: fix the stored data. UPDATE changes values.
--      ALWAYS write WHERE with UPDATE. Without it, every student would be renamed Nisha.
--      Expect (Messages tab): UPDATE 1
UPDATE students SET student_name = 'Nisha' WHERE student_id = 11;

-- 3.13 Check the fix.
--      Expect: 1 row (11, Nisha)
SELECT student_id, student_name FROM students WHERE student_id = 11;

-- 3.14 LIMIT 3 = only the first 3 rows of the sorted result ("page 1").
--      Expect: 3 rows (Arjun 20000, Kiran 18000, Divya 16000)
SELECT student_name, fees FROM students ORDER BY fees DESC, student_id LIMIT 3;

-- 3.15 OFFSET 3 = skip the first 3, then show 3 ("page 2").
--      Expect: 3 rows (Rahul 15000, Priya 15000, Meena 14000)
--      Note: ", student_id" in ORDER BY decides who comes first when fees are equal.
SELECT student_name, fees FROM students ORDER BY fees DESC, student_id LIMIT 3 OFFSET 3;

-- 3.16 MIN = smallest value, MAX = largest. One answer from many rows.
--      Expect: 1 row (10000, 20000)
SELECT MIN(fees) AS lowest_fee, MAX(fees) AS highest_fee FROM students;

-- 3.17 GROUP BY makes one pile per city. SUM and MAX then work on each pile.
--      Expect: 5 rows: Chennai 36000 / 14000, Mumbai 34000 / 12000, Bangalore 33000 / 18000,
--              Hyderabad 31000 / 16000, Delhi 20000 / 20000
--      Why: Chennai = 12000 + 10000 + 14000 = 36000, and the highest of the three is 14000.
SELECT city, SUM(fees) AS total_fees, MAX(fees) AS highest_fee
FROM students GROUP BY city ORDER BY total_fees DESC;

-- 3.18 TRY IT YOURSELF: students from Bangalore or Hyderabad, highest fee first.
--      Expect: 4 rows (Kiran 18000, Divya 16000, Rahul 15000, Priya 15000)
SELECT student_name, city, fees FROM students
WHERE city IN ('Bangalore', 'Hyderabad') ORDER BY fees DESC;

-- 3.19 EXTRA CHALLENGE: names that contain "ee".
--      Expect: 1 row (Meena)
SELECT student_name FROM students WHERE student_name LIKE '%ee%';


-- =====================================================================
--  PART 4  |  Building a table: CREATE TABLE, data types, casting
--  A data type says what kind of thing a column can hold. The database
--  refuses anything else.
-- =====================================================================

-- 4.1  CREATE TABLE builds an empty table. One line per column: name, type, rules.
--      INT = whole numbers.  NUMERIC(10,2) = money, 2 decimals.  DATE = a day.
--      BOOLEAN = true or false.  NOT NULL = must be filled.
--      REFERENCES students(student_id) = must be the ID of a real student.
--      Expect (Messages tab): CREATE TABLE
CREATE TABLE payments (
    payment_id   INT PRIMARY KEY,
    student_id   INT REFERENCES students(student_id),
    amount       NUMERIC(10,2) NOT NULL,
    paid_on      DATE NOT NULL,
    is_verified  BOOLEAN NOT NULL
);

-- 4.2  A new table is an empty shelf with labels.
--      Expect: 0 rows, but the column headings show
SELECT * FROM payments;

-- 4.3  INSERT puts rows in. Highlight the whole block (all 8 lines) and press F5 once.
--      Text and dates go in single quotes; numbers and TRUE/FALSE do not.
--      NULL means "leave the box empty". Payment 8 has no student: money arrived by
--      bank transfer and nobody knows who sent it.
--      Expect (Messages tab): INSERT 0 8
INSERT INTO payments (payment_id, student_id, amount, paid_on, is_verified) VALUES
 (1, 1,    6000.00,  '2026-01-10', TRUE),    -- Anu, installment 1
 (2, 1,    6000.00,  '2026-02-10', TRUE),    -- Anu, installment 2
 (3, 2,    7500.50,  '2026-01-12', TRUE),    -- Rahul, partial
 (4, 4,    10000.00, '2026-02-15', TRUE),    -- John, full
 (5, 5,    12000.00, '2026-03-01', FALSE),   -- Sara, not yet verified
 (6, 8,    20000.00, '2026-04-12', TRUE),    -- Arjun, full
 (7, 10,   11000.00, '2026-05-15', FALSE),   -- Ravi, not yet verified
 (8, NULL, 10000.00, '2026-11-10', FALSE);   -- unidentified payment

-- 4.4  Look at the data: two decimals in amount, dates in paid_on, true/false in
--      is_verified, and the empty box in row 8.
--      Expect: 8 rows
SELECT * FROM payments ORDER BY payment_id;

-- 4.5  FAILS ON PURPOSE: words cannot go into a number column.
--      Expect: ERROR: invalid input syntax for type numeric: "five thousand"
--      Nothing is inserted. Always read the first line of an error: it names the rule you broke.
INSERT INTO payments VALUES (9, 2, 'five thousand', '2026-11-12', TRUE);

-- 4.6  FAILS ON PURPOSE: there is no month 13. Dates are always written 'YYYY-MM-DD'.
--      Expect: ERROR: date/time field value out of range: "2026-13-01"
INSERT INTO payments VALUES (9, 2, 5000, '2026-13-01', TRUE);

-- 4.7  FAILS ON PURPOSE: the status column is VARCHAR(20) = at most 20 characters.
--      "Completed with distinction" has 25.
--      Expect: ERROR: value too long for type character varying(20)
INSERT INTO enrollments VALUES (13, 11, 106, '2026-11-13', 'Completed with distinction');

-- 4.8  A BOOLEAN column is already a yes/no answer, so it can be the whole condition.
--      Expect: 5 rows (payments 1, 2, 3, 4, 6)
SELECT payment_id, amount, is_verified FROM payments WHERE is_verified = TRUE;

-- 4.9  NOT flips the condition.
--      Expect: 3 rows (payments 5, 7, 8)
SELECT payment_id, amount, is_verified FROM payments WHERE NOT is_verified;

-- 4.10 Dates compare like numbers: a later date is "bigger".
--      Expect: 7 rows (Sara, Kiran, Meena, Arjun, Divya, Ravi, Nisha)
SELECT student_name, admission_date FROM students WHERE admission_date >= '2026-03-01' ORDER BY admission_date;

-- 4.11 Date + a number = that many days later. The database knows the calendar.
--      Expect: 11 rows; Anu 2026-01-10 -> 2026-02-09, Rahul 2026-01-12 -> 2026-02-11, ...
SELECT student_name, admission_date, admission_date + 30 AS fee_due_date FROM students ORDER BY student_id;

-- 4.12 DATE is a day. TIMESTAMP is a day and a time.
--      Expect: today's date, and the current date and time
SELECT CURRENT_DATE AS today, NOW() AS right_now;

-- 4.13 CASTING changes the kind of a value. Two spellings: value::TYPE or CAST(value AS TYPE).
--      Expect: 30   (the text '25' became the number 25, then 25 + 5)
SELECT '25'::INT + 5 AS result;

-- 4.14 Text became a date.
--      Expect: 2026-11-13
SELECT CAST('2026-11-13' AS DATE) AS a_date;

-- 4.15 FAILS ON PURPOSE: nonsense cannot become a number.
--      Expect: ERROR: invalid input syntax for type integer: "abc"
SELECT 'abc'::INT;

-- 4.16 THE DIVISION TRAP: whole number / whole number = whole number. The .5 is thrown away.
--      Expect: 3
SELECT 7 / 2 AS result;

-- 4.17 Make one side a decimal (2.0) and the decimals stay. ROUND(x, 1) keeps one decimal.
--      Expect: 3.5
SELECT ROUND(7 / 2.0, 1) AS result;

-- 4.18 The same trap on real data. Compare the last two columns.
--      Expect: 11 rows; Anu 1000 / 1000.00, John 833 / 833.33, Meena 1166 / 1166.67, ...
SELECT student_name, fees, fees / 12 AS wrong_monthly, ROUND(fees / 12.0, 2) AS monthly
FROM students ORDER BY student_id;

-- 4.19 TRY IT YOURSELF: students admitted in January or February.
--      Expect: 4 rows (Anu, Rahul, Priya, John)
SELECT student_name, admission_date FROM students
WHERE admission_date BETWEEN '2026-01-01' AND '2026-02-28' ORDER BY admission_date;

-- 4.20 EXTRA CHALLENGE: days since each admission. Date - date = number of days.
--      Expect: 11 rows; the numbers change every day
SELECT student_name, CURRENT_DATE - admission_date AS days_since_admission FROM students ORDER BY student_id;


-- =====================================================================
--  PART 5  |  Constraints: the rules a table refuses to break
--  A constraint is written once, when the table is created. The database
--  checks it on every insert, update and delete. Run each statement ALONE.
--  The first six FAIL ON PURPOSE; each error names the rule that stopped it.
-- =====================================================================

-- 5.1  PRIMARY KEY: student_id 1 is already Anu. Two rows cannot share an ID.
--      Expect: ERROR: duplicate key value violates unique constraint "students_pkey"
INSERT INTO students VALUES (1, 'Deepa', 24, 'Pune', 'deepa@example.com', 15000, '2026-11-13');

-- 5.2  NOT NULL: the name box must be filled.
--      Expect: ERROR: null value in column "student_name" ... violates not-null constraint
INSERT INTO students VALUES (12, NULL, 24, 'Pune', 'deepa@example.com', 15000, '2026-11-13');

-- 5.3  CHECK (age >= 0): minus five fails the test.
--      Expect: ERROR: new row for relation "students" violates check constraint "students_age_check"
INSERT INTO students VALUES (12, 'Deepa', -5, 'Pune', 'deepa@example.com', 15000, '2026-11-13');

-- 5.4  UNIQUE: anu@example.com already belongs to Anu. One account per email.
--      Expect: ERROR: duplicate key value violates unique constraint "students_email_key"
INSERT INTO students VALUES (12, 'Deepa', 24, 'Pune', 'anu@example.com', 15000, '2026-11-13');

-- 5.5  FOREIGN KEY: there is no student 99, so there can be no enrollment for 99.
--      Expect: ERROR: ... violates foreign key constraint "enrollments_student_id_fkey"
INSERT INTO enrollments VALUES (13, 99, 101, '2026-11-13', 'Active');

-- 5.6  FOREIGN KEY, the other direction: Anu still has enrollments and payments pointing
--      at her ID, so the database refuses to delete her. No orphan records.
--      Expect: ERROR: ... Key (student_id)=(1) is still referenced from table "enrollments"
DELETE FROM students WHERE student_id = 1;

-- 5.7  A correct insert. Deepa joined today. We do not know her city, so city is NULL;
--      that is allowed because the city column has no NOT NULL rule.
--      Listing the column names before VALUES is safer than relying on their order.
--      Expect (Messages tab): INSERT 0 1
INSERT INTO students (student_id, student_name, age, city, email, fees, admission_date)
VALUES (12, 'Deepa', 24, NULL, 'deepa@example.com', 15000, CURRENT_DATE);

-- 5.8  Deepa's city shows [null]: the box is empty. Not zero, not blank text. Unknown.
--      Expect: 12 rows
SELECT * FROM students ORDER BY student_id;

-- 5.9  TRY IT YOURSELF: insert yourself as student 13 (change the name, age, city and
--      email to yours), count the rows, then delete yourself again. Run the four
--      statements one at a time.
--      Expect: INSERT 0 1, then 13, then DELETE 1, then 12
INSERT INTO students (student_id, student_name, age, city, email, fees, admission_date)
VALUES (13, 'Your Name', 30, 'Pune', 'you@example.com', 10000, CURRENT_DATE);
SELECT COUNT(*) FROM students;
DELETE FROM students WHERE student_id = 13;
SELECT COUNT(*) FROM students;


-- =====================================================================
--  PART 6  |  Changing a table: ALTER TABLE and DROP TABLE
--  INSERT, UPDATE and DELETE change the DATA. CREATE, ALTER and DROP
--  change the STRUCTURE: the table itself.
-- =====================================================================

-- 6.1  ALTER TABLE changes the shape of a table that already has data. A new column is
--      empty ([null]) in every existing row: the database cannot invent values.
--      Expect (Messages tab): ALTER TABLE
ALTER TABLE payments ADD COLUMN method VARCHAR(20);

-- 6.2  Expect: 8 rows, with the new method column empty in all of them
SELECT * FROM payments ORDER BY payment_id;

-- 6.3  Fill one value. Payment 8 came by bank transfer.
--      Expect (Messages tab): UPDATE 1
UPDATE payments SET method = 'Bank transfer' WHERE payment_id = 8;

-- 6.4  Expect: 8 rows; only payment 8 has a method
SELECT payment_id, amount, method FROM payments ORDER BY payment_id;

-- 6.5  DROP TABLE throws a table away: rows, columns and rules. There is no undo.
--      Practise only on a throwaway table. Run these four one at a time.
--      Expect: CREATE TABLE, then INSERT 0 1, then 1 row, then DROP TABLE
CREATE TABLE practice_delete (id INT PRIMARY KEY);
INSERT INTO practice_delete (id) VALUES (1);
SELECT * FROM practice_delete;
DROP TABLE practice_delete;

-- 6.6  FAILS ON PURPOSE: the table is gone.
--      Expect: ERROR: relation "practice_delete" does not exist
SELECT * FROM practice_delete;


-- =====================================================================
--  PART 7  |  Empty boxes: NULL, COALESCE, CASE, text and maths
-- =====================================================================

-- 7.1  "= NULL" is NEVER true. An empty box is not equal to anything, not even another
--      empty box. So this finds nobody, not even Deepa.
--      Expect: 0 rows
SELECT student_name, city FROM students WHERE city = NULL;

-- 7.2  IS NULL is the right question: which boxes are empty?
--      Expect: 1 row (Deepa)
SELECT student_name, city FROM students WHERE city IS NULL;

-- 7.3  COALESCE = "if the box is empty, show this instead". The stored data is not changed.
--      Expect: 12 rows; everyone shows their city, Deepa shows "Not given"
SELECT student_name, COALESCE(city, 'Not given') AS city_shown FROM students ORDER BY student_id;

-- 7.4  The same idea on the half-filled method column.
--      Expect: 8 rows; payments 1 to 7 show "Not recorded", payment 8 shows "Bank transfer"
SELECT payment_id, amount, COALESCE(method, 'Not recorded') AS method FROM payments ORDER BY payment_id;

-- 7.5  COUNT(*) counts rows. COUNT(column) counts filled boxes only.
--      Expect: 1 row (12, 11)
SELECT COUNT(*) AS all_rows, COUNT(city) AS rows_with_city FROM students;

-- 7.6  CASE with several WHENs: checked top to bottom, the first true one wins.
--      Put the biggest threshold first.
--      Expect: 12 rows. High = Arjun, Kiran. Medium = Divya, Deepa, Priya, Rahul, Meena.
--              Low = Anu, Sara, Nisha, Ravi, John.
SELECT student_name, fees,
       CASE WHEN fees >= 18000 THEN 'High'
            WHEN fees >= 13000 THEN 'Medium'
            ELSE 'Low' END AS fee_band
FROM students ORDER BY fees DESC, student_name;

-- 7.7  || glues text together. Glue anything to an empty box and the whole result is empty.
--      Expect: 12 rows: "Anu from Chennai", ... and Deepa's row is EMPTY
SELECT student_name || ' from ' || city AS label FROM students ORDER BY student_id;

-- 7.8  COALESCE fixes it.
--      Expect: 12 rows; the last one is "Deepa from unknown city"
SELECT student_name || ' from ' || COALESCE(city, 'unknown city') AS label FROM students ORDER BY student_id;

-- 7.9  Text functions: UPPER = capitals, LENGTH = number of characters.
--      Expect: 12 rows; ANU 3, RAHUL 5, PRIYA 5, JOHN 4, ...
SELECT student_name, UPPER(student_name) AS shout, LENGTH(student_name) AS letters FROM students ORDER BY student_id;

-- 7.10 Maths in the SELECT list. The fees column itself is NOT changed.
--      Expect: 12 rows; Anu 12000 -> 14160.00, Rahul 15000 -> 17700.00, ...
SELECT student_name, fees, fees * 1.18 AS total_with_gst FROM students ORDER BY student_id;

-- 7.11 TRY IT YOURSELF: label each payment Verified or Pending.
--      Expect: 8 rows. Verified = 1, 2, 3, 4, 6. Pending = 5, 7, 8.
SELECT payment_id, amount, CASE WHEN is_verified THEN 'Verified' ELSE 'Pending' END AS status FROM payments ORDER BY payment_id;

-- 7.12 EXTRA CHALLENGE: amounts in thousands, like 7.5k.
--      Expect: 8 rows (6.0k, 6.0k, 7.5k, 10.0k, 12.0k, 20.0k, 11.0k, 10.0k)
SELECT payment_id, ROUND(amount / 1000, 1) || 'k' AS short_amount FROM payments ORDER BY payment_id;


-- =====================================================================
--  PART 8  |  Joins
--  The students table is the class register. The payments table is the
--  receipt book. Every receipt carries a student's ID number. A join lays
--  each receipt next to the register line with the same ID.
-- =====================================================================

-- 8.1  First, the two tables on their own. Run separately.
--      Expect: 12 students; 8 payments (student_id 1 appears twice, payment 8 has none)
SELECT student_id, student_name FROM students ORDER BY student_id;
SELECT payment_id, student_id, amount FROM payments ORDER BY payment_id;

-- 8.2  THE PICTURE: every student and every payment side by side, matched on student_id.
--      Both IDs are shown so you can see the matching. A filled row on both sides = a match.
--      Empty on the right = a student with no payment. Empty on the left = a payment with no student.
--      Expect: 14 rows = 7 matches + 6 students with no payment + 1 payment with no student
--      Every join below is just a choice of which of these 14 lines to keep.
SELECT s.student_id AS s_id, s.student_name, p.student_id AS p_id, p.payment_id, p.amount
FROM students s FULL JOIN payments p ON s.student_id = p.student_id
ORDER BY s.student_id, p.payment_id;

-- 8.3  INNER JOIN keeps only the lines filled on BOTH sides.
--      Expect: 7 rows (Anu twice, Rahul, John, Sara, Arjun, Ravi). No [null] anywhere.
--      Why: the six unpaid students and payment 8 have no match, so they are dropped.
SELECT s.student_id AS s_id, s.student_name, p.student_id AS p_id, p.payment_id, p.amount
FROM students s INNER JOIN payments p ON s.student_id = p.student_id
ORDER BY s.student_id, p.payment_id;

-- 8.4  LEFT JOIN keeps every row of the LEFT table (students), matched or not.
--      Expect: 13 rows = 7 matches + 6 students with empty payment boxes. Payment 8 is gone.
SELECT s.student_id AS s_id, s.student_name, p.student_id AS p_id, p.payment_id, p.amount
FROM students s LEFT JOIN payments p ON s.student_id = p.student_id
ORDER BY s.student_id, p.payment_id;

-- 8.5  THE PATTERN TO REMEMBER: LEFT JOIN + IS NULL = "who has NOT ...".
--      Keep every student, then keep only the lines whose payment box is empty.
--      Expect: 6 rows (Priya, Kiran, Meena, Divya, Nisha, Deepa)
SELECT s.student_name, s.fees
FROM students s LEFT JOIN payments p ON s.student_id = p.student_id
WHERE p.payment_id IS NULL
ORDER BY s.student_id;

-- 8.6  RIGHT JOIN keeps every row of the RIGHT table (payments), matched or not.
--      Expect: 8 rows = 7 matches + payment 8 with an empty name. The unpaid students are gone.
SELECT s.student_id AS s_id, s.student_name, p.student_id AS p_id, p.payment_id, p.amount
FROM students s RIGHT JOIN payments p ON s.student_id = p.student_id
ORDER BY p.payment_id;

-- 8.7  A RIGHT JOIN is a LEFT JOIN with the tables swapped. Same 8 rows, easier to read.
--      Expect: the same 8 rows as 8.6
SELECT s.student_id AS s_id, s.student_name, p.student_id AS p_id, p.payment_id, p.amount
FROM payments p LEFT JOIN students s ON s.student_id = p.student_id
ORDER BY p.payment_id;

-- 8.8  FULL JOIN keeps everything from both tables. This is the picture from 8.2.
--      Expect: 14 rows
SELECT s.student_id AS s_id, s.student_name, p.student_id AS p_id, p.payment_id, p.amount
FROM students s FULL JOIN payments p ON s.student_id = p.student_id
ORDER BY s.student_id, p.payment_id;

-- 8.9  Only the problems: students who have not paid AND the payment nobody can explain.
--      Expect: 7 rows (6 students with empty payment boxes, then payment 8 with an empty name)
SELECT s.student_name, p.payment_id, p.amount
FROM students s FULL JOIN payments p ON s.student_id = p.student_id
WHERE s.student_id IS NULL OR p.payment_id IS NULL
ORDER BY s.student_id, p.payment_id;

-- 8.10 The same pattern on other tables: which course has no students?
--      Expect: 1 row (Cloud Computing)
SELECT c.course_name
FROM courses c LEFT JOIN enrollments e ON c.course_id = e.course_id
WHERE e.enrollment_id IS NULL;

-- 8.11 Which students have no enrollment?
--      Expect: 2 rows (Nisha, Deepa)
SELECT s.student_name
FROM students s LEFT JOIN enrollments e ON s.student_id = e.student_id
WHERE e.enrollment_id IS NULL
ORDER BY s.student_id;

-- 8.12 Three tables, one hop at a time. Students and courses are not directly linked;
--      enrollments sits between them like a bridge. Hop 1: students -> enrollments.
--      Expect: 12 rows, one per enrollment; course numbers only (Anu 101, Anu 102, Rahul 102, ...)
SELECT s.student_name, e.course_id
FROM students s INNER JOIN enrollments e ON s.student_id = e.student_id
ORDER BY s.student_id, e.course_id;

-- 8.13 Hop 2: one more JOIN ... ON line brings in the course names.
--      Expect: 12 rows (Anu Python, Anu SQL, Rahul SQL, Rahul Data Science, Priya SQL, ...)
SELECT s.student_name, c.course_name
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id
ORDER BY s.student_id, c.course_id;

-- 8.14 TRY IT YOURSELF: each payment with the student's name and the date paid.
--      Expect: 7 rows (Anu twice)
--      Why INNER: a payment without a student has no name to show.
SELECT s.student_name, p.amount, p.paid_on
FROM students s INNER JOIN payments p ON s.student_id = p.student_id
ORDER BY p.payment_id;

-- 8.15 EXTRA CHALLENGE: total paid per student. Join first, then GROUP BY piles the rows
--      per student, then SUM adds each pile. Anu's two receipts become one line.
--      Expect: 6 rows (Anu 12000.00, Rahul 7500.50, John 10000.00, Sara 12000.00, Arjun 20000.00, Ravi 11000.00)
SELECT s.student_name, SUM(p.amount) AS total_paid
FROM students s INNER JOIN payments p ON s.student_id = p.student_id
GROUP BY s.student_id, s.student_name
ORDER BY s.student_id;

-- 8.16 EXTRA CHALLENGE: everyone, with 0 if nothing was paid. LEFT JOIN keeps the unpaid
--      students; their SUM is empty; COALESCE turns the empty sum into 0.
--      Expect: 12 rows; six of them show paid = 0
SELECT s.student_name, s.fees, COALESCE(SUM(p.amount), 0) AS paid
FROM students s LEFT JOIN payments p ON s.student_id = p.student_id
GROUP BY s.student_id, s.student_name, s.fees
ORDER BY s.student_id;


-- =====================================================================
--  PART 9  |  Self join: a table joined to itself
--  Imagine two photocopies of the student list, nicknamed a and b.
--  Then it is an ordinary join between copy a and copy b.
-- =====================================================================

-- 9.1  Step 1: match on city. Chennai only, to keep it small.
--      Expect: 9 rows (3 students x 3 students). Two problems: Anu is paired with herself,
--              and Anu-John and John-Anu are the same pair twice.
SELECT a.student_name AS student_a, b.student_name AS student_b, a.city
FROM students a JOIN students b ON a.city = b.city
WHERE a.city = 'Chennai'
ORDER BY a.student_name, b.student_name;

-- 9.2  Step 2: <> removes the self-pairs.
--      Expect: 6 rows. Each pair still appears twice.
SELECT a.student_name AS student_a, b.student_name AS student_b, a.city
FROM students a JOIN students b ON a.city = b.city AND a.student_id <> b.student_id
WHERE a.city = 'Chennai'
ORDER BY a.student_name, b.student_name;

-- 9.3  Step 3: < keeps each pair once, with the smaller ID on the left. The standard trick.
--      Expect: 3 rows (Anu-John, Anu-Meena, John-Meena)
SELECT a.student_name AS student_a, b.student_name AS student_b, a.city
FROM students a JOIN students b ON a.city = b.city AND a.student_id < b.student_id
WHERE a.city = 'Chennai'
ORDER BY a.student_name, b.student_name;

-- 9.4  All cities.
--      Expect: 8 rows: Rahul-Kiran (Bangalore); Anu-John, Anu-Meena, John-Meena (Chennai);
--              Priya-Divya (Hyderabad); Ravi-Nisha, Sara-Nisha, Sara-Ravi (Mumbai)
--      Why is Deepa in no pair? Her city is empty, and an empty box never equals anything.
--      Why is Arjun in no pair? He is alone in Delhi.
SELECT a.student_name AS student_a, b.student_name AS student_b, a.city
FROM students a JOIN students b ON a.city = b.city AND a.student_id < b.student_id
ORDER BY a.city, a.student_name, b.student_name;

-- 9.5  TRY IT YOURSELF: pairs of students who pay the same fees, each pair once.
--      Expect: 5 rows (Ravi-Nisha 11000; Anu-Sara 12000; Priya-Deepa, Rahul-Deepa, Rahul-Priya 15000)
SELECT a.student_name AS student_a, b.student_name AS student_b, a.fees
FROM students a JOIN students b ON a.fees = b.fees AND a.student_id < b.student_id
ORDER BY a.fees, a.student_name, b.student_name;


-- =====================================================================
--  PART 10  |  Final question
-- =====================================================================

-- 10.1 Names and cities of the students who have not paid. Where the city is
--      missing, show "Not given". (LEFT JOIN + IS NULL, plus COALESCE.)
--      Expect: 6 rows (Deepa Not given, Divya Hyderabad, Kiran Bangalore, Meena Chennai,
--              Nisha Mumbai, Priya Hyderabad)
SELECT s.student_name, COALESCE(s.city, 'Not given') AS city
FROM students s LEFT JOIN payments p ON s.student_id = p.student_id
WHERE p.payment_id IS NULL
ORDER BY s.student_name;


-- =====================================================================
--  IF YOUR TABLES BREAK PART-WAY THROUGH THIS FILE
-- =====================================================================
--  1. Run setup/class2_setup.sql again (F5). It rebuilds students, courses
--     and enrollments and removes the payments table.
--  2. Come back here and run the statements below, from the top down to
--     the part you were in. Example: if you were in Part 7, run the
--     statements for Parts 3, 4, 5 and 6.
-- =====================================================================

-- Part 3
UPDATE students SET student_name = 'Nisha' WHERE student_id = 11;

-- Part 4
CREATE TABLE payments (
    payment_id   INT PRIMARY KEY,
    student_id   INT REFERENCES students(student_id),
    amount       NUMERIC(10,2) NOT NULL,
    paid_on      DATE NOT NULL,
    is_verified  BOOLEAN NOT NULL
);
INSERT INTO payments (payment_id, student_id, amount, paid_on, is_verified) VALUES
 (1, 1,    6000.00,  '2026-01-10', TRUE),
 (2, 1,    6000.00,  '2026-02-10', TRUE),
 (3, 2,    7500.50,  '2026-01-12', TRUE),
 (4, 4,    10000.00, '2026-02-15', TRUE),
 (5, 5,    12000.00, '2026-03-01', FALSE),
 (6, 8,    20000.00, '2026-04-12', TRUE),
 (7, 10,   11000.00, '2026-05-15', FALSE),
 (8, NULL, 10000.00, '2026-11-10', FALSE);

-- Part 5
INSERT INTO students (student_id, student_name, age, city, email, fees, admission_date)
VALUES (12, 'Deepa', 24, NULL, 'deepa@example.com', 15000, CURRENT_DATE);

-- Part 6
ALTER TABLE payments ADD COLUMN method VARCHAR(20);
UPDATE payments SET method = 'Bank transfer' WHERE payment_id = 8;
