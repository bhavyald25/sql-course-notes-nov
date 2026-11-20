-- =====================================================================
--  SQL CLASS 6  |  Every query from the class, in order, with explanations
--  Topics: window functions, part 1: what a window function is (OVER),
--          ROW_NUMBER, RANK, DENSE_RANK, using a rank with a CTE,
--          and a 20-question practice set at the end
-- =====================================================================
--  HOW TO USE THIS FILE
--  1. Run setup/class6_setup.sql first.
--  2. Open this file in the Query Tool (folder icon -> Open File).
--  3. Highlight ONE statement, from its first word to the semicolon,
--     and press F5. A WITH query is ONE statement: highlight from WITH
--     down to the final semicolon.
--  4. Compare your result with the "Expect" line written above it.
--
--  Do not run the whole file at once. One statement FAILS ON PURPOSE,
--  and the first failure cancels everything else in the run.
--
--  TRY IT YOURSELF  = write the query before looking at the answer below it.
--  EXTRA CHALLENGE  = optional, a little harder.
--  [null]           = how pgAdmin shows an empty box.
-- =====================================================================


-- =====================================================================
--  PART 0  |  Check that the setup worked
-- =====================================================================

-- 0.1  Must show 12 | 20000 | 8.
--      12 students, but only 8 different fee amounts: several students pay the same.
--      Those ties are what today is about.
--      Expect: 1 row (12, 20000, 8)
SELECT (SELECT COUNT(*) FROM students)              AS students,
       (SELECT MAX(fees) FROM students)              AS highest_fee,
       (SELECT COUNT(DISTINCT fees) FROM students)   AS different_fees;


-- =====================================================================
--  PART R  |  Three quick questions from class 5
-- =====================================================================

-- R1  Students who have not paid, with NOT EXISTS.
--     Expect: 6 rows (Priya, Kiran, Meena, Divya, Nisha, Deepa)
SELECT s.student_name
FROM students s
WHERE NOT EXISTS (SELECT 1 FROM payments p WHERE p.student_id = s.student_id)
ORDER BY s.student_id;

-- R2  A CTE: cities with a fee total above 32000.
--     Expect: 3 rows (Chennai 36000, Mumbai 34000, Bangalore 33000)
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

-- R3  A CTE used twice: courses with more students than the average course.
--     Expect: 2 rows (SQL 4, Data Science 3)
WITH course_counts AS (
    SELECT c.course_name, COUNT(e.enrollment_id) AS students
    FROM courses c LEFT JOIN enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.course_name
)
SELECT course_name, students
FROM course_counts
WHERE students > (SELECT AVG(students) FROM course_counts)
ORDER BY students DESC;


-- =====================================================================
--  PART A  |  What a window function is
--  GROUP BY squashes many rows into one summary row. A window function
--  keeps EVERY row and adds a column that is calculated by looking at
--  OTHER rows. OVER ( ) is the "window": the set of rows the function
--  may look at. Empty brackets = the whole table.
-- =====================================================================

-- A1  The GROUP BY way: the highest fee. 12 rows become 1.
--     Expect: 1 row (20000)
SELECT MAX(fees) AS highest_fee FROM students;

-- A2  The window way: MAX(fees) OVER ( ). Every student keeps their row, and a new column
--     shows the highest fee in the whole table.
--     Expect: 12 rows; the highest_fee column shows 20000 on every row
SELECT student_name, fees, MAX(fees) OVER () AS highest_fee
FROM students
ORDER BY student_id;

-- A3  Now the extra column is useful: how far is each student below the highest fee?
--     Expect: 12 rows (Anu 8000, Rahul 5000, Priya 5000, John 10000, Sara 8000, Kiran 2000,
--             Meena 6000, Arjun 0, Divya 4000, Ravi 9000, Nisha 9000, Deepa 5000)
SELECT student_name, fees, MAX(fees) OVER () - fees AS gap_to_highest
FROM students
ORDER BY student_id;

-- A4  Several window columns at once. Compare with class 5, where the same numbers needed
--     a subquery in the SELECT list.
--     Expect: 12 rows; total_students 12 and average_fee 14083 on every row
SELECT student_name, fees,
       COUNT(*) OVER ()           AS total_students,
       ROUND(AVG(fees) OVER ())   AS average_fee
FROM students
ORDER BY student_id;

-- A5  ORDER BY inside the brackets puts the window in an order. ROW_NUMBER() then gives each
--     row its position in that order: 1, 2, 3, ...
--     Expect: 12 rows, numbered 1 to 12 from the highest fee (Arjun) to the lowest (John)
SELECT student_name, fees,
       ROW_NUMBER() OVER (ORDER BY fees DESC) AS position
FROM students;


-- =====================================================================
--  PART B  |  ROW_NUMBER: 1, 2, 3, ... with no ties, ever
-- =====================================================================

-- B1  The tie problem. Rahul, Priya and Deepa all pay 15000. ROW_NUMBER must give them three
--     different numbers (4, 5, 6), and nothing says who gets which. The database chooses.
--     Run it twice; the order of those three MAY change. Same for Anu/Sara and Ravi/Nisha.
--     Expect: 12 rows; 4, 5, 6 go to Rahul, Priya and Deepa in some order
SELECT student_name, fees,
       ROW_NUMBER() OVER (ORDER BY fees DESC) AS position
FROM students;

-- B2  The fix: a tie-breaker. ", student_id" says: when fees are equal, the smaller ID first.
--     Now the numbering is always the same.
--     Expect: 12 rows (1 Arjun, 2 Kiran, 3 Divya, 4 Rahul, 5 Priya, 6 Deepa, 7 Meena,
--             8 Anu, 9 Sara, 10 Ravi, 11 Nisha, 12 John)
SELECT student_name, fees,
       ROW_NUMBER() OVER (ORDER BY fees DESC, student_id) AS position
FROM students;

-- B3  Two different ORDER BYs. The one inside OVER decides the NUMBERS. The one at the end
--     decides how the rows are LISTED. They are independent.
--     Expect: 12 rows listed A to Z, each with the same position as in B2
--             (Anu 8, Arjun 1, Deepa 6, Divya 3, John 12, Kiran 2, Meena 7, Nisha 11,
--              Priya 5, Rahul 4, Ravi 10, Sara 9)
SELECT student_name, fees,
       ROW_NUMBER() OVER (ORDER BY fees DESC, student_id) AS position
FROM students
ORDER BY student_name;

-- B4  Youngest first.
--     Expect: 12 rows (1 Priya 20, 2 Anu 21, 3 Meena 21, 4 John 22, 5 Divya 22, 6 Rahul 23,
--             7 Ravi 23, 8 Nisha 23, 9 Sara 24, 10 Deepa 24, 11 Kiran 25, 12 Arjun 26)
SELECT student_name, age,
       ROW_NUMBER() OVER (ORDER BY age, student_id) AS position
FROM students;

-- B5  Another table: payments, largest first.
--     Expect: 8 rows (1: payment 6 20000, 2: payment 5 12000, 3: payment 7 11000,
--             4: payment 4 10000, 5: payment 8 10000, 6: payment 3 7500.50,
--             7: payment 1 6000, 8: payment 2 6000)
SELECT payment_id, amount,
       ROW_NUMBER() OVER (ORDER BY amount DESC, payment_id) AS position
FROM payments;

-- B6  TRY IT YOURSELF: number the courses by duration, longest first; tie-break on course_id.
--     Expect: 6 rows (1 Data Science 6, 2 Machine Learning 5, 3 Java 4, 4 Python 3,
--             5 Cloud Computing 3, 6 SQL 2)
SELECT course_name, duration_months,
       ROW_NUMBER() OVER (ORDER BY duration_months DESC, course_id) AS position
FROM courses;

-- B7  EXTRA CHALLENGE: number the students alphabetically.
--     Expect: 12 rows (1 Anu, 2 Arjun, 3 Deepa, 4 Divya, 5 John, 6 Kiran, 7 Meena, 8 Nisha,
--             9 Priya, 10 Rahul, 11 Ravi, 12 Sara)
SELECT student_name,
       ROW_NUMBER() OVER (ORDER BY student_name) AS position
FROM students;


-- =====================================================================
--  PART C  |  RANK and DENSE_RANK: what to do with ties
--  ROW_NUMBER: ties get different numbers anyway (1, 2, 3, 4).
--  RANK:       ties share a number, and the next number is SKIPPED (1, 2, 2, 4),
--              like exam ranks: joint second, nobody is third.
--  DENSE_RANK: ties share a number, nothing is skipped (1, 2, 2, 3),
--              like fee LEVELS: the 3rd level is the 3rd different amount.
-- =====================================================================

-- C1  All three side by side, on fees. Look at the three students who pay 15000.
--     Expect: 12 rows
--       Arjun 20000: 1 1 1 | Kiran 18000: 2 2 2 | Divya 16000: 3 3 3
--       Rahul 15000: 4 4 4 | Priya 15000: 5 4 4 | Deepa 15000: 6 4 4
--       Meena 14000: 7 7 5 | Anu 12000: 8 8 6 | Sara 12000: 9 8 6
--       Ravi 11000: 10 10 7 | Nisha 11000: 11 10 7 | John 10000: 12 12 8
SELECT student_name, fees,
       ROW_NUMBER() OVER (ORDER BY fees DESC, student_id) AS row_num,
       RANK()       OVER (ORDER BY fees DESC)             AS rnk,
       DENSE_RANK() OVER (ORDER BY fees DESC)             AS dense
FROM students
ORDER BY fees DESC, student_id;

-- C2  The highest DENSE_RANK equals the number of different fee amounts.
--     Expect: 1 row (8, 8)
SELECT MAX(dense) AS fee_levels, COUNT(DISTINCT fees) AS different_fees
FROM (SELECT fees, DENSE_RANK() OVER (ORDER BY fees DESC) AS dense FROM students) AS ranked;

-- C3  Payments, largest first. Two payments of 10000 and two of 6000.
--     Expect: 8 rows
--       payment 6 20000: 1 1 1 | payment 5 12000: 2 2 2 | payment 7 11000: 3 3 3
--       payment 4 10000: 4 4 4 | payment 8 10000: 5 4 4 | payment 3 7500.50: 6 6 5
--       payment 1 6000: 7 7 6 | payment 2 6000: 8 7 6
SELECT payment_id, amount,
       ROW_NUMBER() OVER (ORDER BY amount DESC, payment_id) AS row_num,
       RANK()       OVER (ORDER BY amount DESC)             AS rnk,
       DENSE_RANK() OVER (ORDER BY amount DESC)             AS dense
FROM payments
ORDER BY amount DESC, payment_id;

-- C4  Courses by duration, longest first. Python and Cloud Computing are both 3 months.
--     Expect: 6 rows (Data Science 6: 1 1 | Machine Learning 5: 2 2 | Java 4: 3 3 |
--             Python 3: 4 4 | Cloud Computing 3: 4 4 | SQL 2: 6 5)
SELECT course_name, duration_months,
       RANK()       OVER (ORDER BY duration_months DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY duration_months DESC) AS dense
FROM courses
ORDER BY duration_months DESC, course_id;

-- C5  TRY IT YOURSELF: rank the students by age, youngest = 1, with RANK and DENSE_RANK.
--     Expect: 12 rows (Priya 20: 1 1 | Anu 21: 2 2 | Meena 21: 2 2 | John 22: 4 3 |
--             Divya 22: 4 3 | Rahul 23: 6 4 | Ravi 23: 6 4 | Nisha 23: 6 4 | Sara 24: 9 5 |
--             Deepa 24: 9 5 | Kiran 25: 11 6 | Arjun 26: 12 7)
SELECT student_name, age,
       RANK()       OVER (ORDER BY age) AS rnk,
       DENSE_RANK() OVER (ORDER BY age) AS dense
FROM students
ORDER BY age, student_id;

-- C6  EXTRA CHALLENGE: rank the cities by total fees, using the city_totals CTE from class 5.
--     Expect: 5 rows (1 Chennai 36000, 2 Mumbai 34000, 3 Bangalore 33000,
--             4 Hyderabad 31000, 5 Delhi 20000)
WITH city_totals AS (
    SELECT city, SUM(fees) AS total_fees
    FROM students
    WHERE city IS NOT NULL
    GROUP BY city
)
SELECT city, total_fees,
       RANK() OVER (ORDER BY total_fees DESC) AS rnk
FROM city_totals
ORDER BY rnk;


-- =====================================================================
--  PART D  |  Using the rank: "top 3", "second highest", "who is at level 5"
--  A window function is calculated AFTER WHERE has already chosen the
--  rows. So you cannot filter on a rank in the same query: the rank does
--  not exist yet when WHERE runs. Rank first in a CTE, filter second.
-- =====================================================================

-- D1  FAILS ON PURPOSE: a window function inside WHERE.
--     Expect: ERROR: window functions are not allowed in WHERE
SELECT student_name, fees
FROM students
WHERE RANK() OVER (ORDER BY fees DESC) <= 3;

-- D2  The fix: rank in a CTE, filter in the main query. The top 3 by fees.
--     Expect: 3 rows (Arjun 20000 1, Kiran 18000 2, Divya 16000 3)
WITH ranked AS (
    SELECT student_name, fees,
           RANK() OVER (ORDER BY fees DESC) AS rnk
    FROM students
)
SELECT student_name, fees, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY rnk;

-- D3  "Top 5" with RANK gives SIX rows, because three students share rank 4 and nobody is
--     rank 5. Ties come along.
--     Expect: 6 rows (Arjun 1, Kiran 2, Divya 3, Rahul 4, Priya 4, Deepa 4)
WITH ranked AS (
    SELECT student_name, fees,
           RANK() OVER (ORDER BY fees DESC) AS rnk
    FROM students
)
SELECT student_name, fees, rnk
FROM ranked
WHERE rnk <= 5
ORDER BY rnk, student_name;

-- D4  "Top 5" with ROW_NUMBER gives exactly five. The tie is cut by the tie-breaker: Deepa
--     (student_id 12) is left out, not because she pays less, but because her ID is larger.
--     Expect: 5 rows (Arjun 1, Kiran 2, Divya 3, Rahul 4, Priya 5)
WITH numbered AS (
    SELECT student_name, fees,
           ROW_NUMBER() OVER (ORDER BY fees DESC, student_id) AS position
    FROM students
)
SELECT student_name, fees, position
FROM numbered
WHERE position <= 5
ORDER BY position;

-- D5  "Top 5 fee LEVELS" with DENSE_RANK gives seven students: the five highest amounts
--     (20000, 18000, 16000, 15000, 14000) and everyone who pays them.
--     Expect: 7 rows (Arjun 1, Kiran 2, Divya 3, Rahul 4, Priya 4, Deepa 4, Meena 5)
WITH ranked AS (
    SELECT student_name, fees,
           DENSE_RANK() OVER (ORDER BY fees DESC) AS level
    FROM students
)
SELECT student_name, fees, level
FROM ranked
WHERE level <= 5
ORDER BY level, student_name;

-- D6  The second-highest fee, three ways. All give Kiran 18000.
--     Expect: 1 row each (Kiran 18000)
-- D6a Class 2: sort, skip one, take one.
SELECT student_name, fees FROM students ORDER BY fees DESC LIMIT 1 OFFSET 1;

-- D6b Class 4: the highest fee among those below the highest.
SELECT student_name, fees FROM students
WHERE fees = (SELECT MAX(fees) FROM students WHERE fees < (SELECT MAX(fees) FROM students));

-- D6c Today: fee level 2. This one also works for "third", "fourth", ..., and shows
--     everyone at that level, not just one person.
WITH ranked AS (
    SELECT student_name, fees,
           DENSE_RANK() OVER (ORDER BY fees DESC) AS level
    FROM students
)
SELECT student_name, fees FROM ranked WHERE level = 2;

-- D7  Why DENSE_RANK and not RANK for "the Nth highest"? Ask for the 5th. With DENSE_RANK,
--     level 5 is 14000: Meena.
--     Expect: 1 row (Meena 14000)
WITH ranked AS (
    SELECT student_name, fees,
           DENSE_RANK() OVER (ORDER BY fees DESC) AS level
    FROM students
)
SELECT student_name, fees FROM ranked WHERE level = 5;

-- D8  With RANK, nobody is rank 5: three students share rank 4, so the next rank is 7.
--     Expect: 0 rows
WITH ranked AS (
    SELECT student_name, fees,
           RANK() OVER (ORDER BY fees DESC) AS rnk
    FROM students
)
SELECT student_name, fees FROM ranked WHERE rnk = 5;

-- D9  Class 5 + class 6: rank the courses by number of students. The CTE builds the counts,
--     the window function ranks them.
--     Expect: 6 rows (SQL 4: 1 1 | Data Science 3: 2 2 | Java 2: 3 3 | Python 2: 3 3 |
--             Machine Learning 1: 5 4 | Cloud Computing 0: 6 5)
WITH course_counts AS (
    SELECT c.course_name, COUNT(e.enrollment_id) AS students
    FROM courses c LEFT JOIN enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.course_name
)
SELECT course_name, students,
       RANK()       OVER (ORDER BY students DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY students DESC) AS dense
FROM course_counts
ORDER BY rnk, course_name;

-- D10 TRY IT YOURSELF: the three oldest students, using a CTE and RANK. Careful: Sara and
--     Deepa are both 24.
--     Expect: 4 rows (Arjun 26 1, Kiran 25 2, Sara 24 3, Deepa 24 3)
WITH ranked AS (
    SELECT student_name, age,
           RANK() OVER (ORDER BY age DESC) AS rnk
    FROM students
)
SELECT student_name, age, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY rnk, student_name;

-- D11 EXTRA CHALLENGE: the two largest payments, with the student's name.
--     Expect: 2 rows (1 Arjun 20000, 2 Sara 12000)
WITH numbered AS (
    SELECT s.student_name, p.amount,
           ROW_NUMBER() OVER (ORDER BY p.amount DESC, p.payment_id) AS position
    FROM payments p JOIN students s ON p.student_id = s.student_id
)
SELECT position, student_name, amount
FROM numbered
WHERE position <= 2
ORDER BY position;


-- =====================================================================
--  PART E  |  A look at tomorrow: PARTITION BY = a separate ranking per group
-- =====================================================================

-- E1  Rank within each city. PARTITION BY city restarts the ranking for every city.
--     Deepa's empty city forms a group of its own.
--     Expect: 12 rows (Bangalore: Kiran 1, Rahul 2 | Chennai: Meena 1, Anu 2, John 3 |
--             Delhi: Arjun 1 | Hyderabad: Divya 1, Priya 2 | Mumbai: Sara 1, Ravi 2, Nisha 2 |
--             [null]: Deepa 1)
SELECT student_name, city, fees,
       RANK() OVER (PARTITION BY city ORDER BY fees DESC) AS rank_in_city
FROM students
ORDER BY city, rank_in_city, student_name;

-- E2  The highest-paying student in each city: rank per city, then keep rank 1.
--     Expect: 6 rows (Bangalore Kiran, Chennai Meena, Delhi Arjun, Hyderabad Divya,
--             Mumbai Sara, [null] Deepa)
WITH ranked AS (
    SELECT student_name, city, fees,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY fees DESC, student_id) AS position
    FROM students
)
SELECT city, student_name, fees
FROM ranked
WHERE position = 1
ORDER BY city;


-- =====================================================================
--  PART F  |  Final questions
-- =====================================================================

-- F1  Using a CTE and DENSE_RANK, the students at fee level 4.
--     Expect: 3 rows (Deepa, Priya, Rahul, all 15000)
WITH ranked AS (
    SELECT student_name, fees,
           DENSE_RANK() OVER (ORDER BY fees DESC) AS level
    FROM students
)
SELECT student_name, fees
FROM ranked
WHERE level = 4
ORDER BY student_name;

-- F2  EXTRA CHALLENGE: the two youngest students, using ROW_NUMBER with a tie-breaker.
--     Expect: 2 rows (1 Priya 20, 2 Anu 21)
WITH numbered AS (
    SELECT student_name, age,
           ROW_NUMBER() OVER (ORDER BY age, student_id) AS position
    FROM students
)
SELECT position, student_name, age
FROM numbered
WHERE position <= 2
ORDER BY position;


-- =====================================================================
--  PRACTICE SET  |  20 questions with answers
--  Cover the answer, write your own query, then compare. Row counts are
--  given so you can check yourself before looking.
--
--  Level 1 - ROW_NUMBER
--    P1  Number the students by fees, highest first, tie-break on student_id.      (12 rows)
--    P2  Number the students alphabetically by name.                               (12 rows)
--    P3  Number the payments by date, earliest first.                              (8 rows)
--    P4  Number the courses alphabetically by name.                                (6 rows)
--    P5  Which student is 7th by fees (highest first, tie-break on student_id)?     (1 row)
--  Level 2 - RANK and DENSE_RANK
--    P6  RANK the students by age, oldest first.                                   (12 rows)
--    P7  DENSE_RANK the students by age, oldest first.                             (12 rows)
--    P8  RANK and DENSE_RANK the payments by amount, largest first.                (8 rows)
--    P9  How many different fee levels are there? Use MAX of a DENSE_RANK.          (1 row)
--    P10 RANK the courses by duration, longest first.                              (6 rows)
--  Level 3 - using the rank with a CTE
--    P11 The top 3 students by fees, with RANK.                                    (3 rows)
--    P12 The top 4 students by fees, with RANK. Why more than 4 rows?               (6 rows)
--    P13 The students at fee level 2.                                              (1 row)
--    P14 The students at fee level 6.                                              (2 rows)
--    P15 The students with RANK = 5 by fees. Why this many?                         (0 rows)
--    P16 The two largest payments, with the student's name.                        (2 rows)
--    P17 Rank the cities by total fees (CTE city_totals).                          (5 rows)
--    P18 DENSE_RANK the courses by number of students (CTE course_counts).          (6 rows)
--  Level 4 - spot the mistake
--    P19 WHERE RANK() OVER (ORDER BY fees DESC) <= 3   -- what error, and why?
--    P20 ROW_NUMBER() OVER (ORDER BY fees DESC) with no tie-breaker: why can the
--        numbering of Rahul, Priya and Deepa change between two runs?
-- =====================================================================

-- P1  Expect: 12 rows (1 Arjun ... 12 John), the same as B2
SELECT student_name, fees,
       ROW_NUMBER() OVER (ORDER BY fees DESC, student_id) AS position
FROM students;

-- P2  Expect: 12 rows (1 Anu, 2 Arjun, 3 Deepa, 4 Divya, 5 John, 6 Kiran, 7 Meena, 8 Nisha,
--             9 Priya, 10 Rahul, 11 Ravi, 12 Sara)
SELECT student_name,
       ROW_NUMBER() OVER (ORDER BY student_name) AS position
FROM students;

-- P3  Expect: 8 rows (1 payment 1 2026-01-10, 2 payment 3 2026-01-12, 3 payment 2 2026-02-10,
--             4 payment 4 2026-02-15, 5 payment 5 2026-03-01, 6 payment 6 2026-04-12,
--             7 payment 7 2026-05-15, 8 payment 8 2026-11-10)
SELECT payment_id, paid_on, amount,
       ROW_NUMBER() OVER (ORDER BY paid_on, payment_id) AS position
FROM payments;

-- P4  Expect: 6 rows (1 Cloud Computing, 2 Data Science, 3 Java, 4 Machine Learning,
--             5 Python, 6 SQL)
SELECT course_name,
       ROW_NUMBER() OVER (ORDER BY course_name) AS position
FROM courses;

-- P5  Expect: 1 row (Meena 14000)
WITH numbered AS (
    SELECT student_name, fees,
           ROW_NUMBER() OVER (ORDER BY fees DESC, student_id) AS position
    FROM students
)
SELECT student_name, fees FROM numbered WHERE position = 7;

-- P6  Expect: 12 rows (Arjun 26: 1 | Kiran 25: 2 | Sara 24: 3 | Deepa 24: 3 | Rahul 23: 5 |
--             Ravi 23: 5 | Nisha 23: 5 | Divya 22: 8 | John 22: 8 | Anu 21: 10 |
--             Meena 21: 10 | Priya 20: 12)
SELECT student_name, age,
       RANK() OVER (ORDER BY age DESC) AS rnk
FROM students
ORDER BY rnk, student_id;

-- P7  Expect: 12 rows (Arjun 26: 1 | Kiran 25: 2 | Sara 24: 3 | Deepa 24: 3 | Rahul 23: 4 |
--             Ravi 23: 4 | Nisha 23: 4 | Divya 22: 5 | John 22: 5 | Anu 21: 6 |
--             Meena 21: 6 | Priya 20: 7)
SELECT student_name, age,
       DENSE_RANK() OVER (ORDER BY age DESC) AS dense
FROM students
ORDER BY dense, student_id;

-- P8  Expect: 8 rows, the same as C3
SELECT payment_id, amount,
       RANK()       OVER (ORDER BY amount DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY amount DESC) AS dense
FROM payments
ORDER BY amount DESC, payment_id;

-- P9  Expect: 1 row (8)
WITH ranked AS (
    SELECT DENSE_RANK() OVER (ORDER BY fees DESC) AS level FROM students
)
SELECT MAX(level) AS fee_levels FROM ranked;

-- P10 Expect: 6 rows (Data Science 6: 1 | Machine Learning 5: 2 | Java 4: 3 | Python 3: 4 |
--             Cloud Computing 3: 4 | SQL 2: 6)
SELECT course_name, duration_months,
       RANK() OVER (ORDER BY duration_months DESC) AS rnk
FROM courses
ORDER BY rnk, course_id;

-- P11 Expect: 3 rows (Arjun 1, Kiran 2, Divya 3)
WITH ranked AS (
    SELECT student_name, fees, RANK() OVER (ORDER BY fees DESC) AS rnk FROM students
)
SELECT student_name, fees, rnk FROM ranked WHERE rnk <= 3 ORDER BY rnk;

-- P12 Expect: 6 rows (Arjun 1, Kiran 2, Divya 3, Rahul 4, Priya 4, Deepa 4).
--     Three students share rank 4; RANK brings all of them.
WITH ranked AS (
    SELECT student_name, fees, RANK() OVER (ORDER BY fees DESC) AS rnk FROM students
)
SELECT student_name, fees, rnk FROM ranked WHERE rnk <= 4 ORDER BY rnk, student_name;

-- P13 Expect: 1 row (Kiran 18000)
WITH ranked AS (
    SELECT student_name, fees, DENSE_RANK() OVER (ORDER BY fees DESC) AS level FROM students
)
SELECT student_name, fees FROM ranked WHERE level = 2;

-- P14 Expect: 2 rows (Anu 12000, Sara 12000)
WITH ranked AS (
    SELECT student_name, fees, DENSE_RANK() OVER (ORDER BY fees DESC) AS level FROM students
)
SELECT student_name, fees FROM ranked WHERE level = 6 ORDER BY student_name;

-- P15 Expect: 0 rows. Ranks go 1, 2, 3, 4, 4, 4, 7, ...: rank 5 is skipped.
WITH ranked AS (
    SELECT student_name, fees, RANK() OVER (ORDER BY fees DESC) AS rnk FROM students
)
SELECT student_name, fees FROM ranked WHERE rnk = 5;

-- P16 Expect: 2 rows (1 Arjun 20000, 2 Sara 12000)
WITH numbered AS (
    SELECT s.student_name, p.amount,
           ROW_NUMBER() OVER (ORDER BY p.amount DESC, p.payment_id) AS position
    FROM payments p JOIN students s ON p.student_id = s.student_id
)
SELECT position, student_name, amount FROM numbered WHERE position <= 2 ORDER BY position;

-- P17 Expect: 5 rows (1 Chennai 36000, 2 Mumbai 34000, 3 Bangalore 33000, 4 Hyderabad 31000,
--             5 Delhi 20000)
WITH city_totals AS (
    SELECT city, SUM(fees) AS total_fees
    FROM students WHERE city IS NOT NULL GROUP BY city
)
SELECT city, total_fees, RANK() OVER (ORDER BY total_fees DESC) AS rnk
FROM city_totals ORDER BY rnk;

-- P18 Expect: 6 rows (SQL 4: 1 | Data Science 3: 2 | Java 2: 3 | Python 2: 3 |
--             Machine Learning 1: 4 | Cloud Computing 0: 5)
WITH course_counts AS (
    SELECT c.course_name, COUNT(e.enrollment_id) AS students
    FROM courses c LEFT JOIN enrollments e ON c.course_id = e.course_id
    GROUP BY c.course_id, c.course_name
)
SELECT course_name, students, DENSE_RANK() OVER (ORDER BY students DESC) AS dense
FROM course_counts ORDER BY dense, course_name;

-- P19 FAILS ON PURPOSE. WHERE runs before the window function is calculated, so the rank
--     does not exist yet. Rank in a CTE first, then filter.
--     Expect: ERROR: window functions are not allowed in WHERE
SELECT student_name, fees FROM students WHERE RANK() OVER (ORDER BY fees DESC) <= 3;

-- P20 Without a tie-breaker, nothing says which of the three 15000 students gets 4, 5 or 6;
--     the database picks, and may pick differently next time. Add ", student_id" after
--     fees DESC inside the brackets.
--     Expect: 12 rows; 4, 5, 6 go to Rahul, Priya and Deepa in some order
SELECT student_name, fees, ROW_NUMBER() OVER (ORDER BY fees DESC) AS position FROM students;
