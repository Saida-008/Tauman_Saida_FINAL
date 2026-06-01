Grading Rubric
Criterion	Max Points	Notes
Conceptual ERD	3	Entities, relationships, cardinality all drawn graphically
Logical schema	2	Types, keys, constraints; 5+ tables; 1+ M:N; 3+ FKs
3NF	2	Each table justified as 3NF
DB + schema with domain names	1	Meaningful names documented
Re-runnable header	1	CREATE … IF NOT EXISTS + DROP … CASCADE in correct order
CREATE TABLE	3	Correct types, PK, FK with explicit ON DELETE
DEFAULT + GENERATED	1	Both present and meaningful
5 CHECK constraints (all required kinds)	2	Date > 2026-01-01, non-negative, enumerated, UNIQUE, NOT NULL
5 ALTER TABLE statements	3	Each meaningful, with why-comment, different ops
TRUNCATE CASCADE in correct order	1	Re-runnable reset
INSERT — row counts & realistic data	2	10+ in largest, 5+ in others; no aaa/test123
INSERT — no hard-coded FKs	3	Subquery lookups for every FK value
INSERT … SELECT	1	At least one, typically for the junction table
UPDATE × 2	2	One simple, one UPDATE … FROM or subquery in SET; business reason in comment
DELETE in transaction with RETURNING + ROLLBACK	3	Wrapped in BEGIN … ROLLBACK; comment with reason
GRANT + REVOKE	3	Two roles, GRANT, REVOKE, role purpose commented
Code quality & re-runnability	2	Runs twice cleanly; lowercase keywords; section headers; aliases
Total	35	
Grade Boundaries (out of 35)
Score	Grade
32–35	Excellent
26–31	Good
21–25	Satisfactory
15–20	Needs improvement
< 15	Unsatisfactory
