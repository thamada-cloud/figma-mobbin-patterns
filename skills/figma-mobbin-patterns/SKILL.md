---
name: figma-mobbin-patterns
description: >-
  Compare in-progress Figma designs against real-world UI patterns and build a
  Mobbin reference board on a new page in the same Figma file — mirroring the
  source designs alongside the references and annotating each. Use this whenever
  the user wants to validate design directions against existing apps, find
  similar/precedent/competitive design patterns for screens or flows in a Figma
  file, pull references from Mobbin, or export/populate example screens onto a
  separate page in Figma. Trigger for phrasing like "find similar patterns", "do
  other apps do this", "pull Mobbin references", "benchmark these designs against
  real apps", "add a competitive-analysis / references page", or any request that
  pairs Figma designs with precedent research — even if Mobbin is not named
  explicitly.
---

# Figma ↔ Mobbin Pattern References

Take design options (or a set of screens) from a Figma file, find analogous real-world UI patterns on Mobbin, and build a **new page in the same Figma file** that mirrors each source design beside its matching references, annotates everything, and flags where no good match exists. Someone opening the page sees each design direction, what shipped apps do, and whether the direction follows a proven pattern.

**Lean by default** — this skill is tuned to keep runs fast and cheap. The dominant cost is *vision* (examining Mobbin result images and verification screenshots), so: request a small number of candidates, verify once at the end, and keep the source as a screenshot rather than a live clone.

## Tools this relies on

- **Figma MCP** (official server): `get_metadata`, `get_screenshot`, `use_figma`, `upload_assets`. Writing needs the file writable by the connected account.
- **Mobbin MCP**: `search_screens`, `search_flows`, `search_sections` (web).
- A shell with `curl` + an image converter (`sips` on macOS, else `magick`/`convert`/`dwebp`).

Load the **figma-use** skill before the first `use_figma` call (Plugin API rules: font loading, auto-layout, `setCurrentPageAsync`, returning node IDs).

## Workflow

Steps 1–4 are judgment; 5–8 are mechanical and mostly scripted.

### 1. Understand the source designs — and record their node IDs
Get the file key from the URL (`figma.com/design/<fileKey>/...`). `get_screenshot` the linked node for an overview; `get_metadata` for structure (if it overflows, save it and parse with a script — group top-level frames by `y` to find rows/options). **Record the node ID of each design option / screen** — you'll screenshot these onto the new page in step 7.

### 2. Enumerate the design options / screens to cover
List each option and its distinct screen states (entry, compose, confirmation, success, empty, permission…). Match references against this list so coverage is demonstrable. (If the set is large, it's fine to confirm with the user which screens matter most rather than doing every one.)

### 3. Search Mobbin — cover every screen
Run a search **for each distinct screen** you enumerated in step 2 — not just the option's entry/defining screen. Coverage is per-screen: the entry, the compose/typing state, the recording state, the confirmation dialog, the success/empty state, etc. each get their own search. `limit` ~6 (fewer images in context = faster, cheaper). Query rules: describe ONE screen in plain language; set `platform` explicitly; name specific apps to bias results; avoid negations/vague style words. Use `search_flows` for journeys, `search_sections` for web. **Look at the returned images** — relevance is visual.

### 4. Curate — up to 5 per screen, honest about gaps
Keep **up to 5** genuinely relevant references **for each distinct screen**, strongest first, varied apps. The cap is per-screen, not per-option — a 6-screen flow can have far more than 5 references total. A reference can be reused across screens if it genuinely illustrates both. Don't pad weak matches. If a screen has *no* close analogue, record it — you'll render a "No close match found" callout in step 7. Say what you dropped.

### 5. Prepare images — PNG, full-bleed (no crop, no rounding)
**Figma renders WebP fills BLANK — always convert to PNG.** References must show the **whole uncropped screenshot**, so cards are sized to each image's true aspect ratio.

Also **screenshot every screen of each option's flow** (`get_screenshot` on the frame IDs from step 1 — get the URLs without reading them into context) and treat those as extra images in the same batch. The source goes on the board as screenshots, not live clones (simpler, and avoids font-availability failures that break cloning).

Write a `name|url` manifest (references + one `*_SOURCE` entry per design), then:
```bash
scripts/prepare_images.sh <manifest.txt> <outdir>
```
Downloads, converts to PNG, writes `<outdir>/dims.tsv` (`name  width  height`). Use dims in step 7 to size each card (`height = round(cardWidth * h / w)`). (Figma screenshot asset URLs are short-lived — download them within the run.)

### 6. Upload to Figma and capture hashes
`upload_assets` with `count=<N>` and **no `nodeId`** (commits the bytes; the `nodeId` route didn't reliably set fills). Pair returned `submitUrl`s with names, then:
```bash
scripts/post_uploads.sh <submit_manifest.txt> <outdir>
```
Prints `name|imageHash|placedOnNodeId`. Keep the `imageHash` (paint it) and `placedOnNodeId` (throwaway frame to delete).

### 7. Build the reference page
`use_figma`; read **references/figma-board.md** for exact code. Build incrementally, return node IDs, name the page to match the file's convention. Each section, in order:

1. **A full-flow overview strip.** Screenshot *every* screen in the option's flow (frame IDs from step 1) as a horizontal row of small thumbnails (~160px, `cornerRadius:0`) under a "Your design — full flow (N screens)" label — the flow at a glance.
2. **Per-screen reference groups — one per distinct screen.** For each screen in the flow, a group: a small "Your screen" thumbnail of that screen + up to 5 **full-bleed, square-cornered** reference cards for *that specific screen* (`cornerRadius:0`, height from `dims.tsv`, `scaleMode:"FILL"`). This is the core of per-screen coverage — the entry screen gets entry references, the recording screen gets voice-record references, the confirmation screen gets dialog references, etc.
3. **Annotations on every card** — a title line (`App · what the app is`) and a detail line (`Pattern:` + short `Note:`).
4. **Explicit gap callouts** — for any screen with no close match, a "No close match found on Mobbin" note (nearest thing seen + how it differs). Never silently omit.
5. **A comparison note** at the end of the section — 1–3 sentences: does this option align overall with the patterns found? Where does it diverge, and is that intentional/risky?

(No recommendation section — the per-section comparison notes carry the analysis.)

Use wrapping rows for the references. Delete the `placedOnNodeId` auto-frames when done.

### 8. Verify — once
Take **one** `get_screenshot` of the finished board (or a representative section if it's tall) and look. Only screenshot again if something's actually wrong. Blank cards ⇒ still WebP or uncommitted hash. Clean up scratch files.

## Gotchas

- **WebP → blank.** Convert to PNG. #1 failure mode. See [[figma-image-upload-webp]].
- **`upload_assets` + `nodeId` may not set the fill.** Use the no-`nodeId` route, capture the hash, paint it yourself.
- **No crop / no rounding on references:** size cards to true aspect ratio, `cornerRadius:0`. Fixed-height + `FILL` crops — don't.
- **Source = screenshot, not clone.** Cloning breaks when a source uses an unavailable font (e.g. `sf pro text`) and is slower; a screenshot always works and looks the same on the board.
- **Wrapping rows must hug vertically:** after `layoutWrap="WRAP"`, set `counterAxisSizingMode="AUTO"` — a fixed row height collapses wrapped cards to ~10px.
- **zsh vs bash:** run the scripts with `bash`. Load fonts before text. Switch pages with `await figma.setCurrentPageAsync(page)`. Place the board away from (0,0). Many sections ⇒ lay them in a multi-column grid so the board isn't excessively tall.

## Output shape

A new page: title + intro, then one section per design option — each with a full-flow overview strip, then a per-screen reference group for every distinct screen (that screen + up to 5 annotated full-bleed references for it, or a no-match callout), and a closing comparison note. Cite each `mobbin_url` back to the user in chat.
