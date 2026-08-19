# gum/tests/smoke.star — stable across upstream gum releases.
#
# Asserts the contract (exit codes, version SHAPE, exact rendered geometry, a
# markdown transformation, and semver arithmetic), never help/version prose.
#
# ─── WHY THIS TEST IS SHAPED THE WAY IT IS: MOST OF gum IS A TUI ────────────
#
# gum's product is interactive prompts. Of its fourteen subcommands, EIGHT open
# a full-screen terminal UI and block on input — `choose`, `confirm`, `file`,
# `filter`, `input`, `pager`, `table`, `write` — and `spin` runs a child under
# an animated spinner. Reaching terminal init inside `ocx package test` is not
# a slow test, it is a HUNG WINDOWS LEG: the process waits on a console the
# runner never hands it. So every call below is one of the FIVE non-interactive
# verbs: `--version`, `style`, `format`, `version-check`, and flag-parse
# failure. None of them opens the alternate screen on any platform.
#
# EVERY call passes `stdin = ""`. That is not decoration — it is the fix for a
# measured hang. `gum format` reads stdin when given no positional argument,
# and a child that inherits an open-but-silent stdin blocks forever rather than
# seeing EOF. Passing the empty string closes it immediately. Do not drop it
# from a call here on the grounds that "this verb doesn't read stdin": that is
# an upstream-behaviour assumption, and the failure mode it buys is a timeout
# on the slowest runner in the matrix.
#
# ─── WHY NOTHING ASSERTS ON THE UNKNOWN-FLAG EXIT CODE ─────────────────────
#
# gum's exit code for an unrecognised flag MOVED INSIDE the mirrored major:
# 1 up to and including 0.16.0/0.16.1, then 80 from 0.16.2 on. Asserting either
# would red half the range, and asserting "non-zero" is not a check. The
# negative control is `version-check` instead, whose failure code is a measured
# 1 on all four in-range versions.

GUM = "gum.exe" if ocx.target_platform.os == ocx.os.Windows else "gum"

# Exactly six characters — the border geometry asserted below is computed from
# that length, so changing the token means recomputing the rule width.
TOKEN = "OCXGUM"

# ─── Tier 1 + 2: liveness on the composed PATH + version SHAPE ──────────────
#
# gum prints `gum version v0.17.0 (6045525)`. The digits and the commit are the
# contract; the banner around them is not. An `expect.contains(stdout, "gum")`
# would break on a rebrand, and an `expect.eq` on the line would break on every
# release. Note the leading `v` — gum's own output carries it even though the
# mirrored VERSION does not (`tag_pattern` strips it), which is why this regex
# and glow's differ by exactly that character.
r_version = ocx.run(GUM, "--version", stdin = "")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\bv\d+\.\d+\.\d+ \([0-9a-f]+\)")

# ─── Tier 3a: `style` renders EXACT geometry, not merely some output ────────
#
# `--border double --padding "0 1"` around a 6-character token is a fully
# determined 3×10 box. Measured byte-identical on all four in-range versions
# (0.16.0, 0.16.1, 0.16.2, 0.17.0), and with NO SGR escapes: lipgloss drops to
# a plain profile when stdout is not a tty, which is exactly the case under
# `ocx package test`, so the bytes are stable and colour-free.
#
# This is the assertion that a truncated or wrong-flavour archive cannot pass.
# A binary that merely starts and prints something fails it: the rule width is
# 6 + 1 + 1 = 8, derived from the token and the padding, so a lipgloss that
# mis-measured the string, dropped the padding, or picked the wrong border set
# reds here rather than drifting silently.
RULE = "════════"                    # 8 = len(TOKEN) + left pad + right pad
r_style = ocx.run(GUM, "style", "--border", "double", "--padding", "0 1", TOKEN, stdin = "")
expect.ok(r_style)
expect.contains(r_style.stdout, "╔" + RULE + "╗")
expect.contains(r_style.stdout, "║ " + TOKEN + " ║")
expect.contains(r_style.stdout, "╚" + RULE + "╝")

# ─── Tier 3b: `format` performs a real markdown TRANSFORMATION ──────────────
#
# Fed on stdin, so it is hermetic — nothing is read from the filesystem and no
# ambient state can change the answer. The assertion is on the TRANSFORM, not
# on the input echoing through: gum rewrites the ASCII list marker `-` into the
# bullet `•`, so `• alpha` appears in the output and nowhere in the input. A
# binary that passed its stdin through unchanged would fail this.
#
# Deliberately NOT asserted: the ANSI colour codes gum emits around headings,
# and anything about the `[link](url)` form — both are styling decisions that
# have moved upstream inside this fleet's memory.
r_format = ocx.run(GUM, "format", stdin = "# Heading\n\n- alpha\n- beta\n")
expect.ok(r_format)
expect.contains(r_format.stdout, "• alpha")
expect.contains(r_format.stdout, "• beta")

# ─── Tier 3c: `version-check` — semver arithmetic AND the negative control ──
#
# Two jobs in one pair of calls.
#
#   (1) Functional: gum parses its own version and evaluates a semver range
#       against it. `>=0.1.0` is satisfied by every version this mirror can
#       ever carry (the floor is 0.16.0), so it must exit 0.
#
#   (2) NEGATIVE CONTROL. Every assertion above is satisfiable by a binary that
#       prints plausible things and always succeeds. This one is not: no gum
#       release can satisfy `>=99.0.0`, so it MUST fail — and with exit code 1
#       specifically, measured on all four in-range versions. A tolerated
#       RANGE of non-zero codes would not be a check.
r_vc_ok = ocx.run(GUM, "version-check", ">=0.1.0", stdin = "")
expect.ok(r_vc_ok)

r_vc_no = ocx.run(GUM, "version-check", ">=99.0.0", stdin = "")
expect.eq(r_vc_no.exit_code, 1)

# No Tier 4: metadata.json declares PATH only (proven by the Tier 1 liveness
# call resolving `gum` off the composed PATH).
