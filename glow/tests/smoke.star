# glow/tests/smoke.star — stable across upstream glow releases.
#
# Asserts the contract (exit codes, version SHAPE, and a markdown
# transformation performed on input this test supplied), never help/version
# prose.
#
# ─── WHY THIS TEST IS SHAPED THE WAY IT IS: glow IS A TUI ──────────────────
#
# Run bare in a terminal, glow opens a full-screen file browser and pager.
# Reaching terminal init inside `ocx package test` is not a slow test, it is a
# HUNG WINDOWS LEG — the process waits on a console the runner never hands it.
# So glow is never invoked bare: every call below carries either an explicit
# source (`-`) or a flag, both of which provably run to completion.
#
# ─── THE STDIN TRAP, MEASURED ──────────────────────────────────────────────
#
# glow takes its markdown from STDIN whenever stdin is a pipe, and only falls
# back to its file argument when stdin is not. A char device does not count as
# piped input, which is why the two obvious spellings disagree:
#
#   $ glow doc.md </dev/null        → 554 bytes   (/dev/null is a char device;
#                                                  the FILE ARGUMENT is used)
#   $ printf '' | glow doc.md       → "\n\n"      (empty PIPE wins over the
#                                                  argument: an empty document)
#   $ glow doc.md | cat             → hung, killed at 120 s (inherited pipe on
#                                                  stdin, never closed)
#
# The middle case is the one that bites here: `ocx.run(…, stdin = "")` hands
# the child a pipe that closes immediately, so a `glow <file>` call written
# that way renders NOTHING and still exits 0 — a green-looking call that
# verified nothing at all. That failure was reproduced against all four
# in-range versions before this file was rewritten.
#
# So the render below feeds the document through the channel glow actually
# prefers, and names it explicitly with `-`. That is simultaneously hermetic
# (no file, no ambient state) and immune to the precedence rule. The other two
# calls read no stdin at all, and pass `stdin = ""` purely so neither can ever
# block on an inherited descriptor.

GLOW = "glow.exe" if ocx.target_platform.os == ocx.os.Windows else "glow"

DOC = "# Heading\n\n- alpha\n- beta\n"

# ─── Tier 1 + 2: liveness on the composed PATH + version SHAPE ──────────────
#
# glow prints `glow version 3.0.0 (add5e7a)` — note there is NO `v` before the
# digits, unlike gum's `gum version v0.17.0 (…)`. That difference is why the
# two smoke tests carry different regexes rather than a shared one; asserting
# gum's pattern here would red every glow version.
r_version = ocx.run(GLOW, "--version", stdin = "")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\b\d+\.\d+\.\d+ \([0-9a-f]+\)")

# ─── Tier 3: a real markdown render ────────────────────────────────────────
#
# The assertions are on the TRANSFORMATION, not on the input echoing back:
# glow rewrites the ASCII list marker `-` into the bullet `•`, which appears
# nowhere in DOC. A binary that copied its input to stdout would fail here, and
# so would the empty render the stdin trap above produces. Measured identical
# on all four in-range versions (2.1.0, 2.1.1, 2.1.2, 3.0.0).
#
# Deliberately NOT asserted: anything about a `[link](url)` line. v3.0.0
# changed link rendering to OSC 8 terminal hyperlinks (`ESC]8;id=…`) where
# v2.1.x emitted plain `link https://…`, so an assertion there would split the
# range. The heading IS asserted verbatim because glow keeps the `#` marker in
# its rendered output — measured on all four.
r_render = ocx.run(GLOW, "-", stdin = DOC)
expect.ok(r_render)
expect.contains(r_render.stdout, "# Heading")
expect.contains(r_render.stdout, "• alpha")
expect.contains(r_render.stdout, "• beta")

# ─── Tier 3b: NEGATIVE CONTROL ─────────────────────────────────────────────
#
# Every assertion above is satisfiable by a binary that prints plausible things
# and always succeeds. This one is not: an unknown flag must be REJECTED.
# Measured at exit 1 with ZERO bytes on stdout across all four in-range
# versions — asserted as that specific code rather than "non-zero", because a
# tolerated range of exit codes is not a check.
#
# The empty stdout does double duty: the alternate screen announces itself with
# a CSI burst on stdout, so 0 bytes is positive evidence that terminal init was
# never reached. Argument parsing runs before any UI code on every platform,
# which is why this call — and not a missing-file one — carries that proof.
r_bad = ocx.run(GLOW, "--ocx-smoke-not-a-flag", stdin = "")
expect.eq(r_bad.exit_code, 1)
expect.eq(r_bad.stdout, "")

# No Tier 4: metadata.json declares PATH only (proven by the Tier 1 liveness
# call resolving `glow` off the composed PATH).
