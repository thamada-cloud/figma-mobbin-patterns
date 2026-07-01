# Building the reference board with `use_figma`

Tested Plugin-API code. Build **incrementally** — one `use_figma` call per step, and `return` every created node ID. Load `figma-use` first. All calls take `fileKey` and `skillNames: "figma-use"`.

Each design-option section, top to bottom: **(a)** the source design as a compact full-flow strip of ~160px thumbnails ("Your design — full flow"), **(b)** up to 5 annotated full-bleed reference cards (or a no-match callout), **(c)** a comparison note. No recommendation section — the comparison notes carry the analysis.

## Shared helpers (paste into each call that needs them)

```js
const INK={r:0.09,g:0.09,b:0.11}, SUB={r:0.42,g:0.42,b:0.47}, ACC={r:0.72,g:0.11,b:0.11};
const txt=(s,size,style,color,w)=>{const t=figma.createText();t.fontName={family:"Inter",style};t.characters=s;t.fontSize=size;t.fills=[{type:"SOLID",color}];if(w){t.textAutoResize="HEIGHT";t.resize(w,t.height);}return t;};
const CARD_W=280;
// Full-bleed, square-cornered image card with a two-line annotation.
// dims {w,h} from dims.tsv → height is exact so the screenshot is never cropped.
function imgCard(hash, dims, title, detail, titleColor){
  const card=figma.createAutoLayout("VERTICAL"); card.itemSpacing=8; card.fills=[]; card.name="card:"+title;
  const img=figma.createFrame(); img.name="img"; img.resize(CARD_W, Math.round(CARD_W*(dims.h/dims.w)));
  img.cornerRadius=0; img.clipsContent=true;                          // no rounding
  img.fills=[{type:"IMAGE",imageHash:hash,scaleMode:"FILL"}];          // FILL at true ratio = no crop
  card.appendChild(img); img.layoutSizingHorizontal="FIXED";
  card.appendChild(txt(title,13,"Semi Bold", titleColor||INK, CARD_W));
  card.appendChild(txt(detail,12,"Regular",SUB,CARD_W));
  return card;
}
```

## Step A — Skeleton: page + board + one empty section per option

```js
// ...load Inter Regular/Semi Bold/Bold, helpers above...
const page=figma.createPage(); page.name="[Mobbin Patterns] [<initials>] [<MM/DD>]";
await figma.setCurrentPageAsync(page);
const board=figma.createAutoLayout("VERTICAL");
board.name="Mobbin Pattern References"; board.x=400; board.y=200; board.itemSpacing=40;
board.paddingTop=56;board.paddingBottom=56;board.paddingLeft=56;board.paddingRight=56;
board.fills=[{type:"SOLID",color:{r:0.98,g:0.98,b:0.99}}]; board.cornerRadius=24;
const title=txt("<Feature> — Mobbin Pattern References",40,"Bold",INK); board.appendChild(title); title.layoutSizingHorizontal="HUG";
board.appendChild(txt("Each section shows the source design (left), then up to 5 real-world references from Mobbin — full-bleed and annotated — with a comparison. Curated <date>.",18,"Regular",SUB,1000));
const OPTIONS=[{k:"A",h:"Design A — <name>"},{k:"B",h:"Design B — <name>"}];
const secIds={};
for(const o of OPTIONS){
  const sec=figma.createAutoLayout("VERTICAL"); sec.name="Section "+o.k; sec.itemSpacing=18;
  sec.paddingTop=32;sec.paddingBottom=32;sec.paddingLeft=32;sec.paddingRight=32;
  sec.fills=[{type:"SOLID",color:{r:1,g:1,b:1}}]; sec.cornerRadius=16;
  board.appendChild(sec); sec.layoutSizingHorizontal="HUG";
  const h=txt(o.h,26,"Semi Bold",INK); sec.appendChild(h); h.layoutSizingHorizontal="HUG";
  secIds[o.k]=sec.id;
}
return { pageId: page.id, boardId: board.id, secIds };
```

## Step B — Fill a section: source card + references + comparison note

The source is a screenshot (uploaded in the same batch as the references — no cloning). `srcHash`/`srcDims` come from the `*_SOURCE` image; `cards` is `[hash, {w,h}, title, detail]`.

```js
await figma.loadFontAsync({family:"Inter",style:"Regular"});
await figma.loadFontAsync({family:"Inter",style:"Semi Bold"});
const page=await figma.getNodeByIdAsync("<PAGE_ID>"); await figma.setCurrentPageAsync(page);
const sec=await figma.getNodeByIdAsync("<SECTION_ID>");

// (a) source design as a compact FULL-FLOW strip (every screen of the option, ~160px thumbnails)
const yd=figma.createAutoLayout("VERTICAL"); yd.itemSpacing=10; yd.fills=[]; sec.appendChild(yd);
yd.appendChild(txt("Your design — full flow (N screens): <one-line flow summary>",13,"Semi Bold",ACC,1400));
const strip=figma.createAutoLayout("HORIZONTAL"); strip.itemSpacing=10; strip.fills=[]; yd.appendChild(strip);
strip.layoutWrap="WRAP"; strip.counterAxisSpacing=10; strip.layoutSizingHorizontal="FIXED"; strip.resize(1740,10); strip.counterAxisSizingMode="AUTO"; // AUTO so it hugs; wraps if very long
const flow=[["<srcHash1>",423,860],["<srcHash2>",375,812] /* every screen, in order */];
for(const [h,w,ht] of flow){ const f=figma.createFrame(); f.resize(160,Math.round(160*ht/w)); f.cornerRadius=0; f.clipsContent=true; f.fills=[{type:"IMAGE",imageHash:h,scaleMode:"FILL"}]; strip.appendChild(f); f.layoutSizingHorizontal="FIXED"; }

// (b) per-screen reference groups — ONE GROUP PER DISTINCT SCREEN in the flow.
// Each group = a sub-heading + a row that starts with a small "Your screen" thumbnail
// then up to 5 full-bleed references for THAT screen.
function screenGroup(subhead, srcHash, srcDims, refs){
  sec.appendChild(txt(subhead,15,"Semi Bold",INK,1400));
  const row=figma.createAutoLayout("HORIZONTAL"); row.itemSpacing=16; row.fills=[]; sec.appendChild(row);
  row.layoutWrap="WRAP"; row.counterAxisSpacing=24; row.layoutSizingHorizontal="FIXED"; row.resize(1740,10);
  row.counterAxisSizingMode="AUTO";   // REQUIRED after resize, else wrapped rows collapse to ~10px
  const yc=imgCard(srcHash, srcDims, "Your screen", "(this design)", ACC); row.appendChild(yc); yc.layoutSizingHorizontal="HUG";
  for(const [hash,dims,t,d] of refs){ const c=imgCard(hash,dims,t,d); row.appendChild(c); c.layoutSizingHorizontal="HUG"; }
}
screenGroup("① Entry — <what the screen is>", "<srcHashEntry>", {w:423,h:860}, [
  ["<hash>", {w:299,h:678}, "App · what the app is", "Pattern: … Note: …"],
  // up to 5 for THIS screen
]);
// screenGroup("② Compose — …", …);  screenGroup("③ Confirmation — …", …);  // one per distinct screen
// Build ~2 groups per use_figma call to stay within node limits.

// (c) comparison note
sec.appendChild(txt("Comparison: <does this align with the patterns found? where does it diverge? intentional/risky?>",14,"Regular",{r:0.2,g:0.2,b:0.24},1000));
return { done:true };
```

If a section is large, split it across calls (source card first, then references in batches of ~4–5) — return the ref-row id so later calls can append to it.

## Step C — "No close match" callout (use when a screen has no good analogue)

```js
const sec=await figma.getNodeByIdAsync("<SECTION_ID>");
const box=figma.createAutoLayout("VERTICAL"); box.itemSpacing=6; box.paddingTop=16;box.paddingBottom=16;box.paddingLeft=16;box.paddingRight=16;
box.cornerRadius=12; box.fills=[{type:"SOLID",color:{r:0.99,g:0.96,b:0.96}}];
box.strokes=[{type:"SOLID",color:{r:0.88,g:0.7,b:0.7}}]; box.strokeWeight=1; box.dashPattern=[6,4];
sec.appendChild(box); box.layoutSizingHorizontal="FIXED"; box.resize(560,10);
box.appendChild(txt("⚠︎ No close match found on Mobbin — <screen>",14,"Semi Bold",{r:0.72,g:0.11,b:0.11},520));
box.appendChild(txt("Nearest seen: <app/pattern>, but it differs because <reason>. Likely a novel/uncommon pattern worth extra scrutiny.",13,"Regular",{r:0.42,g:0.42,b:0.47},520));
return { calloutId: box.id };
```

## Step D — Delete the throwaway auto-frames

```js
const ids=[/* placedOnNodeId values from post_uploads.sh */];
const deleted=[]; for(const id of ids){ const n=await figma.getNodeByIdAsync(id); if(n){ n.remove(); deleted.push(id); } }
return { deleted };
```

## Notes

- **No crop / no rounding:** cards use `cornerRadius:0` and a height from the image's real dimensions. Never force a fixed height with `FILL` — that crops.
- **Up to 5 references per pattern**, strongest first; don't pad weak matches.
- **Source = full-flow screenshot strip**, not a clone — screenshot every screen of the option and lay them as ~160px thumbnails. Avoids font-availability failures, is faster, and shows the whole flow compactly. (A single-screen pattern is just one thumbnail.)
- **Wrapping rows:** always `counterAxisSizingMode="AUTO"` after `resize`, or wrapped cards collapse to ~10px.
- **Web references:** landscape — the `imgCard` helper handles any ratio via `dims.tsv`.
- **Many sections?** Lay them in a 2–3 column grid so the board isn't excessively tall.
- **Verify once** at the end with `get_screenshot`; blank card ⇒ still WebP or uncommitted hash.
