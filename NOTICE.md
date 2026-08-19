# NOTICE

This repository packages and redistributes upstream software published by
[Charm](https://charm.sh) (`charmbracelet` on GitHub). The Apache-2.0 license
in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — the redistributed bytes carry their
own license, recorded below.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `gum` | `ghcr.io/ocx-contrib/charm/gum` | `MIT` |
| `glow` | `ghcr.io/ocx-contrib/charm/glow` | `MIT` |

The package logos are **original marks authored for this repository**, not
upstream assets. Charm publishes no SVG logo for either tool — a listing of
`charmbracelet/gum@main` and `charmbracelet/glow@main` returns no `.svg`
anywhere, and the raster artwork on `stuff.charm.sh` is promotional wordmark
imagery, not a square icon. The marks here are plain geometric glyphs used for
catalog identification only. "Charm", "gum" and "glow" are used nominatively to
identify the upstream software; no endorsement is implied and no trademark
claim is made.

---

## `gum`

Upstream: <https://github.com/charmbracelet/gum>
Published to `ghcr.io/ocx-contrib/charm/gum`.

| Component | SPDX | Holder |
|---|---|---|
| gum | **MIT** | Copyright (c) 2022-2024 Charmbracelet, Inc |

Verified at the Phase 1.5 license gate:

```
$ gh api repos/charmbracelet/gum/license --jq '{spdx: .license.spdx_id, name: .license.name}'
{"name":"MIT License","spdx":"MIT"}
```

## `glow`

Upstream: <https://github.com/charmbracelet/glow>
Published to `ghcr.io/ocx-contrib/charm/glow`.

| Component | SPDX | Holder |
|---|---|---|
| glow | **MIT** | Copyright (c) 2019-2024 Charmbracelet, Inc |

Verified at the Phase 1.5 license gate:

```
$ gh api repos/charmbracelet/glow/license --jq '{spdx: .license.spdx_id, name: .license.name}'
{"name":"MIT License","spdx":"MIT"}
```

---

## How the MIT notice condition is met

MIT is permissive and grants redistribution of the compiled binary subject to
its notice-retention condition. That condition is met at two levels for both
packages: every upstream release archive **carries its own `LICENSE` file
alongside the binary**, and this mirror republishes the archive contents
unaltered, so the notice travels inside the bundle exactly as upstream shipped
it. The canonical texts are
<https://github.com/charmbracelet/gum/blob/main/LICENSE> and
<https://github.com/charmbracelet/glow/blob/main/LICENSE>, and every published
manifest carries an `org.opencontainers.image.source` annotation pointing at
this repository alongside `org.opencontainers.image.licenses: MIT`.

The published binaries are statically linked Go builds that vendor third-party
modules under permissive licenses, enumerated in the `go.mod` / `go.sum` of the
tagged upstream source for each mirrored version, and in the SBOM upstream
publishes beside each release archive.

No modifications are made to any upstream artifact in this repository. The
archive contents — the binary, `LICENSE`, `README.md`, `completions/` and
`manpages/` — are republished byte-for-byte inside an OCX bundle; the only
transformation is unwrapping the archive's single top-level directory
(`strip_components: 1`), which renames no file and alters no byte.

---

## Not mirrored: `crush`

`charmbracelet/crush` is **deliberately absent** from this repository. It ships
under the **Functional Source License, Version 1.1, MIT Future License**
(`FSL-1.1-MIT`, Copyright 2025-2026 Charmbracelet, Inc), not MIT:

```
$ gh api repos/charmbracelet/crush/license --jq '{spdx: .license.spdx_id, name: .license.name}'
{"name":"Other","spdx":"NOASSERTION"}
$ gh api repos/charmbracelet/crush/contents/LICENSE.md --jq .content | base64 -d | head -5
# Functional Source License, Version 1.1, MIT Future License
```

FSL grants redistribution only for a "Permitted Purpose", defined as any
purpose other than a **Competing Use** — "making the Software available to
others in a commercial product or service that … offers the same or
substantially similar functionality". Whether republishing crush through a
package registry falls inside that carve-out is the licensor's call, not the
mirror author's, so crush is not mirrored here pending a **written
redistribution grant** from Charm. If one is obtained, cite its URL and date in
this file alongside the SPDX id.

Each FSL version converts to MIT two years after its release date, so crush
releases become mirrorable under MIT on that schedule regardless.
