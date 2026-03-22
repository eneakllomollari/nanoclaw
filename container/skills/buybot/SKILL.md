---
name: buybot
description: Access purchase transaction history from BuyBot API. Use when asked about orders, purchases, Amazon spending, or when enriching transactions.
---

# BuyBot — Purchase History API

Pull purchase transaction history via the BuyBot REST API.

## Authentication

The API key is available as `BUYBOT_API_KEY` env var. Trim whitespace before use:

```bash
KEY=$(echo "$BUYBOT_API_KEY" | tr -d '[:space:]')
curl -s -H "Authorization: Bearer $KEY" "https://api.buybot.app/..."
```

If the env var is not set, ask the user to provide one from [buybot.app/connect](https://buybot.app/connect).

## Behavior

Be proactive — don't ask clarifying questions before fetching. If the user says "show my orders", just call the API and return results. Paginate when needed (250 per page).

## Endpoints

Full API reference: [api.buybot.app/docs](https://api.buybot.app/docs)

Key endpoint:
```bash
curl -s -H "Authorization: Bearer $KEY" "https://api.buybot.app/transactions?limit=250&offset=0"
```

Continue paginating (offset=250, 500, ...) until a page returns fewer than 250 results.

## Common Issues

- **401 Unauthorized**: Hidden whitespace in key, missing `Bearer` prefix, or invalid key
- **Empty transactions**: Wait 30 minutes after first connecting a merchant account
