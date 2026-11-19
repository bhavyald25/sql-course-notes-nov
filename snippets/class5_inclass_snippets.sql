-- =====================================================================
--  SQL CLASS 5  |  Every query from the class, in order, with explanations
--  Topics: EXISTS and NOT EXISTS; a subquery used as a table and as a
--          column; CTEs (WITH): one CTE, a CTE used twice, several CTEs,
--          CTE + join; and a 20-question practice set at the end
-- =====================================================================
--  HOW TO USE THIS FILE
--  1. Run setup/class5_setup.sql first.
--  2. Open this file in the Query Tool (folder icon -> Open File).
--  3. Highlight ONE statement, from its first word to the semicolon,
--     and press F5. A WITH query is ONE statement: highlight from WITH
--     down to the final semicolon.
--  4. Compare your result with the "Expect" line written above it.
--
--  Do not run the whole file at once. Some statements FAIL ON PURPOSE,
--  and the first failure cancels everything else in the run.
--
--  TRY IT YOURSELF  = write the query before looking at the answer below it.
--  EXTRA CHALLENGE  = optional, a little harder.
--  [null]           = how pgAdmin shows an empty box.
-- =====================================================================


-- =====================================================================
--  PART 0  |  Check that the setup worked
-- =====================================================================

-- 0.1  Must show 12 | 8 | 12.
--      Expect: 1 row (12, 8, 12)
SELECT (SELECT COUNT(*) FROM students)    AS students,
       (SELECT COUNT(*) FROM payments)    AS payments,
       (SELECT COUNT(*) FROM enrollments) AS enrollments;


-- =====================================================================
--  PART R  |  Three quick questions from class 4
-- =====================================================================

-- R1  Students who pay more than the average fee. One value in the brackets.
--     Expect: 6 rows (Arjun 20000, Kiran 18000, Divya 16000, Deepa, Priya, Rahul 15000)
SELECT student_name, fees FROM students
WHERE fees > (SELECT AVG(fees) FROM students)
ORDER BY fees DESC, student_name;

-- R2  Students enrolled in Python (course 101). A list in the brackets.
--     Expect: 2 rows (Anu, Sara)
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM enrollments WHERE course_id = 101)
ORDER BY student_id;

-- R3  Customers who have never ordered, with NOT IN. Order 104 has an empty customer_id,
--     so without IS NOT NULL this gives 0 rows.
--     Expect: 2 rows (Sara, John)
SELECT customer_name FROM customers
WHERE customer_id NOT IN (SELECT customer_id FROM orders WHERE customer_id IS NOT NULL)
ORDER BY customer_id;


-- =====================================================================
--  PART D  |  EXISTS and NOT EXISTS
--  EXISTS asks one question: "is there at least one matching row?"
--  Picture: go down the class register one name at a time. For each name,
--  flip through the receipt book: is there ANY receipt with this ID?
--  Yes -> keep the name. No -> skip it.
--  Two things to notice in the query:
--    * the inner query mentions the outer table (p.student_id = s.student_id).
--      That is the LINK: "a payment for THIS student". The inner query is
--      answered once per student.
--    * SELECT 1 inside: we only want to know whether any row comes back,
--      not what is in it. The 1 is a placeholder.
-- =====================================================================

-- D1  Students who have paid.
--     Expect: 6 rows (Anu, Rahul, John, Sara, Arjun, Ravi). Anu once: one receipt is enough.
SELECT s.student_name
FROM students s
WHERE EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
ORDER BY s.student_id;

-- D2  Students who have NOT paid. The empty box on payment 8 does no harm here: for Priya (3),
--     the inner query looks for payments with student_id = 3; payment 8's empty box is simply
--     not equal to 3, so it is not found; nothing found -> NOT EXISTS is true -> Priya is kept.
--     Expect: 6 rows (Priya, Kiran, Meena, Divya, Nisha, Deepa)
SELECT s.student_name
FROM students s
WHERE NOT EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
ORDER BY s.student_id;

-- D3  Courses with no students.
--     Expect: 1 row (Cloud Computing)
SELECT c.course_name
FROM courses c
WHERE NOT EXISTS (SELECT 1 FROM enrollments e WHERE e.course_id = c.course_id);

-- D4  Customers with no orders. Order 104's empty customer_id does no harm.
--     Expect: 2 rows (Sara, John)
SELECT c.customer_name
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)
ORDER BY c.customer_id;

-- D5  THE MISTAKE: forget the link, and the inner question becomes "is there any payment at
--     all in the table?". Yes, eight. So the answer is yes for every student.
--     Expect: 12 rows (everyone).  If EXISTS returns everyone, check the link.
SELECT s.student_name
FROM students s
WHERE EXISTS (SELECT 1 FROM payments p)
ORDER BY s.student_id;

-- D6  TRY IT YOURSELF: students with at least one Completed enrollment. The inner query
--     can have more conditions than just the link.
--     Expect: 2 rows (John, Meena)
SELECT s.student_name
FROM students s
WHERE EXISTS (SELECT 1 FROM enrollments e
              WHERE e.student_id = s.student_id AND e.status = 'Completed')
ORDER BY s.student_id;

-- D7  EXTRA CHALLENGE: courses that have at least one student.
--     Expect: 5 rows (all except Cloud Computing)
SELECT c.course_name
FROM courses c
WHERE EXISTS (SELECT 1 FROM enrollments e WHERE e.course_id = c.course_id)
ORDER BY c.course_id;

-- D8  THREE WAYS, ONE ANSWER: students who have not paid. Run all three.
--     Expect: the same 6 names each time (Priya, Kiran, Meena, Divya, Nisha, Deepa)
--     1. LEFT JOIN + IS NULL: can also show columns from payments.
--     2. NOT IN: shortest, but only safe when the list has no empty boxes.
--     3. NOT EXISTS: always safe.
SELECT s.student_name FROM students s
LEFT JOIN payments p ON s.student_id = p.student_id
WHERE p.payment_id IS NULL ORDER BY s.student_id;

SELECT student_name FROM students
WHERE student_id NOT IN (SELECT student_id FROM payments WHERE student_id IS NOT NULL)
ORDER BY student_id;

SELECT s.student_name FROM students s
WHERE NOT EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
ORDER BY s.student_id;


-- =====================================================================
--  PART E  |  Two more places a subquery can go: as a TABLE, as a COLUMN
--  So far the brackets sat inside WHERE. A query's result is itself a
--  table, so it can also sit in FROM. And a one-value query can sit in
--  the SELECT list and become a column.
-- =====================================================================

-- E1  A query result used as a TABLE. The inner query makes a five-row table of city totals,
--     nicknamed city_totals; the outer query filters it like any table.
--     Expect: 3 rows (Chennai 36000, Mumbai 34000, Bangalore 33000)
SELECT city, total_fees
FROM (SELECT city, SUM(fees) AS total_fees
      FROM students
      WHERE city IS NOT NULL
      GROUP BY city) AS city_totals
WHERE total_fees > 32000
ORDER BY total_fees DESC;

-- E2  Something HAVING cannot do: the average of the five city totals. First make the
--     totals, then average them. Two steps, one query.
--     Expect: 30800.00   ((36000 + 34000 + 33000 + 31000 + 20000) / 5)
SELECT ROUND(AVG(total_fees), 2) AS average_city_total
FROM (SELECT city, SUM(fees) AS total_fees
      FROM students
      WHERE city IS NOT NULL
      GROUP BY city) AS city_totals;

-- E3  A one-value query used as a COLUMN. Every row shows the same average next to its own fee.
--     Expect: 12 rows (Anu 12000, 14083, -2083; Rahul 15000, 14083, 917; ...)
SELECT student_name, fees,
       (SELECT ROUND(AVG(fees)) FROM students) AS average_fee,
       fees - (SELECT ROUND(AVG(fees)) FROM students) AS difference
FROM students
ORDER BY student_id;

-- E4  A column that looks at THIS row: the number of payments per student. The link
--     p.student_id = s.student_id again. Counting nothing gives 0, so no COALESCE is needed.
--     Expect: 12 rows (Anu 2, Rahul 1, Priya 0, John 1, Sara 1, Kiran 0, Meena 0, Arjun 1,
--             Divya 0, Ravi 1, Nisha 0, Deepa 0)
SELECT s.student_name,
       (SELECT COUNT(*) FROM payments p WHERE p.student_id = s.student_id) AS payments
FROM students s
ORDER BY s.student_id;


-- =====================================================================
--  PART W  |  CTEs: WITH
--  A CTE (common table expression) is a subquery with a NAME, written at
--  the TOP of the statement. "WITH city_totals AS ( ... )" means: first
--  build this small table and call it city_totals; then the main query
--  below can use that name like a real table. Same rows as the subquery
--  version; the difference is that the query now reads top to bottom.
--  A WITH query is ONE statement: highlight from WITH to the final semicolon.
-- =====================================================================

-- W1  The first CTE. This is E1 rewritten: the bracket moved to the top and got a name.
--     Expect: 3 rows (Chennai 36000, Mumbai 34000, Bangalore 33000), the same as E1
WITH city_totals AS (
    SELECT city, SUM(fees) AS total_fees
    FROM students
    WHERE city IS NOT NULL
    GROUP BY city
)
SELECT city, total_fees
FROM city_totals
WHERE total_fees > 32000
ORDER BY total_fees DESC;

-- W2  FAILS ON PURPOSE: a CTE lives only inside its own statement. After the semicolon the
--     name is gone.
--     Expect: ERROR: relation "city_totals" does not exist
SELECT * FROM city_totals;

-- W3  A CTE can be used TWICE in the same statement. Cities whose total is above the average
--     city total: city_totals is used in FROM and again inside the brackets.
--     Expect: 4 rows (Chennai 36000, Mumbai 34000, Bangalore 33000, Hyderabad 31000)
--     Why: the average city total is 30800; Delhi (20000) is the only city below it.
WITH city_totals AS (
    SELECT city, SUM(fees) AS total_fees
    FROM students
    WHERE city IS NOT NULL
    GROUP BY city
)
SELECT city, total_fees
FROM city_totals
WHERE total_fees > (SELECT AVG(total_fees) FROM city_totals)
ORDER BY total_fees DESC;

-- W4  SEVERAL CTEs, one after another, separated by a comma. The second one can use the first.
--     Step 1 on its own: how much has each student paid?
--     Expect: 6 rows (1: 12000.00, 2: 7500.50, 4: 10000.00, 5: 12000.00, 8: 20000.00, 10: 11000.00)
SELECT student_id, SUM(amount) AS paid
FROM payments
WHERE student_id IS NOT NULL
GROUP BY student_id
ORDER BY student_id;

-- W5  Step 2 on its own: every student with fees, paid and balance. LEFT JOIN keeps the
--     students who paid nothing; COALESCE turns their empty paid box into 0.
--     Expect: 12 rows (Anu 12000, 12000.00, 0.00; Rahul 15000, 7500.50, 7499.50; Priya 15000, 0, 15000; ...)
WITH paid_per_student AS (
    SELECT student_id, SUM(amount) AS paid
    FROM payments
    WHERE student_id IS NOT NULL
    GROUP BY student_id
)
SELECT s.student_name, s.fees,
       COALESCE(p.paid, 0) AS paid,
       s.fees - COALESCE(p.paid, 0) AS balance
FROM students s LEFT JOIN paid_per_student p ON s.student_id = p.student_id
ORDER BY s.student_id;

-- W6  Both steps as two CTEs, then the final question: who still owes money?
--     Expect: 7 rows (Kiran 18000, Divya 16000, Deepa 15000, Priya 15000, Meena 14000,
--             Nisha 11000, Rahul 7499.50)
WITH paid_per_student AS (
    SELECT student_id, SUM(amount) AS paid
    FROM payments
    WHERE student_id IS NOT NULL
    GROUP BY student_id
),
balances AS (
    SELECT s.student_name, s.fees,
           COALESCE(p.paid, 0) AS paid,
           s.fees - COALESCE(p.paid, 0) AS balance
    FROM students s LEFT JOIN paid_per_student p ON s.student_id = p.student_id
)
SELECT student_name, fees, paid, balance
FROM balances
WHERE balance > 0
ORDER BY balance DESC, student_name;

-- W7  A CTE joined to other tables: the unpaid students and the courses they take.
--     Expect: 4 rows (Divya Data Science, Kiran Data Science, Meena SQL, Priya SQL)
--     Why only 4 of the 6 unpaid students? Nisha and Deepa take no course, and JOIN keeps
--     only matches.
WITH unpaid AS (
    SELECT s.student_id, s.student_name
    FROM students s
    WHERE NOT EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
)
SELECT u.student_name, c.course_name
FROM unpaid u
JOIN enrollments e ON u.student_id = e.student_id
JOIN courses c ON e.course_id = c.course_id
ORDER BY u.student_name, c.course_name;

-- W8  The same with LEFT JOIN: all six unpaid students, course or not.
--     Expect: 6 rows (Deepa [null], Divya Data Science, Kiran Data Science, Meena SQL,
--             Nisha [null], Priya SQL)
WITH unpaid AS (
    SELECT s.student_id, s.student_name
    FROM students s
    WHERE NOT EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
)
SELECT u.student_name, c.course_name
FROM unpaid u
LEFT JOIN enrollments e ON u.student_id = e.student_id
LEFT JOIN courses c ON e.course_id = c.course_id
ORDER BY u.student_name, c.course_name;

-- W9  Untangling brackets inside brackets. Class 4's three-level query: students taught by Neha.
--     Expect: 3 rows (Rahul, Kiran, Divya)
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM enrollments
                     WHERE course_id IN (SELECT course_id FROM courses
                                         WHERE instructor = 'Neha'))
ORDER BY student_id;

-- W10 The same as two CTEs. Read it top to bottom: Neha's courses; students in those courses;
--     their names. Same 3 rows.
--     Expect: 3 rows (Rahul, Kiran, Divya)
WITH neha_courses AS (
    SELECT course_id FROM courses WHERE instructor = 'Neha'
),
neha_students AS (
    SELECT student_id FROM enrollments
    WHERE course_id IN (SELECT course_id FROM neha_courses)
)
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM neha_students)
ORDER BY student_id;

-- W11 FAILS ON PURPOSE: two CTEs need a COMMA between them.
--     Expect: ERROR: syntax error at or near "neha_students"
WITH neha_courses AS (
    SELECT course_id FROM courses WHERE instructor = 'Neha'
)
neha_students AS (
    SELECT student_id FROM enrollments WHERE course_id IN (SELECT course_id FROM neha_courses)
)
SELECT student_name FROM students WHERE student_id IN (SELECT student_id FROM neha_students);

-- W12 FAILS ON PURPOSE: WITH is written once, not once per CTE.
--     Expect: ERROR: syntax error at or near "WITH"
WITH neha_courses AS (
    SELECT course_id FROM courses WHERE instructor = 'Neha'
)
WITH neha_students AS (
    SELECT student_id FROM enrollments WHERE course_id IN (SELECT course_id FROM neha_courses)
)
SELECT student_name FROM students WHERE student_id IN (SELECT student_id FROM neha_students);

-- W13 FAILS ON PURPOSE: a semicolon after the CTE ends the statement before the main query.
--     Expect: ERROR: syntax error at or near ";"
WITH neha_courses AS (
    SELECT course_id FROM courses WHERE instructor = 'Neha'
);

-- W14 TRY IT YOURSELF: using a CTE called course_counts (each course with its number of
--     students, including 0), show the courses with fewer than 3 students.
--     Expect: 4 rows (Cloud Computing 0, Machine Learning 1, Java 2, Python 2)
WITH course_counts AS (
    SELECT c.course_name, COUNT(e.enrollment_id) AS students
    FROM courses c LEFT JOIN enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.course_name
)
SELECT course_name, students
FROM course_counts
WHERE students < 3
ORDER BY students, course_name;

-- W15 EXTRA CHALLENGE: the same CTE, then the average number of students per course.
--     Expect: 2.00   ((2 + 4 + 2 + 3 + 1 + 0) / 6)
WITH course_counts AS (
    SELECT c.course_name, COUNT(e.enrollment_id) AS students
    FROM courses c LEFT JOIN enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.course_name
)
SELECT ROUND(AVG(students), 2) AS average_students_per_course
FROM course_counts;


-- =====================================================================
--  PART F  |  Final question: both of today's topics in one query
-- =====================================================================

-- F1  A CTE called unpaid (students with no payment, using NOT EXISTS), then how many they
--     are and how much fee is outstanding in total.
--     Expect: 1 row (6, 89000)
WITH unpaid AS (
    SELECT s.student_name, s.fees
    FROM students s
    WHERE NOT EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
)
SELECT COUNT(*) AS unpaid_students, SUM(fees) AS fees_outstanding
FROM unpaid;


-- =====================================================================
--  PRACTICE SET  |  20 questions with answers
--  Cover the answer, write your own query, then compare. Row counts are
--  given so you can check yourself before looking.
--
--  Level 1 - EXISTS and NOT EXISTS
--    P1  Students with at least one payment, using EXISTS.                        (6 rows)
--    P2  Students with no enrollment, using NOT EXISTS.                           (2 rows)
--    P3  Courses that have at least one Completed enrollment.                      (2 rows)
--    P4  Customers who have placed an order of more than 400.                     (2 rows)
--    P5  Students with at least one VERIFIED payment.                             (4 rows)
--    P6  Students who have paid, but none of their payments is verified.          (2 rows)
--  Level 2 - a subquery as a table or a column
--    P7  Students whose fee is above the average fee of THEIR OWN city.           (4 rows)
--    P8  Each student with the number of courses they take (subquery in SELECT).  (12 rows)
--    P9  The average of the five city totals (subquery in FROM).                  (1 row)
--    P10 Students with more than one payment.                                     (1 row)
--  Level 3 - CTEs
--    P11 CTE city_totals; cities with a total BELOW 32000.                        (2 rows)
--    P12 CTE course_counts; courses with 0 students.                              (1 row)
--    P13 CTE paid_per_student; students who have paid their full fee.             (5 rows)
--    P14 Two CTEs: unpaid students, then how many per city ("Not given" if empty). (5 rows)
--    P15 CTE course_counts used twice: courses with more students than average.   (2 rows)
--    P16 "Students taught by Vikram" written as two CTEs.                          (4 rows)
--    P17 CTE payment_counts + LEFT JOIN: every student with their number of payments. (12 rows)
--    P18 CTE chennai_students; their average fee.                                 (1 row)
--  Level 4 - spot the mistake
--    P19 Two CTEs with no comma between them.
--    P20 Using a CTE's name in the next statement.
-- =====================================================================

-- P1  Expect: 6 rows (Anu, Rahul, John, Sara, Arjun, Ravi)
SELECT s.student_name FROM students s
WHERE EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
ORDER BY s.student_id;

-- P2  Expect: 2 rows (Nisha, Deepa)
SELECT s.student_name FROM students s
WHERE NOT EXISTS (SELECT 1 FROM enrollments e WHERE e.student_id = s.student_id)
ORDER BY s.student_id;

-- P3  Expect: 2 rows (SQL, Java)
SELECT c.course_name FROM courses c
WHERE EXISTS (SELECT 1 FROM enrollments e
              WHERE e.course_id = c.course_id AND e.status = 'Completed')
ORDER BY c.course_id;

-- P4  Expect: 2 rows (Anu with the Book 500, Ravi with the Bag 900)
SELECT c.customer_name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o
              WHERE o.customer_id = c.customer_id AND o.amount > 400)
ORDER BY c.customer_id;

-- P5  Expect: 4 rows (Anu, Rahul, John, Arjun)
SELECT s.student_name FROM students s
WHERE EXISTS (SELECT 1 FROM payments p
              WHERE p.student_id = s.student_id AND p.is_verified)
ORDER BY s.student_id;

-- P6  EXISTS ... AND NOT EXISTS ...: has a payment, but has no verified payment.
--     Expect: 2 rows (Sara, Ravi)
SELECT s.student_name FROM students s
WHERE EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
  AND NOT EXISTS (SELECT 1 FROM payments p
                  WHERE p.student_id = s.student_id AND p.is_verified)
ORDER BY s.student_id;

-- P7  The inner query looks at the outer row's city (x.city = s.city), so it is answered once
--     per student. City averages: Bangalore 16500, Chennai 12000, Hyderabad 15500,
--     Mumbai 11333.33, Delhi 20000. Arjun equals his city's average (he is alone), so > leaves
--     him out. Deepa's city is empty, so her inner query finds nobody.
--     Expect: 4 rows (Kiran 18000, Meena 14000, Divya 16000, Sara 12000)
SELECT s.student_name, s.city, s.fees
FROM students s
WHERE s.fees > (SELECT AVG(x.fees) FROM students x WHERE x.city = s.city)
ORDER BY s.city;

-- P8  Expect: 12 rows (Anu 2, Rahul 2, then 1 each, Nisha 0, Deepa 0)
SELECT s.student_name,
       (SELECT COUNT(*) FROM enrollments e WHERE e.student_id = s.student_id) AS courses
FROM students s ORDER BY s.student_id;

-- P9  Expect: 30800.00
SELECT ROUND(AVG(total_fees), 2) AS average_city_total
FROM (SELECT city, SUM(fees) AS total_fees
      FROM students WHERE city IS NOT NULL GROUP BY city) AS city_totals;

-- P10 Expect: 1 row (Anu)
SELECT s.student_name FROM students s
WHERE (SELECT COUNT(*) FROM payments p WHERE p.student_id = s.student_id) > 1;

-- P11 Expect: 2 rows (Hyderabad 31000, Delhi 20000)
WITH city_totals AS (
    SELECT city, SUM(fees) AS total_fees
    FROM students WHERE city IS NOT NULL GROUP BY city
)
SELECT city, total_fees FROM city_totals
WHERE total_fees < 32000
ORDER BY total_fees DESC;

-- P12 Expect: 1 row (Cloud Computing)
WITH course_counts AS (
    SELECT c.course_name, COUNT(e.enrollment_id) AS students
    FROM courses c LEFT JOIN enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.course_name
)
SELECT course_name FROM course_counts WHERE students = 0;

-- P13 Paid in full = paid is at least the fee. Rahul paid 7500.50 of 15000, so he is out.
--     Expect: 5 rows (Anu, John, Sara, Arjun, Ravi)
WITH paid_per_student AS (
    SELECT student_id, SUM(amount) AS paid
    FROM payments WHERE student_id IS NOT NULL GROUP BY student_id
)
SELECT s.student_name
FROM students s JOIN paid_per_student p ON s.student_id = p.student_id
WHERE p.paid >= s.fees
ORDER BY s.student_id;

-- P14 Expect: 5 rows (Bangalore 1, Chennai 1, Hyderabad 2, Mumbai 1, Not given 1)
WITH unpaid AS (
    SELECT s.student_id, s.city
    FROM students s
    WHERE NOT EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
),
per_city AS (
    SELECT COALESCE(city, 'Not given') AS city, COUNT(*) AS unpaid_students
    FROM unpaid
    GROUP BY COALESCE(city, 'Not given')
)
SELECT city, unpaid_students FROM per_city ORDER BY city;

-- P15 The average is 2.00 students per course.
--     Expect: 2 rows (SQL 4, Data Science 3)
WITH course_counts AS (
    SELECT c.course_name, COUNT(e.enrollment_id) AS students
    FROM courses c LEFT JOIN enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.course_name
)
SELECT course_name, students FROM course_counts
WHERE students > (SELECT AVG(students) FROM course_counts)
ORDER BY students DESC;

-- P16 Expect: 4 rows (Anu, Rahul, Priya, Meena). Vikram teaches SQL.
WITH vikram_courses AS (
    SELECT course_id FROM courses WHERE instructor = 'Vikram'
),
vikram_students AS (
    SELECT student_id FROM enrollments
    WHERE course_id IN (SELECT course_id FROM vikram_courses)
)
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM vikram_students)
ORDER BY student_id;

-- P17 Expect: 12 rows (Anu 2, Rahul 1, Priya 0, John 1, Sara 1, Kiran 0, Meena 0, Arjun 1,
--             Divya 0, Ravi 1, Nisha 0, Deepa 0)
WITH payment_counts AS (
    SELECT student_id, COUNT(*) AS payments
    FROM payments WHERE student_id IS NOT NULL GROUP BY student_id
)
SELECT s.student_name, COALESCE(pc.payments, 0) AS payments
FROM students s LEFT JOIN payment_counts pc ON s.student_id = pc.student_id
ORDER BY s.student_id;

-- P18 Expect: 12000.00   ((12000 + 10000 + 14000) / 3)
WITH chennai_students AS (
    SELECT student_name, fees FROM students WHERE city = 'Chennai'
)
SELECT ROUND(AVG(fees), 2) AS average_fee FROM chennai_students;

-- P19 FAILS ON PURPOSE: no comma between the two CTEs.
--     Expect: ERROR: syntax error at or near "b"
WITH a AS (SELECT 1 AS n)
b AS (SELECT 2 AS n)
SELECT * FROM a;

-- P20 FAILS ON PURPOSE: a CTE's name is gone after its statement ends. The first statement
--     works; the second does not.
--     Expect: 1 row (1), then ERROR: relation "a" does not exist
WITH a AS (SELECT 1 AS n) SELECT * FROM a;
SELECT * FROM a;
