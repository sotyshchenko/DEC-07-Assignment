{% macro get_quarter(date_column) %}
    CASE
        WHEN EXTRACT(MONTH FROM {{ date_column }}) IN (1, 2, 3) THEN 'Q1'
        WHEN EXTRACT(MONTH FROM {{ date_column }}) IN (4, 5, 6) THEN 'Q2'
        WHEN EXTRACT(MONTH FROM {{ date_column }}) IN (7, 8, 9) THEN 'Q3'
        WHEN EXTRACT(MONTH FROM {{ date_column }}) IN (10, 11, 12) THEN 'Q4'
        ELSE NULL
    END
{% endmacro %}
