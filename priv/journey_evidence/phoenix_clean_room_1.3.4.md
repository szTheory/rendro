# Phoenix clean-room advisory evidence — Rendro 1.3.4

Outcome: **advisory failure**. The verified public prerequisite still binds exact
Rendro `1.3.4` and candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3` to
the successful protected `Release to Hex` publication (run `32763039854`,
publish job `97549444486`); it does not make the local Phoenix proof succeed.

The first bounded attempt is preserved byte-for-byte as
`phoenix_clean_room_1.3.4_failed_attempt.{json,md}` (JSON SHA-256
`8cb4a6a1d00e7b1160531ac3a01b8bbf989e16d9d84e1601a5d69134dfe57436`,
transcript SHA-256
`c42d9969dc6aaecefb60a753438230130ff63110398390f63efcbf682c3cc13f`). It
stopped because the generator was unavailable.

The single repaired attempt bootstrapped exact `phx_new` `1.8.5` only inside a
new isolated Mix home, then failed closed at the archive-source audit with
`phx_new_source_missing`: the disposable archive layout did not match the
expected isolated `phx_new-1.8.5` path. No consumer app, dependency cache,
build, lockfile, server process, PDF, or response body was retained. Therefore
no public Hex source audit, ConnCase response, or loopback response is claimed.

No retry was performed. Correct the bootstrap archive-layout audit, then run
one new approved advisory attempt from a fresh empty isolated root. Until that
succeeds, this record is an advisory failure and JOURNEY/Nyquist remain red.
