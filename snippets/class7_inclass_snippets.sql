-- =====================================================================
--  SQL CLASS 7  |  Every query from the class, in order, with explanations
--  Topics: window functions, part 2: PARTITION BY (a separate window per
--          group), ORDER BY inside OVER for running totals, LAG (look at
--          the previous row), and an 18-question practice set
-- =====================================================================
--  HOW TO USE THIS FILE
--  1. Run setup/class7_setup.sql first.
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
--
--  Deepa's admission_date is the day the setup was run, so any gap
--  calculated from it changes with the date.
-- =====================================================================


-- =====================================================================
--  PART 0  |  Check that the setup worked
-- =====================================================================

-- 0.1  Must show 12 | 5 | 82500.50.
--      Expect: 1 row (12, 5, 82500.50)
SELECT (SELECT COUNT(*) FROM students)              AS students,
       (SELECT COUNT(DISTINCT city) FROM students)   AS cities,
       (SELECT SUM(amount) FROM payments)            AS total_paid;


-- =====================================================================
--  PART R  |  Three quick questions from class 6
-- =====================================================================

-- R1  Number the students by fees, highest first, with a tie-breaker.
--     Expect: 12 rows (1 Arjun, 2 Kiran, 3 Divya, 4 Rahul, 5 Priya, 6 Deepa, 7 Meena,
--             8 Anu, 9 Sara, 10 Ravi, 11 Nisha, 12 John)
SELECT student_name, fees,
       ROW_NUMBER() OVER (ORDER BY fees DESC, student_id) AS position
FROM students;

-- R2  RANK and DENSE_RANK on fees. Look at Meena: 7 and 5.
--     Expect: 12 rows (Arjun 1 1 | Kiran 2 2 | Divya 3 3 | Rahul, Priya, Deepa 4 4 |
--             Meena 7 5 | Anu, Sara 8 6 | Ravi, Nisha 10 7 | John 12 8)
SELECT student_name, fees,
       RANK()       OVER (ORDER BY fees DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY fees DESC) AS dense
FROM students
ORDER BY fees DESC, student_id;

-- R3  The top 3 by fees: rank in a CTE, filter after.
--     Expect: 3 rows (Arjun 1, Kiran 2, Divya 3)
WITH ranked AS (
    SELECT student_name, fees, RANK() OVER (ORDER BY fees DESC) AS rnk
    FROM students
)
SELECT student_name, fees, rnk FROM ranked WHERE rnk <= 3 ORDER BY rnk;


-- =====================================================================
--  PART P  |  PARTITION BY: a separate window for each group
--  Yesterday every window was the whole table. PARTITION BY city splits
--  the window into one piece per city. The function then looks only at
--  the rows of the SAME city as the current row. Every row is still kept.
--  GROUP BY city would give 5 rows; PARTITION BY city keeps all 12.
-- =====================================================================

-- P0  Start from what you know (class 6): empty brackets = the whole table,
--     so every row shows the same total.
--     Expect: 12 rows (everyone_total 169000 on every row)
SELECT student_name, city, fees,
       SUM(fees) OVER () AS everyone_total
FROM students
ORDER BY city, fees DESC, student_id;

-- P1  Upgrade: write PARTITION BY city inside the brackets. Nothing else changes.
--     Each student next to the total fees of THEIR city.
--     Expect: 12 rows (Bangalore rows 33000, Chennai rows 36000, Delhi 20000,
--             Hyderabad rows 31000, Mumbai rows 34000, Deepa [null] city 15000)
SELECT student_name, city, fees,
       SUM(fees) OVER (PARTITION BY city) AS city_total
FROM students
ORDER BY city, fees DESC, student_id;

-- P2  Compare: GROUP BY gives one row per city and loses the students.
--     Expect: 6 rows (Bangalore 33000, Chennai 36000, Delhi 20000, Hyderabad 31000,
--             Mumbai 34000, [null] 15000)
SELECT city, SUM(fees) AS city_total
FROM students
GROUP BY city
ORDER BY city;

-- P3  Several partitioned columns at once: how many in my city, the city average, and the
--     whole-class average for comparison.
--     Expect: 12 rows (Bangalore: 2, 16500 | Chennai: 3, 12000 | Delhi: 1, 20000 |
--             Hyderabad: 2, 15500 | Mumbai: 3, 11333.33 | [null]: 1, 15000; class_avg 14083.33 everywhere)
SELECT student_name, city, fees,
       COUNT(*) OVER (PARTITION BY city)                AS students_in_city,
       ROUND(AVG(fees) OVER (PARTITION BY city), 2)     AS city_avg,
       ROUND(AVG(fees) OVER (), 2)                      AS class_avg
FROM students
ORDER BY city, fees DESC, student_id;

-- P4  How far is each student above or below their OWN city's average?
--     Expect: 12 rows (Kiran +1500, Rahul -1500, Meena +2000, Anu 0, John -2000, Arjun 0,
--             Divya +500, Priya -500, Sara +666.67, Ravi -333.33, Nisha -333.33, Deepa 0)
SELECT student_name, city, fees,
       ROUND(fees - AVG(fees) OVER (PARTITION BY city), 2) AS vs_city_avg
FROM students
ORDER BY city, fees DESC, student_id;

-- P5  Only the students ABOVE their city's average. A window function cannot go in WHERE,
--     so: calculate in a CTE, filter after. In class 4 this needed a correlated subquery.
--     Expect: 4 rows (Kiran 1500.00, Meena 2000.00, Divya 500.00, Sara 666.67)
WITH compared AS (
    SELECT student_name, city, fees,
           ROUND(fees - AVG(fees) OVER (PARTITION BY city), 2) AS vs_city_avg
    FROM students
)
SELECT student_name, city, fees, vs_city_avg
FROM compared
WHERE vs_city_avg > 0
ORDER BY city;

-- P6  Each student's share of their city's fees, as a percentage.
--     Expect: 12 rows (Kiran 54.55, Rahul 45.45 | Meena 38.89, Anu 33.33, John 27.78 |
--             Arjun 100.00 | Divya 51.61, Priya 48.39 | Sara 35.29, Ravi 32.35, Nisha 32.35 |
--             Deepa 100.00)
SELECT student_name, city, fees,
       ROUND(fees * 100.0 / SUM(fees) OVER (PARTITION BY city), 2) AS pct_of_city
FROM students
ORDER BY city, fees DESC, student_id;

-- P7  Ranking inside each city (yesterday's preview). The ranking restarts at 1 for every city.
--     Expect: 12 rows (Bangalore: Kiran 1, Rahul 2 | Chennai: Meena 1, Anu 2, John 3 |
--             Delhi: Arjun 1 | Hyderabad: Divya 1, Priya 2 | Mumbai: Sara 1, Ravi 2, Nisha 2 |
--             [null]: Deepa 1)
SELECT student_name, city, fees,
       RANK() OVER (PARTITION BY city ORDER BY fees DESC) AS rank_in_city
FROM students
ORDER BY city, rank_in_city, student_id;

-- P8  The highest-paying student in each city: number within the city, then keep number 1.
--     Expect: 6 rows (Bangalore Kiran, Chennai Meena, Delhi Arjun, Hyderabad Divya,
--             Mumbai Sara, [null] Deepa)
WITH ranked AS (
    SELECT student_name, city, fees,
           ROW_NUMBER() OVER (PARTITION BY city
                              ORDER BY fees DESC, student_id) AS position
    FROM students
)
SELECT city, student_name, fees
FROM ranked
WHERE position = 1
ORDER BY city;

-- P9  Another table: each payment next to the total paid by THAT student.
--     Expect: 8 rows (Anu's two rows both show 12000.00; Rahul 7500.50; John 10000.00;
--             Sara 12000.00; Arjun 20000.00; Ravi 11000.00; payment 8 [null] 10000.00)
SELECT payment_id, student_id, amount,
       SUM(amount) OVER (PARTITION BY student_id) AS student_total
FROM payments
ORDER BY student_id, payment_id;

-- P10 TRY IT YOURSELF: each enrollment with the number of students in that course.
--     Expect: 12 rows (course 101 rows 2, 102 rows 4, 103 rows 2, 104 rows 3, 105 row 1)
SELECT e.enrollment_id, e.student_id, e.course_id,
       COUNT(*) OVER (PARTITION BY e.course_id) AS students_in_course
FROM enrollments e
ORDER BY e.course_id, e.enrollment_id;

-- P11 EXTRA CHALLENGE: the same, with course names and student names (join first, then window).
--     Expect: 12 rows (Python 2, SQL 4, Java 2, Data Science 3, Machine Learning 1)
SELECT c.course_name, s.student_name,
       COUNT(*) OVER (PARTITION BY c.course_id) AS students_in_course
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses  c ON e.course_id  = c.course_id
ORDER BY c.course_id, s.student_name;


-- =====================================================================
--  PART O  |  ORDER BY inside OVER with SUM and COUNT: running totals
--  Yesterday ORDER BY inside the brackets gave positions. With SUM or
--  COUNT it does something new: the window becomes "all rows UP TO this
--  one" in that order. So SUM adds up as it goes: a running total.
-- =====================================================================

-- O0  Start from what you know: SUM with empty brackets = the grand total on every row.
--     Expect: 8 rows (total_paid 82500.50 on every row)
SELECT payment_id, paid_on, amount,
       SUM(amount) OVER () AS total_paid
FROM payments
ORDER BY paid_on, payment_id;

-- O1  Upgrade: write ORDER BY paid_on, payment_id inside the brackets. The same SUM
--     now stops at the current row: a running total.
--     Expect: 8 rows (6000.00, 13500.50, 19500.50, 29500.50, 41500.50, 61500.50,
--             72500.50, 82500.50)
SELECT payment_id, paid_on, amount,
       SUM(amount) OVER (ORDER BY paid_on, payment_id) AS running_total
FROM payments
ORDER BY paid_on, payment_id;

-- O2  The last running total equals the plain total.
--     Expect: 1 row (82500.50)
SELECT SUM(amount) AS total_paid FROM payments;

-- O3  Running count: how many payments had been received by each date.
--     Expect: 8 rows (1, 2, 3, 4, 5, 6, 7, 8)
SELECT payment_id, paid_on, amount,
       COUNT(*) OVER (ORDER BY paid_on, payment_id) AS payments_so_far
FROM payments
ORDER BY paid_on, payment_id;

-- O4  Running total AND the whole-table total side by side: brackets with ORDER BY grow row
--     by row; empty brackets are the whole table.
--     Expect: 8 rows; running_total as in O1, grand_total 82500.50 on every row
SELECT payment_id, paid_on, amount,
       SUM(amount) OVER (ORDER BY paid_on, payment_id) AS running_total,
       SUM(amount) OVER ()                              AS grand_total
FROM payments
ORDER BY paid_on, payment_id;

-- O5  Fee income committed through the year: running total of fees by admission date.
--     Expect: 12 rows (12000, 27000, 42000, 52000, 64000, 82000, 96000, 116000, 132000,
--             143000, 154000, 169000)
SELECT student_name, admission_date, fees,
       SUM(fees) OVER (ORDER BY admission_date, student_id) AS fees_so_far
FROM students
ORDER BY admission_date, student_id;

-- O6  WATCH OUT: without the tie-breaker, rows with the SAME date are treated as one step.
--     Ravi and Nisha both joined on 2026-05-15, so both show 154000 (the total including both).
--     Expect: 12 rows; Ravi AND Nisha both show 154000 instead of 143000 / 154000
SELECT student_name, admission_date, fees,
       SUM(fees) OVER (ORDER BY admission_date) AS fees_so_far
FROM students
ORDER BY admission_date, student_id;

-- O7  PARTITION BY and ORDER BY together: a running total PER STUDENT. The total restarts
--     for each student and grows along their own payments.
--     Expect: 8 rows (Anu: 6000.00 then 12000.00; everyone else: one row equal to their amount)
SELECT payment_id, student_id, paid_on, amount,
       SUM(amount) OVER (PARTITION BY student_id ORDER BY paid_on) AS student_running_total
FROM payments
ORDER BY student_id, paid_on;

-- O8  TRY IT YOURSELF: running count of students by admission date (how many had joined).
--     Expect: 12 rows (1 to 12)
SELECT student_name, admission_date,
       COUNT(*) OVER (ORDER BY admission_date, student_id) AS students_so_far
FROM students
ORDER BY admission_date, student_id;

-- O9  EXTRA CHALLENGE: running total of payments per month. Step 1 in a CTE: total per month.
--     Step 2: running total over the months.
--     Expect: 6 rows (2026-01 13500.50 -> 13500.50 | 2026-02 16000.00 -> 29500.50 |
--             2026-03 12000.00 -> 41500.50 | 2026-04 20000.00 -> 61500.50 |
--             2026-05 11000.00 -> 72500.50 | 2026-11 10000.00 -> 82500.50)
WITH monthly AS (
    SELECT TO_CHAR(paid_on, 'YYYY-MM') AS month, SUM(amount) AS month_total
    FROM payments
    GROUP BY TO_CHAR(paid_on, 'YYYY-MM')
)
SELECT month, month_total,
       SUM(month_total) OVER (ORDER BY month) AS running_total
FROM monthly
ORDER BY month;


-- =====================================================================
--  PART L  |  LAG: look at the previous row
--  LAG(column) = the value of that column on the PREVIOUS row of the
--                window, in the window's order. The first row has no
--                previous row, so it gets an empty box.
--  It needs ORDER BY inside the brackets: "previous" means nothing
--  without an order. L1 shows what happens without it; L2 adds it.
-- =====================================================================

-- L1  The smallest LAG that runs: nothing inside OVER. It works, but "previous"
--     means "whatever row the database happened to hand over before this one".
--     Look at payment 3 (12 Jan): it is told the payment before it was payment 2
--     (10 Feb). Nobody asked for an order, so the dates are ignored.
--     Expect: 8 rows (previous_amount: [null], 6000.00, 6000.00, 7500.50, 10000.00,
--             12000.00, 20000.00, 11000.00 when the rows come out in payment_id order)
SELECT payment_id, paid_on, amount,
       LAG(amount) OVER () AS previous_amount
FROM payments;

-- L2  Upgrade: ORDER BY paid_on, payment_id inside the brackets. Now "previous"
--     means the payment made just before this one in time. Payment 3 moves up to
--     second place and sees 6000.00 (payment 1), the real previous payment.
--     Expect: 8 rows (previous_amount: [null], 6000.00, 7500.50, 6000.00, 10000.00,
--             12000.00, 20000.00, 11000.00)
SELECT payment_id, paid_on, amount,
       LAG(amount) OVER (ORDER BY paid_on, payment_id) AS previous_amount
FROM payments
ORDER BY paid_on, payment_id;

-- L3  Now the useful part: how much more or less than the previous payment?
--     Expect: 8 rows (change: [null], 1500.50, -1500.50, 4000.00, 2000.00, 8000.00,
--             -9000.00, -1000.00)
SELECT payment_id, paid_on, amount,
       amount - LAG(amount) OVER (ORDER BY paid_on, payment_id) AS change_vs_previous
FROM payments
ORDER BY paid_on, payment_id;

-- L4  LAG on a date: the previous payment's date, and the number of days since it.
--     Date minus date = days (class 2).
--     Expect: 8 rows (days_since_previous: [null], 2, 29, 5, 14, 42, 33, 179)
SELECT payment_id, paid_on, amount,
       LAG(paid_on) OVER (ORDER BY paid_on, payment_id)            AS previous_date,
       paid_on - LAG(paid_on) OVER (ORDER BY paid_on, payment_id)  AS days_since_previous
FROM payments
ORDER BY paid_on, payment_id;

-- L5  Upgrade: two more things inside LAG's brackets. LAG(column, 1, 0) = one row
--     back, and 0 instead of the empty box if there is no previous row.
--     Expect: 8 rows; the first row shows 0 instead of [null]
SELECT payment_id, paid_on, amount,
       LAG(amount, 1, 0) OVER (ORDER BY paid_on, payment_id) AS previous_amount
FROM payments
ORDER BY paid_on, payment_id;

-- =====================================================================
--  PART F  |  Final questions
-- =====================================================================

-- F1  Each payment with the previous payment's amount and the change, using LAG.
--     Expect: 8 rows (change: [null], 1500.50, -1500.50, 4000.00, 2000.00, 8000.00,
--             -9000.00, -1000.00)
SELECT payment_id, paid_on, amount,
       LAG(amount) OVER (ORDER BY paid_on, payment_id)          AS previous_amount,
       amount - LAG(amount) OVER (ORDER BY paid_on, payment_id) AS change
FROM payments
ORDER BY paid_on, payment_id;

-- F2  EXTRA CHALLENGE: each student with their city's total fees and their rank within the
--     city, in one query.
--     Expect: 12 rows (Kiran Bangalore 33000 1, Rahul Bangalore 33000 2, Meena Chennai 36000 1, ...)
SELECT student_name, city, fees,
       SUM(fees) OVER (PARTITION BY city)                       AS city_total,
       RANK()    OVER (PARTITION BY city ORDER BY fees DESC)    AS rank_in_city
FROM students
ORDER BY city, rank_in_city, student_id;


-- =====================================================================
--  PRACTICE SET  |  18 questions with answers
--  Cover the answer, write your own query, then compare. Row counts are
--  given so you can check yourself before looking.
--
--  Level 1 - PARTITION BY
--    P1  Each student with the total fees of their city.                           (12 rows)
--    P2  Each student with the number of students in their city.                   (12 rows)
--    P3  DENSE_RANK of students by fees within each city.                           (12 rows)
--    P4  Each payment with the total paid by that student.                         (8 rows)
--    P5  Each enrollment with the number of students in that course.               (12 rows)
--  Level 2 - running totals
--    P6  Running total of payments by date.                                        (8 rows)
--    P7  Running count of students by admission date.                              (12 rows)
--    P8  Running total of fees by admission date.                                  (12 rows)
--    P9  Running total of payments per student.                                    (8 rows)
--  Level 3 - LAG
--    P10 Each payment with the previous payment's amount.                          (8 rows)
--    P11 Each payment with the change from the previous payment.                   (8 rows)
--    P12 Each payment with the days since the previous payment.                    (8 rows)
--    P13 Each student with the previous admission date and the gap in days.        (12 rows)
--  Level 4 - combinations
--    P14 Payments that were larger than the previous payment.                       (4 rows)
--    P15 The longest gap between two consecutive payments.                         (1 row)
--    P16 The first student to enroll in each course.                               (5 rows)
--    P17 Students above their city's average fee (window version).                 (4 rows)
--    P18 Spot the mistake: WHERE amount > LAG(amount) OVER (ORDER BY paid_on).
-- =====================================================================

-- P1  Expect: 12 rows (Bangalore 33000, Chennai 36000, Delhi 20000, Hyderabad 31000,
--             Mumbai 34000, [null] 15000)
SELECT student_name, city, fees, SUM(fees) OVER (PARTITION BY city) AS city_total
FROM students ORDER BY city, student_id;

-- P2  Expect: 12 rows (Bangalore 2, Chennai 3, Delhi 1, Hyderabad 2, Mumbai 3, [null] 1)
SELECT student_name, city, COUNT(*) OVER (PARTITION BY city) AS students_in_city
FROM students ORDER BY city, student_id;

-- P3  Expect: 12 rows (Mumbai: Sara 1, Ravi 2, Nisha 2; every other city 1, 2, 3 with no ties)
SELECT student_name, city, fees,
       DENSE_RANK() OVER (PARTITION BY city ORDER BY fees DESC) AS level_in_city
FROM students ORDER BY city, level_in_city, student_id;

-- P4  Expect: 8 rows (Anu's rows 12000.00; the others equal their own amount)
SELECT payment_id, student_id, amount, SUM(amount) OVER (PARTITION BY student_id) AS student_total
FROM payments ORDER BY student_id, payment_id;

-- P5  Expect: 12 rows (101: 2, 102: 4, 103: 2, 104: 3, 105: 1)
SELECT enrollment_id, course_id, COUNT(*) OVER (PARTITION BY course_id) AS students_in_course
FROM enrollments ORDER BY course_id, enrollment_id;

-- P6  Expect: 8 rows (6000.00 ... 82500.50)
SELECT payment_id, paid_on, amount, SUM(amount) OVER (ORDER BY paid_on, payment_id) AS running_total
FROM payments ORDER BY paid_on, payment_id;

-- P7  Expect: 12 rows (1 to 12)
SELECT student_name, admission_date, COUNT(*) OVER (ORDER BY admission_date, student_id) AS students_so_far
FROM students ORDER BY admission_date, student_id;

-- P8  Expect: 12 rows (12000 ... 169000)
SELECT student_name, admission_date, fees, SUM(fees) OVER (ORDER BY admission_date, student_id) AS fees_so_far
FROM students ORDER BY admission_date, student_id;

-- P9  Expect: 8 rows (Anu 6000.00 then 12000.00; the others one row each)
SELECT payment_id, student_id, paid_on, amount,
       SUM(amount) OVER (PARTITION BY student_id ORDER BY paid_on) AS student_running_total
FROM payments ORDER BY student_id, paid_on;

-- P10 Expect: 8 rows ([null], 6000.00, 7500.50, 6000.00, 10000.00, 12000.00, 20000.00, 11000.00)
SELECT payment_id, paid_on, amount, LAG(amount) OVER (ORDER BY paid_on, payment_id) AS previous_amount
FROM payments ORDER BY paid_on, payment_id;

-- P11 Expect: 8 rows ([null], 1500.50, -1500.50, 4000.00, 2000.00, 8000.00, -9000.00, -1000.00)
SELECT payment_id, paid_on, amount,
       amount - LAG(amount) OVER (ORDER BY paid_on, payment_id) AS change_vs_previous
FROM payments ORDER BY paid_on, payment_id;

-- P12 Expect: 8 rows ([null], 2, 29, 5, 14, 42, 33, 179)
SELECT payment_id, paid_on,
       paid_on - LAG(paid_on) OVER (ORDER BY paid_on, payment_id) AS days_since_previous
FROM payments ORDER BY paid_on, payment_id;

-- P13 Expect: 12 rows ([null], 2, 24, 10, 14, 9, 26, 7, 19, 14, 0, and Deepa's gap depends on
--             the day the setup was run)
SELECT student_name, admission_date,
       admission_date - LAG(admission_date) OVER (ORDER BY admission_date, student_id) AS gap_days
FROM students ORDER BY admission_date, student_id;

-- P14 Expect: 4 rows (payments 3, 4, 5, 6)
WITH with_previous AS (
    SELECT payment_id, paid_on, amount,
           LAG(amount) OVER (ORDER BY paid_on, payment_id) AS previous_amount
    FROM payments
)
SELECT payment_id, paid_on, amount, previous_amount
FROM with_previous WHERE amount > previous_amount ORDER BY paid_on;

-- P15 Expect: 1 row (payment 8, 179 days)
WITH gaps AS (
    SELECT payment_id, paid_on,
           paid_on - LAG(paid_on) OVER (ORDER BY paid_on, payment_id) AS days_since_previous
    FROM payments
)
SELECT payment_id, paid_on, days_since_previous
FROM gaps WHERE days_since_previous IS NOT NULL
ORDER BY days_since_previous DESC LIMIT 1;

-- P16 Expect: 5 rows (Data Science Kiran, Java John, Machine Learning Arjun, Python Anu, SQL Rahul)
WITH numbered AS (
    SELECT c.course_name, s.student_name, e.enrollment_date,
           ROW_NUMBER() OVER (PARTITION BY e.course_id
                              ORDER BY e.enrollment_date, e.enrollment_id) AS position
    FROM enrollments e
    JOIN students s ON e.student_id = s.student_id
    JOIN courses  c ON e.course_id  = c.course_id
)
SELECT course_name, student_name, enrollment_date
FROM numbered WHERE position = 1 ORDER BY course_name;

-- P17 Expect: 4 rows (Kiran, Meena, Divya, Sara)
WITH compared AS (
    SELECT student_name, city, fees,
           fees - AVG(fees) OVER (PARTITION BY city) AS vs_city_avg
    FROM students
)
SELECT student_name, city, fees FROM compared WHERE vs_city_avg > 0 ORDER BY city;

-- P18 FAILS ON PURPOSE. WHERE runs before window functions are calculated, so LAG does not
--     exist yet. Fix: calculate LAG in a CTE, then filter (see P14).
--     Expect: ERROR: window functions are not allowed in WHERE
SELECT payment_id, amount FROM payments
WHERE amount > LAG(amount) OVER (ORDER BY paid_on);
