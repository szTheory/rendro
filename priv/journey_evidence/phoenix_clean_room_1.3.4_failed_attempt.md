# Phoenix clean-room advisory evidence — Rendro 1.3.4

Outcome: **advisory failure**. The verified public prerequisite still binds exact
Rendro `1.3.4` and candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3` to
the successful protected `Release to Hex` publication (run `32763039854`,
publish job `97549444486`); it does not make the local Phoenix proof succeed.

The single bounded attempt created a unique empty root outside the repository
and home directory, then stopped at the API-only generator command because
`mix phx.new is unavailable` in this execution environment. No consumer app,
dependency cache, build, lockfile, server process, PDF, or response body was
retained. Therefore no public Hex source audit, ConnCase response, or loopback
response is claimed.

Next action: install the legitimate `phx_new` generator, then run the harness
once from a fresh empty isolated root. Until that succeeds, this record is an
advisory failure and JOURNEY/Nyquist remain red.
