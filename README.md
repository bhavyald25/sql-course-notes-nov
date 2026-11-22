# SQL Course — Notes and Practice Files

PostgreSQL 17 · pgAdmin 4 · database name: `sql_class`

## Download everything

Click the green **Code** button at the top of this page → **Download ZIP**. Unzip it. You get three folders:

| Folder | What is in it |
|---|---|
| `notes/` | The class notes as PDF. Read these. |
| `setup/` | SQL files that build the practice tables. Run one before practising. |
| `snippets/` | Every query we ran in class, in order, with the expected result in a comment. |

## Notes

| File | Covers |
|---|---|
| `notes/SQL_NOTES_CLASSES_1_2.pdf` | SELECT, WHERE, ORDER BY, LIMIT, COUNT/SUM/AVG/MIN/MAX, GROUP BY, HAVING, CASE, NULL and COALESCE, text/number/date functions, data types, CREATE/ALTER/DROP, constraints. 10 practice questions with answers. |
| `notes/SQL_NOTES_JOINS_SET_OPERATIONS.pdf` | INNER, LEFT, RIGHT, FULL JOIN, LEFT JOIN + IS NULL, self join, designing tables for joins, CROSS JOIN, UNION, UNION ALL, INTERSECT, EXCEPT. 40 practice questions with answers. |
| `notes/SQL_NOTES_SUBQUERIES.pdf` | Subqueries: a query inside a query with =, >, <; IN and NOT IN (and the NULL trap); two ways to write "who has not". 20 practice questions with answers. |
| `notes/SQL_NOTES_EXISTS_CTES.pdf` | EXISTS and NOT EXISTS; a subquery as a table and as a column; CTEs (WITH): one CTE, a CTE used twice, several CTEs, CTE + join. 20 practice questions with answers. |
| `notes/SQL_NOTES_WINDOW_FUNCTIONS_1.pdf` | Window functions, part 1: what OVER ( ) does, ROW_NUMBER with a tie-breaker, RANK and DENSE_RANK on ties, using a rank with a CTE (top N, Nth highest). 20 practice questions with answers. |
| `notes/SQL_NOTES_WINDOW_FUNCTIONS_2.pdf` | Window functions, part 2: PARTITION BY (per-group totals, ranks, top one per group), running totals with ORDER BY inside OVER, LAG (previous row, change from the previous row, days between events). 18 practice questions with answers. |
| `notes/SQL_NOTES_TRANSACTIONS.pdf` | LEAD (next row, days until the next event), LAG inside a group, a monthly report; then transactions: BEGIN, COMMIT, ROLLBACK, autocommit, the "transaction is aborted" message, SAVEPOINT, ACID with a two-tab demonstration. 13 practice questions with answers. |

## Setting up the tables (do this once, and again whenever your tables break)

1. Open pgAdmin → **Servers → PostgreSQL 17** → enter the password you chose when you installed PostgreSQL.
2. If you do not have a database called `sql_class` yet: right-click **Databases → Create → Database**, name it `sql_class`, Save.
3. Click `sql_class` once so it is highlighted → menu **Tools → Query Tool**. The tab title must show `sql_class`.
4. Open `setup/class8_setup.sql` in Notepad, select all, copy, paste into the Query Tool.
5. Press **F5**. The Messages tab may first say *WARNING: there is no transaction in progress* (that is fine: the file closes any transaction left open in the tab), then *Query returned successfully*.
6. Right-click **Tables → Refresh**. You should see: students, courses, enrollments, payments, accounts, customers, orders, orders_bad, shirts, trousers, morning_batch, evening_batch.

`class8_setup.sql` builds the **current** state of all tables and is safe to run as many times as you like. The older files are kept only if you want to replay an earlier class exactly as it was:

| Setup file | Builds the tables as they were at |
|---|---|
| `setup/class2_setup.sql` | the start of class 2 (students, courses, enrollments only) |
| `setup/class3_setup.sql` | the start of class 3 (same as classes 4 to 7) |
| `setup/class4_setup.sql` | the start of class 4 |
| `setup/class5_setup.sql` | the start of class 5 |
| `setup/class6_setup.sql` | the start of class 6 |
| `setup/class7_setup.sql` | the start of class 7 |
| `setup/class8_setup.sql` | the start of class 8 (adds the accounts table) — **use this one** |

## Replaying a class with the snippets

1. Run the matching setup file first (table below).
2. Open the snippets file in the Query Tool (folder icon → Open File).
3. **Highlight one statement** with the mouse, from its first word to the semicolon, then press **F5**. A `WITH` query is one statement: highlight from `WITH` down to the final semicolon.
4. Compare your result with the comment above the statement.

Do not run the whole file at once. Some statements are marked `FAILS ON PURPOSE`; the first error cancels everything else in the run.

From class 8 on, some steps are **transactions**: `BEGIN;`, then one or more changes, then `COMMIT;` or `ROLLBACK;`. Run the statements of a step in the order written, one at a time, **in the same Query Tool tab**. If you see `current transaction is aborted, commands ignored until end of transaction block`, run `ROLLBACK;` and carry on.

| Class | Topics | Run this setup first | Then open | Notes |
|---|---|---|---|---|
| 2 | WHERE toolbox, data types, constraints, ALTER/DROP, NULL, COALESCE, joins, self join | `class2_setup.sql` | `snippets/class2_inclass_snippets.sql` | Notes 1 and Notes 2 |
| 3 | Joins from scratch, table design, CROSS JOIN, UNION, INTERSECT, EXCEPT | `class3_setup.sql` | `snippets/class3_inclass_snippets.sql` | Notes 2 |
| 4 | Subqueries: WHERE, IN, NOT IN | `class4_setup.sql` | `snippets/class4_inclass_snippets.sql` (practice set at the bottom) | Notes 3 (Subqueries) |
| 5 | EXISTS, NOT EXISTS, subquery as a table / column, CTEs (WITH) | `class5_setup.sql` | `snippets/class5_inclass_snippets.sql` (practice set at the bottom) | Notes 4 (EXISTS and CTEs) |
| 6 | Window functions part 1: OVER, ROW_NUMBER, RANK, DENSE_RANK, top N with a CTE | `class6_setup.sql` | `snippets/class6_inclass_snippets.sql` (practice set at the bottom) | Notes 5 (Window Functions 1) |
| 7 | Window functions part 2: PARTITION BY, running totals, LAG | `class7_setup.sql` | `snippets/class7_inclass_snippets.sql` (practice set at the bottom) | Notes 6 (Window Functions 2) |
| 8 | LEAD, LAG inside a group, monthly report; transactions: BEGIN, COMMIT, ROLLBACK, SAVEPOINT, ACID | `class8_setup.sql` | `snippets/class8_inclass_snippets.sql` (practice set at the bottom) | Notes 7 (Transactions) |

## Three rules for pgAdmin

1. The tab title of the Query Tool must say **sql_class**. If it says `postgres`, you are in the wrong database.
2. **F5 runs everything in the editor.** To run one statement, highlight it first.
3. If one statement in a run fails, PostgreSQL cancels the whole run. Nothing is half-done.

## If something looks wrong

| You see | Do this |
|---|---|
| `relation "students" does not exist` or `relation "accounts" does not exist` | Check the tab title says `sql_class`, then run `class8_setup.sql` again |
| `duplicate key value violates unique constraint` when running a snippet | The row already exists. Run `class8_setup.sql` to reset, then try again |
| Nothing appears after F5 | You are on the Messages tab. Click Data Output |
| A result does not match the comment | Run `class8_setup.sql` to reset the data, then re-run the statement |
| `current transaction is aborted, commands ignored until end of transaction block` | A statement inside an open transaction failed. Run `ROLLBACK;` once, then continue |
| `WARNING: there is no transaction in progress` | You ran COMMIT or ROLLBACK with no BEGIN open. Nothing was changed by it |
| A second Query Tool tab hangs on the spinner | It is waiting for a transaction left open in another tab. Run `COMMIT;` or `ROLLBACK;` in that other tab |
