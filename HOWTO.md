# HOWTO

Recipes for living with this setup. For first-time install see [QUICKSTART.md](QUICKSTART.md).

- [Running the installer](#running-the-installer)
- [Customising](#customising)
- [Shell: zsh, aliases, keys](#shell-zsh-aliases-keys)
- [Python: conda vs uv](#python-conda-vs-uv)
- [Rust](#rust) · [Go](#go) · [Node.js](#nodejs)
- [Docker](#docker)
- [Git & GitHub](#git--github)
- [Neovim, tmux, Ghostty](#neovim-tmux-ghostty)
- [Dotfiles workflow](#dotfiles-workflow)
- [Updating](#updating)
- [Testing changes safely](#testing-changes-safely)
- [Troubleshooting](#troubleshooting)
- [Undo / uninstall](#undo--uninstall)

---

## Running the installer

```bash
./install.sh                          # all default modules
./install.sh --list                   # what's available
./install.sh python node              # only these, in the order given
./install.sh --skip docker,terminal   # everything except
./install.sh --gpu                    # also install the NVIDIA driver (opt-in, off by default)
./install.sh --hold-gpu base          # apt-mark hold the current NVIDIA driver packages
devenv install docker                 # same thing, from any directory
```

- Every module is **idempotent** — re-running is the fix for most problems.
- Each module runs in its own process with `set -Eeuo pipefail`; a failure prints the
  failing line, and the run continues with the next module.
- Full log: `~/.local/state/devenv/install-<timestamp>.log`.

### Useful environment knobs

| Variable | Effect |
|----------|--------|
| `GITHUB_TOKEN` | avoids GitHub API rate limits for mise downloads (any classic token, no scopes needed) |
| `DEVENV_CONDA_PREFIX` | Miniconda location (default `~/miniconda3`) |
| `DEVENV_CONDA_DEFAULTS=1` | use Anaconda `defaults` channels instead of conda-forge (accepts their ToS) |
| `DEVENV_CONDA_ENV="dev python=3.13 numpy"` | also create a starter conda env |
| `DEVENV_NVIDIA_DRIVER=nvidia-driver-570` | with `--gpu`: install this driver branch instead of Ubuntu's recommendation |
| `DEVENV_NVIM_SYNC=0` | skip the headless LazyVim plugin pre-install |
| `DEVENV_REPO`, `DEVENV_DIR` | (bootstrap.sh) where to clone from / to |

## Customising

**Add an apt package** → append a line to `packages/apt-cli.txt` (or `apt-toolchain.txt`), then `./install.sh cli`.

**Add a CLI binary** → append to `packages/mise-tools.txt`. Find names with `mise registry | rg <name>`.
Pin a version with `tool@1.2.3`. Then `./install.sh cli`.

**Add a module** → create `modules/NN-name.sh`:

```bash
# shellcheck shell=bash
# desc: one line shown by --list
# default: yes            # "no" = only runs when named explicitly

run() {
  log "name — doing the thing"
  apt_install something
  write_if_missing "$HOME/.config/thing/config" <<'EOF'
key = value
EOF
  ok "done"
}
```

All helpers from `lib/common.sh` are available: `log ok info warn die have apt_install
apt_install_best_effort fetch write_if_missing ensure_block backup_path git_sync
mise_use_global is_container has_systemd has_desktop deb_arch`.

**Turn a default module off for good** → change its header to `# default: no`.

## Shell: zsh, aliases, keys

### Alias tiers

`~/.zshrc.pre.local`:

```bash
export DEVENV_ALIASES=all    # default: grep→rg, find→fd, sed→sd, du→dust, df→duf, ps→procs, dig→doggo, ping→gping, diff→delta
export DEVENV_ALIASES=safe   # only drop-ins: ls/tree→eza, cat→bat, cd→zoxide, top→btop, vim→nvim
export DEVENV_ALIASES=none   # no overrides; z/zi for zoxide
```

`reload` (= `exec zsh`) to apply. `devenv aliases` shows the live map.

> **Know the sharp edges of `all`:** `grep -r` becomes `rg -r` (= *replace*, not recursive —
> rg is already recursive, so just drop `-r`). `find . -name x` errors with fd (use `fd x`).
> `sed -i 's/a/b/' f` → `sd a b f`. When pasting commands from the internet, prefix with `\`
> (`\grep -rn foo .`) or use `command grep`. Scripts are never affected — aliases only exist
> in interactive shells.

### Keys worth learning

| Keys | Action |
|------|--------|
| `Ctrl-R` | atuin history search (filter by dir/session/host with `Ctrl-R` again) |
| `Ctrl-T` | fzf file picker → inserts path |
| `Alt-C` | fzf directory jump |
| `Tab` | fzf-tab completion; `<` `>` switch groups |
| `↑` / `↓` | history matching what you've typed |
| `→` / `Ctrl-Space` | accept autosuggestion |
| `Esc Esc` | prefix the line with `sudo` |
| `Ctrl-X Ctrl-E` | edit the current command in nvim |
| `cd foo<Space><Tab>` | zoxide interactive matches |

### Functions (`functions <name>` prints the source)

| Function | Does |
|----------|------|
| `fe [query]` | fuzzy-find a file, open in nvim |
| `rgv PATTERN` | ripgrep → fzf with preview → nvim at the line |
| `fbr` / `flog` | fuzzy branch switch / browse log with delta preview |
| `fkill [sig]` | pick processes to kill |
| `dsh` | shell into a running container |
| `mkenv NAME [specs]` | create + activate a conda env |
| `y` | yazi file manager; quitting leaves you in that directory |
| `port 5432` | who's listening on a port |
| `serve [port]` | static HTTP server on 127.0.0.1 |
| `mkcd`, `bak`, `up N`, `cheat tar`, `wttr city` | small conveniences |

### Vi mode

`export DEVENV_VI_MODE=1` in `~/.zshrc.pre.local`.

## Python: conda vs uv

Rule of thumb: **uv for projects, conda for heavy binary stacks.**

```bash
# A normal project (web app, CLI, library)
uv init myapp && cd myapp
uv add fastapi httpx
uv run python -m myapp           # creates/updates .venv automatically
uv python install 3.13           # uv manages its own interpreters too

# One-off tools, isolated (pipx replacement)
uv tool install httpie
uvx ruff check .                 # run without installing

# Data science / GPU / GIS stack
mkenv ml python=3.12             # = conda create -n ml python=3.12 ipython pip && conda activate ml
conda install pytorch pytorch-cuda -c pytorch -c nvidia   # if you need those channels
conda env export --from-history > environment.yml
```

- `conda` isn't active until you use it (lazy hook); base never auto-activates.
- Starship shows the active conda env (`🅒 ml`) or venv.
- Auto-activate per directory: put `source .venv/bin/activate` or `conda activate ml` in an
  `.envrc`, then `direnv allow`.

## Rust

```bash
cargo new hello && cd hello
bacon                  # background clippy/test watcher in a side pane
cargo nextest run      # (alias: ct)
cargo add serde -F derive
cargo install-update -a    # update binstalled tools (devenv update does this)
rustup toolchain install nightly   # side by side; pin per project via rust-toolchain.toml
```

Faster linking: uncomment the mold block in `~/.cargo/config.toml`.

## Go

```bash
mkdir hello && cd hello && go mod init example.com/hello
go run .               # (alias: gor)
golangci-lint run
govulncheck ./...
```

Need an older/newer Go for one project? Add `toolchain go1.24.6` to its `go.mod` — the
`go` command downloads and uses it automatically.

## Node.js

```bash
node -v                        # LTS from mise
echo 22 > .nvmrc               # per-project version (also: mise use node@22 → mise.toml)
cd .                           # mise switches automatically
pnpm create vite@latest
bun run dev
```

## Docker

```bash
docker run --rm hello-world
dc up -d / dcl / dcd           # compose up / logs -f / down
lzd                            # lazydocker TUI
dive myimage:latest            # inspect layers
dsh                            # shell into a running container
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi   # GPU check
```

- Logs rotate (10 MB × 3) via `/etc/docker/daemon.json`.
- **Firewall caveat:** Docker's published ports bypass ufw. Bind dev services to localhost:
  `ports: ["127.0.0.1:5432:5432"]`.
- "permission denied … docker.sock" → you haven't re-logged in since joining the group
  (`newgrp docker` for the current shell).

## Git & GitHub

`devenv post` sets identity, creates `~/.ssh/id_ed25519`, logs in `gh` over SSH, uploads
the key for auth **and** signing, and turns on SSH commit signing.

Handy aliases (all in `~/.config/git/config`): `git st`, `git lg`, `git sw`, `git amend`,
`git undo`, `git wip`, `git fixup` (fzf-pick the target commit), `git cleanup` (delete
merged branches), `git aliases`. Pager is delta; `n`/`N` jump between files.

Repos clone over HTTPS but **push over SSH** (`pushInsteadOf`) — no credential prompts.

## Neovim, tmux, Ghostty

- **Neovim**: LazyVim lives in `~/.config/nvim` (yours, not stowed). `:LazyHealth`,
  `:Mason` for LSPs, `:LazyExtras` to enable language packs (python, rust, go, typescript, docker).
- **tmux**: prefix `Ctrl-a`; `|` / `-` split; `h j k l` move; `H J K L` resize;
  `prefix g` lazygit popup; `prefix f` fuzzy session switch; `prefix r` reload.
- **Ghostty**: config at `~/.config/ghostty/config`; `ghostty +list-themes`; `Ctrl+Shift+,` reloads.

## Dotfiles workflow

Everything under `dotfiles/` is symlinked file-by-file into `$HOME` with GNU stow, so
**editing `~/.zshrc` edits the repo**. Commit and push from the repo:

```bash
dotfiles                        # cd to the repo
git diff && git commit -am "zsh: add foo alias" && git push
```

Add a new config file:

```bash
mkdir -p dotfiles/cli/.config/foo
mv ~/.config/foo/config dotfiles/cli/.config/foo/config
./install.sh dotfiles           # re-stows; anything in the way is backed up first
```

Secrets never go in the repo — use `~/.zshrc.local`, or encrypt with `sops`/`age`.

## Updating

```bash
devenv update      # everything
devenv doctor      # verify
```

The kit itself: `cd "$(devenv cd)" && git pull && ./install.sh` (safe to re-run).

## Testing changes safely

```bash
test/run.sh lint           # bash -n + shellcheck + zsh -n
test/run.sh                # full install inside a clean ubuntu:24.04 container
test/run.sh zsh cli        # just some modules
docker run --rm -it devenv-test   # poke around the result
```

Works from your Mac too (Docker Desktop; Apple Silicon exercises the arm64 paths).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Many `mise could not install …` warnings | GitHub rate limit. `export GITHUB_TOKEN=…` (or `gh auth login` first) and `./install.sh cli` |
| Icons show as boxes / `?` | terminal font isn't a Nerd Font. Ghostty is preconfigured; elsewhere pick "JetBrainsMono Nerd Font" |
| Still in bash after install | log out/in; check `getent passwd $USER` ends in `/usr/bin/zsh` |
| `docker: permission denied` | log out/in (or `newgrp docker`) |
| `nvidia-smi` fails, no driver installed | drivers are opt-in: `devenv install --gpu drivers`, then reboot (Secure Boot may ask to enrol a MOK key) |
| `nvidia-smi` fails after `--gpu` | reboot first; the module won't stack a second driver while one is installed but not loaded |
| GPU gone after a kernel update while held | boot the previous kernel, or `sudo apt-mark unhold $(apt-mark showhold \| grep nvidia)` then `devenv update` |
| Shell feels slow | `DEVENV_PROFILE=1 zsh -i -c exit` shows the culprit |
| A command behaves strangely | it's probably aliased: `type grep`, then `\grep …` or set `DEVENV_ALIASES=safe` |
| `stow` conflict | `./install.sh dotfiles` moves conflicting files to `~/.dotfiles-backup/` automatically |
| conda ToS prompt | you enabled `defaults` channels; re-run with `DEVENV_CONDA_DEFAULTS=1` to accept, or stay on conda-forge |
| Module failed mid-run | read the `[fail]` line in the log, fix, `./install.sh <module>` |

## Undo / uninstall

- Dotfiles: `stow -D -d ~/dev_env/dotfiles -t ~ zsh bash git cli term`, then restore from `~/.dotfiles-backup/<ts>/`.
- Login shell back to bash: `chsh -s /bin/bash`.
- Remove the bash hook: delete the `# >>> dev_env >>>` block in `~/.bashrc`.
- Toolchains are self-contained: `~/miniconda3`, `~/.rustup ~/.cargo` (or `rustup self uninstall`),
  `/usr/local/go ~/go`, `~/.local/share/mise` (`mise implode`), `/opt/nvim`, `~/.oh-my-zsh`.
