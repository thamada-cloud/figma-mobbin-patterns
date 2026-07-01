# Changelog

All notable changes to this skill are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2026-07-01

Initial release.

### Added
- **Core workflow** (`SKILL.md`): read a Figma design → find analogous UI patterns on
  Mobbin → build an annotated reference board on a new page in the same Figma file.
- **Per-screen coverage**: every distinct screen in a flow gets its own reference group
  (that screen's thumbnail beside up to 5 full-bleed, annotated Mobbin references).
- **Full-flow overview strip** per design option (all screens as thumbnails).
- **Source designs placed as screenshots** (not clones) — avoids unavailable-font failures.
- **"No close match found" callouts** so gaps are explicit, never silently omitted.
- **Per-option comparison notes** summarizing alignment with the patterns found.
- `scripts/prepare_images.sh` — download references, convert WebP→PNG, capture dimensions
  (`dims.tsv`) so cards are sized to true aspect ratio (no crop, no rounding).
- `scripts/post_uploads.sh` — POST images to Figma upload URLs and return `imageHash` +
  `placedOnNodeId`.
- `references/figma-board.md` — tested Figma Plugin-API code for building the board.
- Packaged as a Claude Code plugin + marketplace for install and updates.

### Known gotchas encoded in the skill
- Figma renders **WebP** image fills blank → convert to **PNG** first.
- `upload_assets` with a `nodeId` did not reliably set fills → use the no-`nodeId` route
  and paint the returned `imageHash`.
- Wrapping rows require `counterAxisSizingMode = "AUTO"` or they collapse to ~10px tall.

[Unreleased]: https://github.com/thamada-cloud/figma-mobbin-patterns/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/thamada-cloud/figma-mobbin-patterns/releases/tag/v0.1.0
