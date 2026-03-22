---
name: financial-sync
description: Full financial sync and summary. Use when asked to "sync", "refresh", "how am I doing financially", "spending summary", "financial check-in", or any review of spending/income over a period. Chains enrichment, Gmail scan, and categorized summary.
---

# Financial Sync

Full financial sync: enrich transactions, pull missing data from email, and produce a spending/income summary.

## Arguments

Time period. Examples: `last month`, `february`, `this week`, `Q1 2026`, `ytd`, `last 30 days`
Default: current month to date.

## Execution Order

### Step 1: Enrich transactions

Run the `enrich-transactions` skill process to annotate un-enriched BuyBot orders in CSVs.

### Step 2: Scan Gmail for missing data

Use `gws` to search for financial emails in the target period:

```bash
gws gmail users messages list --params '{"userId": "me", "maxResults": 25, "q": "after:YYYY/MM/DD before:YYYY/MM/DD (from:(chase.com OR americanexpress.com OR capitalone.com OR sofi.com OR marcus.com OR venmo.com OR zelle OR paypal.com OR bfrwd.com) subject:(payment OR statement OR alert OR receipt OR confirmation))"}'
```

Also check for: paystub emails (Gusto), subscription charges, large transactions, Zelle/Venmo notifications.

Flag anything in email missing from CSV. Do NOT auto-add — flag for review.

### Step 3: Load transactions

Read from `/workspace/extra/life/finances/transactions/`:
- Current year: `ytd-{year}.csv`
- Prior years: `final_export.csv`

Filter to date range. Exclude: Type=Transfer, Category=Credit card payment, Category=Transfer.

### Step 4: Load context

- `/workspace/extra/life/context/financial.yaml` — subscriptions, accounts, net worth
- `/workspace/extra/life/accounts/accounts.md` — subscription list, balances
- `/workspace/extra/life/context/timeline-{year}.yaml` — events explaining spend

### Step 5: Produce summary

Output to chat (NOT a file). Structure:

```
=== FINANCIAL SYNC: {period} ===

INCOME
  Paychecks:        $X,XXX (N pay periods)
  Interest:         $XXX
  Total income:     $X,XXX

SPENDING BY CATEGORY (descending)
  Category          Amount    %    Txns   vs last period
  Housing           $X,XXX    XX%  N      ...
  ...

TOP 10 INDIVIDUAL CHARGES

SUBSCRIPTIONS CHECK
  - Recurring charges detected
  - NEW charges not in accounts.md
  - MISSING expected subscriptions

ALBANIA (family transfers)
  Total sent, via which services

SHARED EXPENSES (Michelle)
  - Shared cards (9839, 0106) or Venmo/Zelle to Michelle
  - Net: who owes whom

SAVINGS & INVESTMENTS
  - Acorns, Chase auto-invest ($150/wk), other

BUYBOT HIGHLIGHTS
  - Top personal purchases from enriched Notes

FLAGS & ANOMALIES
  - Large charges, duplicates, unexpected accounts, missing data
```

### Step 6: Compare to prior period

Show total spend delta, categories with >20% swings, new/disappeared categories.

### Step 7: Update context files

If sync reveals new info, update files and commit via git:
- New subscription → `accounts/accounts.md`
- Net worth change → `context/financial.yaml`
- Notable event → `context/timeline-{year}.yaml`

## Key Rules

- Card Depot = halal food cart, not office supplies
- Albania category = money to family (Wolt, Patoko, Western Union, ONE.al, etc.)
- All output to chat unless asked for a file
- Flag ambiguous charges, don't guess categories
