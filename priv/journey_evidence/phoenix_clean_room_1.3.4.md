# Phoenix clean-room advisory success — Rendro 1.3.4

The final accepted advisory attempt resolved exact public Rendro `1.3.4`, bound
to candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3` and prerequisite SHA
`505394af4ab54393ac06ac35592e8b2bfd935b3365983775191a2a7cca7278bf`.

The isolated consumer used Phoenix `1.8.12`, Plug `1.20.3`, Bandit `1.12.5`,
and the isolated Phoenix installer `1.8.5`. ConnCase completed before the
bounded loopback probe; both observed HTTP 200, `application/pdf`, attachment
`invoice.pdf`, nonempty bodies, and PDF magic. The disposable root and process
state were removed after projection.

Seven archived failed attempts remain under explicit `*_failed_attempt` names.
The prior dual-HTTP success is retained as
`phoenix_clean_room_1.3.4_pre_schema_success.json` (SHA-256
`a4f0e53e9c4d9a9afa14f8b3959e739522cbf5c644e81107f59d46bbf0b66f1d`),
rejected only because its evidence schema was incomplete. No paths, ports,
PIDs, bodies, caches, or secrets are retained.
