extends RefCounted

# docs/spec/update-check.md「公钥表」: production public keys only, keyed by the manifest
# `key_id`. The maintainer generates the pair offline and pastes the public PEM here (U1b);
# no private key, passphrase or token may ever be committed to this repository, its tests,
# its logs or its documents.
#
# The table is empty until that key exists. An empty table answers every manifest with
# `{"kind":"none","reason":"key"}` — that is the correct answer, not a failure to hide.
const KEYS={}
