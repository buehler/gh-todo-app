# Design System Specification: The Engineering Editorial

## 1. Overview & Creative North Star
**Creative North Star: "The Precise Artisan"**

This design system moves away from the utilitarian, density-packed interfaces typically associated with developer tools. Instead, it adopts an "Editorial Tech" aesthetic—where the precision of Git-based workflows meets the high-end breathing room of a premium consumer experience. 

We break the "standard dashboard" template through **intentional asymmetry** and **tonal layering**. The system prioritizes the "quiet" moments of project management, using generous whitespace to frame complex technical data. By rejecting rigid grid lines in favor of background shifts and soft depth, we create an environment that feels less like a spreadsheet and more like a curated workspace.

---

## 2. Colors & Surface Philosophy
The palette is a sophisticated evolution of the GitHub identity, utilizing "Deep Sea" blues and "Slate" grays to provide a sense of authority and calm.

### The "No-Line" Rule
**Borders are a design failure.** To achieve a high-end feel, designers are prohibited from using 1px solid borders to section content. Boundaries must be defined through:
*   **Background Shifts:** Placing a `surface_container_low` card on a `surface` background.
*   **Tonal Transitions:** Using the hierarchy of surface tokens to create "zones" of focus.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. Each layer deeper into the workflow should feel more "recessed" or "elevated" through color, not lines.
*   **Base Layer:** `surface` (#f7f9ff) — The canvas.
*   **Content Sections:** `surface_container_low` (#ecf4ff) — Large grouping areas.
*   **Interactive Cards:** `surface_container_lowest` (#ffffff) — High-priority actionable items.
*   **Modals/Floating Elements:** `surface_bright` with Glassmorphism.

### The "Glass & Gradient" Rule
To inject "soul" into the technical nature of the app:
*   **CTAs:** Use a subtle linear gradient from `primary` (#0051ae) to `primary_container` (#0969da) at a 135° angle. This adds a tactile, pressurized feel to buttons.
*   **Overlays:** Use semi-transparent `surface_container_highest` with a `20px` backdrop-blur for a "frosted glass" effect on navigation bars and floating action menus.

---

## 3. Typography
We utilize a dual-typeface system to balance technical clarity with editorial character.

*   **Display & Headline (Manrope):** Our "Brand Voice." Manrope provides a modern, geometric clarity that feels more consumer-friendly than standard system fonts. Use `headline-lg` for project titles to create a strong, authoritative anchor.
*   **Title & Body (Inter):** Our "Functional Voice." Inter is chosen for its exceptional legibility in dense data environments (issue tracking, commit hashes).
*   **The Hierarchy Strategy:** Use high-contrast sizing. A `display-sm` project title should sit confidently above a `body-sm` metadata string, creating a clear entry point for the eye.

---

## 4. Elevation & Depth
We eschew traditional Material Design shadows in favor of **Tonal Layering** and **Ambient Diffusion**.

*   **The Layering Principle:** A `surface_container_lowest` card sitting on a `surface_container_low` background creates a natural, soft "lift" without a single pixel of shadow. This is the preferred method for list items.
*   **Ambient Shadows:** When an element must float (e.g., a New Issue FAB), use an extra-diffused shadow: `box-shadow: 0 12px 32px rgba(20, 28, 37, 0.06);`. The shadow color is a low-opacity tint of `on_surface`, making it feel like it's part of the environment.
*   **The "Ghost Border" Fallback:** If accessibility requires a container boundary, use `outline_variant` at **15% opacity**. It should be felt, not seen.

---

## 5. Components

### Buttons
*   **Primary:** Gradient fill (`primary` to `primary_container`), `xl` roundedness, `title-sm` (Medium weight).
*   **Secondary:** `surface_container_high` fill with `on_surface_variant` text. No border.
*   **Tertiary:** Ghost style. `on_primary_fixed_variant` text, no background. Use for "Cancel" or "Archive" actions.

### Task Cards & Issue Lists
*   **Structure:** No dividers. Use `16px` or `24px` of vertical whitespace to separate items.
*   **Interaction:** On press, a card should shift from `surface_container_low` to `surface_container_highest`.
*   **Priority Indicators:** Instead of loud labels, use a `4px` vertical "accent strip" on the far left of the card using `tertiary` (High Priority) or `primary` (Standard).

### Input Fields
*   **Minimalist State:** A simple `surface_container_low` background with `sm` roundedness. No bottom line.
*   **Active State:** Background shifts to `surface_container_lowest` with a subtle `2px` "Ghost Border" using `primary_fixed`.

### Specific App Components
*   **Commit-Stream Chip:** A small, `full` rounded chip using `secondary_container` background and `label-sm` Inter for displaying abbreviated hashes.
*   **Status Blips:** Soft, glowing pips using `on_tertiary_container` (for alerts) or `primary` (for active work), utilizing a `4px` outer glow of the same color at 30% opacity.

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical margins (e.g., more padding on the left than the right in certain headers) to create an editorial feel.
*   **Do** lean into `surface_container` variations to group related GitHub issues rather than using lines.
*   **Do** use `manrope` for numbers and metrics; the geometric nature makes data look premium.

### Don't
*   **Don't** use pure black (#000000). Use `on_background` (#141c25) to maintain the deep-sea tonal depth.
*   **Don't** use standard 1px dividers between list items. Use the spacing scale to create separation.
*   **Don't** use high-saturation reds for error states. Use the sophisticated `error` (#ba1a1a) which feels integrated into the palette.