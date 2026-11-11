# M3 requirements

- REQ-input: invalid input and EOF must be safe.
- REQ-finish: win, loss and final state are deterministic.
- REQ-flight: flat-ground projectile motion uses SI units and standard gravity.

- REQ-wind: numerical motion has bounded no-wind error and converges with smaller steps; the screen plots measured points and units.
- REQ-level: five placements follow from a fixed seed, are the same on every run, and each can be hit with a speed and angle inside the accepted input.
- REQ-reason: every result names the distance to the target and the wind's share of the landing.
- REQ-retry: r restarts the level and n starts the next; nothing of the previous attempt remains.

`make test` runs the native unit suite. `make check` adds a real command-line victory.
Reports are ignored under `test-results/<run>/` with the latest summary at `test-results/summary.json`.
Network services, graphics, audio and persistence are outside M1.
