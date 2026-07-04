# Reconciling income to source documents

The single most important discipline: **one number per income head, each tied to
a document**. Build a small reconciliation table and don't move on until every
figure has a source and the figures cross-tie. AIS/26AS are starting points, not
gospel — they can miss income (under-threshold banks, foreign platforms) and can
double-count (e.g., the same payout seen by two reporters).

## The documents and what each gives you

- **Form 16** (from each employer): gross salary 17(1), perquisites 17(2),
  TDS deducted, regime opted. The Part B has the breakup.
- **Form 26AS**: tax credit statement — every TDS/TCS entry against the PAN,
  plus the deductor (TAN) and section (192 salary, 194C contract, 194J
  professional, 194-IB rent, etc.). Use it to confirm TDS and to discover payers.
- **AIS / TIS** (Annual Information Statement): a wider feed — interest,
  dividends, securities transactions, mutual-fund purchases, salary, etc. Often
  has OCR-only PDFs; extract carefully.
- **Bank statements**: the ground truth for interest credited and for tracing
  platform payouts. Search for the interest credit lines and total them per bank.
- **Broker / capital-gains statement**: realised STCG/LTCG with buy/sell dates,
  cost, and STT flag.
- **Platform payout files** (Stripe/PayPal/YouTube/X/etc.): the creator/freelance
  gross receipts. Sum them and **cross-check the total against the bank credits**
  so you know the money actually landed.

## How to reconcile each head

**Salary:** Sum gross 17(1) across all Form 16s = total gross salary. Confirm
each against the 26AS salary (192) entries. Subtract the single ₹75,000 standard
deduction (new regime). The result is income chargeable under "Salaries".

**Business/profession receipts:** Add every professional/contract receipt: 26AS
194C/194J entries **plus** platform payouts that weren't subject to TDS. Watch
for overlap — a payout already inside a 26AS entry must not be counted twice.
The sum is gross receipts; the presumptive income is a % of it
(see `creator-44ada.md`).

**Interest:** Total the interest credits from **every** bank statement, not just
the ones in AIS. Add HDFC + SBI + PNB + … = total savings-bank interest. In the
new regime there is no 80TTA, so the whole amount is taxable. If a small bank's
interest is absent from AIS, it still goes in — flag it to the user.

**Capital gains:** From the broker statement, per scrip: sale value − cost =
gain, with the dates (for holding period) and STT flag (for 111A/112A special
rates). Cross-check the sale proceeds credit in the bank.

**Dividends:** From AIS / broker; taxable at slab rate in Schedule OS.

## Worked reconciliation pattern (illustrative)

```
# Illustrative figures only — not anyone's real return.
SALARY
  Employer A (Form 16 / 26AS-192)             6,00,000
  Employer B (Form 16 / 26AS-192)             9,00,000
  Gross salary                               15,00,000
  − standard deduction                         −75,000
  Income from Salary                         14,25,000

BUSINESS (profession, presumptive 44ADA)
  Contract receipt (26AS 194C)                  20,000
  Platform payouts (bank-confirmed)             30,000   ← Σ payouts = bank credits
  Gross receipts                                50,000
  Presumptive income @ 50%                      25,000

CAPITAL GAINS (STCG, listed equity, STT paid)
  Sale 40,000 − cost 25,000                     15,000

OTHER SOURCES (interest)
  Bank A 3,000 + Bank B 2,000 + Bank C 5,000    10,000   ← a bank below the AIS threshold → still declared

TOTAL INCOME                                 14,75,000
```

The point of the table is that an auditor (or the user) can follow every rupee
back to a document. If a number can't be sourced, stop and find the source.

## Mismatches — what to do

- **AIS shows income you can't trace:** ask the user; it may be a duplicate, a
  joint-account entry, or genuinely theirs. Don't silently drop it.
- **Income you have but AIS doesn't:** declare it anyway (see SKILL.md).
- **TDS in 26AS but no matching income:** find the income — TDS implies a
  payment was made to the PAN.
- **Foreign-platform money received in INR in India:** generally Indian-source
  business income for a resident; it is not "foreign income" merely because the
  payer is abroad. Treat the foreign-asset/foreign-income questions on their
  own facts and flag any genuine foreign asset for Schedule FA.
