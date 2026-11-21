extends RefCounted

# docs/spec/update-check.md「公钥表」: production public keys only, keyed by the manifest
# `key_id`. The maintainer generated the k1 pair offline and pasted only its public PEM (SPKI)
# here; no private key, passphrase or token may ever be committed to this repository, its tests,
# its logs or its documents. tests/update_cases.gd pins this table: exactly one entry, k1,
# loadable as public material, DER sha256 fixed.
#
# Each entry is one triple-quoted PEM literal: tools/sign-update-manifest.ps1 reads this file as
# text and refuses to sign with a private key whose public half differs from the entry the
# manifest's key_id names.
#
# Rotation: add the new public key as k2 beside k1 and ship a build that carries both, then
# switch the manifest key_id to k2; delete k1 only after every manifest signed with it has been
# replaced. A build only verifies the keys it carries.
const KEYS={
 "k1":"""-----BEGIN PUBLIC KEY-----
MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAnUmdoFqDxk5i+ukxgNc+
03HzOfU1iXIHEmEHPvNKX8KORwk1paHYdO/S0khiWqo7pWL81duZjrjg33+4aG04
lz/POgpK5FyYC3GqtzBsYJ6hqrDPoGtI8UHFn5fWOF2iiYrKukp8v3fr+5n+LGjZ
PAh+4QcaBoXhf2JuHlgUSA7GZx7VsfHsKn3CS2A3sfNp6wZs+3jRLbjxwZ6VCN3b
EqdHqX+i5E2c3pzKVekjXcMax3zVO3a9y/bgmX+9+c8degft9gS/rjUkYXAszvo8
srvP1O3HI2JyOLl2nZppsSN+w85u8EWFdXLwoX+kxhGHM+UrhSRw+GjTz1EyQkqF
nqwVow7ZQSOzKaFV5eGd7bXaRLNXiPDAJrFbpqvJGsjVs98drZ4k80TIfR8pYx1/
P1ehDKCSTKTS3QNghw7cuI23I2DBfBnw6LuVWjgA0g9IUWz9275k7RAz/NGN2Lgp
hEUZy4p1wvqYwfLccXkiJxhU7deXc8PnsRJ7SGj01M5zAgMBAAE=
-----END PUBLIC KEY-----
""",
}
