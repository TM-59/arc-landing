# Arc Landing

Choose a launch speed and angle to land within **30 ± 2 metres**, in at most three throws. Enter two numbers such as **17 45**. The result shows whether you landed short, long or on target. **q** or EOF exits; invalid input consumes no throw.

Julia calculates range, flight time and peak height from the analytic flat-ground projectile equations, with gravity 9.81 m/s² and no air resistance. M1 is a small numeric aiming game; wind, a trajectory plot and campaign are future work.

![Actual CLI output](docs/images/play.png)

Captured from the real CLI demo on 2026-11-06; its stdout is rendered in a monospace viewer for the image. The game runs in a terminal.

## Install and play

Linux x86-64, no sudo or containers. Install the current stable runtime as checked on 2026-11-06 ([Julia manual downloads](https://julialang.org/downloads/manual-downloads/)).

```sh
curl -fLO https://julialang-s3.julialang.org/bin/linux/x64/1.13/julia-1.13.3-linux-x86_64.tar.gz
curl -fLO https://julialang-s3.julialang.org/bin/checksums/julia-1.13.3.sha256
awk '$2 == "julia-1.13.3-linux-x86_64.tar.gz"' julia-1.13.3.sha256 | sha256sum -c -
mkdir -p "$HOME/.tools"
tar xzf julia-1.13.3-linux-x86_64.tar.gz -C "$HOME/.tools"
export PATH="$HOME/.tools/julia-1.13.3/bin:$PATH"
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate()'
```

Python 3.14 is required by the local report adapter. From this repository:

```sh
make play
make demo
make test
make check
```

`test` runs native unit tests; `check` also drives a real CLI victory. JUnit XML and schema-versioned summary JSON go to ignored `test-results/`. No test contacts a live service. PR CI runs unit checks only.

M2 and M3 are separate milestones. Terminal accessibility, Windows and macOS execution, long sessions and player enjoyment are unverified.

Verified on Linux: 14 native Test results + 1 CLI smoke, all passing. See [requirements](docs/requirements.md).
