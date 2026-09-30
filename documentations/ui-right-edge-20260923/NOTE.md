# Right-side edge fix

Scoped only to Friends, Updates and Profile via `HUD` passing `{SingleSurface=true}` to `SideActionButton`. Their offset backplate, full-size grain overlay and second focus shell are absent. One rounded native Frame and one UIStroke now define both edges in every state. Existing palette, icons, labels, actions and positions are preserved. Admin Room uses another shell and was not changed; left controls, bottom navigation and top bars were not changed.

Play checked normal, native hover/held press/cancel, selected and focus states. Each right button retained exactly one fill and one stroke, with no backplate, texture shell or extra focus border. Enlarged visual inspection: [close-up](edge-closeup.png). [State checks](qa.json). Three affected sources compile and match Studio. Final state: Edit, original camera restored, no publication.
