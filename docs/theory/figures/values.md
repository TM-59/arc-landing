# Measured values

Written by `make theory-figs` (scripts/theory_figs.jl) from the functions of src/ArcLanding.jl. Do not edit by hand.
SI units; gravity 9.81 m/s^2. The last column is the relative error; where the theory column is 0 it is the absolute value.

| id | what is measured | measured | theory | error |
|---|---|---|---|---|
| `range-10-45` | range at 10 m/s and 45 degrees [m] (theory v^2 / g) | 10.19368 | 10.19368 | 0.00e+00 |
| `apex-10-45` | apex of the same throw [m] (theory v^2 sin^2 / 2g = 25 / g) | 2.54842 | 2.54842 | 2.22e-16 |
| `time-10-45` | its time of flight [s] (theory 2 v sin / g) | 1.441604 | 1.441604 | 0.00e+00 |
| `complementary` | range at 20 m/s and 30 degrees over range at 60 degrees (theory 1) | 1 | 1 | 0.00e+00 |
| `best-angle` | angle of the largest range at 17 m/s among 1..89 degrees (theory 45) | 45 | 45 | 0.00e+00 |
| `wind-shift--2.0` | range at 17 m/s, 45 degrees with wind -2.0, minus the no-wind range, dt = 0.001 [m] (theory wind x T^2 / 2) | -6.006062 | -6.0060622 | 3.31e-08 |
| `wind-shift-1.2` | range at 17 m/s, 45 degrees with wind 1.2, minus the no-wind range, dt = 0.001 [m] (theory wind x T^2 / 2) | 3.6036372 | 3.6036373 | 3.31e-08 |
| `wind-shift-2.0` | range at 17 m/s, 45 degrees with wind 2.0, minus the no-wind range, dt = 0.001 [m] (theory wind x T^2 / 2) | 6.006062 | 6.0060622 | 3.31e-08 |
| `best-angle-wind` | angle of the largest range at 17 m/s with the game's wind +1.2 (above 45: staying up longer pays; theory 45 + atan(wind / g) / 2) | 48 | 48.487006 | 1.00e-02 |
| `time-unchanged` | time of flight with wind 2 over the time without (theory 1: the wind is horizontal) | 1 | 1 | 0.00e+00 |
| `points-on-path` | largest distance component between a stored point before landing and the exact position at its time, dt = 0.2 [m] (theory 0: the update is exact for constant acceleration) | 7.1054274e-15 | 0 | 7.11e-15 |
| `points-count` | points stored for that throw, the landing point included | 13 | 0 | 1.30e+01 |
| `apex-sampled` | apex reported with dt = 0.2 over the exact apex (the largest stored height: at or below the true apex) | 0.99991941 | 1 | 8.06e-05 |
| `landing-order` | slope of log(worst range error) against log(dt) between dt = 0.1 and 0.0125 (theory 2) | 2.0005771 | 2 | 2.89e-04 |
| `landing-error-game` | worst range error at the game's dt = 0.02 over speeds 16..18 m/s [m] (it stays under the bound of the next row) | 0.00055050531 | 0 | 5.51e-04 |
| `landing-bound-game` | the bound g dt^2 / 8 x (landing vx / landing vy) at 18 m/s, 45 degrees, dt = 0.02 [m]: the chord of a parabola lies at most g dt^2 / 8 below it | 0.0006105 | 0 | 6.11e-04 |
| `landing-demo` | range of the demonstration throw 16.5 m/s at 45 degrees, as the game computes it [m] (theory v^2 / g + wind T^2 / 2) | 31.14693 | 31.14707 | 4.49e-06 |
| `landing-early` | sign of (numerical time - exact time) for that throw: the chord meets the ground before the parabola does (theory -1) | -1 | -1 | 0.00e+00 |
| `shallow-points` | points stored for the shallowest, slowest throw (1 m/s at 1 degree) asked with dt = 0.2 (theory 3: start, one in the air, landing) | 3 | 3 | 0.00e+00 |
| `shallow-range` | its range over the exact range (theory 1: one step to the apex, one interpolated) | 1 | 1 | 0.00e+00 |
| `shallow-apex` | its reported apex over the exact apex (theory 1: the shortened step lands on the apex) | 1 | 1 | 2.22e-16 |
| `steep-ground` | height of the last stored point of the steepest, fastest throw (theory 0) | 0 | 0 | 0.00e+00 |
| `steep-above` | lowest stored height of that throw (theory 0: never below ground) | 0 | 0 | 0.00e+00 |
| `hit-speed-low` | slowest speed on a 0.05 grid that hits at 45 degrees [m/s] | 15.65 | 0 | 1.57e+01 |
| `hit-speed-high` | fastest such speed [m/s] | 16.7 | 0 | 1.67e+01 |
| `hit-28` | hit(28) (theory 1: the ends of the target count) | 1 | 1 | 0.00e+00 |
| `hit-32` | hit(32) (theory 1) | 1 | 1 | 0.00e+00 |
| `hit-just-outside` | hit just below 28 plus hit just above 32 (theory 0) | 0 | 0 | 0.00e+00 |
| `game-won` | won after the demonstration throw (theory 1) | 1 | 1 | 0.00e+00 |
| `game-frozen` | attempts after a further throw at a won game (theory 1: nothing more is counted) | 1 | 1 | 0.00e+00 |
| `game-three` | attempts after five misses (theory 3: the game stops at three) | 3 | 3 | 0.00e+00 |
| `input-rejected` | of ten out-of-range calls, how many raise ArgumentError (theory 10) | 10 | 10 | 0.00e+00 |
| `input-accepted` | of four calls on the edges of the allowed ranges, how many are rejected (theory 0) | 0 | 0 | 0.00e+00 |
| `input-no-throw` | throws consumed by three invalid lines followed by one valid throw (theory 1) | 1 | 1 | 0.00e+00 |
| `input-eof` | throws consumed when the input ends at once (theory 0) | 0 | 0 | 0.00e+00 |
| `screen-rows` | rows of the character plot (theory 7) | 7 | 7 | 0.00e+00 |
| `screen-width` | characters per row after the axis bar (theory 51) | 51 | 51 | 0.00e+00 |
| `screen-target` | T characters on the bottom row: the target 28..32 m at 40 m per 50 columns (theory 6 columns) | 6 | 6 | 0.00e+00 |
| `screen-stars` | columns holding at least one star: the flight is drawn from measured points | 39 | 0 | 3.90e+01 |
| `level-count` | placements (theory 5) | 5 | 5 | 0.00e+00 |
| `level-first` | centre of level 1 [m] (theory 30: the M2 game) | 30 | 30 | 0.00e+00 |
| `level-same-seed` | levels() called twice gives equal placements (theory 1) | 1 | 1 | 0.00e+00 |
| `level-other-seed` | placements 2..5 that differ under seed 1 (reported) | 4 | 0 | 4.00e+00 |
| `level-reachable` | levels hit by a 45 degree throw at a speed rounded to 0.1 m/s (theory 5) | 5 | 5 | 0.00e+00 |
| `level-speed-low` | smallest of those five speeds [m/s] (allowed: 1..30) | 11.990613 | 0 | 1.20e+01 |
| `level-speed-high` | largest of those five speeds [m/s] (allowed: 1..30) | 21.923662 | 0 | 2.19e+01 |
| `level-wind-low` | most leftward wind of the five [m/s^2] (allowed: -3..3) | -1.8 | 0 | 1.80e+00 |
| `level-wind-high` | most rightward wind of the five [m/s^2] | 1.2 | 0 | 1.20e+00 |
| `reason-wind` | wind share reported for the demonstration throw [m]: range with wind minus range without | 3.3947607 | 0 | 3.39e+00 |
| `reason-shown` | the message of that throw names the wind share (theory 1) | 1 | 1 | 0.00e+00 |
| `restart-clean` | after two throws, restart equals a fresh game on the same level: attempts, message, points (theory 1) | 1 | 1 | 0.00e+00 |
| `restart-attempts` | attempts after restart (theory 0) | 0 | 0 | 0.00e+00 |
| `next-level` | level after next_level from level 3 (theory 4) | 4 | 4 | 0.00e+00 |
| `next-wraps` | level after next_level from level 5 (theory 1) | 1 | 1 | 0.00e+00 |
| `finished-ignores` | throws counted when a throw is entered after a win, in the real loop (theory 1) | 1 | 1 | 0.00e+00 |
