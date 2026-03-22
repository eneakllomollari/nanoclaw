---
name: gws
description: Query Google Workspace (Gmail, Calendar, Drive) using the gws CLI. Use for email searches, calendar lookups, or finding financial data not in local files.
---

# Google Workspace CLI (gws)

Query Gmail, Calendar, and Drive from the command line.

## Gmail

### Search messages
```bash
gws gmail users messages list --params '{"userId": "me", "maxResults": 10, "q": "search query"}'
```

### Read a message
```bash
gws gmail users messages get --params '{"userId": "me", "id": "MSG_ID", "format": "full"}'
```

### Date filters in query
- `newer_than:7d` or `after:YYYY/MM/DD before:YYYY/MM/DD`
- Exclude noise: `from:(-github.com -linkedin.com -newsletter)`

### Extract message content
- Quick preview: use the `snippet` field
- Headers: parse `payload.headers` for From, Subject, Date
- Body: base64-decode `payload.body.data` or recurse through `payload.parts`

```bash
# Decode body from a message
gws gmail users messages get --params '{"userId": "me", "id": "MSG_ID", "format": "full"}' | python3 -c "
import sys, json, base64
msg = json.load(sys.stdin)
for part in msg.get('payload', {}).get('parts', []):
    if part.get('mimeType') == 'text/plain':
        data = part.get('body', {}).get('data', '')
        print(base64.urlsafe_b64decode(data + '==').decode('utf-8', errors='replace'))
"
```

## Calendar

```bash
gws calendar events list --params '{"calendarId": "primary", "timeMin": "2026-01-01T00:00:00Z", "timeMax": "2026-12-31T23:59:59Z", "singleEvents": true, "orderBy": "startTime"}'
```

## Extracting ticket details (Ticketmaster emails)

HTML-only — decode `text/html` part, strip tags with `re.sub(r'<[^>]+>', ' ', html)`, search text after venue name for section/row/seat. Don't regex for "GA" — matches CSS classes.

## Tips

- Always check local files first before querying Gmail
- Use focused search queries to minimize API calls
- Gmail search syntax: `from:`, `to:`, `subject:`, `has:attachment`, `filename:pdf`
