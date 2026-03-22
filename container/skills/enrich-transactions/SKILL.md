---
name: enrich-transactions
description: Enrich transaction CSVs with BuyBot item-level purchase details. Use when importing new transactions, when asked to enrich/annotate transactions, or after pulling BuyBot data. Matches bank charges to BuyBot orders and adds product names + order URLs to the Notes column.
---

# Enrich Transactions with BuyBot

Match BuyBot orders to bank statement transactions and add product names + order URLs to the CSV Notes column.

## Prerequisites

- `BUYBOT_API_KEY` env var must be set
- Transaction CSVs must exist at `/workspace/extra/life/finances/transactions/`

## CSV Format

```
Date,Description,Statement description,Type,Category,Amount,Account,Tags,Notes
```

Key files:
- `ytd-YYYY.csv` — current year consolidated transactions (single source of truth)
- `final_export.csv` — historical transactions

## Enrichment Process

### 1. Fetch all BuyBot transactions

```bash
KEY=$(echo "$BUYBOT_API_KEY" | tr -d '[:space:]')
curl -s -H "Authorization: Bearer $KEY" "https://api.buybot.app/transactions?limit=250&offset=0"
```
Paginate until fewer than 250 results.

### 2. Classify: company vs personal

Read rule from `/workspace/extra/life/context/financial.yaml` under `amazon_office_orders`:
- **Shipped to office** (36 E 20th St, NYC) = company-covered, skip
- **Shipped anywhere else** = personal, enrich

### 3. Match BuyBot orders to CSV rows

Match on amount + card last 4 + date proximity:
- Amount must match exactly (2 decimal places)
- Card last 4 must match (from Account column in parentheses)
- Date within 7 days (bank posting delay)
- Fallback: amount + date within 5 days (any card)
- Track used rows to prevent double-matching

### 4. Write to Notes column

Format: `BuyBot: {product_names} ({order_url})`

Rules:
- Product names: join all, truncate to 80 chars
- If Notes has content without "BuyBot": append with ` | `
- If Notes contains "BuyBot": skip (already enriched)
- Use csv module, not string manipulation

### 5. Process these files

- `/workspace/extra/life/finances/transactions/ytd-{current_year}.csv`
- `/workspace/extra/life/finances/transactions/final_export.csv`

### 6. Report results

- Rows enriched per file
- Unmatched BuyBot orders (with reason)
- Ambiguous matches (flag for review)

## Important

- **Merchant-agnostic**: BuyBot includes any connected merchant, not just Amazon
- **Only modify Notes column** — never change amounts or categories
- **Corp cards** shipped to home = personal purchases, still enrich
- **Idempotent**: check for "BuyBot" prefix before writing
