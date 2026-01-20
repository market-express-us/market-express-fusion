# FusionAuth Deployment Automation

## What This Is

A CI/CD deployment system for FusionAuth authentication infrastructure serving the marketexpress.us B2B marketplace. Automates first-time setup and ongoing updates of FusionAuth with three pre-configured applications (admin, vendor, store) on dedicated server infrastructure, ensuring user data persistence across deployments.

## Core Value

Automated, repeatable FusionAuth deployment that preserves user data across configuration updates and version upgrades.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] First-time deployment via `make init` creates private Docker network, PostgreSQL database, and FusionAuth container
- [ ] Kickstart configuration automatically provisions three FusionAuth applications per specification
- [ ] GitHub Actions pipeline deploys to 15.204.91.25 on push to main branch
- [ ] Updates via `make update` apply configuration changes without data loss
- [ ] PostgreSQL schema migrations handled safely during updates
- [ ] FusionAuth version upgrades supported through update workflow
- [ ] Environment variables and secrets managed securely
- [ ] User authentication data persists across all deployment operations

### Out of Scope

- MercurJS integration code — Separate project implementing auth provider
- Elasticsearch deployment — Deferred until user search requirements defined
- B2C customer application activation — Future phase, infrastructure only
- FusionAuth Cloud deployment — Using self-hosted Docker approach
- Monitoring and alerting infrastructure — Phase 3 from specification
- Load testing automation — Phase 3 from specification

## Context

This project builds the authentication infrastructure for a multi-vendor B2B marketplace platform (MercurJS) that will scale to 2,000-30,000 vendor accounts with team member support. The architecture specification exists at `/Users/colin/Projects/market-express-project/specifications/FUSION-AUTH.md` and defines three actor types requiring separate authentication flows:

**Actor Types:**
- **Admin**: Platform administrators managing the marketplace
- **Vendor**: Seller users managing storefronts and fulfilling orders
- **Customer**: Future B2C shoppers (infrastructure prepared but inactive)

**FusionAuth Applications:**
- `marketexpress-admin` - Platform administration with required MFA
- `marketexpress-vendor` - Vendor operations with optional MFA and enterprise SSO
- `marketexpress-store` - Future customer authentication (inactive at launch)

**Single Tenant Architecture:** Per specification decision, all identities exist in one FusionAuth tenant with role-based access control, avoiding operational complexity of multi-tenant segmentation for this use case.

**Deployment Model:** Self-hosted FusionAuth on dedicated infrastructure rather than FusionAuth Cloud, providing control over deployment automation and infrastructure-as-code approach.

## Constraints

- **Target Server**: 15.204.91.25 (SSH user: fusion-auth)
- **Tech Stack**: Docker, docker-compose, PostgreSQL, FusionAuth, GitHub Actions, Make
- **CI/CD Platform**: GitHub Actions (must support SSH deployment to target server)
- **Data Persistence**: User database must survive all updates and configuration changes
- **Security**: Secrets (database passwords, FusionAuth API keys, client secrets) must not be committed to git
- **Network Isolation**: FusionAuth and PostgreSQL communicate over private Docker network
- **Specification Compliance**: Applications, roles, and configuration must match FUSION-AUTH.md specification

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Docker deployment vs FusionAuth Cloud | Infrastructure-as-code approach, cost control, deployment automation requirements | — Pending |
| Makefile interface (init vs update) | Clear separation between first-time setup and ongoing updates, familiar developer interface | — Pending |
| GitHub Actions for CI/CD | Specified CI/CD platform, integrates with git workflow | — Pending |
| Single tenant architecture | Per specification: avoids multi-tenant complexity without security benefit for marketplace use case | — Pending |
| PostgreSQL in Docker | Co-located with FusionAuth, lifecycle managed together, private network isolation | — Pending |
| Kickstart for configuration | FusionAuth's native configuration-as-code approach, enables repeatable deployments | — Pending |

---
*Last updated: 2026-01-20 after initialization*
