# Phoenix clean-room advisory evidence — Rendro 1.3.4

Outcome: **advisory failure**. Exact public `1.3.4` remains bound to candidate
`f03c78bab54efe1cd1596d51cf3f28193232e2a3` and protected release run
`32763039854`/publish job `97549444486`.

The six prior bounded failures are retained under the explicit
`phoenix_clean_room_1.3.4_*_failed_attempt.{json,md}` names. Attempt 6 is
byte-for-byte preserved in `sixth_failed_attempt` (JSON SHA-256
`80a69cb16d783a59f0ca6be4d04d7db4812b562bc91a36309f358f2585a0abda`,
transcript SHA-256
`5b4b639156a7ed6351431663a2103be2bf024cda1bc072ca86ab11111d71afed`).
Earlier attempts record the isolated `phx_new_source_missing` boundary.

The one new fresh-root attempt passed isolated generator setup, dependency
resolution, and the exact lock boundary, then failed during the generated
consumer test command. No ConnCase or loopback response is claimed, no retry
was performed, and no app/cache/build/lock/PDF/process state was retained.
JOURNEY/Nyquist remain red.
