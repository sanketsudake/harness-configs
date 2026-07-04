# Virtual Digital Assets (VDA) — crypto, NFTs, tokens

VDAs (cryptocurrency, NFTs, and similar tokens) have their own hard-edged regime
under **Section 115BBH**, separate from normal capital gains. It is unusually
unfavourable, and several "obvious" tax moves are explicitly disallowed — so get
this right and set expectations with the user. Re-confirm current-year rules; this
area is still evolving.

## The core rules (Section 115BBH)

- **Flat 30% tax** on income from transfer of any VDA, **+ 4% health & education
  cess** (effective 31.2%). The 30% applies in **both** the old and new regime —
  the regime choice does not change VDA tax.
- **No deductions except cost of acquisition.** You cannot deduct mining costs,
  electricity, internet, exchange fees, infra, or any expense other than what you
  paid to acquire the coin/asset.
- **No set-off of losses.** A loss on one VDA **cannot** be set off against gain
  on another VDA, nor against any other income, and **cannot be carried forward**.
  Each profitable transfer is taxed; losing transfers give no relief. (This is the
  current statutory position — flag it clearly, people are routinely surprised.)
- **No 87A rebate, no basic-exemption benefit** against VDA income — the 30% bites
  from the first rupee of gain.
- **Gifts of VDA** received without consideration are taxable in the recipient's
  hands under Section 56(2)(x) if above the threshold.

## TDS — Section 194S

A **1% TDS** applies on the transfer of a VDA (above small thresholds). Indian
exchanges deduct it; in peer-to-peer/foreign-exchange trades the buyer may be
responsible. This 1% TDS shows up in **26AS / AIS** and is claimed as a credit in
the return — reconcile it like any other TDS, and use the AIS VDA feed to make
sure no transfer is missed.

## Where it goes in the return

- VDA income is reported in **Schedule VDA** (available in ITR-2 and ITR-3). If
  the user has *any* VDA transfer, they generally cannot use ITR-1/ITR-4.
- **Each transfer is one line**: date of acquisition, date of transfer, cost of
  acquisition, consideration received, and income (consideration − cost, floored
  so losses don't offset other gains).
- The head is **Capital Gain** for an investor, or **Business income** for someone
  trading as a business — Schedule VDA splits the totals accordingly. Most
  individuals report it as capital gains.
- The total flows into Schedule SI (special rate 115BBH @ 30%) and Part B-TTI.

## Practical reconciliation

1. Pull the full transaction/tax report from each exchange (and wallet records for
   off-exchange trades).
2. For each **sale/transfer**, compute consideration − cost = gain (per asset, per
   transaction). Sum only the **positive** incomes for the taxable figure — losses
   are ignored, not netted.
3. Cross-check the 1% **194S TDS** against 26AS/AIS and claim the credit.
4. Compute tax = total positive VDA income × 30% × 1.04 (cess), independent of the
   slab tax on the rest of the income, and reconcile against the portal.

> Because losses can't offset and there's no expense deduction, the VDA number is
> often higher than people expect. There's little legitimate room to "reduce" VDA
> tax — the honest job here is to capture every transfer accurately (under-reporting
> crypto is heavily data-matched via AIS/exchanges) and claim the 1% TDS credit.
