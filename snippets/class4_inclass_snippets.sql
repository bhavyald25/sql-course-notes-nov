-- =====================================================================
--  SQL CLASS 4  |  Every query from the class, in order, with explanations
--  Topics: 10 practice questions on joins and set operations, then
--          subqueries: a query inside a query (WHERE, IN, NOT IN, EXISTS,
--          NOT EXISTS), and a 30-question practice set at the end
-- =====================================================================
--  HOW TO USE THIS FILE
--  1. Run setup/class4_setup.sql first.
--  2. Open this file in the Query Tool (folder icon -> Open File).
--  3. Highlight ONE statement, from its first word to the semicolon,
--     and press F5.
--  4. Compare your result with the "Expect" line written above it.
--
--  Do not run the whole file at once. Two statements FAIL ON PURPOSE,
--  and the first failure cancels everything else in the run.
--
--  TRY IT YOURSELF  = write the query before looking at the answer below it.
--  EXTRA CHALLENGE  = optional, a little harder.
--  [null]           = how pgAdmin shows an empty box.
-- =====================================================================


-- =====================================================================
--  PART 0  |  Check that the setup worked
-- =====================================================================

-- 0.1  Must show 12 | 8 | 4.
--      Notice the two brackets: each holds a small query inside the big one.
--      That is a subquery, the topic of this class.
--      Expect: 1 row (12, 8, 4)
SELECT COUNT(*)                          AS students,
       (SELECT COUNT(*) FROM payments)   AS payments,
       (SELECT COUNT(*) FROM customers)  AS customers
FROM students;


-- =====================================================================
--  PART R  |  Practice: ten questions on joins and set operations
--  Try each one yourself before looking at the answer. The numbers in
--  brackets are the question numbers in Notes 2.
-- =====================================================================

-- R1  (Notes 2, Q1) Each order with the customer's name. Orders with no customer left out.
--     Expect: 3 rows (101 Anu Book, 102 Anu Pen, 103 Ravi Bag)
--     Why INNER: it keeps only the matches, so order 104 (no customer) is dropped.
SELECT o.order_id, c.customer_name, o.item
FROM orders o JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_id;

-- R2  (Q2) Every customer with the items they ordered; customers with no order still appear.
--     Expect: 5 rows (Anu Book, Anu Pen, Ravi Bag, Sara [null], John [null])
--     Why LEFT: it protects the customer side, so Sara and John stay with empty boxes.
SELECT c.customer_name, o.item
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

-- R3  (Q3) Customers who have never ordered.
--     Expect: 2 rows (Sara, John)
--     Why: take R2 and keep only the rows with an empty order box. LEFT JOIN + IS NULL.
SELECT c.customer_name
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- R4  (Q5) Number of orders per customer, including customers with 0.
--     Expect: 4 rows (Anu 2, Ravi 1, Sara 0, John 0)
--     Why COUNT(o.order_id): it counts filled boxes only, so Sara and John get 0.
SELECT c.customer_name, COUNT(o.order_id) AS orders
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY c.customer_id;

-- R4b The trap: COUNT(*) counts rows, and Sara's row exists even with empty boxes.
--     Expect: 4 rows (Anu 2, Ravi 1, Sara 1, John 1)  <- wrong answer for the question
SELECT c.customer_name, COUNT(*) AS orders
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY c.customer_id;

-- R5  (Q10) Students not enrolled in any course. Same pattern as R3, different tables.
--     Expect: 2 rows (Nisha, Deepa)
SELECT s.student_name
FROM students s LEFT JOIN enrollments e ON s.student_id = e.student_id
WHERE e.enrollment_id IS NULL
ORDER BY s.student_id;

-- R6  (Q17) Students taking the SQL course, A to Z. Students and courses are not directly
--     linked; enrollments is the bridge, so two JOIN ... ON lines.
--     Expect: 4 rows (Anu, Meena, Priya, Rahul)
SELECT s.student_name
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN courses c ON e.course_id = c.course_id
WHERE c.course_name = 'SQL'
ORDER BY s.student_name;

-- R7  (Q12) Students per course, including courses with nobody.
--     Expect: 6 rows (Python 2, SQL 4, Java 2, Data Science 3, Machine Learning 1, Cloud Computing 0)
--     Why: courses on the left so Cloud Computing stays; COUNT(e.enrollment_id) gives it 0.
SELECT c.course_name, COUNT(e.enrollment_id) AS students
FROM courses c LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name
ORDER BY c.course_id;

-- R8  (Q26) Names on both attendance sheets.
--     Expect: 2 rows (Ravi, Sara)
SELECT student_name FROM morning_batch
INTERSECT
SELECT student_name FROM evening_batch
ORDER BY student_name;

-- R9  (Q27) Names on the evening sheet only. EXCEPT is "first minus second", so evening goes first.
--     Expect: 1 row (Meena)
SELECT student_name FROM evening_batch
EXCEPT
SELECT student_name FROM morning_batch;

-- R10 (Q14) Students who have not paid: name and fees.
--     Expect: 6 rows (Priya, Kiran, Meena, Divya, Nisha, Deepa)
--     Remember these six names. Later in this file the same six come back two more
--     ways, without any join.
SELECT s.student_name, s.fees
FROM students s LEFT JOIN payments p ON s.student_id = p.student_id
WHERE p.payment_id IS NULL
ORDER BY s.student_id;


-- =====================================================================
--  PART A  |  A query inside a query: "above average"
--  A subquery is a small question in brackets inside a big one. The
--  database answers the small one first, then uses that answer in the
--  big one. Read it from the inside out: find the brackets, answer them,
--  then read the rest. In this part the small question gives ONE value.
-- =====================================================================

-- A1  Step 1: the small question on its own.
--     Expect: 14083.33
SELECT ROUND(AVG(fees), 2) AS average_fee FROM students;

-- A2  Step 2: use the answer by hand. This works, but the number is copied by hand;
--     when a new student joins, the average changes and the number is wrong.
--     Expect: 6 rows (Arjun 20000, Kiran 18000, Divya 16000, Deepa, Priya, Rahul 15000)
SELECT student_name, fees FROM students
WHERE fees > 14083.33
ORDER BY fees DESC, student_name;

-- A3  Both steps in ONE query. The brackets hold the small question; it runs first and
--     gives 14083.33; the big question then reads as "fees > 14083.33".
--     Expect: the same 6 rows
SELECT student_name, fees FROM students
WHERE fees > (SELECT AVG(fees) FROM students)
ORDER BY fees DESC, student_name;

-- A4  Who pays the highest fee? The small question gives 20000; the big one keeps whoever pays it.
--     Expect: 1 row (Arjun 20000)
--     Note: ORDER BY fees DESC LIMIT 1 shows one row even if two people share the top fee.
--     This way shows everyone at the top.
SELECT student_name, fees FROM students
WHERE fees = (SELECT MAX(fees) FROM students);

-- A5  Who pays the lowest fee?
--     Expect: 1 row (John 10000)
SELECT student_name, fees FROM students
WHERE fees = (SELECT MIN(fees) FROM students);

-- A6  The small question can look up one person's value. Who pays the same fee as Priya?
--     Expect: 3 rows (Rahul, Priya, Deepa, all 15000). Priya is included because she pays it too.
SELECT student_name, fees FROM students
WHERE fees = (SELECT fees FROM students WHERE student_name = 'Priya')
ORDER BY student_id;

-- A6b The same, leaving Priya herself out.
--     Expect: 2 rows (Rahul, Deepa)
SELECT student_name, fees FROM students
WHERE fees = (SELECT fees FROM students WHERE student_name = 'Priya')
  AND student_name <> 'Priya'
ORDER BY student_id;

-- A7  FAILS ON PURPOSE. With =, > or <, the small question must give EXACTLY ONE value.
--     Chennai has three students, so the brackets give three fees, and the database
--     cannot know which one you mean.
--     Expect: ERROR: more than one row returned by a subquery used as an expression
--     Fix: make the inner query give one value (MAX, MIN, AVG), or use IN (Part B).
SELECT student_name FROM students
WHERE fees > (SELECT fees FROM students WHERE city = 'Chennai');

-- A8  Another table: payments above the average payment. First the average alone, then the query.
--     Expect: 10312.56, then 3 rows (payments 5, 6, 7)
SELECT ROUND(AVG(amount), 2) AS average_payment FROM payments;
SELECT payment_id, amount FROM payments
WHERE amount > (SELECT AVG(amount) FROM payments)
ORDER BY payment_id;

-- A9  TRY IT YOURSELF: students older than the average age (the average is 22.75).
--     Expect: 7 rows (Nisha, Rahul, Ravi 23; Deepa, Sara 24; Kiran 25; Arjun 26)
SELECT student_name, age FROM students
WHERE age > (SELECT AVG(age) FROM students)
ORDER BY age, student_name;

-- A10 EXTRA CHALLENGE: courses longer than the average course (the average is 3.83 months).
--     Expect: 3 rows (Java 4, Machine Learning 5, Data Science 6)
SELECT course_name, duration_months FROM courses
WHERE duration_months > (SELECT AVG(duration_months) FROM courses)
ORDER BY duration_months;


-- =====================================================================
--  PART B  |  IN and NOT IN with a list from a query
--  In class 2 the list was typed by hand: city IN ('Chennai', 'Mumbai').
--  Now the list comes from a small question. "Students whose ID is in the
--  list of IDs that appear in payments" = students who have paid.
-- =====================================================================

-- B1  Step 1: the list on its own. Two things to notice: 1 appears twice (Anu's two
--     receipts), and the last value is an empty box (payment 8). Both matter below.
--     Expect: 8 rows (1, 1, 2, 4, 5, 8, 10, [null])
SELECT student_id FROM payments ORDER BY student_id;

-- B2  Students whose ID is in that list = students who have paid.
--     Expect: 6 rows (Anu, Rahul, John, Sara, Arjun, Ravi)
--     Why 6, not 8? IN asks "is the ID in the list?", a yes/no question, so Anu is kept once
--     even though she is in the list twice. The empty box matches nobody and is ignored.
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM payments)
ORDER BY student_id;

-- B2b Compare with the join: one row per receipt, so Anu appears twice.
--     Expect: 7 rows (Anu, Anu, Rahul, John, Sara, Arjun, Ravi)
SELECT s.student_name
FROM students s JOIN payments p ON s.student_id = p.student_id
ORDER BY s.student_id;

-- B3  Students taking course 102 (SQL). The inner list = student IDs enrolled in 102.
--     Expect: 4 rows (Anu, Rahul, Priya, Meena). Same as R6, without any join.
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM enrollments WHERE course_id = 102)
ORDER BY student_id;

-- B3b The same by course NAME: a list inside a list. Read from the inside out:
--     which course ID is called SQL? 102. Which students are enrolled in 102? 1, 2, 3, 7.
--     Show those students' names.
--     Expect: the same 4 rows
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM enrollments
                     WHERE course_id IN (SELECT course_id FROM courses
                                         WHERE course_name = 'SQL'))
ORDER BY student_id;

-- B4  NOT IN: students who are NOT in the enrollments list.
--     Expect: 2 rows (Nisha, Deepa). Same as R5, without a join.
SELECT student_name FROM students
WHERE student_id NOT IN (SELECT student_id FROM enrollments)
ORDER BY student_id;

-- B5  THE TRAP. The same idea with payments: students who have NOT paid. We know the
--     answer is six names (R10). But this gives nobody, not even Deepa.
--     Expect: 0 rows
--     Why: NOT IN asks "is 3 different from EVERY value in the list?". Different from 1? Yes.
--     From 2? Yes. From the empty box? Unknown; nobody knows what is in it. Yes + yes + unknown
--     = unknown, and WHERE drops anything that is not a definite yes. Every student fails.
SELECT student_name FROM students
WHERE student_id NOT IN (SELECT student_id FROM payments);

-- B5b The same thing with plain numbers.
--     Expect: 1 row (true, [null])
SELECT 3 NOT IN (1, 2) AS normal_list, 3 NOT IN (1, NULL) AS list_with_empty_box;

-- B5c THE FIX: leave the empty box out of the list.
--     Expect: 6 rows (Priya, Kiran, Meena, Divya, Nisha, Deepa)
--     Rule: before writing NOT IN, ask "can this list contain an empty box?". If yes, add
--     WHERE ... IS NOT NULL inside the brackets, or use NOT EXISTS (Part D).
SELECT student_name FROM students
WHERE student_id NOT IN (SELECT student_id FROM payments WHERE student_id IS NOT NULL)
ORDER BY student_id;

-- B6  Courses nobody takes. Safe here: enrollments.course_id has no empty boxes.
--     Expect: 1 row (Cloud Computing)
SELECT course_name FROM courses
WHERE course_id NOT IN (SELECT course_id FROM enrollments);

-- B7  TRY IT YOURSELF: customers who have ordered.
--     Expect: 2 rows (Anu, Ravi)
SELECT customer_name FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders)
ORDER BY customer_id;

-- B7b TRY IT YOURSELF: customers who have never ordered, with NOT IN. Most people write this first.
--     Expect: 0 rows!  Order 104 has an empty customer_id: the same trap as B5.
SELECT customer_name FROM customers
WHERE customer_id NOT IN (SELECT customer_id FROM orders);

-- B7c Fixed.
--     Expect: 2 rows (Sara, John)
SELECT customer_name FROM customers
WHERE customer_id NOT IN (SELECT customer_id FROM orders WHERE customer_id IS NOT NULL)
ORDER BY customer_id;

-- B8  EXTRA CHALLENGE: students taught by Neha. Three levels deep; read from the inside out.
--     Expect: 3 rows (Rahul, Kiran, Divya). Neha teaches 104, Data Science.
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM enrollments
                     WHERE course_id IN (SELECT course_id FROM courses
                                         WHERE instructor = 'Neha'))
ORDER BY student_id;


-- =====================================================================
--  PART D  |  EXISTS and NOT EXISTS
--  EXISTS asks one question: "is there at least one matching row?"
--  Picture: go down the register one name at a time; for each name, flip
--  through the receipt book: is there ANY receipt with this ID? Yes -> keep
--  the name. No -> skip it.
--  Two things to notice in the query: the inner query mentions the outer
--  table (p.student_id = s.student_id), which is the link, "a payment for
--  THIS student"; and SELECT 1 inside, because we only want to know whether
--  any row comes back, not what is in it.
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
--     NOT EXISTS is the safe way to write "who has not", whether or not the other table has empty boxes.
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
--     Expect: 12 rows (everyone)
--     If EXISTS returns everyone, check the link.
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
--  PART E  |  Two more places a subquery can go: as a table, as a column
-- =====================================================================

-- E1  A query result used as a TABLE. The inner query makes a five-row table of city totals,
--     nicknamed city_totals; the outer query filters it like any table.
--     Expect: 3 rows (Chennai 36000, Mumbai 34000, Bangalore 33000)
SELECT city, total_fees
FROM (SELECT city, SUM(fees) AS total_fees
      FROM students WHERE city IS NOT NULL
      GROUP BY city) AS city_totals
WHERE total_fees > 32000
ORDER BY total_fees DESC;

-- E2  Something HAVING cannot do: the average of the five city totals. First make the
--     totals, then average them. Two steps, one query.
--     Expect: 30800.00   ((36000 + 34000 + 33000 + 31000 + 20000) / 5)
SELECT ROUND(AVG(total_fees), 2) AS average_city_total
FROM (SELECT city, SUM(fees) AS total_fees
      FROM students WHERE city IS NOT NULL
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
--     Expect: 12 rows (Anu 2, Rahul 1, Priya 0, John 1, Sara 1, Kiran 0, ...)
SELECT s.student_name,
       (SELECT COUNT(*) FROM payments p WHERE p.student_id = s.student_id) AS payments
FROM students s
ORDER BY s.student_id;


-- =====================================================================
--  PART F  |  Final questions
-- =====================================================================

-- F1  Names of the students who have not paid, using NOT EXISTS, A to Z.
--     Expect: 6 rows (Deepa, Divya, Kiran, Meena, Nisha, Priya)
SELECT s.student_name
FROM students s
WHERE NOT EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
ORDER BY s.student_name;

-- F2  EXTRA CHALLENGE: students who pay more than Anu.
--     Expect: 7 rows (Meena 14000; Deepa, Priya, Rahul 15000; Divya 16000; Kiran 18000; Arjun 20000)
SELECT student_name, fees FROM students
WHERE fees > (SELECT fees FROM students WHERE student_name = 'Anu')
ORDER BY fees, student_name;


-- =====================================================================
--  PRACTICE SET  |  30 questions with answers
--  Cover the answer, write your own query, then compare. Row counts are
--  given so you can check yourself before looking.
--
--  Level 1 - one-value subqueries
--    P1  Students who pay LESS than the average fee.                            (6 rows)
--    P2  The student with the highest fee.                                      (1 row)
--    P3  The youngest student, using MIN.                                       (1 row)
--    P4  Students older than Anu.                                               (9 rows)
--    P5  Payments smaller than the average payment.                             (5 rows)
--    P6  Who made the largest payment? Name and amount.                         (1 row)
--    P7  The second-highest fee, and who pays it.                               (1 row)
--    P8  Courses shorter than the average course.                               (3 rows)
--  Level 2 - IN and NOT IN
--    P9  Students who have paid, using IN.                                      (6 rows)
--    P10 Students enrolled in Python (course 101).                              (2 rows)
--    P11 Students taught by Vikram.                                             (4 rows)
--    P12 Courses taken by Anu.                                                  (2 rows)
--    P13 Courses NOT taken by Anu.                                              (4 rows)
--    P14 Students who have not paid, using NOT IN. Remember the empty box.      (6 rows)
--    P15 Customers who have never ordered, using NOT IN. Remember order 104.    (2 rows)
--    P16 Students who live in the same city as Kiran.                           (2 rows)
--    P17 Students who live in a city with more than two students.               (6 rows)
--    P18 Students with at least one Active enrollment, using IN.                (8 rows)
--  Level 3 - EXISTS and NOT EXISTS
--    P19 Students with at least one payment, using EXISTS.                      (6 rows)
--    P20 Students with no enrollment, using NOT EXISTS.                         (2 rows)
--    P21 Courses with at least one Completed enrollment.                        (2 rows)
--    P22 Customers who have placed an order of more than 400.                   (2 rows)
--    P23 Students with at least one VERIFIED payment.                           (4 rows)
--    P24 Students who have paid, but none of their payments is verified.        (2 rows)
--  Level 4 - harder
--    P25 Students whose fee is above the average fee of THEIR OWN city.         (4 rows)
--    P26 Each student with the number of courses they take (subquery in SELECT). (12 rows)
--    P27 The average of the five city totals (subquery in FROM).                (1 row)
--    P28 Students with more than one payment.                                   (1 row)
--    P29 "Students who have not paid" three ways: see D8.                       (6 rows each)
--    P30 Spot the mistake in each of the three statements at the end.
-- =====================================================================

-- P1  Expect: 6 rows (John 10000; Nisha, Ravi 11000; Anu, Sara 12000; Meena 14000)
SELECT student_name, fees FROM students
WHERE fees < (SELECT AVG(fees) FROM students) ORDER BY fees, student_name;

-- P2  Expect: 1 row (Arjun 20000)
SELECT student_name, fees FROM students WHERE fees = (SELECT MAX(fees) FROM students);

-- P3  Expect: 1 row (Priya 20)
SELECT student_name, age FROM students WHERE age = (SELECT MIN(age) FROM students);

-- P4  Expect: 9 rows (Divya, John 22; Nisha, Rahul, Ravi 23; Deepa, Sara 24; Kiran 25; Arjun 26)
SELECT student_name, age FROM students
WHERE age > (SELECT age FROM students WHERE student_name = 'Anu') ORDER BY age, student_name;

-- P5  Expect: 5 rows (payments 1, 2, 3, 4, 8). The average is 10312.56.
SELECT payment_id, amount FROM payments
WHERE amount < (SELECT AVG(amount) FROM payments) ORDER BY payment_id;

-- P6  A join to get the name, plus a subquery to find the largest amount.
--     Expect: 1 row (Arjun 20000.00)
SELECT s.student_name, p.amount
FROM payments p JOIN students s ON p.student_id = s.student_id
WHERE p.amount = (SELECT MAX(amount) FROM payments);

-- P7  Inside out: the highest fee is 20000; the highest fee below 20000 is 18000; who pays 18000?
--     Expect: 1 row (Kiran 18000)
SELECT student_name, fees FROM students
WHERE fees = (SELECT MAX(fees) FROM students
              WHERE fees < (SELECT MAX(fees) FROM students));

-- P8  Expect: 3 rows (Python 3, SQL 2, Cloud Computing 3). The average is 3.83.
SELECT course_name, duration_months FROM courses
WHERE duration_months < (SELECT AVG(duration_months) FROM courses) ORDER BY course_id;

-- P9  Expect: 6 rows (Anu, Rahul, John, Sara, Arjun, Ravi)
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM payments) ORDER BY student_id;

-- P10 Expect: 2 rows (Anu, Sara)
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM enrollments WHERE course_id = 101) ORDER BY student_id;

-- P11 A list inside a list. Vikram teaches SQL (102).
--     Expect: 4 rows (Anu, Rahul, Priya, Meena)
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM enrollments
                     WHERE course_id IN (SELECT course_id FROM courses WHERE instructor = 'Vikram'))
ORDER BY student_id;

-- P12 Expect: 2 rows (Python, SQL)
SELECT course_name FROM courses
WHERE course_id IN (SELECT course_id FROM enrollments WHERE student_id = 1) ORDER BY course_id;

-- P13 Expect: 4 rows (Java, Data Science, Machine Learning, Cloud Computing)
SELECT course_name FROM courses
WHERE course_id NOT IN (SELECT course_id FROM enrollments WHERE student_id = 1) ORDER BY course_id;

-- P14 Expect: 6 rows (Priya, Kiran, Meena, Divya, Nisha, Deepa). Without IS NOT NULL: 0 rows.
SELECT student_name FROM students
WHERE student_id NOT IN (SELECT student_id FROM payments WHERE student_id IS NOT NULL)
ORDER BY student_id;

-- P15 Expect: 2 rows (Sara, John). Without IS NOT NULL: 0 rows.
SELECT customer_name FROM customers
WHERE customer_id NOT IN (SELECT customer_id FROM orders WHERE customer_id IS NOT NULL)
ORDER BY customer_id;

-- P16 Expect: 2 rows (Rahul, Kiran in Bangalore). Add AND student_name <> 'Kiran' to get Rahul only.
SELECT student_name, city FROM students
WHERE city = (SELECT city FROM students WHERE student_name = 'Kiran') ORDER BY student_id;

-- P17 GROUP BY ... HAVING inside the brackets gives the list of big cities.
--     Expect: 6 rows (Anu, John, Meena in Chennai; Sara, Ravi, Nisha in Mumbai)
SELECT student_name, city FROM students
WHERE city IN (SELECT city FROM students GROUP BY city HAVING COUNT(*) > 2)
ORDER BY city, student_id;

-- P18 Expect: 8 rows (Anu, Rahul, Priya, Sara, Kiran, Arjun, Divya, Ravi).
--     John and Meena have only Completed enrollments.
SELECT student_name FROM students
WHERE student_id IN (SELECT student_id FROM enrollments WHERE status = 'Active') ORDER BY student_id;

-- P19 Expect: 6 rows (Anu, Rahul, John, Sara, Arjun, Ravi)
SELECT s.student_name FROM students s
WHERE EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id) ORDER BY s.student_id;

-- P20 Expect: 2 rows (Nisha, Deepa)
SELECT s.student_name FROM students s
WHERE NOT EXISTS (SELECT 1 FROM enrollments e WHERE e.student_id = s.student_id) ORDER BY s.student_id;

-- P21 Expect: 2 rows (SQL, Java)
SELECT c.course_name FROM courses c
WHERE EXISTS (SELECT 1 FROM enrollments e WHERE e.course_id = c.course_id AND e.status = 'Completed')
ORDER BY c.course_id;

-- P22 Expect: 2 rows (Anu with the Book 500, Ravi with the Bag 900)
SELECT c.customer_name FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id AND o.amount > 400)
ORDER BY c.customer_id;

-- P23 Expect: 4 rows (Anu, Rahul, John, Arjun)
SELECT s.student_name FROM students s
WHERE EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id AND p.is_verified)
ORDER BY s.student_id;

-- P24 EXISTS ... AND NOT EXISTS ...: has a payment, but has no verified payment.
--     Expect: 2 rows (Sara, Ravi)
SELECT s.student_name FROM students s
WHERE EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
  AND NOT EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id AND p.is_verified)
ORDER BY s.student_id;

-- P25 The inner query looks at the outer row's city (x.city = s.city), so it is answered
--     once per student. City averages: Bangalore 16500, Chennai 12000, Hyderabad 15500,
--     Mumbai 11333.33, Delhi 20000. Arjun equals his city's average (he is alone), so > leaves
--     him out. Deepa's city is empty, so her inner query finds nobody.
--     Expect: 4 rows (Kiran 18000, Meena 14000, Divya 16000, Sara 12000)
SELECT s.student_name, s.city, s.fees
FROM students s
WHERE s.fees > (SELECT AVG(x.fees) FROM students x WHERE x.city = s.city)
ORDER BY s.city;

-- P26 Expect: 12 rows (Anu 2, Rahul 2, then 1 each, Nisha 0, Deepa 0)
SELECT s.student_name,
       (SELECT COUNT(*) FROM enrollments e WHERE e.student_id = s.student_id) AS courses
FROM students s ORDER BY s.student_id;

-- P27 Expect: 30800.00
SELECT ROUND(AVG(total_fees), 2) AS average_city_total
FROM (SELECT city, SUM(fees) AS total_fees
      FROM students WHERE city IS NOT NULL GROUP BY city) AS city_totals;

-- P28 A COUNT subquery used in a comparison.
--     Expect: 1 row (Anu)
SELECT s.student_name FROM students s
WHERE (SELECT COUNT(*) FROM payments p WHERE p.student_id = s.student_id) > 1;

-- P29 See D8 above: the three queries each give the same 6 names.

-- P30 Spot the mistake. Run each one and see.
--     (a) FAILS ON PURPOSE: the brackets return three fees, but > needs exactly one.
--         Expect: ERROR: more than one row returned by a subquery used as an expression
--         Fix: use MAX/MIN/AVG inside, or use IN.
SELECT student_name FROM students WHERE fees > (SELECT fees FROM students WHERE city = 'Chennai');

--     (b) The list contains payment 8's empty box, so NOT IN can never say a definite yes.
--         Expect: 0 rows.  Fix: add WHERE student_id IS NOT NULL inside, or use NOT EXISTS.
SELECT student_name FROM students WHERE student_id NOT IN (SELECT student_id FROM payments);

--     (c) The link to the outer row is missing, so EXISTS is true for every student.
--         Expect: 12.  Fix: add WHERE p.student_id = s.student_id inside.
SELECT COUNT(*) FROM students s WHERE EXISTS (SELECT 1 FROM payments p);
