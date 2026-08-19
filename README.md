# mirror-charmbracelet

OCX mirrors for the CLI tools published by [Charm](https://charm.sh)
(`charmbracelet` on GitHub). One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [gum](https://github.com/charmbracelet/gum) | [`gum/mirror.yml`](gum/mirror.yml) | `ghcr.io/ocx-contrib/charmbracelet/gum` | [`ocx.sh/charmbracelet/gum`](https://index.ocx.sh/charmbracelet/gum) | `MIT` |
| [glow](https://github.com/charmbracelet/glow) | [`glow/mirror.yml`](glow/mirror.yml) | `ghcr.io/ocx-contrib/charmbracelet/glow` | [`ocx.sh/charmbracelet/glow`](https://index.ocx.sh/charmbracelet/glow) | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

The namespace is **`charmbracelet`, not `charm`** — and that is a deliberate
reversal of the usual vendor-beats-handle rule. Charm calls itself Charm, holds
charm.sh and charm.land, and brands the tool `charm_ gum` in its own artwork,
which is exactly the argument that makes `github/cli` not `cli/cli`. But the
index's namespace policy prefers a namespace matching an identity the vendor
demonstrably holds, and `github.com/charm` is an unrelated dormant org (created
2018, four repos, none of them Charm's). Every fleet precedent for the rule
names a handle its vendor actually owns, so the org handle wins here. Branding
and provenance are not lost — they are in each claim's `upstream` block and in
the catalogs.

**`crush` is deliberately not mirrored here.** It ships under `FSL-1.1-MIT`,
which grants redistribution only for a non-competing "Permitted Purpose"; that
is the licensor's call to make, so crush waits on a written grant from Charm.
See [`NOTICE.md`](NOTICE.md) for the full gate transcript.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
gum/  glow/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
path filter and would never trigger a describe run.

## Toolchain

`ocx.toml` pins the **floating minor** of the prod toolchain
(`ocx.sh/ocx/cli:0.5`, `ocx.sh/ocx/mirror:0.5`); the concrete digests live in
`ocx.lock`. `direnv allow` once to put them on `PATH`, then invoke
`ocx-mirror` **directly** — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

```sh
direnv allow
ocx update                      # re-resolve the floating tags
grep lock_version ocx.lock      # must be 3
```

## Editing

Everything in `.github/workflows/` is **generated**. Never hand-edit it — the
`verify-generated.yml` drift guard fails CI at exit 65 on any change. Edit the
spec (or the renderer template), then regenerate, **naming every spec** —
`--spec` appends rather than replaces, so a command naming a subset silently
stops rendering the rest while staying green:

```sh
ocx-mirror package validate gum/mirror.yml
ocx-mirror package validate glow/mirror.yml
ocx-mirror package pipeline generate ci --spec gum/mirror.yml --spec glow/mirror.yml
ocx-mirror package pipeline generate ci --check --spec gum/mirror.yml --spec glow/mirror.yml
```

`--repo-root` is inferred from the enclosing git repository, so it is never
passed here — and the drift guard bakes in the same inference, which is why a
`generate ci` run from outside a git checkout exits 64.

Editing `mirror-base.yml` re-runs **both** packages' workflows; editing `gum/`
never wakes `glow`.

## Testing the smoke locally before pushing

CI runs the smoke on macOS (10× minutes) and Windows (2×), so a Starlark
dialect error costs a full matrix round trip to find. Run it against a real
native bundle first, **for every in-range version** — a binary's flag surface
can change inside the range even when its asset set does not (gum's
unknown-flag exit code moved from 1 to 80 between 0.16.1 and 0.16.2, which is
why nothing in `gum/tests/smoke.star` asserts on it):

```sh
ocx-mirror package pipeline prepare --spec gum/mirror.yml \
  --version 0.17.0 --work-dir "$(mktemp -d)"
# bundle lands at <work-dir>/<V>_<YYYYMMDD>/linux_amd64/ under build_timestamp: date
ocx package test --platform linux/amd64 \
  --identifier ghcr.io/ocx-contrib/charmbracelet/gum:0.17.0 \
  <work-dir>/<V>_<YYYYMMDD>/linux_amd64/bundle.tar.xz \
  --script gum/tests/smoke.star
```

**Both tools are TUIs, and that constrains the smoke tests.** Eight of gum's
fourteen subcommands open a full-screen UI and block on input; glow opens a
file browser when invoked bare. Reaching terminal init inside
`ocx package test` hangs a Windows leg. Two rules hold in both scripts:

- Only non-interactive verbs are used — gum's `--version`, `style`, `format`,
  `version-check`; glow with an explicit source (`-`) or a flag, never bare.
- **Every `ocx.run` names its stdin explicitly**, because glow's source
  precedence is not what it looks like. glow reads STDIN whenever stdin is a
  pipe and only falls back to its file argument when it is not — and a char
  device does not count as a pipe:

  ```sh
  glow doc.md </dev/null    # 554 bytes — the FILE ARGUMENT is used
  printf '' | glow doc.md   # "\n\n"    — empty PIPE wins, renders nothing
  glow doc.md | cat         # hung      — inherited pipe, never closed
  ```

  `ocx.run(…, stdin = "")` is the middle case, so `glow <file>` written that
  way renders nothing and still exits 0 — green, having verified nothing. The
  smoke therefore feeds markdown through `glow -` with `stdin = DOC`, which is
  both hermetic and immune to the rule, and passes `stdin = ""` only to calls
  that read no stdin at all.

## Platform rollout

Platforms are staged to keep macOS and Windows minutes off an unproven layout:
pass 1 linux only, pass 2 darwin, pass 3 windows. Each pass uncomments the
platform key in `mirror-base.yml` **and** its asset regex in **both**
`gum/mirror.yml` and `glow/mirror.yml` together — staging `assets:` alone still
boots a real macOS/Windows runner that self-skips per version and reports
success having tested nothing. Uncomment with an editor, never `sed`: the
values are regexes, and backslash is special on `sed`'s replacement side.

There is no `windows/arm64` pass. Upstream has never shipped one for either
tool — its Windows matrix is `i386` + `x86_64` only, and ocx has no 386
architecture.

## Claim + announce

The index claim (`p/charmbracelet/gum.json` and `p/charmbracelet/glow.json` in `ocx-sh/index`)
is the one PR in this workflow; **mirror repos themselves take no PRs — push
straight to `main`**. Order is publish → verify the GHCR package is public →
merge the claim → announce:

```sh
gh workflow run announce-from-registry-gum.yml  -f dry_run=false
gh workflow run announce-from-registry-glow.yml -f dry_run=false
```

An announce before the claim lands fails with `unclaimed namespace`, exit 79 —
expected at that point, not a misconfiguration.
