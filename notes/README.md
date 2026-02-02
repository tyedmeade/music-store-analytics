## Project Notes & Approach

This project was built to simulate how analytics work is performed in a real business environment, where data lives in a relational database and dashboards are consumed by non-technical stakeholders.

### Goals
- Model clean, reusable SQL views for reporting
- Separate business logic (SQL) from visualization (Power BI)
- Answer practical business questions around revenue, customers, products, and operations

### Data Modeling Decisions
- SQL views were created to centralize transformations and aggregations
- Time-based metrics were modeled at a monthly grain to support trend analysis
- Product and customer metrics were derived from invoice line items to avoid double-counting
- Window functions were used to calculate percentage-of-total metrics in SQL

### Dashboard Design Considerations
- Overview pages avoid scrolling and emphasize high-level KPIs
- Detail pages (Product and Customer Insights) allow scrolling where appropriate
- Filters and slicers were designed for intuitive exploration without overwhelming the user

### Assumptions & Limitations
- Revenue calculations are based on historical invoice data only
- Customer lifetime value reflects observed spend, not predicted value
- Employee performance metrics assume equal support responsibility per assigned customer

### Tools Used
- PostgreSQL for data modeling
- Power BI for visualization and dashboarding
- GitHub for documentation and version control
