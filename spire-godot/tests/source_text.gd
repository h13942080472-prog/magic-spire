extends RefCounted

# The one reader of scanned source text (tests/state_reader_scan.gd and tests/check_index.gd).
# A frozen fingerprint must not depend on the checkout's line endings: one commit is checked out
# with CRLF here (core.autocrlf=true) and with LF upstream, while the tracked blobs never contain
# CR. Normalizing the text before hashing or scanning makes a frozen digest equal to the digest of
# the git blob, so one commit has one value on an LF, a CRLF or a mixed checkout
# (docs/spec/state-readers.md「真源与唯一写者」, docs/spec/check-routing.md §4「扫描输入」).
#
# Only CRLF pairs fold. A lone CR and a BOM are bytes no checkout conversion touches, so they stay
# -- the same rule git's core.autocrlf applies. An unreadable path reads as "": the callers keep
# their existing empty-string handling, and the existence test keeps a missing scanned file from
# printing an engine error into the log of an otherwise green run.
#
# Leaf module: no preload, no run(), no scan semantics. The frozen tables (tests/*.json) are read
# with FileAccess directly -- a JSON body does not depend on line endings.

static func normalized_text(path: String) -> String:
 if not FileAccess.file_exists(path): return ""
 return FileAccess.get_file_as_string(path).replace("\r\n","\n")

static func normalized_text_sha256(path: String) -> String:
 return normalized_text(path).sha256_text()
