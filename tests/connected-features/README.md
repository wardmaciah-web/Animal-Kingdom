# Connected feature checks

These files are outside the Rojo `src` tree and are not production scripts.

Start a fresh Studio Play session with the existing ProfileService `AKUseMockProfiles=true` attribute. Wait for the profile to report `StudioMockSnapshot` and for Knit to start. Run `Core.server.lua` as a temporary server Script; read its `Result` attribute and destroy it. Run `Integration.server.lua` in a fresh mock session whose saved copy has Forest locked. It uses existing runtime services, mock funding, Studio-only reward injection, and sends a real Secret reveal to the test client. Inspect its `Result`, then destroy the test Script.

Run `Layout.client.lua` as a temporary LocalScript under the test player's PlayerGui. Read `Result`, then fire its `Cleanup` BindableEvent. These layout fixtures exercise seven usable-content sizes; they do not simulate real touch hardware, controller navigation, a notch, or a Lucky world model.

Stop Play to discard mock balances, pets, and progression. Do not run these tests against live profiles. Copy/JSON restoration does not prove durable datastore persistence. Missing special tree templates intentionally keep automatic Lucky Trees disabled.
