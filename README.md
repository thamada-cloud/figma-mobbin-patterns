# figma-mobbin-patterns

A Claude Code skill that compares in-progress **Figma** designs against real-world UI patterns from **Mobbin**, then builds an annotated reference board on a **new page in the same Figma file** — mirroring each source screen next to shipped precedents.

For every design option it produces:
- a **full-flow overview strip** (every screen, as thumbnails),
- a **per-screen reference group** — each screen sits beside up to 5 full-bleed, annotated Mobbin references (app · what it is · pattern · note),
- explicit **"no close match found"** callouts where a screen has no precedent,
- a short **comparison note** per option.

## Requirements

This skill drives two MCP servers that must be connected in your Claude Code session:

- **Figma MCP** (official) — `get_metadata`, `get_screenshot`, `use_figma`, `upload_assets`. The target file must be writable by the connected account.
- **Mobbin MCP** — `search_screens`, `search_flows`, `search_sections`.
- A shell with `curl` and an image converter (`sips` on macOS, or `magick` / `convert` / `dwebp`).

## Install

In Claude Code:

```
/plugin marketplace add thamada-cloud/figma-mobbin-patterns
/plugin install figma-mobbin-patterns@thamada-design-skills
```

## Update

```
/plugin marketplace update thamada-design-skills
```

(new commits pushed here are picked up on update)

## Use

Just describe the task and include a Figma link (with a node selected):

> Look at these design options in Figma and pull similar patterns from Mobbin onto a new page: `<figma link>`

Or invoke explicitly: `/figma-mobbin-patterns <figma link>`

Steer it with phrases like *"cover every screen"*, *"iOS"* / *"web"*, *"up to 3 references each"*, or *"name the page [Competitive Analysis]"*.

## What's inside

```
skills/figma-mobbin-patterns/
├── SKILL.md                     # the workflow + when-to-trigger description
├── references/figma-board.md    # tested Figma Plugin-API code for building the board
└── scripts/
    ├── prepare_images.sh        # download references + convert WebP→PNG + capture dimensions
    └── post_uploads.sh          # POST images to Figma upload URLs, return image hashes
```

## Notes / gotchas baked into the skill

- Figma renders **WebP** image fills blank — everything is converted to **PNG** first.
- `upload_assets` with a `nodeId` didn't reliably set fills; the skill uses the no-`nodeId` route and paints the returned `imageHash`.
- Source designs are placed as **screenshots**, not clones (avoids unavailable-font failures).
- Wrapping rows must use `counterAxisSizingMode = "AUTO"` or they collapse.

## License

MIT — see [LICENSE](LICENSE).
