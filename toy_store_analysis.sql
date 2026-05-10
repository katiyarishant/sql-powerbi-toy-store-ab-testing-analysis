------------------------------------------------- Use Database ---------------------------------------------------------------
USE toy_store_ecommerce_project;



----------------------------------------------------- Add Columns -------------------------------------------------------------
ALTER TABLE website_sessions
ADD
    traffic_source_group   VARCHAR(50),
    page_type              VARCHAR(20);



----------------------------------------------- Traffic Source Classification ------------------------------------------------
UPDATE website_sessions
SET traffic_source_group =
    CASE

        WHEN utm_source = 'gsearch'
            THEN 'Google Ads'

        WHEN utm_source = 'bsearch'
            THEN 'Bing Ads'

        WHEN utm_source = 'socialbook'
            THEN 'Social Media Ads'

        WHEN utm_source IS NULL
             AND http_referer = 'https://www.gsearch.com'
            THEN 'Organic Google'

        WHEN utm_source IS NULL
             AND http_referer = 'https://www.bsearch.com'
            THEN 'Organic Bing'

        WHEN utm_source IS NULL
             AND http_referer IS NULL
            THEN 'Direct Traffic'

        ELSE 'Other'

    END;



--------------------------------------------------- Create Page Type Column ---------------------------------------------------
WITH first_page AS (
    SELECT
        website_session_id,
        pageview_url,
        ROW_NUMBER() OVER(
            PARTITION BY website_session_id
            ORDER BY
                created_at ASC,
                website_pageview_id ASC
        ) AS rn
    FROM website_pageviews
)

UPDATE ws
SET page_type =
    CASE
        WHEN fp.pageview_url = '/home'
            THEN 'old'

        WHEN fp.pageview_url = '/lander-1'
            THEN 'new'

        ELSE 'ignore'

    END

FROM website_sessions ws
JOIN first_page fp
    ON ws.website_session_id = fp.website_session_id
WHERE fp.rn = 1;



------------------------------------------------ Sessions -----------------------------------------------------
SELECT
    page_type,
    COUNT(DISTINCT website_session_id) AS total_sessions
FROM website_sessions
GROUP BY page_type;



------------------------------------------------- Bounce Rate ------------------------------------------------------
SELECT
    ws.page_type,
    COUNT(DISTINCT CASE
        WHEN pv.pageviews = 1
        THEN ws.website_session_id
    END) * 100.0
    /
    COUNT(DISTINCT ws.website_session_id) AS bounce_rate
FROM website_sessions ws
JOIN (
    SELECT
        website_session_id,
        COUNT(*) AS pageviews
    FROM website_pageviews
    GROUP BY website_session_id
) pv
ON ws.website_session_id = pv.website_session_id
GROUP BY ws.page_type;



--------------------------------------------- Engagement Rate ------------------------------------------------------
SELECT
    ws.page_type,
    COUNT(DISTINCT CASE
        WHEN pv.pageviews > 1
        THEN ws.website_session_id
    END) * 100.0
    /
    COUNT(DISTINCT ws.website_session_id) AS engagement_rate
FROM website_sessions ws
JOIN (
    SELECT
        website_session_id,
        COUNT(*) AS pageviews
    FROM website_pageviews
    GROUP BY website_session_id
) pv
ON ws.website_session_id = pv.website_session_id
GROUP BY ws.page_type;



---------------------------------------------------- Orders ----------------------------------------------------
SELECT
    ws.page_type,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
GROUP BY ws.page_type;



------------------------------------------------- Conversion Rate ---------------------------------------------------
SELECT
    ws.page_type,
    COUNT(DISTINCT o.order_id) * 100.0
    /
    COUNT(DISTINCT ws.website_session_id) AS conversion_rate
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
GROUP BY ws.page_type;



--------------------------------------------------- Avg. Order Value ---------------------------------------------------
SELECT
    ws.page_type,
    SUM(o.price_usd)
    /
    COUNT(DISTINCT o.order_id) AS avg_order_value
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
GROUP BY ws.page_type;



------------------------------------------------------ Revenue ------------------------------------------------------
SELECT
    ws.page_type,
    SUM(o.price_usd) AS revenue
FROM website_sessions ws
LEFT JOIN orders o
ON ws.website_session_id = o.website_session_id
GROUP BY ws.page_type;