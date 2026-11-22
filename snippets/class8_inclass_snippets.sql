-- =====================================================================
--  SQL CLASS 8  |  Every query from the class, in order, with explanations
--  Topics: finishing window functions (LEAD, LAG inside a group, two
--          small reports), then transactions: BEGIN, COMMIT, ROLLBACK,
--          SAVEPOINT, and what ACID means. 13-question practice set at
--          the end.
-- =====================================================================
--  HOW TO USE THIS FILE
--  1. Run setup/class8_setup.sql first (it adds the small accounts table).
--  2. Open this file in the Query Tool (folder icon -> Open File).
--  3. Highlight ONE statement, from its first word to the semicolon,
--     and press F5. A WITH query is ONE statement: highlight from WITH
--     down to the final semicolon.
--  4. Compare your result with the "Expect" line written above it.
--
--  NEW TODAY: order matters. BEGIN, the changes, and COMMIT or ROLLBACK
--  must be run in the SAME Query Tool tab, one after the other. Run the
--  statements of each numbered step in the order written.
--
--  Do not run the whole file at once. Several statements FAIL ON PURPOSE,
--  and the first failure cancels everything else in the run.
--
--  If you ever see "current transaction is aborted, commands ignored
--  until end of transaction block": run   ROLLBACK;   and carry on.
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

-- 0.2  Today's new table: three bank accounts. The total is 88000.00. Every
--      transfer today moves money between these accounts, so the total must
--      still be 88000.00 after each one. Watch for it.
--      Expect: 3 rows (Arjun 30000.00, Priya 8000.00, Institute 50000.00; total 88000.00 on each)
SELECT holder, balance,
       SUM(balance) OVER () AS total
FROM accounts
ORDER BY account_id;


-- =====================================================================
--  PART W  |  Finishing window functions: LEAD, and LAG inside a group
--  Last class: LAG(column) copies the value from the PREVIOUS row of
--  the window. LEAD(column) is the same thing looking the other way:
--  it copies the value from the NEXT row. The last row has no next row,
--  so it gets an empty box.
-- =====================================================================

-- W1  Start with the smallest LEAD that runs: nothing inside OVER. It works,
--     but "next" means "whatever row the database hands over after this one".
--     Payment 2 (10 Feb) is told that the payment after it is payment 3 (12 Jan).
--     Expect: 8 rows (next_amount: 6000.00, 7500.50, 10000.00, 12000.00, 20000.00,
--             11000.00, 10000.00, [null] when the rows come out in payment_id order)
SELECT payment_id, paid_on, amount,
       LEAD(amount) OVER () AS next_amount
FROM payments;

-- W2  Upgrade: ORDER BY paid_on, payment_id inside the brackets. Now "next" means
--     the payment made just after this one in time. Compare W2 with last class's
--     LAG: previous_amount looked UP one row, next_amount looks DOWN one row.
--     Expect: 8 rows (next_amount: 7500.50, 6000.00, 10000.00, 12000.00, 20000.00,
--             11000.00, 10000.00, [null])
SELECT payment_id, paid_on, amount,
       LEAD(amount) OVER (ORDER BY paid_on, payment_id) AS next_amount
FROM payments
ORDER BY paid_on, payment_id;

-- W3  Upgrade: LEAD on the date, then subtract. "How many days until the next
--     payment came in?" Next date minus this date.
--     Expect: 8 rows (days_until_next: 2, 29, 5, 14, 42, 33, 179, [null])
SELECT payment_id, paid_on, amount,
       LEAD(paid_on) OVER (ORDER BY paid_on, payment_id)            AS next_date,
       LEAD(paid_on) OVER (ORDER BY paid_on, payment_id) - paid_on  AS days_until_next
FROM payments
ORDER BY paid_on, payment_id;

-- W4  LAG inside a group: PARTITION BY student_id ORDER BY paid_on. "Previous"
--     now means the previous payment BY THE SAME STUDENT. Only Anu paid twice,
--     so only her second payment has a previous one.
--     Expect: 8 rows (payment 2: prev_by_same_student 6000.00, 31 days;
--             every other row [null], [null])
SELECT payment_id, student_id, paid_on, amount,
       LAG(amount)  OVER (PARTITION BY student_id ORDER BY paid_on) AS prev_by_same_student,
       paid_on - LAG(paid_on) OVER (PARTITION BY student_id ORDER BY paid_on)
                                                                     AS days_since_their_last
FROM payments
ORDER BY student_id, paid_on;

-- W5  The same idea on another table: for each enrollment, how many days after the
--     previous enrollment IN THE SAME COURSE did it happen? Join first for the
--     names, then the window.
--     Expect: 12 rows (Data Science: [null], 52, 35; Java: [null], 89; Machine
--             Learning: [null]; Python: [null], 50; SQL: [null], 24, 59, 57)
SELECT c.course_name, s.student_name, e.enrollment_date,
       LAG(e.enrollment_date) OVER (PARTITION BY e.course_id
                                    ORDER BY e.enrollment_date, e.enrollment_id)
           AS previous_in_course,
       e.enrollment_date
       - LAG(e.enrollment_date) OVER (PARTITION BY e.course_id
                                      ORDER BY e.enrollment_date, e.enrollment_id)
           AS gap_days
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses  c ON e.course_id  = c.course_id
ORDER BY c.course_name, e.enrollment_date, e.enrollment_id;

-- W6  A monthly report: GROUP BY in a CTE, then LAG and a running total over the
--     six monthly rows. Four columns a manager would ask for, in one query.
--     Expect: 6 rows (change_vs_previous: [null], 2499.50, -4000.00, 8000.00,
--             -9000.00, -1000.00; running_total ends at 82500.50)
WITH monthly AS (
    SELECT TO_CHAR(paid_on, 'YYYY-MM') AS month,
           SUM(amount)                 AS month_total
    FROM payments
    GROUP BY TO_CHAR(paid_on, 'YYYY-MM')
)
SELECT month, month_total,
       LAG(month_total) OVER (ORDER BY month)                AS previous_month,
       month_total - LAG(month_total) OVER (ORDER BY month)  AS change_vs_previous,
       SUM(month_total) OVER (ORDER BY month)                AS running_total
FROM monthly
ORDER BY month;

-- W7  TRY IT YOURSELF: each student with the NEXT admission date and the days
--     until it. (Nisha's gap depends on the day the setup was run.)
--     Expect: 12 rows (days_until_next: 2, 24, 10, 14, 9, 26, 7, 19, 14, 0, Nisha's
--             gap to Deepa, [null])
SELECT student_name, admission_date,
       LEAD(admission_date) OVER (ORDER BY admission_date, student_id)
           AS next_admission,
       LEAD(admission_date) OVER (ORDER BY admission_date, student_id) - admission_date
           AS days_until_next
FROM students
ORDER BY admission_date, student_id;


-- =====================================================================
--  PART T  |  Transactions: BEGIN, COMMIT, ROLLBACK
--  A transaction is a group of changes that the database treats as ONE
--  action: either all of them are saved, or none of them.
--    BEGIN     = start the group. From here on nothing is final.
--    COMMIT    = save everything in the group. Final.
--    ROLLBACK  = throw everything in the group away. As if nothing happened.
--  Without BEGIN, every statement is its own tiny transaction and is
--  saved the moment it finishes. That is what has happened in every
--  class so far.
-- =====================================================================

-- T0  Where we start. Three accounts, total 88000.00.
--     Expect: 3 rows (Arjun 30000.00, Priya 8000.00, Institute 50000.00)
SELECT holder, balance FROM accounts ORDER BY account_id;

-- T1  Start from what you know: a plain UPDATE. Then try to undo it.
--     Run T1.1 to T1.4 one at a time.

-- T1.1 Take 1000 from Arjun. Messages tab: UPDATE 1.
--      Expect: UPDATE 1
UPDATE accounts SET balance = balance - 1000 WHERE holder = 'Arjun';

-- T1.2 It is done.
--      Expect: 1 row (Arjun 29000.00)
SELECT holder, balance FROM accounts WHERE holder = 'Arjun';

-- T1.3 Try to undo it. Messages tab: WARNING: there is no transaction in progress.
--      There was nothing to undo: the UPDATE was saved the moment it finished.
--      Expect: WARNING, then ROLLBACK
ROLLBACK;

-- T1.4 Still 29000. The change is permanent.
--      Expect: 1 row (Arjun 29000.00)
SELECT holder, balance FROM accounts WHERE holder = 'Arjun';

-- T2  Upgrade: say BEGIN first. Now the change is not final until you say so.
--     Run T2.1 to T2.5 one at a time, in this tab.

-- T2.1 Open the group.
--      Expect: BEGIN
BEGIN;

-- T2.2 Take another 1000 from Arjun.
--      Expect: UPDATE 1
UPDATE accounts SET balance = balance - 1000 WHERE holder = 'Arjun';

-- T2.3 Inside the group you see your own change: 28000.
--      Expect: 1 row (Arjun 28000.00)
SELECT holder, balance FROM accounts WHERE holder = 'Arjun';

-- T2.4 Change your mind. Throw the group away.
--      Expect: ROLLBACK
ROLLBACK;

-- T2.5 Back to 29000, as if T2.2 never happened.
--      Expect: 1 row (Arjun 29000.00)
SELECT holder, balance FROM accounts WHERE holder = 'Arjun';

-- T3  The other way to close the group: COMMIT. Run T3.1 to T3.6 one at a time.

-- T3.1 Open the group.
--      Expect: BEGIN
BEGIN;

-- T3.2 Take 1000 from Arjun.
--      Expect: UPDATE 1
UPDATE accounts SET balance = balance - 1000 WHERE holder = 'Arjun';

-- T3.3 Save it. Final.
--      Expect: COMMIT
COMMIT;

-- T3.4 28000, and it stays.
--      Expect: 1 row (Arjun 28000.00)
SELECT holder, balance FROM accounts WHERE holder = 'Arjun';

-- T3.5 After COMMIT there is no undo. Same warning as T1.3.
--      Expect: WARNING, then ROLLBACK
ROLLBACK;

-- T3.6 Still 28000.
--      Expect: 1 row (Arjun 28000.00)
SELECT holder, balance FROM accounts WHERE holder = 'Arjun';

-- T3.7 Arjun's 2000 left the table for good in T1 and T3 (a withdrawal has no
--      partner account). Put him back to 30000 with a plain UPDATE, saved at once,
--      so the transfers below start from round numbers: total 88000 again.
--      Expect: UPDATE 1
UPDATE accounts SET balance = 30000 WHERE holder = 'Arjun';

-- T4  The real reason transactions exist: TWO changes that belong together.
--     Move 5000 from Arjun to Priya. If only one of the two happened, money
--     would vanish or appear from nowhere. Run T4.1 to T4.5 one at a time.

-- T4.1
--      Expect: BEGIN
BEGIN;

-- T4.2 Money out.
--      Expect: UPDATE 1
UPDATE accounts SET balance = balance - 5000 WHERE holder = 'Arjun';

-- T4.3 Money in.
--      Expect: UPDATE 1
UPDATE accounts SET balance = balance + 5000 WHERE holder = 'Priya';

-- T4.4 Both saved together.
--      Expect: COMMIT
COMMIT;

-- T4.5 Arjun 25000, Priya 13000. The total is still 88000.
--      Expect: 3 rows (Arjun 25000.00, Priya 13000.00, Institute 50000.00; total 88000.00)
SELECT holder, balance,
       SUM(balance) OVER () AS total
FROM accounts
ORDER BY account_id;

-- T5  A transfer that goes wrong half way. Move 100000 from Priya to the Institute.
--     Priya does not have 100000, and the table has CHECK (balance >= 0).
--     Run T5.1 to T5.6 one at a time and read every message.

-- T5.1
--      Expect: BEGIN
BEGIN;

-- T5.2 Money in, first. This works: the Institute now shows 150000 inside the group.
--      Expect: UPDATE 1
UPDATE accounts SET balance = balance + 100000 WHERE holder = 'Institute';

-- T5.3 FAILS ON PURPOSE. Money out: Priya would go to -87000, and the rule says no.
--      Expect: ERROR: new row for relation "accounts" violates check constraint
--              "accounts_balance_check"
UPDATE accounts SET balance = balance - 100000 WHERE holder = 'Priya';

-- T5.4 FAILS ON PURPOSE. After an error inside a group, the database refuses to do
--      anything else until the group is closed. Even a SELECT.
--      Expect: ERROR: current transaction is aborted, commands ignored until end of
--              transaction block
SELECT holder, balance FROM accounts ORDER BY account_id;

-- T5.5 Close the group. Everything in it, including the 100000 that appeared in
--      T5.2, is thrown away.
--      Expect: ROLLBACK
ROLLBACK;

-- T5.6 The Institute is back to 50000. No money was created from nothing.
--      Expect: 3 rows (Arjun 25000.00, Priya 13000.00, Institute 50000.00; total 88000.00)
SELECT holder, balance,
       SUM(balance) OVER () AS total
FROM accounts
ORDER BY account_id;

-- T6  TRY IT YOURSELF: move 3000 from the Institute to Priya as one transaction,
--     then show all three balances with the total. (Four statements, then a SELECT.)
BEGIN;
UPDATE accounts SET balance = balance - 3000 WHERE holder = 'Institute';
UPDATE accounts SET balance = balance + 3000 WHERE holder = 'Priya';
COMMIT;
--     Expect: 3 rows (Arjun 25000.00, Priya 16000.00, Institute 47000.00; total 88000.00)
SELECT holder, balance,
       SUM(balance) OVER () AS total
FROM accounts
ORDER BY account_id;

-- T7  EXTRA CHALLENGE: inside a transaction, give EVERY account 1000 more (one
--     UPDATE, no WHERE), look at the total, then change your mind.
BEGIN;
UPDATE accounts SET balance = balance + 1000;
--     Expect: 3 rows (26000.00, 17000.00, 48000.00; total 91000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;
ROLLBACK;
--     Expect: 3 rows (25000.00, 16000.00, 47000.00; total 88000.00 again)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;


-- =====================================================================
--  PART S  |  SAVEPOINT: a marker inside a transaction
--  ROLLBACK throws away the WHOLE group. SAVEPOINT name; puts a marker
--  in the middle, and ROLLBACK TO SAVEPOINT name; goes back only to that
--  marker. The work before the marker is kept, and the group stays open.
-- =====================================================================

-- S0  Start from what you know: a transaction with a typo in it, and no marker.
--     Enrol a new student, Kavya, in two courses. The second course number is wrong.
--     Run S0.1 to S0.6 one at a time.

-- S0.1
--      Expect: BEGIN
BEGIN;

-- S0.2 Step 1 of 3: the student.
--      Expect: INSERT 0 1
INSERT INTO students (student_id, student_name, age, city, email, fees, admission_date)
VALUES (13, 'Kavya', 22, 'Pune', 'kavya@example.com', 14000, CURRENT_DATE);

-- S0.3 Step 2 of 3: her first course, SQL (102).
--      Expect: INSERT 0 1
INSERT INTO enrollments VALUES (13, 13, 102, CURRENT_DATE, 'Active');

-- S0.4 FAILS ON PURPOSE. Step 3 of 3: a typo, course 999 does not exist.
--      Expect: ERROR: insert or update on table "enrollments" violates foreign key
--              constraint "enrollments_course_id_fkey"
INSERT INTO enrollments VALUES (14, 13, 999, CURRENT_DATE, 'Active');

-- S0.5 The group is poisoned (T5.4). The only way out is ROLLBACK.
--      Expect: ROLLBACK
ROLLBACK;

-- S0.6 Kavya is gone. One typo threw away two good steps.
--      Expect: 0 rows
SELECT student_name FROM students WHERE student_id = 13;

-- S1  Upgrade: put a SAVEPOINT before the risky step. Run S1.1 to S1.9 one at a time.

-- S1.1
--      Expect: BEGIN
BEGIN;

-- S1.2 The student.
--      Expect: INSERT 0 1
INSERT INTO students (student_id, student_name, age, city, email, fees, admission_date)
VALUES (13, 'Kavya', 22, 'Pune', 'kavya@example.com', 14000, CURRENT_DATE);

-- S1.3 Her first course.
--      Expect: INSERT 0 1
INSERT INTO enrollments VALUES (13, 13, 102, CURRENT_DATE, 'Active');

-- S1.4 The marker. Everything up to here is safe.
--      Expect: SAVEPOINT
SAVEPOINT after_first_course;

-- S1.5 FAILS ON PURPOSE. The same typo.
--      Expect: ERROR: insert or update on table "enrollments" violates foreign key
--              constraint "enrollments_course_id_fkey"
INSERT INTO enrollments VALUES (14, 13, 999, CURRENT_DATE, 'Active');

-- S1.6 Go back to the marker, not to the start. The group is alive again.
--      Expect: ROLLBACK
ROLLBACK TO SAVEPOINT after_first_course;

-- S1.7 Kavya and her first course are still here.
--      Expect: 1 row (Kavya)
SELECT student_name FROM students WHERE student_id = 13;

-- S1.8 The corrected step 3: Python is 101.
--      Expect: INSERT 0 1
INSERT INTO enrollments VALUES (14, 13, 101, CURRENT_DATE, 'Active');

-- S1.9 Save the group.
--      Expect: COMMIT
COMMIT;

-- S1.10 Kavya is enrolled in two courses, and the typo never reached the table.
--       Expect: 2 rows (Kavya SQL, Kavya Python)
SELECT s.student_name, c.course_name, e.enrollment_date
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses  c ON e.course_id  = c.course_id
WHERE s.student_id = 13
ORDER BY e.enrollment_id;

-- S2  TRY IT YOURSELF: remove Kavya again, as one transaction. Her enrollments
--     must go before she does (the foreign key rule from class 2), so: BEGIN, delete
--     her enrollments, delete her, COMMIT, then count.
BEGIN;
--     Expect: DELETE 2
DELETE FROM enrollments WHERE student_id = 13;
--     Expect: DELETE 1
DELETE FROM students    WHERE student_id = 13;
COMMIT;
--     Expect: 1 row (12, 12)
SELECT (SELECT COUNT(*) FROM students)    AS students,
       (SELECT COUNT(*) FROM enrollments) AS enrollments;


-- =====================================================================
--  PART A  |  ACID: the four promises, and seeing isolation with two tabs
--    Atomicity    all of the group or none of it          (T5, S0)
--    Consistency  the rules are never broken, even half way (T5: CHECK)
--    Isolation    nobody else sees your unfinished group    (A1 to A4)
--    Durability   once COMMIT answers, it is saved for good
--  For A1 to A4 you need TWO Query Tool tabs on sql_class. Open the
--  second one with: right-click sql_class -> Query Tool. Keep this file
--  in tab 1 and type the tab-2 statements by hand (they are short).
-- =====================================================================

-- A0  RESET the accounts to 30000 / 8000 / 50000 so everyone has the same numbers.
--     (CASE from class 2 picks the right number for each row.)
--     Expect: UPDATE 3
UPDATE accounts
SET balance = CASE holder WHEN 'Arjun' THEN 30000
                          WHEN 'Priya' THEN 8000
                          ELSE 50000 END;

-- A1  TAB 1: open a group and move 2000 from Arjun to Priya. Do NOT commit yet.
--     Highlight all three lines and press F5 once. Messages tab: UPDATE 1 (pgAdmin
--     reports the last statement).
BEGIN;
UPDATE accounts SET balance = balance - 2000 WHERE holder = 'Arjun';
UPDATE accounts SET balance = balance + 2000 WHERE holder = 'Priya';

-- A2  TAB 1: you see your own unfinished work: 28000 / 10000, total 88000.
--     Expect: 3 rows (Arjun 28000.00, Priya 10000.00, Institute 50000.00; total 88000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- A3  TAB 2: type and run this same SELECT in the second tab. It shows the OLD
--     numbers: 30000 / 8000, total 88000. Tab 2 cannot see tab 1's unfinished group.
--     In tab 2 the total is ALSO 88000: at no moment does anybody see a half-done
--     transfer.
--     Expect (in tab 2): 3 rows (Arjun 30000.00, Priya 8000.00, Institute 50000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- A4  TAB 1: commit. Then run A3's SELECT in TAB 2 again: now 28000 / 10000.
--     Close tab 2 when you have seen it.
--     Expect: COMMIT; then in tab 2, 3 rows (Arjun 28000.00, Priya 10000.00, ...)
COMMIT;

-- A5  Durability: close tab 2 (or close pgAdmin itself and open it again), open a
--     fresh Query Tool on sql_class, and run this. 28000 / 10000 are still there.
--     COMMIT means written to disk. pgAdmin can close, the computer can restart;
--     the data stays.
--     Expect: 3 rows (Arjun 28000.00, Priya 10000.00, Institute 50000.00; total 88000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;


-- =====================================================================
--  PART F  |  Final question
-- =====================================================================

-- F1  Move 1000 from Arjun to the Institute as one transaction, then prove the
--     total is still 88000.
BEGIN;
UPDATE accounts SET balance = balance - 1000 WHERE holder = 'Arjun';
UPDATE accounts SET balance = balance + 1000 WHERE holder = 'Institute';
COMMIT;
--     Expect: 3 rows (Arjun 27000.00, Priya 10000.00, Institute 51000.00; total 88000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;


-- =====================================================================
--  PRACTICE SET  |  13 questions with answers
--  RUN THE SETUP AGAIN FIRST (setup/class8_setup.sql) so that the numbers
--  below match. Cover the answer, write your own statements, then compare.
--
--  Level 1 - LEAD, and LAG inside a group
--    P1  Each payment with the next payment's amount.                          (8 rows)
--    P2  Each payment with the next payment's date and the days until it.      (8 rows)
--    P3  Each student with the next admission date and the days until it.      (12 rows)
--    P4  Each payment with the previous payment by the same student.           (8 rows)
--    P5  Each enrollment with the gap since the previous one in the same course. (12 rows)
--    P6  Monthly totals with the change from the previous month.               (6 rows)
--  Level 2 - transactions
--    P7  Move 2000 from the Institute to Arjun in one transaction; show the total.
--    P8  Give every account 1000 more inside a transaction, look, then undo it.
--    P9  Inside a transaction, try to take 100000 from Priya. What happens? What next?
--    P10 Without BEGIN, add 500 to Priya, then ROLLBACK. Did it undo?
--  Level 3 - SAVEPOINT
--    P11 In one transaction: add course 107, Cloud Security; SAVEPOINT; enrol student
--        99 in it (fails); back to the savepoint; enrol Deepa (12) instead; COMMIT.
--  Level 4 - think about it (no query needed)
--    P12 Spot the mistake:  BEGIN; UPDATE accounts SET balance = 0
--        WHERE holder = 'Priya'; COMMIT; ROLLBACK;   What did the ROLLBACK undo?
--    P13 Which letter of ACID? (a) a transfer's two updates are saved together or not
--        at all; (b) the second tab did not see the first tab's unfinished transfer;
--        (c) CHECK (balance >= 0) stopped Priya going negative; (d) the data was
--        still there after pgAdmin was closed and reopened.
-- =====================================================================

-- P1  Expect: 8 rows (next_amount: 7500.50, 6000.00, 10000.00, 12000.00, 20000.00,
--             11000.00, 10000.00, [null])
SELECT payment_id, paid_on, amount,
       LEAD(amount) OVER (ORDER BY paid_on, payment_id) AS next_amount
FROM payments ORDER BY paid_on, payment_id;

-- P2  Expect: 8 rows (days_until_next: 2, 29, 5, 14, 42, 33, 179, [null])
SELECT payment_id, paid_on,
       LEAD(paid_on) OVER (ORDER BY paid_on, payment_id)           AS next_date,
       LEAD(paid_on) OVER (ORDER BY paid_on, payment_id) - paid_on AS days_until_next
FROM payments ORDER BY paid_on, payment_id;

-- P3  Expect: 12 rows (2, 24, 10, 14, 9, 26, 7, 19, 14, 0, Nisha's gap to Deepa, [null])
SELECT student_name, admission_date,
       LEAD(admission_date) OVER (ORDER BY admission_date, student_id) - admission_date
           AS days_until_next
FROM students ORDER BY admission_date, student_id;

-- P4  Expect: 8 rows (only payment 2 has a value: 6000.00)
SELECT payment_id, student_id, paid_on, amount,
       LAG(amount) OVER (PARTITION BY student_id ORDER BY paid_on) AS prev_by_same_student
FROM payments ORDER BY student_id, paid_on;

-- P5  Expect: 12 rows (Data Science [null], 52, 35; Java [null], 89; Machine Learning
--             [null]; Python [null], 50; SQL [null], 24, 59, 57)
SELECT c.course_name, s.student_name, e.enrollment_date,
       e.enrollment_date
       - LAG(e.enrollment_date) OVER (PARTITION BY e.course_id
                                      ORDER BY e.enrollment_date, e.enrollment_id)
           AS gap_days
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses  c ON e.course_id  = c.course_id
ORDER BY c.course_name, e.enrollment_date, e.enrollment_id;

-- P6  Expect: 6 rows (change: [null], 2499.50, -4000.00, 8000.00, -9000.00, -1000.00)
WITH monthly AS (
    SELECT TO_CHAR(paid_on, 'YYYY-MM') AS month, SUM(amount) AS month_total
    FROM payments
    GROUP BY TO_CHAR(paid_on, 'YYYY-MM')
)
SELECT month, month_total,
       month_total - LAG(month_total) OVER (ORDER BY month) AS change_vs_previous
FROM monthly ORDER BY month;

-- P7  Run the statements one at a time.
BEGIN;
UPDATE accounts SET balance = balance - 2000 WHERE holder = 'Institute';
UPDATE accounts SET balance = balance + 2000 WHERE holder = 'Arjun';
COMMIT;
--     Expect: 3 rows (Arjun 32000.00, Priya 8000.00, Institute 48000.00; total 88000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- P8  Run the statements one at a time.
BEGIN;
UPDATE accounts SET balance = balance + 1000;
--     Expect: 3 rows (33000.00, 9000.00, 49000.00; total 91000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;
ROLLBACK;
--     Expect: 3 rows (32000.00, 8000.00, 48000.00; total 88000.00 again)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- P9  Run the statements one at a time and read the messages.
BEGIN;
--     FAILS ON PURPOSE: ERROR ... violates check constraint "accounts_balance_check".
--     The group is now aborted, so the only thing to run next is ROLLBACK.
UPDATE accounts SET balance = balance - 100000 WHERE holder = 'Priya';
ROLLBACK;
--     Expect: 3 rows, unchanged (Arjun 32000.00, Priya 8000.00, Institute 48000.00)
SELECT holder, balance, SUM(balance) OVER () AS total FROM accounts ORDER BY account_id;

-- P10 Run the statements one at a time. No BEGIN means no undo: the 500 stays.
--     Expect: UPDATE 1
UPDATE accounts SET balance = balance + 500 WHERE holder = 'Priya';
--     Expect: WARNING: there is no transaction in progress
ROLLBACK;
--     Expect: 1 row (Priya 8500.00)
SELECT holder, balance FROM accounts WHERE holder = 'Priya';

-- P11 Run the statements one at a time.
BEGIN;
INSERT INTO courses VALUES (107, 'Cloud Security', 3, 'Farah');
SAVEPOINT course_added;
--     FAILS ON PURPOSE: student 99 does not exist (foreign key).
INSERT INTO enrollments VALUES (13, 99, 107, CURRENT_DATE, 'Active');
ROLLBACK TO SAVEPOINT course_added;
INSERT INTO enrollments VALUES (13, 12, 107, CURRENT_DATE, 'Active');
COMMIT;
--     Expect: 1 row (7)
SELECT COUNT(*) AS courses FROM courses;
--     Expect: 1 row (Deepa, Cloud Security)
SELECT s.student_name, c.course_name
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses  c ON e.course_id  = c.course_id
WHERE c.course_id = 107;

-- P12 Nothing. COMMIT had already saved the change, so the ROLLBACK found no open
--     transaction (WARNING: there is no transaction in progress). Priya's balance
--     stays 0 until the setup is run again. ROLLBACK only works BEFORE COMMIT.
--     (Not run here: it would really set Priya to 0.)

-- P13 (a) Atomicity. (b) Isolation. (c) Consistency. (d) Durability.
