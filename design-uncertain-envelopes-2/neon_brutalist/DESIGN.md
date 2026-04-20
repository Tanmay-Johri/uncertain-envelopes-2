# Neon Brutalist Design System

### 1. Overview & Creative North Star
**Creative North Star: "The Cyber-Tactile Ledger"**

The Neon Brutalist system is an editorial-first framework that combines high-energy terminal aesthetics with modern high-end layout principles. It rejects the "standard" rounded-pill SaaS look in favor of sharp, high-contrast intersections and a monochromatic base punctuated by a singular, radioactive brand color (#40f320). 

This design breaks the "template" look through:
*   **Intentional Friction:** High-tracking uppercase labels that demand attention.
*   **Asymmetric Density:** Grouping critical stats in compact grids while allowing headlines to breathe with significant letter spacing.
*   **The Glitch Contrast:** Juxtaposing an organic, high-end display face (Epilogue) with a rigid, technical typeface (Space Grotesk) for data and interaction.

### 2. Colors
The palette is dominated by "True Neutral" depths and a high-fidelity green, accented by a strong red for alerts.

*   **Primary (#40f320):** Used exclusively for success states, brand identity, and the most critical interactive triggers.
*   **Secondary (#FF3B30):** Reserved for destructive actions and high-priority alerts.
*   **Tertiary (#8d363c):** An additional accent for specific highlight or decorative elements.
*   **Neutral (#1F1F1F):** The foundational canvas color for the interface.
*   **The "No-Line" Rule:** Visual sectioning must be achieved via background shifts (e.g., moving from `surface` to `surface_container`). 1px borders are permitted only when using `white/5` or `white/10` opacities to create a "glass hairline" effect, rather than a structural wall.
*   **Surface Hierarchy:**
    *   `background`: The foundational canvas (matching Neutral #1F1F1F).
    *   `surface_container`: Used for primary interactive cards (#2A2A2A).
    *   `surface_container_low`: Used for disabled or read-only states with reduced opacity (50%).

### 3. Typography
The system uses a dual-font approach to signify the "Human vs. Machine" interface.

*   **Display/Headlines:** *Epilogue*. Used for brand titles and large headers. It provides a humanistic, premium touch to an otherwise cold interface.
*   **Interface/Body:** *Space Grotesk*. Used for all data, labels, and system messages. Its technical rhythm ensures that numerical stats (like "68%") feel precise.
*   **Labels:** *Space Grotesk*. For consistency with interface elements.

**Typography Scale (Calibrated):**
*   **Display (Header):** 0.875rem (14px), Weight 700, 0.2em tracking.
*   **Large Stat:** 1.5rem (24px), Weight 700.
*   **Body Base:** 1rem (16px) for high-readability text.
*   **Interface Label:** 0.75rem (12px), Weight 700, Uppercase, 0.1em tracking.
*   **Micro-Tag:** 10px, Uppercase, for secondary status (e.g., "Verified").

### 4. Elevation & Depth
Hierarchy is established through **Tonal Layering** and subtle material properties rather than traditional shadows.

*   **The Layering Principle:** Depth is created by stacking lighter surfaces on darker ones. An active card sits at `surface_container` on top of a `surface` background.
*   **Atmospheric Blur:** The `header` and `bottom_nav` utilize a `backdrop-blur-md` (blur-radius: 12px) with a 95% opacity background to simulate a frosted glass layer floating over the content.
*   **The Ghost Border:** Instead of deep shadows, use a `1px border border-white/10`. This creates a subtle highlight that defines edges in dark mode without adding visual bulk.
*   **Shadows:** The system avoids heavy drop shadows. Where used, they are restricted to 4px blur, 0px spread, black at 20% opacity.

### 5. Components
*   **Interactive Cards:** Rounded with a subtle curvature (1 on the 0-3 scale, for a more angular look than `rounded-xl`). Use `bg-surface-grey` with a hairline white border.
*   **Primary Buttons:** Full-width, 56px height. Should be either high-contrast `surface_container` with white text or specialized destructive `red-900/10` backgrounds.
*   **Status Badges:** Miniature (10px font), strictly uppercase, with a 1px border. No solid fills unless it is the "Primary" brand color.
*   **Input Fields:** Ghost-style. Defined by their background color shift rather than a heavy border box. Labels sit exactly 8px above the field.

### 6. Do's and Don'ts
*   **Do:** Use high tracking (letter-spacing) for all uppercase labels.
*   **Do:** Mix font families—Epilogue for brand, Space Grotesk for values.
*   **Don't:** Use standard gray borders (#CCCCCC). Only use white/black opacities to tint the underlying surface.
*   **Don't:** Use heavily rounded buttons for primary actions; stick to a subtle roundedness to maintain the architectural look.
*   **Do:** Ensure the Primary Green (#40f320) is used sparingly to maintain its "emergency" or "high-value" impact.
*   **Do:** Employ compact spacing to reinforce the "dense ledger" aesthetic.