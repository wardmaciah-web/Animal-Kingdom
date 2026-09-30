# Side action button edge cleanup — 2026-09-23

This targeted change applies to the existing Shop, Daily and Teleport stack (left on desktop, right in compact layouts), plus Friends, Updates and Profile at the top right. Quests and Codes do not currently have a live implementation; no fake destinations were added. The separate Admin Room capsule already uses native rounded primitives and does not use the faulty image shell.

## Cause

The generic WoodButton compressed a large baked wood/bevel image into 56–76-pixel side controls using a 9-slice shell. Its separate selected panel used different bounds/corners. The focus ring extended three pixels past the button on each edge, plus its stroke, while hover scaled the whole hit target to 1.035. The utility stack had only three pixels between buttons, and its notification badge also extended outside its root. Those independent silhouettes could overlap and expose uneven baked edge shading. No duplicate game systems or overlapping menu instances were involved.

## Change

`AnimalKingdomUIV2/SideActionButton.lua` now owns the reusable side shell, exposed as `Components.SideActionButton` and `Components.SideNavButton`.

- Transparent ImageButton hit target with no shell image, no default auto tint, rounded corners and clipping.
- Inset rounded backplate and body; only one outline is visible at a time.
- The existing wood asset supplies **only border-free interior grain**, using a center crop. It no longer defines the outline or uses 9-slice scaling on these buttons.
- Body, grain and focus use the same 14-pixel corner radius. Focus replaces the normal rim at identical bounds.
- Icons, labels and circular count badges fit inside the visual; the badge supports `9+` without changing the shell. The phone screenshot review prompted a second iteration: badge diameter now adapts from 21 pixels on desktop to 16 pixels on compact buttons so it does not crowd the icon.
- All visual-state tweens share one cancellation channel per target. Hover changes the body evenly; press shrinks the centered visual inward to .975 and returns to 1. Hit bounds never grow into adjacent buttons.
- Disabled/pending controls retain a transparent root, preventing the default gray background from reappearing.
- Both utility and top-right groups use UIListLayout with eight-pixel gaps. Portrait navigation clears the taller utility stack.

Theme owns side radius, insets, stroke widths, spacing, colors and state duration. The optional presentation hooks in Components.Bind retain the existing activation/audio/cleanup behavior for other controls. Bottom navigation and large wood panels keep their existing style.

## Verification

Desktop native input exercised hover, held press, selected Daily, all three utility menu actions, twelve rapid enter/leave cycles and a held press cancelled outside the button. All six side/header controls had zero overflowing child rectangles/strokes; settled scale was 1, root transparency 1 and both group gaps eight pixels.

Xbox device simulation visually reviewed normal, focus, selected and maximum badge states. GuiService focus passed for all six controls, with the normal rim disabled while the focus rim was shown. This is visual/focus verification, not hardware A/B certification.

Final iPhone Play checks used 749×361 landscape and a temporary client-only 401×777 portrait stress view. All three landscape actions and portrait Daily/Teleport opened the correct menu and closed normally through native pointer input. Compact controls remained 56×49 with eight-pixel separation, a 16×16 badge and zero overflowing descendants/strokes. Portrait navigation clears the last side button by eight pixels. Production `LandscapeSensor` was preserved. A maximum-badge/selected/focus combination was captured and visually inspected after the badge-size correction.

Disabled and pending probes kept root transparency at 1 and the shell image empty. Restoring the control returned the normal body color, scale 1, Active/Selectable true and Pressed false. The final console contains the previously documented missing-pet catalog warnings, with no new UI runtime exception.

All four affected modules compile and match the live Edit sources byte-for-byte. Rojo build succeeds. No gameplay service, profile data or uploaded asset was changed. Studio was restored to **Edit**, the original camera and default device view, with no temporary QA instances. Nothing was published.

Automation note: one Studio MCP Play start stalled; native Studio Play recovered it. An initial phone pointer probe omitted the simulator offset at a one-pixel-rounded viewport width. That harness offset was corrected and the native menu checks were rerun successfully; neither issue required game logic changes.

Evidence: [desktop states](desktop-states.json), [desktop containment and actions](desktop-containment-qa.json), [Xbox focus](xbox-focus-qa.json), [desktop](desktop-normal.png), [selected](desktop-selected.png), [Xbox focus/badge](xbox-selected-badge.png).


Final evidence: [phone landscape](phone-landscape.png), [phone portrait](phone-portrait.png), [compact focus/badge](phone-badge-focus.png), [landscape actions/containment](phone-landscape-qa.json), [portrait actions/spacing](phone-portrait-qa.json), [disabled/pending](disabled-pending-qa.json), [source verification](final-source-verification.json), [Edit state](final-edit-state.json).

For another real side destination:

```lua
local button = W.SideActionButton(parent, name, icon, size, position, callback)
local setBadge = W.NotificationBadge(button) -- optional, call once
W.Selected(button, isSelected)
setBadge(count)
```

Keep side actions on this component; do not put the old 9-slice shell or another selected-background Frame over it.
