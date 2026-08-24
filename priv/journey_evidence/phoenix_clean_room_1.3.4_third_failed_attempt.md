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

The second failure is also retained byte-for-byte as
`phoenix_clean_room_1.3.4_second_failed_attempt.{json,md}` (JSON SHA-256
`e36e6671dfe69a3c783bc4ce069708b650e089e8d27f1fc5f4d0b4666f2a5b51`,
transcript SHA-256
`1d008406a451b23ff99462dcc5da2888dee49954c8dc1927b322d4198efe6a6c`).

After the `.ez` audit repair, one new fresh-root attempt again failed closed
with `phx_new_source_missing` before any Phoenix consumer was generated. No
retry was performed. Investigate that isolated archive inspection before
authorizing another attempt. Until one succeeds, this record is an advisory
failure and JOURNEY/Nyquist remain red.
