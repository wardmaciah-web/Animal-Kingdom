# Right gameplay buttons: whole-button replacement

The inspected Play client contained the old nested Body and highlight plus three duplicate `CleanAKButtonVisual` frames in each right-side button. Gradients and overlapping shells were still present.

`AnimalKingdomUIV2/RightHudButton.lua` now constructs Friends, Updates and Profile directly as solid TextButtons. Each has exactly one UICorner (12 px), one UIStroke (2 px), one atlas icon and one label. There are no background images, nested Frames, gradients, backplates or extra focus borders. Hover/press/selection change the whole background; controller focus changes the existing border color.

`HUD.lua` uses this component only for the right-hand trio. The existing action callbacks and shared mouse/touch/controller/audio binding are preserved. All three buttons are 62 × 62 with 8 px spacing. Their mobile row clears the existing utility stack, navigation and jump control. Admin Room uses a different component and was left alone. No other source files changed.

Validation: both modules compile and match the verified Studio place (132313449035787). Fresh Play showed one copy of each button and no obsolete visual descendants. Normal, native hover/held press/cancel, selected and controller-focus appearances were inspected. Updates and Profile opened and closed their existing dialogs through native clicks; Friends retains its original invite callback. No invitations were sent. iPhone landscape and portrait were inspected; a second fresh Play confirmed the final landscape placement and readable labels.

- [Desktop](normal.png)
- [Pressed](pressed.png)
- [Selected/focus](selected-focus.png)
- [iPhone landscape, final fresh Play](iphone-landscape.png)
- [iPhone portrait](iphone-portrait.png)
- [Structure/state/layout checks](qa.json)
- [Action checks](actions.json)
- [Final source and Studio verification](final-verification.json)

Final Studio state: Edit, device simulation off, original viewport camera restored. Nothing published.
