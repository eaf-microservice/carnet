# Design System Document: The Editorial Ledger

## 1. Overview & Creative North Star
### Creative North Star: "The Financial Architect"
In the world of retail ledgers, clarity is a commodity. Most applications settle for "functional," resulting in cluttered, spreadsheet-like interfaces. This design system rejects the "flat grid" in favor of **The Financial Architect**—a philosophy that treats financial data as high-end editorial content. 

We break the "template" look by utilizing intentional asymmetry, sophisticated tonal layering, and a dramatic typography scale. By balancing the weight of deep authoritative blues with the lightness of emerald accents, we create a space that feels like a premium banking lounge rather than a digital filing cabinet. We don't just display numbers; we architect trust.

---

## 2. Colors & Surface Philosophy
The palette is built on high-contrast authority. Deep blues provide the "anchor," while emerald greens offer "clarity" and "growth."

### The "No-Line" Rule
**Explicit Instruction:** 1px solid borders are prohibited for sectioning. Boundaries must be defined solely through background color shifts.
*   *Correct:* A `surface-container-low` (#f2f4f5) sidebar sitting against a `surface` (#f8fafb) main content area.
*   *Incorrect:* Using `#737780` (outline) to draw a line between sections.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—stacked sheets of frosted glass or fine paper.
*   **Base:** `surface` (#f8fafb)
*   **Secondary Content:** `surface-container-low` (#f2f4f5)
*   **Actionable Cards:** `surface-container-lowest` (#ffffff)
*   **High-Priority Overlays:** `surface-bright` (#f8fafb)

### Signature Textures: The "Glass & Gradient" Rule
To elevate the ledger from "utility" to "premium," use subtle linear gradients for primary actions. 
*   **Primary CTA Texture:** A linear gradient from `primary` (#001e40) to `primary_container` (#003366) at a 135-degree angle.
*   **Emerald Highlights:** Use `secondary` (#006c48) for successful transactions, but apply a 10% opacity `secondary_container` (#8bf8c2) as a background wash to create a "glow" effect rather than a harsh block of color.

---

## 3. Typography
We utilize a dual-font system to balance authority with utility. **Manrope** provides a modern, geometric headline feel, while **Inter** ensures maximum readability for dense financial data.

*   **Display (Manrope):** Use `display-lg` (3.5rem) for total balance overviews. The large scale creates a sense of "financial weight."
*   **Headlines (Manrope):** `headline-md` (1.75rem) should be used for section headers like "Monthly Revenue" or "Customer Directory."
*   **Body & Labels (Inter):** All ledger entries use `body-md` (0.875rem). Use `label-md` (0.75rem) in `on-surface-variant` (#43474f) for secondary metadata (e.g., timestamps).

**The Editorial Shift:** Increase the letter-spacing of `label-sm` by 0.05rem and use uppercase for category headers to create an architectural, organized feel.

---

## 4. Elevation & Depth
Depth is achieved through **Tonal Layering** rather than structural scaffolding.

*   **The Layering Principle:** Place a `surface-container-lowest` (#ffffff) card on top of a `surface-container-low` (#f2f4f5) background. This creates a soft, natural "lift" that mimics the way high-quality paper sits on a desk.
*   **Ambient Shadows:** For floating elements (like a "New Entry" FAB), use a shadow with a 24px blur and 4% opacity, tinted with the `on-surface` (#191c1d) color. Avoid pure black shadows.
*   **The "Ghost Border" Fallback:** If accessibility requires a container boundary, use the `outline-variant` (#c3c6d1) at **15% opacity**. It should be felt, not seen.
*   **Glassmorphism:** Use `surface_container_lowest` at 80% opacity with a `backdrop-filter: blur(12px)` for navigation bars. This allows the emerald and blue accents of the content to bleed through as the user scrolls.

---

## 5. Components
### Buttons
*   **Primary:** Gradient (Primary to Primary-Container), `DEFAULT` (0.5rem/8px) roundedness. No border.
*   **Secondary:** `surface-container-high` (#e6e8e9) background with `on-primary-fixed-variant` (#1f477b) text.
*   **Tertiary:** No background. Use `primary` (#001e40) text with 600 weight.

### Input Fields
*   **Styling:** Instead of a full box, use a `surface-container-highest` (#e1e3e4) background with a 2px bottom-accent in `outline-variant` (#c3c6d1) that turns `secondary` (#006c48) on focus.
*   **Padding:** Use Spacing `3.5` (0.75rem) for internal vertical padding.

### Cards & Ledger Lists
*   **The No-Divider Rule:** Forbid the use of line dividers between transactions. Use Spacing `2.5` (0.5rem) of vertical white space and alternating subtle background shifts (`surface` to `surface-container-low`) to separate line items.
*   **Data Density:** Use `title-sm` (1rem, Inter) for currency values to ensure they are the most legible element in the row.

### Financial Progress Bar
*   **Track:** `surface-container-highest` (#e1e3e4).
*   **Indicator:** `secondary` (#006c48) with a subtle outer glow using `secondary_fixed` (#8bf8c2) at 30% opacity.

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical spacing. A wider left margin (Spacing `12`) versus a tighter right margin (Spacing `8`) creates a modern, editorial look.
*   **Do** use `secondary` (#006c48) sparingly. It is a "signal" color for profit and completion; overusing it dilutes its psychological impact of "clarity."
*   **Do** leverage `surface-tint` (#3a5f94) at low opacities (3-5%) over white backgrounds to "cool" the interface and align it with the deep blue brand identity.

### Don't
*   **Don't** use pure black (#000000) for text. Always use `on-surface` (#191c1d).
*   **Don't** use 90-degree corners. Everything must adhere to the `DEFAULT` (0.5rem/8px) scale to maintain the "Modern Professional" persona.
*   **Don't** use standard "Success Green." Use the specified Emerald `secondary` (#006c48) to maintain the high-end financial aesthetic.