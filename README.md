# inflow-cleanup

AI-powered data governance for Inflow Inventory. Claude reviews, cleans, and maintains data consistency — issue by issue — with full audit trail.

## Quick Start

```bash
# Clone and install
git clone https://github.com/ldraney/inflow-cleanup.git
cd inflow-cleanup
npm install

# Download latest database snapshot from releases
curl -L https://github.com/ldraney/inflow-cleanup/releases/latest/download/inflow.sqlite -o data/inflow.sqlite

# Or sync fresh from Inflow API (requires credentials)
INFLOW_API_KEY=xxx INFLOW_COMPANY_ID=yyy npm run sync
```

## Database

The SQLite database is **not committed to git** (too large). Instead:

- **Latest snapshot**: Download from [Releases](https://github.com/ldraney/inflow-cleanup/releases/latest)
- **Fresh sync**: Run `npm run sync` with Inflow credentials

Place the database at `data/inflow.sqlite`.

## Architecture

See [CLAUDE.md](./CLAUDE.md) for full architecture and roadmap.

```
SQL Views (detect issues) → Claude Agent (resolve) → Changelog (audit trail)
```

## License

MIT
