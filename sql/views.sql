-- ============================================================================
-- Reporting Views
-- Music Store Analytics (Chinook)
-- ============================================================================
-- Purpose:
--   Create clean, reusable reporting views for Power BI dashboards.
--   These views centralize business logic (joins, aggregations, percent-of-total)
--   and provide consistent metrics for analysis.
--
-- Notes:
--   - Invoice revenue uses invoice.total for invoice-level totals
--   - Line-item revenue uses invoice_line.unit_price * invoice_line.quantity
--   - Time metrics are modeled at a monthly grain for trend reporting
-- ============================================================================


-- ----------------------------------------------------------------------------
-- Revenue Over Time (Monthly, with optional country slice)
-- Grain: month x country
-- Use case: trend lines and country comparisons over time
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_revenue_over_time;

CREATE OR REPLACE VIEW vw_revenue_over_time AS
SELECT
  DATE_TRUNC('month', i.invoice_date)::date AS month,
  i.billing_country AS country,
  SUM(i.total) AS total_revenue
FROM invoice i
GROUP BY 1, 2;


-- ----------------------------------------------------------------------------
-- Revenue by Country
-- Grain: country
-- Use case: geographic distribution of revenue
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_revenue_by_country;

CREATE OR REPLACE VIEW vw_revenue_by_country AS
SELECT
  i.billing_country AS country,
  SUM(i.total) AS total_revenue
FROM invoice i
GROUP BY 1;


-- ----------------------------------------------------------------------------
-- Customer Lifetime Value
-- Grain: customer
-- Use case: identify highest-value customers and segment by country
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_customer_lifetime_value;

CREATE OR REPLACE VIEW vw_customer_lifetime_value AS
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.country,
  SUM(i.total) AS lifetime_value
FROM customer c
JOIN invoice i
  ON c.customer_id = i.customer_id
GROUP BY
  c.customer_id, c.first_name, c.last_name, customer_name, c.country;


-- ----------------------------------------------------------------------------
-- Revenue by Artist
-- Grain: artist
-- Use case: top artists by sales (line-item revenue)
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_revenue_by_artist;

CREATE OR REPLACE VIEW vw_revenue_by_artist AS
SELECT
  ar.name AS artist,
  SUM(il.unit_price * il.quantity) AS revenue
FROM invoice_line il
JOIN track t
  ON il.track_id = t.track_id
JOIN album al
  ON t.album_id = al.album_id
JOIN artist ar
  ON al.artist_id = ar.artist_id
GROUP BY ar.name;


-- ----------------------------------------------------------------------------
-- Revenue by Genre
-- Grain: genre
-- Use case: top genres by sales (line-item revenue)
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_revenue_by_genre;

CREATE OR REPLACE VIEW vw_revenue_by_genre AS
SELECT
  g.name AS genre,
  SUM(il.unit_price * il.quantity) AS revenue
FROM invoice_line il
JOIN track t
  ON il.track_id = t.track_id
JOIN genre g
  ON t.genre_id = g.genre_id
GROUP BY g.name;


-- ----------------------------------------------------------------------------
-- Revenue % Contribution by Genre
-- Grain: genre
-- Use case: percent-of-total mix (great for stacked bars / donut)
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_revenue_pct_by_genre;

CREATE OR REPLACE VIEW vw_revenue_pct_by_genre AS
SELECT
  g.name AS genre,
  SUM(il.unit_price * il.quantity) AS genre_revenue,
  ROUND(
    SUM(il.unit_price * il.quantity)
    / NULLIF(SUM(SUM(il.unit_price * il.quantity)) OVER (), 0)
  , 4) AS revenue_pct
FROM invoice_line il
JOIN track t
  ON il.track_id = t.track_id
JOIN genre g
  ON t.genre_id = g.genre_id
GROUP BY g.name;


-- ----------------------------------------------------------------------------
-- Top Tracks by Revenue
-- Grain: track
-- Use case: top selling tracks with artist/genre context
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_top_tracks_by_revenue;

CREATE OR REPLACE VIEW vw_top_tracks_by_revenue AS
SELECT
  t.track_id,
  t.name AS track_name,
  ar.name AS artist,
  g.name AS genre,
  SUM(il.unit_price * il.quantity) AS total_revenue
FROM invoice_line il
JOIN track t
  ON il.track_id = t.track_id
LEFT JOIN album al
  ON t.album_id = al.album_id
LEFT JOIN artist ar
  ON al.artist_id = ar.artist_id
LEFT JOIN genre g
  ON t.genre_id = g.genre_id
GROUP BY
  t.track_id, t.name, ar.name, g.name;


-- ----------------------------------------------------------------------------
-- Employee Performance (Support Revenue)
-- Grain: employee
-- Use case: revenue influenced by each support rep’s customer book
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_employee_performance;

CREATE OR REPLACE VIEW vw_employee_performance AS
SELECT
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
  SUM(i.total) AS total_support_revenue
FROM employee e
JOIN customer c
  ON e.employee_id = c.support_rep_id
JOIN invoice i
  ON c.customer_id = i.customer_id
GROUP BY e.employee_id, employee_name;


-- ----------------------------------------------------------------------------
-- Employee Support Efficiency
-- Grain: employee
-- Use case: customers supported + revenue per customer
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_employee_support_efficiency;

CREATE OR REPLACE VIEW vw_employee_support_efficiency AS
SELECT
  e.employee_id,
  CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
  COUNT(DISTINCT c.customer_id) AS customers_supported,
  SUM(i.total) AS total_support_revenue,
  ROUND(
    SUM(i.total) / NULLIF(COUNT(DISTINCT c.customer_id), 0)
  , 2) AS revenue_per_customer
FROM employee e
JOIN customer c
  ON e.employee_id = c.support_rep_id
JOIN invoice i
  ON c.customer_id = i.customer_id
GROUP BY e.employee_id, e.first_name, e.last_name;

