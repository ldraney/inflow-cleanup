# inflow-cleanup

AI-powered data governance for Inflow Inventory. Claude reviews, cleans, and maintains data consistency — issue by issue — with full audit trail via GitHub releases.

## Architecture

```
inflow-api-types     (Zod schemas)
       |
       v
+------+------+
|             |
v             v
inflow-get    inflow-put
(read/sync)   (write-back)
       |             |
       v             v
+---------------------+
|   inflow-cleanup    |
|                     |
|  SQL Views          |  <- Detection (find issues)
|       |             |
|       v             |
|  Claude Code        |  <- Resolution (fix issues)
|       |             |
|       v             |
|  Releases           |  <- Audit trail (SQLite snapshots)
+---------------------+
```

## Purpose

A data governance repo where:

1. **SQL views identify issues** — duplicates, missing data, inconsistencies
2. **Claude resolves them** — analyzes context, proposes fixes, executes via `inflow-put`
3. **Releases track state** — each release is a SQLite snapshot with changelog

### Why This Matters

Manual data cleanup is tedious and error-prone. This approach:

- **Surfaces issues automatically** via SQL views
- **Provides AI judgment** for ambiguous cases (which duplicate to keep?)
- **Creates audit trail** via releases (before/after SQLite snapshots)
- **Enables investigation** if a fix was wrong (compare releases)

## Core Workflow

```
1. Sync       inflow-get pulls current Inflow state → SQLite
2. Release    Tag release with SQLite snapshot attached
3. Detect     Claude queries SQL views → issue rows
4. Fix        Claude calls inflow-put (logs to changelog.jsonl)
5. Verify     Re-sync, confirm view returns fewer rows
6. Release    New release with updated SQLite + changelog
```

## Issue Categories

### Products
| View | Issue |
|------|-------|
| `products_missing_cost` | Items with NULL or zero cost |
| `products_duplicate_names` | Multiple products with same name |
| `products_no_vendor` | Inventory items without vendor link |
| `products_orphaned_boms` | BOM references to deleted products |
| `products_inconsistent_units` | Mismatched UOM across related items |
| `products_inactive_in_active_boms` | Inactive items used in active BOMs |

### Vendors
| View | Issue |
|------|-------|
| `vendors_no_products` | Vendors with no linked products |
| `vendors_duplicate_names` | Multiple vendors with same name |

### Customers
| View | Issue |
|------|-------|
| `customers_duplicate_names` | Multiple customers with same name |
| `customers_no_orders` | Customers with no order history |

### Orders
| View | Issue |
|------|-------|
| `orders_stale_draft` | Draft orders older than X days |
| `orders_orphaned_lines` | Order lines referencing deleted products |

### Inventory
| View | Issue |
|------|-------|
| `inventory_negative_stock` | Locations with negative quantities |
| `inventory_phantom_stock` | Stock in inactive locations |

## Structure

```
inflow-cleanup/
├── CLAUDE.md
├── package.json
├── views/
│   ├── products.sql      # Product issue views
│   ├── vendors.sql       # Vendor issue views
│   ├── customers.sql     # Customer issue views
│   ├── orders.sql        # Order issue views
│   └── inventory.sql     # Inventory issue views
├── data/
│   ├── inflow.sqlite     # Current Inflow state (from inflow-get)
│   └── changelog.jsonl   # Changes since last release
└── releases/
    └── (SQLite snapshots attached to GitHub releases)
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `INFLOW_API_KEY` | Yes | Inflow API key |
| `INFLOW_COMPANY_ID` | Yes | Inflow company GUID |

## Dependencies

| Package | Purpose |
|---------|---------|
| `inflow-get` | Sync Inflow → SQLite |
| `inflow-put` | Write fixes back to Inflow |

## Claude Workflow

Claude Code works directly with SQLite and the sibling libraries:

1. **Query views** — `SELECT * FROM products_missing_cost`
2. **Gather context** — join related tables, check history
3. **Propose fix** — explain reasoning, get approval if needed
4. **Execute** — call `inflow-put` to apply fix
5. **Log** — append to changelog.jsonl
6. **Verify** — re-query view to confirm fix worked

### Decision Framework

For each issue, Claude:

1. **Gathers context** — related products, order history, vendor data
2. **Applies heuristics** — newer is usually better, more orders = keep
3. **Proposes resolution** — merge, update, deactivate, or skip
4. **Requests approval** (optional) — for destructive or ambiguous changes
5. **Executes and verifies** — confirms fix worked

## Roadmap

### Phase 1: Foundation
- [ ] Project setup (package.json)
- [ ] SQL view files for each issue category
- [ ] Initial sync via inflow-get → SQLite
- [ ] First release with baseline snapshot

### Phase 2: Detection Views
- [ ] Product views (5-6 issue types)
- [ ] Vendor views (2-3 issue types)
- [ ] Customer views (2-3 issue types)
- [ ] Order views (2-3 issue types)
- [ ] Inventory views (2-3 issue types)

### Phase 3: Fix Workflow
- [ ] Claude queries views, identifies issues
- [ ] Apply fixes via inflow-put
- [ ] Log changes to changelog.jsonl
- [ ] New release with updated snapshot

### Phase 4: Ongoing Governance
- [ ] Regular sync cycles
- [ ] Release per cleanup session
- [ ] Issue trend tracking across releases

## Definition of Done

**For the Repo:**
- [ ] SQL views load and execute against SQLite
- [ ] inflow-get can sync to data/inflow.sqlite
- [ ] Releases include SQLite snapshot + changelog

**For Claude Integration:**
- [ ] Claude can query any view directly
- [ ] Claude can gather context via SQL joins
- [ ] Claude can execute fixes via inflow-put
- [ ] Every fix logs to changelog.jsonl
- [ ] New release captures the updated state

**Completion = a working workflow where:**
```
inflow-get → data/inflow.sqlite
Claude queries views, fixes issues via inflow-put
changelog.jsonl tracks what changed
GitHub release captures the new state
```

## Changelog Format

Each fix appends a JSON line to `data/changelog.jsonl`:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "issueType": "products_missing_cost",
  "entityType": "product",
  "entityId": "prod_abc123",
  "action": "UPDATE",
  "reason": "Set cost based on vendor pricing history",
  "before": { "cost": null },
  "after": { "cost": 12.50 },
  "release": "v1.2.0"
}
```

**Fields:**
| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 when fix was applied |
| `issueType` | Which SQL view flagged this issue |
| `entityType` | product, vendor, customer, order, etc. |
| `entityId` | Inflow ID of the modified entity |
| `action` | UPDATE, MERGE, DEACTIVATE, DELETE |
| `reason` | Claude's explanation for this fix |
| `before` | Relevant fields before the change |
| `after` | Relevant fields after the change |
| `release` | Which release this change targets |

**Why JSONL:**
- Append-only (no conflicts, no corruption)
- One line per entry (easy to grep, tail, stream)
- Human-readable and diffable in git
- Trivial to query with `jq`

## Release Strategy

Each GitHub release includes:
- **SQLite snapshot** — full Inflow state at that point
- **Changelog diff** — changes since previous release
- **Release notes** — summary of issues fixed

This creates a complete audit trail:
- Compare any two releases to see what changed
- Roll back by referencing a previous snapshot
- Track data quality improvement over time
