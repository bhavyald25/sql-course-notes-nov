-- =====================================================================
--  SQL CLASS 3  |  Every query from the class, in order, with explanations
--  Topics: joins on two tiny tables, designing tables for joins,
--          CROSS JOIN, UNION, UNION ALL, INTERSECT, EXCEPT
-- =====================================================================
--  HOW TO USE THIS FILE
--  1. Run setup/class3_setup.sql first.
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
--
--  THE SHOP TABLES used in Part A:
--    customers: 1 Anu, 2 Ravi, 3 Sara, 4 John
--    orders:    101 Anu Book 500 | 102 Anu Pen 50 | 103 Ravi Bag 900 | 104 (no customer) Cap 200
--  Three facts to remember: Anu has two orders. Sara and John have none.
--  Order 104 has no customer (a cash sale; nobody wrote down who bought it).
-- =====================================================================


-- =====================================================================
--  PART 0  |  Check that the setup worked
-- =====================================================================

-- 0.1  Must show 6 rows, with [null] cells in the Sara, John and Cap rows.
--      If you do not see them, run class3_setup.sql again.
--      Expect: 6 rows
SELECT c.customer_name, o.order_id, o.item
FROM customers c FULL JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;


-- =====================================================================
--  PART A  |  The four joins on two tiny tables
--  A join lays two tables side by side, matching rows by ID. The matching
--  rule is written after ON. Every join below is a choice of which lines
--  of "the picture" (A2) to keep.
-- =====================================================================

-- A1  The two tables on their own. Run separately.
--     Expect: 4 customers; 4 orders
SELECT * FROM customers;
SELECT * FROM orders ORDER BY order_id;

-- A2  THE PICTURE: every customer next to every order, matched on customer_id. Both IDs
--     are shown so you can see the matching. Filled on both sides = a match. Empty on the
--     right = a customer with no order. Empty on the left = an order with no customer.
--     Expect: 6 rows = 3 matches (Anu, Anu, Ravi) + 2 lonely customers (Sara, John)
--             + 1 lonely order (Cap)
SELECT c.customer_id AS c_id, c.customer_name, o.customer_id AS o_id, o.order_id, o.item, o.amount
FROM customers c FULL JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

-- A3  INNER JOIN keeps only the matches (both sides filled).
--     Expect: 3 rows (Anu Book, Anu Pen, Ravi Bag). No [null] anywhere.
--     Why: Sara and John have no order; the Cap has no customer. All dropped.
--          Anu appears twice because two orders carry her number.
SELECT c.customer_name, o.order_id, o.item, o.amount
FROM customers c INNER JOIN orders o ON c.customer_id = o.customer_id
ORDER BY o.order_id;

-- A4  LEFT JOIN keeps every row of the LEFT table (customers, written first), matched or not.
--     Expect: 5 rows = the 3 matches + Sara and John with empty order boxes.
--     Why: LEFT protects only the left side, so the Cap (right side) is still dropped.
SELECT c.customer_name, o.order_id, o.item, o.amount
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

-- A5  THE PATTERN TO REMEMBER: LEFT JOIN + IS NULL = "who has NOT ...".
--     Keep every customer, then keep only the lines whose order box is empty.
--     Expect: 2 rows (Sara, John)
--     Why test order_id? Every real order has one, so an empty order_id can only mean "no match".
SELECT c.customer_name
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- A6  RIGHT JOIN keeps every row of the RIGHT table (orders), matched or not.
--     Expect: 4 rows = the 3 matches + the Cap with an empty customer name.
--     Why: Sara and John are on the left, and RIGHT protects only the right.
--     Tip: most people write LEFT JOIN with the tables swapped instead. Same answer.
SELECT c.customer_name, o.order_id, o.item, o.amount
FROM customers c RIGHT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY o.order_id;

-- A7  FULL JOIN keeps everything from both tables. It is the picture from A2.
--     Expect: 6 rows (3 matches, Sara, John, Cap)
SELECT c.customer_name, o.order_id, o.item, o.amount
FROM customers c FULL JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

--     Four joins, four different counts:  INNER 3 | LEFT 5 | RIGHT 4 | FULL 6
--     If you remember these numbers and why they differ, you understand joins.

-- A8  TRY IT YOURSELF: total amount ordered per customer; customers with no order show 0.
--     Hint: LEFT JOIN so Sara and John stay, SUM the amounts, COALESCE turns their empty sum into 0.
--     Expect: 4 rows (Anu 550, Ravi 900, Sara 0, John 0)
SELECT c.customer_name, COALESCE(SUM(o.amount), 0) AS total_ordered
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY c.customer_id;

-- A9  EXTRA CHALLENGE: the same, but only customers whose total is above 600.
--     HAVING filters the piles after grouping.
--     Expect: 1 row (Ravi 900)
SELECT c.customer_name, COALESCE(SUM(o.amount), 0) AS total_ordered
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.amount) > 600
ORDER BY c.customer_id;


-- =====================================================================
--  PART D  |  Designing two tables so they join well
--  The link between two tables must be an ID, never a name. Names get
--  misspelt, repeat and change. The orders_bad table shows what goes
--  wrong when the customer's NAME is stored on each order instead.
-- =====================================================================

-- D1  The badly designed table. Order 202 was typed as 'anu ' (small a, space at the end).
--     Expect: 3 rows (201 Anu Book, 202 anu  Pen, 203 Ravi Bag)
SELECT * FROM orders_bad ORDER BY order_id;

-- D2  Joining on names: 'anu ' does not equal 'Anu', so the Pen order silently disappears.
--     No error, no warning.
--     Expect: 2 rows (Anu Book, Ravi Bag)
SELECT c.customer_name, b.item
FROM customers c INNER JOIN orders_bad b ON c.customer_name = b.customer_name
ORDER BY b.order_id;

-- D3  It can be patched (TRIM removes the space, LOWER removes the capital), but every
--     query on this table, forever, must remember the patch. With IDs there is nothing to patch.
--     Expect: 3 rows (Anu Book, Anu Pen, Ravi Bag)
SELECT c.customer_name, b.item
FROM customers c INNER JOIN orders_bad b ON LOWER(TRIM(b.customer_name)) = LOWER(c.customer_name)
ORDER BY b.order_id;

-- D4  FAILS ON PURPOSE. Good design protects itself: orders.customer_id REFERENCES customers,
--     and there is no customer 9, so the database refuses the order.
--     Expect: ERROR: ... violates foreign key constraint "orders_customer_id_fkey"
--             Key (customer_id)=(9) is not present in table "customers".
INSERT INTO orders VALUES (105, 9, 'Hat', 100);

-- D5  Bad design does not protect itself. An order for "Nobody" is accepted without a word.
--     Expect: INSERT 0 1, then 4 rows (the new one is 204 Nobody Hat)
INSERT INTO orders_bad VALUES (204, 'Nobody', 'Hat');
SELECT * FROM orders_bad ORDER BY order_id;

-- D6  Clean up.
--     Expect (Messages tab): DELETE 1
DELETE FROM orders_bad WHERE order_id = 204;


-- =====================================================================
--  PART B  |  CROSS JOIN: every row with every row
--  No matching, no ON. The number of rows is simply rows x rows.
--  Picture: 3 shirts and 2 trousers. How many outfits? Every shirt with
--  every trouser: 3 x 2 = 6.
-- =====================================================================

-- B1  The two tiny tables. Run separately.
--     Expect: 3 shirts (White, Blue, Black); 2 trousers (Jeans, Chinos)
SELECT * FROM shirts;
SELECT * FROM trousers;

-- B2  Every shirt with every trouser.
--     Expect: 6 rows (each shirt appears with both trousers)
SELECT s.shirt, t.trouser
FROM shirts s CROSS JOIN trousers t
ORDER BY s.shirt, t.trouser;

-- B3  Rows multiply: 3 x 2.
--     Expect: 6
SELECT COUNT(*) AS outfits FROM shirts CROSS JOIN trousers;

-- B4  THE ACCIDENT: a comma between two tables, with no matching rule, is a cross join.
--     Expect: 16 rows of nonsense (4 customers x 4 orders). Anu "bought" a Bag; Sara "bought"
--             four things. Nothing was matched because nothing said what should match.
--     If a result ever has far more rows than you expected, look for this.
SELECT c.customer_name, o.item
FROM customers c, orders o
ORDER BY c.customer_id, o.order_id;

-- B5  Add the matching rule in WHERE and it becomes an INNER JOIN again.
--     Expect: 3 rows (Anu Book, Anu Pen, Ravi Bag)
--     Tip: write JOIN ... ON instead. Then the matching rule cannot be forgotten.
SELECT c.customer_name, o.item
FROM customers c, orders o
WHERE c.customer_id = o.customer_id
ORDER BY o.order_id;

-- B6  A real use: every possible combination, to fill in or check against.
--     Every student x every course, for Anu and Rahul only so it fits on screen.
--     Expect: 12 rows (Anu with all 6 courses, then Rahul with all 6)
SELECT s.student_name, c.course_name
FROM students s CROSS JOIN courses c
WHERE s.student_id IN (1, 2)
ORDER BY s.student_id, c.course_id;

-- B7  TRY IT YOURSELF: how many rows would ALL students x ALL courses give? Guess, then check.
--     Expect: 72   (12 x 6)
SELECT COUNT(*) AS combinations FROM students CROSS JOIN courses;

-- B8  EXTRA CHALLENGE: three tables.
--     Expect: 576   (12 x 6 x 8). Cross joins grow fast.
SELECT COUNT(*) FROM students CROSS JOIN courses CROSS JOIN payments;


-- =====================================================================
--  PART C  |  Set operations: stacking two lists
--  A join puts tables SIDE BY SIDE (wider). A set operation puts one list
--  UNDER another (taller). Picture: two attendance sheets, one under the other.
--  Four rules: same number of columns; same kind of data in each column;
--  headings come from the first SELECT; ORDER BY once, at the very end.
--    morning_batch: Anu, Ravi, Sara, John, Priya      evening_batch: Ravi, Sara, Meena
-- =====================================================================

-- C1  The two lists on their own. Run separately. Ravi and Sara are on both.
--     Expect: 5 names; 3 names
SELECT * FROM morning_batch;
SELECT * FROM evening_batch;

-- C2  UNION ALL: list 2 under list 1, keep everything.
--     Expect: 8 rows (5 + 3). Ravi and Sara appear twice, once from each sheet.
SELECT student_name FROM morning_batch
UNION ALL
SELECT student_name FROM evening_batch;

-- C3  UNION: list 2 under list 1, repeats removed. "Everyone who attends at all."
--     Expect: 6 rows (Anu, John, Meena, Priya, Ravi, Sara)
SELECT student_name FROM morning_batch
UNION
SELECT student_name FROM evening_batch
ORDER BY student_name;

-- C4  INTERSECT: only names that are in BOTH lists.
--     Expect: 2 rows (Ravi, Sara)
SELECT student_name FROM morning_batch
INTERSECT
SELECT student_name FROM evening_batch
ORDER BY student_name;

-- C5  EXCEPT: in the first list but NOT in the second. "First minus second."
--     Expect: 3 rows (Anu, John, Priya)
SELECT student_name FROM morning_batch
EXCEPT
SELECT student_name FROM evening_batch
ORDER BY student_name;

-- C6  EXCEPT the other way round. Order matters.
--     Expect: 1 row (Meena)
SELECT student_name FROM evening_batch
EXCEPT
SELECT student_name FROM morning_batch;

--     Five operations, five different counts:  UNION ALL 8 | UNION 6 | INTERSECT 2 | EXCEPT 3 | EXCEPT reversed 1

-- C7  FAILS ON PURPOSE: the two lists must have the same number of columns.
--     Expect: ERROR: each UNION query must have the same number of columns
SELECT student_name FROM morning_batch
UNION
SELECT student_name, 1 FROM evening_batch;

-- C8  The heading comes from the FIRST SELECT. ORDER BY at the end must use that heading.
--     Expect: 6 rows, under the heading "person"
SELECT student_name AS person FROM morning_batch
UNION
SELECT student_name FROM evening_batch
ORDER BY person;

-- C9  TRY IT YOURSELF: who is in the evening batch only?
--     Expect: 1 row (Meena)
SELECT student_name FROM evening_batch
EXCEPT
SELECT student_name FROM morning_batch;

-- C10 EXTRA CHALLENGE: one list of every customer name and every student name, each once.
--     Expect: 12 rows (4 + 12 = 16, but all four customer names are also student names).
--     "ORDER BY 1" means "sort by the first column".
SELECT customer_name FROM customers
UNION
SELECT student_name FROM students
ORDER BY 1;


-- =====================================================================
--  PART R  |  Set operations on the institute tables
-- =====================================================================

-- R1  Students who have NOT paid, with EXCEPT: all student IDs, minus the IDs in payments.
--     We compare IDs (not names) because payments has IDs. Same kind of data in both lists.
--     Expect: 6 rows (3, 6, 7, 9, 11, 12 = Priya, Kiran, Meena, Divya, Nisha, Deepa)
SELECT student_id FROM students
EXCEPT
SELECT student_id FROM payments
ORDER BY student_id;

-- R2  The same question with LEFT JOIN + IS NULL. Two roads, one answer. The join can
--     also show the names and any other column; EXCEPT is shorter.
--     Expect: the same 6 students, with names
SELECT s.student_id, s.student_name
FROM students s LEFT JOIN payments p ON s.student_id = p.student_id
WHERE p.payment_id IS NULL
ORDER BY s.student_id;

-- R3  Courses nobody takes.
--     Expect: 1 row (106 = Cloud Computing)
SELECT course_id FROM courses
EXCEPT
SELECT course_id FROM enrollments;

-- R4  Students who live in Chennai AND have paid.
--     Expect: 2 rows (1 Anu, 4 John). Meena lives in Chennai but has not paid.
SELECT student_id FROM students WHERE city = 'Chennai'
INTERSECT
SELECT student_id FROM payments
ORDER BY student_id;

-- R5  UNION ALL to build one list of people, with a label saying where each came from.
--     'student' and 'instructor' are just words in quotes; they become a column.
--     Expect: 18 rows (6 instructors, then 12 students)
SELECT student_name AS person, 'student' AS role FROM students
UNION ALL
SELECT instructor, 'instructor' FROM courses
ORDER BY role, person;


-- =====================================================================
--  PART P  |  Putting it together: which courses have Anu and Rahul NOT taken?
--  Step 1: every possible student-course pair (CROSS JOIN).
--  Step 2: the pairs that already exist (enrollments).
--  Step 3: all pairs EXCEPT existing pairs.
-- =====================================================================

-- P1  All possible pairs for Anu (1) and Rahul (2).
--     Expect: 12 rows (1 with 101..106, then 2 with 101..106)
SELECT s.student_id, c.course_id
FROM students s CROSS JOIN courses c
WHERE s.student_id IN (1, 2)
ORDER BY s.student_id, c.course_id;

-- P2  The pairs that already exist.
--     Expect: 4 rows (1-101, 1-102, 2-102, 2-104)
SELECT student_id, course_id
FROM enrollments
WHERE student_id IN (1, 2)
ORDER BY student_id, course_id;

-- P3  All pairs EXCEPT existing pairs = the courses they have not taken.
--     EXCEPT compares the whole pair: (1, 102) is crossed out because Anu took SQL;
--     (2, 101) stays because Rahul never took Python.
--     Expect: 8 rows (1: 103, 104, 105, 106; 2: 101, 103, 105, 106)
SELECT s.student_id, c.course_id
FROM students s CROSS JOIN courses c
WHERE s.student_id IN (1, 2)
EXCEPT
SELECT student_id, course_id
FROM enrollments
ORDER BY student_id, course_id;

-- P4  The same with names. The second SELECT is the three-table join from class 2,
--     used to turn enrollment IDs into names.
--     Expect: 8 rows (Anu: Cloud Computing, Data Science, Java, Machine Learning;
--             Rahul: Cloud Computing, Java, Machine Learning, Python)
SELECT s.student_name, c.course_name
FROM students s CROSS JOIN courses c
WHERE s.student_id IN (1, 2)
EXCEPT
SELECT s.student_name, c.course_name
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN courses c ON e.course_id = c.course_id
ORDER BY student_name, course_name;


-- =====================================================================
--  PART E  |  Final questions
-- =====================================================================

-- E1  Who is in the morning batch but not in the evening batch?
--     Expect: 3 rows (Anu, John, Priya)
SELECT student_name FROM morning_batch
EXCEPT
SELECT student_name FROM evening_batch
ORDER BY student_name;

-- E2  EXTRA CHALLENGE: course IDs that Anu (student 1) has not taken.
--     Expect: 4 rows (103, 104, 105, 106)
SELECT course_id FROM courses
EXCEPT
SELECT course_id FROM enrollments WHERE student_id = 1
ORDER BY course_id;
