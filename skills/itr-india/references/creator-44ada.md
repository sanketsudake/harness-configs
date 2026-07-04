# Presumptive taxation for creators & freelancers (44ADA / 44AD)

Content creators, freelancers, consultants, and independent professionals can
usually declare income **presumptively**, avoiding books of account and audit if
they stay within the limits. This is almost always the right choice for a
small/medium creator.

## 44ADA vs 44AD — pick the right one

- **Section 44ADA (profession):** for *specified professions* and, importantly,
  the CBDT notified-profession codes that include creators. Presumptive income =
  **50%** of gross receipts. Limit: gross receipts up to **₹50L** (₹75L if ≤5%
  of receipts are in cash). The relevant business code for online creators is
  **16021 – "Social media influencers"** (a *profession* code).
- **Section 44AD (business):** for eligible businesses (traders, small biz).
  Presumptive income = **8%** of receipts, or **6%** for receipts via banking/
  digital channels. Limit: turnover up to ₹2cr (₹3cr if ≤5% cash).

**Critical gotcha:** code **16021 is a profession code and appears only under the
44ADA dropdown**, not the 44AD one. If you start under 44AD you will not find
16021 and will be tempted to mis-classify. For a social-media creator, choose
**44ADA + 16021** and declare 50%. It is the cleaner, lower-audit-risk fit for
profession income, even though 44AD's 6% would show a lower number — don't pick a
section just because its percentage is smaller; pick the one that legally fits.

## Building gross receipts

Gross receipts = every rupee earned from the activity in the FY:

- platform payouts (Stripe/YouTube/X/PayPal/brand deals), summed from the payout
  files **and** confirmed against bank credits, plus
- any TDS-deducted contract/professional receipts visible in 26AS (194C/194J).

Avoid double counting: a payout already captured inside a 26AS entry counts once.

```
# Illustrative figures only.
Contract receipt (26AS 194C)      20,000
Platform payouts (bank-confirmed) 30,000
Gross receipts (44ADA 62i)        50,000
Presumptive income @ 50% (62ii)   25,000
```

## Where it goes in ITR-3

- **Part A – P&L, item 62** (44ADA): enter business code 16021, gross receipts
  (62i, split by mode a/b/c), and presumptive income 62ii (50%, or higher if the
  user genuinely earned more — 50% is the floor, not a cap).
- **Schedule BP**: the presumptive income flows to BP item 35ii (44ADA) → A37 →
  D ("Income chargeable under PGBP"). It should equal the 50% figure.
- **Part A – Balance Sheet, item 6 (no-account case):** because income is
  declared presumptively with no books, you **must** fill the "no books of
  account" block — sundry debtors, sundry creditors, stock-in-trade, and **cash
  balance**. Leaving all four at zero triggers a **validation defect** that
  blocks the return (see `portal-workflow.md`). For a service creator with no
  inventory: debtors/creditors/stock = 0, and put a sensible positive **cash
  balance** (the net profit retained is a clean, defensible figure). This is a
  disclosure field; it does not change the tax.

## If receipts exceed the presumptive limit, or profit is genuinely below the %

- Above ₹50L (44ADA) / ₹2cr (44AD): presumptive is unavailable; the user needs
  regular books and possibly a 44AB tax audit — escalate, this is beyond a quick
  self-file.
- If the user's real profit is **below** 50% / 8%, declaring the lower actual
  profit requires maintaining books and a tax audit. Most small creators simply
  declare the presumptive % and move on.
