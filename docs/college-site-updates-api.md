# College website updates API

The app backend exposes the public information published on the Loyola College website.

## Endpoint

`GET /api/v1/college/updates`

Optional query parameter:

- `refresh=1` bypasses the in-memory five-minute scraper cache.

No student login or LRMS link is required because these are public college notices.

## Response

```json
{
  "status": "success",
  "data": {
    "announcements": [
      { "id": "...", "title": "...", "url": "...", "source": "Loyola College" }
    ],
    "events": [
      {
        "id": "...",
        "title": "...",
        "url": "...",
        "details": "...",
        "department": "...",
        "dateLabel": "...",
        "location": "..."
      }
    ],
    "calendar": {
      "month": "November 2026",
      "entries": [
        { "dateLabel": "16 Nov MON", "event": "College Reopens for EVEN Semester", "dayOrder": "Day-1" }
      ],
      "sourceUrl": "https://www.loyolacollege.edu/acnew"
    },
    "sources": {
      "homepage": "https://www.loyolacollege.edu/",
      "calendar": "https://www.loyolacollege.edu/acnew"
    },
    "fetchedAt": "2026-11-12T00:00:00.000Z"
  }
}
```

## Source strategy

The official homepage publishes announcements and upcoming event cards in its
HTML section labelled "Events and announcements". The academic calendar has a
separate HTML list view at `/acnew`. The backend requests those public pages
and parses the HTML with Cheerio; it does not call an undocumented endpoint or
reuse the LRMS student session.

The scraper caches the combined result for five minutes to avoid repeatedly
requesting the college website. The mobile app opens the College Updates screen
from the campaign icon in the dashboard header.
