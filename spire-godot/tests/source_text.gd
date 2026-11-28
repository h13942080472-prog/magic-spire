extends RefCounted

# The one reader of scanned source text (tests/state_reader_scan.gd, tests/check_index.gd, tests/update_cases.gd):
# one commit must give one frozen fingerprint on an LF, a CRLF and a mixed checkout (the
# tracked blobs never contain CR), so for a blob with neither CR nor a BOM the value of
# normalized_text_sha256 equals the digest of the git blob (docs/spec/state-readers.md
# 「真源与唯一写者」, docs/spec/check-routing.md §4).
#
# Only CRLF pairs fold. A lone CR is a byte no checkout conversion touches, so it stays -- the
# same rule git's core.autocrlf applies. The BOM is handled by the read primitive: Godot 4.7.2
# drops a UTF-8 BOM, and the current input face has no BOM file. An unreadable path reads as ""
# (its digest is the empty text's digest): callers keep their existing empty-string handling, and
# the existence test keeps a missing scanned file from printing an engine error into an otherwise
# green run.
#
# Leaf module: no preload, no run(), no scan semantics. The frozen tables (tests/*.json) are
# read with FileAccess directly -- a JSON body does not depend on line endings.

static func normalized_text(path: String) -> String:
 if not FileAccess.file_exists(path): return ""
 return FileAccess.get_file_as_string(path).replace("\r\n","\n")

static func normalized_text_sha256(path: String) -> String:
 return normalized_text(path).sha256_text()
