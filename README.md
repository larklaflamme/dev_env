# dev_env — Ubuntu 24.04 workstation bootstrap

```
     _                                  
  __| | _____   __    ___ _ ____   __  
 / _` |/ _ \ \ / /   / _ \ '_ \ \ / /  
| (_| |  __/\ V /   |  __/ | | \ V /   
 \__,_|\___| \_/     \___|_| |_|\_/    clone → ./install.sh → log out → devenv post
```

One repo that turns a fresh (or existing) Ubuntu 24.04 machine into a fully loaded
terminal-first dev box: **zsh + oh-my-zsh**, a modern CLI that quietly replaces the
1970s classics, **Python (Miniconda3 + uv)**, **Rust**, **Go**, **Node.js**, **git/gh**,
**Docker + Compose**, Neovim (LazyVim), tmux and Ghostty — plus the dotfiles that tie it
all together.

- **Re-runnable.** Every module checks what's already there. Run it on day 1 or day 300.
- **Modular.** `./install.sh python rust` runs just those. A failed module never stops the rest.
- **Non-destructive.** Existing dotfiles are moved to `~/.dotfiles-backup/<timestamp>/`, never deleted.
  Config files the kit seeds (`~/.cargo/config.toml`, `/etc/docker/daemon.json`, …) are only written if missing.
- **Declarative-ish.** Tool lists live in plain text files under `packages/`. Add a line, re-run.
- **Testable.** `test/run.sh` lints everything and does a full install in a throwaway container.

Start with **[QUICKSTART.md](QUICKSTART.md)**. Recipes and troubleshooting are in **[HOWTO.md](HOWTO.md)**.

---

## What gets installed

### Modules (run in this order)

| Module      | What it does |
|-------------|--------------|
| `base`      | full upgrade, universe repo, git/stow/curl, snap refresh, firmware check (`fwupdmgr`) |
| `drivers`   | **opt-in (`--gpu`)** — NVIDIA driver via `ubuntu-drivers`; never replaces a driver that already works |
| `toolchain` | gcc, clang, lld, **mold**, cmake, ninja, meson, gdb, lldb, valgrind, perf, strace + `-dev` headers |
| `dotfiles`  | stows `dotfiles/*` into `$HOME`, creates `~/.zshrc*.local` + `~/.gitconfig`, puts `devenv` on PATH |
| `cli`       | apt CLI set (`packages/apt-cli.txt`) + **mise** + fast-moving binaries (`packages/mise-tools.txt`) |
| `zsh`       | oh-my-zsh + 6 community plugins, zsh as login shell |
| `git`       | latest git (git-core PPA), git-lfs, GitHub CLI |
| `fonts`     | JetBrainsMono + FiraCode **Nerd Fonts** |
| `terminal`  | **Ghostty** (GPU-accelerated terminal), desktop only |
| `neovim`    | latest stable Neovim in `/opt/nvim`, LazyVim starter, dedicated pynvim venv |
| `python`    | **Miniconda3** (conda-forge, base not auto-activated) + **uv**, ruff, pre-commit, ipython |
| `rust`      | **rustup** stable + rust-analyzer, cargo-binstall, nextest, cargo-edit/update/audit/outdated/expand, bacon |
| `go`        | **Go** latest (official tarball) + gopls, dlv, goimports, gofumpt, staticcheck, govulncheck, golangci-lint |
| `node`      | **Node.js LTS**, pnpm, bun via mise; typescript, tsx, npm-check-updates |
| `docker`    | **Docker CE + Buildx + Compose v2** (official repo), log rotation, NVIDIA Container Toolkit if a driver already works (or `--gpu`) |
| `tweaks`    | inotify watcher limits, perf for non-root, weekly SSD trim, 1 GB journal cap |
| `hardening` | ufw (deny inbound), unattended security updates |

### GPU drivers are opt-in

By default the kit **does not install or replace an NVIDIA driver** — many machines ship with
a vendor-validated version, and swapping it can break things. (Routine `apt` upgrades can still
bring patch releases *within* the installed driver branch; `--hold-gpu` freezes it completely.)

| You run | GPU behaviour |
|---------|---------------|
| `./install.sh` | no driver work. If a driver exists it's left alone and reported |
| `./install.sh --gpu` | also runs `drivers`: installs Ubuntu's recommended driver **only if none is working** |
| `DEVENV_NVIDIA_DRIVER=nvidia-driver-570 ./install.sh --gpu drivers` | installs that specific branch instead |
| `./install.sh --hold-gpu base` | `apt-mark hold` the installed driver packages so upgrades can't touch them |

Hold caveat: with Ubuntu's prebuilt signed modules (`linux-modules-nvidia-*`), a later kernel
update may need a matching driver patch release; if the GPU disappears after a kernel update,
boot the previous kernel or `sudo apt-mark unhold $(apt-mark showhold | grep nvidia)` and upgrade.

The Docker module adds the NVIDIA Container Toolkit (for `--gpus all`) only when a driver
already works or `--gpu` was given; the toolkit itself never changes the driver.

### Old command → modern tool

The heart of the "hacker box" feel. Controlled by `DEVENV_ALIASES` in `~/.zshrc.pre.local`
(`all` by default, `safe`, or `none`). The original is always one keystroke away: `\grep` or `command grep`.

| Classic | Modern | Tier | Why |
|---------|--------|------|-----|
| `ls`    | [eza](https://github.com/eza-community/eza) | safe | icons, git column, tree mode |
| `tree`  | eza `--tree` | safe | honours `.gitignore` |
| `cat`   | [bat](https://github.com/sharkdp/bat) | safe | syntax highlight, git gutter; plain when piped |
| `cd`    | [zoxide](https://github.com/ajeetdsouza/zoxide) | safe | `cd proj` jumps by frecency; `cdi` = interactive |
| `top`/`htop` | [btop](https://github.com/aristocratos/btop) | safe | beautiful, mouse-driven |
| `vim`/`vi` | [Neovim](https://neovim.io) + LazyVim | safe | LSP, treesitter, telescope out of the box |
| `grep`  | [ripgrep](https://github.com/BurntSushi/ripgrep) | all | 10–100× faster, recursive, `.gitignore`-aware |
| `find`  | [fd](https://github.com/sharkdp/fd) | all | `fd pattern` — sane syntax, fast |
| `sed`   | [sd](https://github.com/chmln/sd) | all | `sd 'from' 'to' file` — no escaping hell |
| `du`    | [dust](https://github.com/bootandy/dust) | all | visual tree of what's eating disk |
| `df`    | [duf](https://github.com/muesli/duf) | all | readable mount table |
| `ps`    | [procs](https://github.com/dalance/procs) | all | colour, ports, docker container names |
| `dig`   | [doggo](https://github.com/mr-karan/doggo) | all | human DNS output, DoH/DoT |
| `ping`  | [gping](https://github.com/orf/gping) | all | live latency graph |
| `diff`  | [delta](https://github.com/dandavison/delta) | all | also git's pager |
| `curl`  | [xh](https://github.com/ducaale/xh) | new name | `xh POST api/x name=me` (curl stays curl) |
| `man`   | [tldr](https://github.com/tealdeer-rs/tealdeer) | `help` | examples first (man stays man) |
| history | [atuin](https://github.com/atuinsh/atuin) | Ctrl-R | SQLite history with cwd/exit code; optional E2E sync |
| `make`  | [just](https://github.com/casey/just) | new name | a command runner without Makefile footguns |

**Also on board:** fzf (+ fzf-tab completion), lazygit, lazydocker, yazi (file manager),
starship (prompt), direnv, jq/yq, hyperfine, tokei, watchexec, glow, dive, gitleaks, age,
sops, httpie, mtr, nmap, nvtop, ncdu, hexyl, shellcheck/shfmt, tmux.

### zsh setup

oh-my-zsh as the framework, **starship** as the prompt, and these plugins:

| Plugin | What you get |
|--------|--------------|
| fzf-tab | every Tab completion becomes an fzf picker with previews |
| zsh-autosuggestions | ghost-text from history; `→` or `Ctrl-Space` accepts |
| fast-syntax-highlighting | commands turn red before you hit Enter on a typo |
| zsh-completions | hundreds of extra completions |
| you-should-use | reminds you when an alias exists for what you typed |
| zsh-autopair | auto-closes quotes and brackets |
| built-ins | git, gh, docker, docker-compose, rust, golang, npm, python, sudo (`Esc Esc`), extract (`x file.tar.zst`), copypath, history-substring-search, command-not-found |

Startup stays fast: conda is **lazy-loaded** (first `conda` call wires it up) and tool
completions are generated once and cached. Profile anytime: `DEVENV_PROFILE=1 zsh -i -c exit`.

### Language strategy — one manager per language, no overlap

| Language | Manager | Why this one |
|----------|---------|--------------|
| Python | **Miniconda3** for envs with heavy native deps (CUDA, MKL, GDAL, PyTorch); **uv** for app/library projects (`uv init`, `uv add`, `uv run`) and global CLI tools | conda solves the binary-stack problem; uv is 10–100× faster than pip for everything else |
| Rust | **rustup** | the official, only sane choice; `rust-toolchain.toml` per project |
| Go | **official tarball** | since Go 1.21 a `toolchain` line in `go.mod` auto-fetches per-project versions — no version manager needed |
| Node | **mise** | per-project versions from `mise.toml`, `.nvmrc` or `.node-version`; also manages the CLI binaries |

Conda uses **conda-forge only** with `auto_activate: false` — your shell starts clean
and nothing shadows the system/uv Python by accident. (Set `DEVENV_CONDA_DEFAULTS=1` to use
Anaconda's `defaults` channels instead; note their commercial terms for larger organisations.)

---

## Repository layout

```
dev_env/
├── bootstrap.sh          curl|bash entry: installs git, clones, runs install.sh
├── install.sh            orchestrator: module discovery, sudo keepalive, logging, summary
├── bin/devenv            day-2 CLI: doctor | update | post | aliases | install | list
├── lib/
│   ├── common.sh         helpers: logging, apt, fetch, backups, write_if_missing, mise
│   └── run-module.sh     runs one module in its own strict-mode process
├── modules/NN-name.sh    one file per concern; NN = order; header has desc/default
├── packages/
│   ├── apt-toolchain.txt compilers, debuggers, headers
│   ├── apt-cli.txt       CLI tools from the Ubuntu archive
│   └── mise-tools.txt    fast-moving CLI binaries via mise
├── dotfiles/             GNU stow packages, mirrored into $HOME
│   ├── zsh/              .zshenv .zshrc .config/zsh/{10-options,20-tools,30-functions,40-aliases,90-prompt}.zsh
│   ├── bash/             .inputrc .config/bash/devenv.bash (sourced from ~/.bashrc)
│   ├── git/              .config/git/{config,ignore}
│   ├── cli/              starship.toml, bat, ripgrep, atuin configs
│   └── term/             tmux.conf, ghostty config
├── test/                 Dockerfile + run.sh (lint + container install)
└── legacy/               the original starter files, for reference
```

### Machine-local files (created once, never committed)

| File | Purpose |
|------|---------|
| `~/.zshrc.pre.local` | sourced first: `DEVENV_ALIASES`, `DEVENV_VI_MODE` |
| `~/.zshrc.local` | sourced last: tokens, proxies, overrides |
| `~/.gitconfig` | identity + signing (`devenv post` fills it). Shared defaults stay in `~/.config/git/config` |
| `~/.bashrc.local` | same idea for bash |

## The `devenv` command

| Command | Does |
|---------|------|
| `devenv doctor` | checks every installed tool plus shell, docker group/daemon, fonts, git identity, SSH, GPU, pending reboot |
| `devenv update` | apt, snap, mise + tools, rustup + cargo tools, Go + tools, conda, uv + tools, oh-my-zsh + plugins, Neovim + plugins, tldr |
| `devenv post` | git identity, ed25519 key, `gh auth login`, upload auth + signing key, SSH commit signing |
| `devenv aliases` | the classic → modern table with what's installed |
| `devenv install …` | same as `./install.sh …` from anywhere |

## Requirements

Ubuntu 24.04 (x86_64 or arm64), a sudo-capable user, internet. Works on desktop and server
(desktop-only steps skip themselves); also runs inside containers for testing.

## Credits

Standing on the shoulders of oh-my-zsh, mise, starship, LazyVim and the authors of every
tool in the tables above.
# dev_env
