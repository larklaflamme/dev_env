# QUICKSTART

Fresh Ubuntu 24.04 → fully loaded dev box in about 20–30 minutes (mostly downloads).

## 1. Get the repo onto the machine

```bash
# Option A — one-liner (installs git, clones to ~/dev_env, runs everything)
curl -fsSL https://raw.githubusercontent.com/<you>/dev_env/main/bootstrap.sh | bash

# Option B — clone it yourself
sudo apt update && sudo apt install -y git
git clone https://github.com/<you>/dev_env.git ~/dev_env
cd ~/dev_env
```

> Before pushing the repo, set your URL in `bootstrap.sh` (`DEVENV_REPO=`).

## 2. Run the installer

```bash
./install.sh                         # everything, in order — NVIDIA driver is NOT touched
./install.sh --gpu                   # same, plus install the NVIDIA driver (only if none works)
```

Already have a vendor-installed GPU driver you want to keep exactly as is? Use plain
`./install.sh` (optionally `./install.sh --hold-gpu base` to freeze it against upgrades).

It asks for your sudo password once, logs to `~/.local/state/devenv/install-*.log`,
and keeps going if one module fails (re-run just that module later).

Want to see or trim the menu first?

```bash
./install.sh --list                  # modules and what they do
./install.sh --skip docker,hardening
./install.sh zsh cli python          # only these
```

Hit GitHub rate limits (lots of `mise could not install` warnings)? Export a token and re-run:
`export GITHUB_TOKEN=ghp_... && ./install.sh cli`

## 3. Log out and back in

Needed once: your login shell becomes **zsh** and you join the **docker** group.
If you used `--gpu` (or a kernel update landed), **reboot** instead.

## 4. Personalise (interactive, 2 minutes)

```bash
devenv post        # git name/email, SSH key, GitHub login, SSH commit signing
devenv doctor      # green across the board?
```

## 5. Open Ghostty and look around

| Try this            | What happens                                         |
|---------------------|------------------------------------------------------|
| `ll`                | eza listing with icons + git status                  |
| `cat install.sh`    | bat: syntax-highlighted                              |
| `cd dev` then `cd -`| zoxide jumps to the best match for "dev"             |
| `Ctrl-R`            | atuin: fuzzy history with directory & exit code      |
| `Ctrl-T` / `Alt-C`  | fzf: pick a file / jump to a directory               |
| `git st`, `lg`      | short status / lazygit TUI                           |
| `rgv TODO`          | live ripgrep → open the hit in nvim at that line     |
| `nvim`              | LazyVim (plugins finish installing on first launch)  |
| `devenv aliases`    | the full old-command → new-tool map                  |

Keep it fresh: `devenv update` (weekly is plenty).

Next: [HOWTO.md](HOWTO.md) for recipes, [README.md](README.md) for the full tour.
