# iTunes Market Analysis and Segmentation

This project presents a full-stack data analysis process based on real iTunes sales and user data. It includes database design, SQL querying, Python-based data exploration, customer segmentation, trend analysis, and the development of a simple recommendation logic. The goal is to extract business insights that could support marketing and product decisions.

## Project Objectives

- Design and build a normalized Data Warehouse using a star schema
- Integrate external currency data to standardize revenue values
- Explore customer behavior across purchases and genres
- Identify seasonality trends in music preferences
- Perform segmentation based on behavioral logic
- Develop a genre recommendation mechanism per user

## Project Structure

- `python/`  
  Contains the Jupyter Notebooks used for data cleaning, processing, segmentation logic and visualizations:
  
  - `Part_1+2_.ipynb` – Data exploration, cleaning, feature engineering and preparation for DWH
  - `Part_5_.ipynb` – Segmentation analysis, insights and custom recommendation logic

- `sql/`  
  SQL scripts for schema creation and querying:
  
  - `Part 3 - DWH.sql` – Star schema setup and data model
  - `Part 4.sql` – Analytical queries and marketing-oriented metrics

- `docs/`  
  Contains the project documentation:
  
  - `Project explanation.pdf` – Full explanation in Hebrew, including screenshots of the notebooks and SQL scripts

## Key Highlights

- Revenue normalized using real-time currency exchange API
- Customers segmented by purchasing behavior and engagement level
- Clear seasonal trends observed across genres
- Business-driven SQL queries to extract insights on user habits
- Recommendation logic selects the most suitable genre for each user based on historical activity

## How to Use

1. Create the schema using `sql/Part 3 - DWH.sql`
2. Run analysis queries from `sql/Part 4.sql`
3. Open and run the Jupyter notebooks from the `python/` folder
4. Consult the documentation in `docs/` for full context

## Authors

Gabriel Mizrahi  
Ilay Habib  
Ronen Lesnik
