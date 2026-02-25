# WS-Seeker — Estimated Monthly Run Cost

## App Profile

| Metric | Estimate |
|--------|----------|
| Active wholesale customers | 5–10 |
| Orders per month | 10–40 |
| Products in catalog | ~300 |
| Admin users | 2–3 |
| Transactional emails/month | 20–40 |
| Proof of payment uploads/month | 10–40 (small images) |

---

## Service Breakdown

### Cloud Run (Backend)

| | Free Tier | Our Usage | Cost |
|---|-----------|-----------|------|
| Requests | 2M/month | ~2,000–5,000 | **$0** |
| CPU | 180,000 vCPU-seconds | ~500–2,000 vCPU-sec | **$0** |
| Memory | 360,000 GiB-seconds | ~1,000–4,000 GiB-sec | **$0** |
| Egress | 1 GB (North America) | < 100 MB | **$0** |

Single container, 256 MB RAM, 1 vCPU, min-instances=0. Stays well within free tier.

Beyond free tier: $0.000024/vCPU-sec, $0.0000025/GiB-sec, $0.40/million requests.

### Firestore (Database)

| | Free Tier | Our Usage | Cost |
|---|-----------|-----------|------|
| Document reads | 50,000/day | ~500–2,000/day | **$0** |
| Document writes | 20,000/day | ~50–200/day | **$0** |
| Document deletes | 20,000/day | ~0–10/day | **$0** |
| Storage | 1 GiB | < 50 MB | **$0** |

~300 product docs + ~40 orders/month + ~40 invoices/month + comments. Trivial volume.

Beyond free tier: $0.06/100K reads, $0.18/100K writes, $0.02/100K deletes, $0.18/GB storage.

### Firebase Hosting (Frontend)

| | Free Tier | Our Usage | Cost |
|---|-----------|-----------|------|
| Storage | 10 GB | ~50 MB (WASM bundle) | **$0** |
| Bandwidth | 10 GB/month | < 500 MB | **$0** |

Flutter Web WASM build is ~30–50 MB. With 10–15 users loading the app a few times/month, bandwidth is minimal.

### Firebase Authentication

| | Free Tier | Our Usage | Cost |
|---|-----------|-----------|------|
| Monthly active users | 50,000 MAUs | ~15 | **$0** |

Magic link (email) auth only — no SMS costs.

### Cloud Storage (Proof of Payment Uploads)

| | Free Tier | Our Usage | Cost |
|---|-----------|-----------|------|
| Storage | 5 GB | < 100 MB | **$0** |
| Class A ops (uploads) | 5,000/month | ~10–40 | **$0** |
| Class B ops (downloads) | 50,000/month | ~50–200 | **$0** |
| Egress | 100 GB | < 1 GB | **$0** |

Proof of payment screenshots are typically 100 KB–2 MB each.

### Resend (Transactional Email)

| | Free Tier | Our Usage | Cost |
|---|-----------|-----------|------|
| Emails | 3,000/month | 20–40 | **$0** |
| Domains | 1 | 1 | **$0** |

Order confirmations, invoice notifications, payment received, shipped notifications.

---

## Total Estimated Monthly Cost

| Service | Monthly Cost |
|---------|-------------|
| Cloud Run | $0 |
| Firestore | $0 |
| Firebase Hosting | $0 |
| Firebase Auth | $0 |
| Cloud Storage | $0 |
| Resend Email | $0 |
| **Total** | **$0/month** |

All services fit comfortably within their free tiers at this scale.

---

## When Would Costs Start?

| Trigger | Threshold | Estimated Cost |
|---------|-----------|----------------|
| Many more customers | > 50,000 MAU | Firebase Auth: $0.0055/MAU |
| Heavy API traffic | > 2M requests/month | Cloud Run: ~$0.40/million |
| Large file storage | > 5 GB uploads | Cloud Storage: $0.020/GB/month |
| High email volume | > 3,000 emails/month | Resend Pro: $20/month |
| Large Firestore dataset | > 1 GiB stored | Firestore: $0.18/GB/month |

At 10x current scale (~100 customers, 400 orders/month), costs would still likely be **< $5/month**.

---

## Notes

- All pricing as of February 2026, Blaze (pay-as-you-go) plan.
- Cloud Run uses min-instances=0, so idle periods incur zero cost.
- Custom domain (if used) is the only hard cost — typically ~$12/year from a registrar.
- No paid third-party services (no Stripe, no paid analytics, no paid monitoring).
