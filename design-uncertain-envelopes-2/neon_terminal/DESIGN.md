# Neon Terminal Design System

### 1. Overview & Creative North Star
**Creative North Star: The Sovereign Protocol**
Neon Terminal is a high-fidelity, data-driven design system inspired by financial trading floors and tactical military interfaces. It rejects the "softness" of consumer web design in favor of a rigid, high-contrast aesthetic that prioritizes speed of information processing and clarity. The system utilizes intentional asymmetry and a "command-line" typographic rhythm to create an environment of urgency and high stakes.

### 2. Colors
The palette is dominated by deep charcoals and blacks, punctuated by a hyper-vibrant "Radioactive Green" (`#40f320`) and a "Critical Red" (`#ff3b30`).

*   **The "No-Line" Rule:** Visual separation should be achieved through tonal shifts between `surface_container_low` and `surface_container`. Traditional 1px solid borders are strictly limited to interactive card boundaries and must use `outline_variant` at 10% opacity.
*   **Surface Hierarchy:** 
    *   `Background`: The void (#1f1f1f).
    *   `Surface Container`: For interactive modules (#2a2a2a).
    *   `Surface Container High`: For focused or active states.
*   **Signature Textures:** Use a 95% opacity blur on fixed headers to maintain context of the underlying data scroll. Glow effects (Box Shadows) are reserved exclusively for the Primary Action (`primary`).

### 3. Typography
The system employs a dual-font strategy to balance editorial impact with functional data display.

*   **Display/Headlines (Epilogue):** Used for brand identity and major section headings. It provides a humanistic but bold weight to the interface.
*   **Body/Labels/Mono (Space Grotesk/Fira Code):** Every piece of functional data is rendered in a monospace or high-readability sans-serif to evoke a terminal feel.

**Scale Ground Truth:**
*   **Hero Headline:** 1.875rem (30px) - Bold Epilogue.
*   **Section Header:** 1.5rem (24px).
*   **Terminal Input/Data:** 1rem (16px) - Monospace.
*   **Primary Body:** 0.875rem (14px).
*   **Micro-Labels:** 10px - All caps with 0.15em tracking.

### 4. Elevation & Depth
Depth is created through "Layered Luminosity" rather than physics-based shadows.

*   **The Layering Principle:** Instead of lifting objects "off" the page, we cut "into" the page or stack different shades of grey.
*   **Ambient Shadows:** We avoid heavy drop shadows. The only exception is the `shadow-sm` used on floating utility buttons and the signature `0 0 15px rgba(64, 243, 32, 0.3)` glow used for the "Start Game" call to action.
*   **Glassmorphism:** Navigation bars and sticky headers utilize `backdrop-blur-md` with a high-transparency surface color to maintain a sense of vertical scale.

### 5. Components
*   **High-Stakes Buttons:** Primary buttons are solid `primary` with black text. They must use `uppercase` and `tracking-widest` to signal importance.
*   **Data Modules:** Rectangular containers with `rounded-lg` (0.5rem) corners and a subtle `white/10` border.
*   **Status Badges:** Small, pill-shaped or subtle rectangles. Use `primary/20` backgrounds for "Active" states and `white/5` for "Static" states.
*   **Terminal Inputs:** Characterized by wide letter spacing and high-contrast text against a `surface_grey` background.
*   **Close/Utility Actions:** Floating circular or square buttons with high-contrast borders and minimal padding.

### 6. Do's and Don'ts
*   **Do:** Use extreme letter-spacing on micro-labels to enhance the "Technical" aesthetic.
*   **Do:** Maintain at least 24px of vertical spacing between major data sections.
*   **Don't:** Use gradients for surfaces; stick to solid, deep grays.
*   **Don't:** Use rounded corners exceeding 12px except for status pips or specific iconography.
*   **Do:** Use "Primary Green" sparingly as a "laser-pointer" to guide the user's eye to the most critical action on the screen.