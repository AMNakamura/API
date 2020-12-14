--- Pageviews by URL for a subsite
SELECT
  event_date,
  event_params.value.string_value as page_url,
  COUNT(*) AS pageviews,
  COUNT(DISTINCT user_pseudo_id) AS unique_pageviews
FROM
  `MyProject.analytics_id.events_*` AS t,
  UNNEST(t.event_params) AS event_params
WHERE
  event_params.key = "page_location"
  AND event_name = "page_view"
  AND event_params.value.string_value like '%/doa/%'
GROUP BY
  1,
  2
ORDER BY
  3 DESC
LIMIT 1000
