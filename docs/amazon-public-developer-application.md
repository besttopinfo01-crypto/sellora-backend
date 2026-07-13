# Amazon Public Developer Application — Content Drafts

Two distinct pieces of required text, different audiences. Draft both now
(Day 1), refine later — neither is copying Amazon's own policy language,
which is a specific, confirmed requirement for the profile description.

---

## 1. Developer/app profile description (Seller Central form)

Audience: Amazon's app reviewers. Hard cap: 500 words. Word count below: ~300.

> Sellora.ai is a subscription web application built for Amazon
> Professional-plan sellers who need to combine multiple standalone listings
> into a single parent-child variation family — for example, five separate
> ASINs for the same shirt in five colors, unified into one listing with
> five child variations, instead of five listings competing against each
> other in search and splitting review history.
>
> This is a common, well-documented problem: sellers accumulate "orphaned"
> listings from catalogs inherited from a previous account manager, from
> agencies onboarding a client's existing products, or simply because they
> weren't aware Amazon's variation relationship existed when they first
> created listings. Amazon's own tools for creating these relationships
> after the fact are reported by many sellers to be difficult to use
> correctly, and a mistake can cost search ranking or review history.
>
> Sellora.ai connects to each subscribing seller's own Seller Central
> account using Amazon's standard Website Authorization Workflow (OAuth).
> Each seller's credentials are stored encrypted and isolated from every
> other seller's; nothing is shared across accounts. Once connected,
> Sellora.ai:
>
> - Reads the seller's real catalog data (Catalog Items API) to confirm
>   brand, product type, and existing variation relationships before
>   proposing any change
> - Reads and helps the seller set the listing attributes (Listings Items
>   API) needed to establish a variation relationship
> - Looks up the seller's own product category's valid variation themes and
>   attributes directly from Amazon (Product Type Definitions API), rather
>   than assuming a fixed list of themes
> - Submits the actual merge as a JSON_LISTINGS_FEED (Feeds API) — only
>   after the seller has reviewed a full preview and explicitly confirmed
>   four required statements, including that the merge is not intended to
>   manipulate reviews or rankings
>
> Sellora.ai's validation layer actively screens submitted merge requests
> for language associated with review manipulation and blocks those
> requests outright; it treats a brand-new, unreviewed ASIN joining an
> established family as a normal, expected pattern rather than a violation.
> Sellers can disconnect their Amazon account at any time from within
> Sellora.ai.
>
> Version 1 supports sellers whose variation catalogs use Size and/or
> Color; support for additional product categories is planned as a
> deliberate, later expansion once the core product is validated with real
> customers.

---

## 2. Public-facing website copy (the site itself, tied to domain setup)

Audience: prospective seller customers, and — since this is also what
satisfies the "public-facing website describing the service" requirement —
Amazon's reviewers looking at sellora.ai directly. Not built as a page yet,
just the copy; say the word and this becomes an actual one-pager once the
domain's live.

> # Sellora.ai
> ### Turn scattered listings into one real product family.
>
> If you're sitting on standalone ASINs that are really the same product —
> different colors, different sizes — Sellora.ai connects to your own
> Seller Central account and merges them into a proper parent-child
> variation listing, the way Amazon's own tools make surprisingly hard to
> do correctly.
>
> **How it works**
>
> 1. Connect your Amazon Seller account (standard Amazon OAuth — we never
>    see your password, and you can disconnect at any time)
> 2. Tell us which listings belong together and pick your variation theme
>    (Size, Color, or both)
> 3. We check your real listing data against Amazon's own rules before
>    anything is submitted, and show you exactly what will change
> 4. You approve, we submit, and we confirm the new family actually shows
>    up in your live catalog — not just that Amazon said "processing
>    complete"
>
> Built for Amazon Professional sellers. Version 1 supports Size and Color
> variations, with more categories on the way.
