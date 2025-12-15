# inflow-cleanup

AI-powered data governance for Inflow Inventory. Claude reviews, cleans, and maintains data consistency — issue by issue — with full audit trail.

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
|  Claude Agent       |  <- Resolution (fix issues)
|       |             |
|       v             |
|  Changelog          |  <- Audit trail (track changes)
+---------------------+
```

## Purpose

A data cleanup tool where:

1. **SQL views identify issues** — duplicates, missing data, inconsistencies
2. **Claude resolves them** — analyzes context, proposes fixes, executes via `inflow-put`
3. **Every change is logged** — structured changelog records what changed and why

### Why This Matters

Manual data cleanup is tedious and error-prone. This tool:

- **Surfaces issues automatically** via SQL views
- **Provides AI judgment** for ambiguous cases (which duplicate to keep?)
- **Creates audit trail** so you can see what changed and why
- **Enables investigation** if a fix was wrong (before/after values logged)

## Core Workflow

```
1. Sync       inflow-get pulls current Inflow state → SQLite
2. Detect     SQL views query SQLite → issue rows
3. Review     Claude analyzes issue + context
4. Fix        Claude calls inflow-put (before/after logged to changelog)
5. Verify     Re-sync, confirm view returns fewer rows
6. Repeat     Next issue until views return empty
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
├── src/
│   ├── index.ts              # CLI entry point
│   ├── sync.ts               # Wrapper around inflow-get
│   ├── changelog.ts          # Append-only audit log
│   └── views/
│       ├── products.sql      # Product issue views
│       ├── vendors.sql       # Vendor issue views
│       ├── customers.sql     # Customer issue views
│       ├── orders.sql        # Order issue views
│       └── inventory.sql     # Inventory issue views
├── data/
│   ├── inflow.sqlite         # Current Inflow state (from inflow-get)
│   └── changelog.jsonl       # Append-only audit log
└── tests/
    └── views.test.ts         # Verify views return expected structure
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
| `better-sqlite3` | Query SQLite views |

## Claude Integration

Claude interacts with this tool via MCP or function calls:

```typescript
// Available tools for Claude
listIssues(viewName?: string)        // Query views, get issue rows
getContext(productId: string)        // Fetch related data for analysis
proposeFix(issueId, fix)             // Log proposed resolution
executeFix(issueId)                  // Call inflow-put, log to changelog
```

### Decision Framework

For each issue, Claude:

1. **Gathers context** — related products, order history, vendor data
2. **Applies heuristics** — newer is usually better, more orders = keep
3. **Proposes resolution** — merge, update, deactivate, or skip
4. **Requests approval** (optional) — for destructive or ambiguous changes
5. **Executes and verifies** — confirms fix worked

## Roadmap

### Phase 1: Foundation
- [ ] Project setup (package.json, tsconfig)
- [ ] SQLite view infrastructure (load .sql files, execute)
- [ ] Changelog manager (append-only JSONL audit log)
- [ ] Basic CLI (`cleanup sync`, `cleanup issues`, `cleanup log`)

### Phase 2: Detection Views
- [ ] Product views (5-6 issue types)
- [ ] Vendor views (2-3 issue types)
- [ ] Customer views (2-3 issue types)
- [ ] Order views (2-3 issue types)
- [ ] Inventory views (2-3 issue types)

### Phase 3: Claude Integration
- [ ] MCP server or function calling interface
- [ ] Context gathering tools
- [ ] Fix execution with inflow-put
- [ ] Approval workflow (optional human-in-loop)

### Phase 4: Workflow Automation
- [ ] Issue prioritization (most impactful first)
- [ ] Batch processing mode
- [ ] Scheduled runs
- [ ] Reporting (issues found, fixed, remaining)

## Definition of Done

**For the Tool:**
- [ ] `cleanup sync` pulls latest Inflow state
- [ ] `cleanup issues` lists all detected issues across views
- [ ] `cleanup log` shows recent changelog entries
- [ ] All SQL views load and execute without error

**For Claude Integration:**
- [ ] Claude can query any view and get structured results
- [ ] Claude can gather context for any entity
- [ ] Claude can execute fixes via inflow-put
- [ ] Every fix logs before/after state to changelog
- [ ] Audit trail shows what changed and why

**Completion = a working tool where:**
```bash
# Human or Claude runs:
cleanup sync                              # Pull latest state
cleanup issues                            # See what needs fixing
cleanup fix products_missing_cost --auto  # Claude fixes all cost issues
cleanup log --last 50                     # Review what was changed
```

...with a searchable changelog showing every mutation made to Inflow data.

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
  "session": "cleanup-2024-01-15-001"
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
| `session` | Groups related fixes in a cleanup run |

**Why JSONL:**
- Append-only (no conflicts, no corruption)
- One line per entry (easy to grep, tail, stream)
- Human-readable and diffable in git
- Trivial to query with `jq`

**Releases:** For major milestones, attach the SQLite database to a GitHub release. The changelog stays lightweight in the repo; full DB snapshots go in releases.
