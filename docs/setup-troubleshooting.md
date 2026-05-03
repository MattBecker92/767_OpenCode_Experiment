# Setup Troubleshooting

Common issues encountered during setup and how to fix them.

## "Big Pickle / OpenCode Zen" appears instead of local model

OpenCode has a free hosted model ("Big Pickle") that appears when no provider
is configured. This means your `opencode.json` is either missing, malformed,
or being overridden.

**Fix:** Check config ownership and content:
```bash
ls -la ~/.config/opencode/
cat ~/.config/opencode/opencode.json
```

If files are owned by root:
```bash
sudo chown -R $USER:$USER ~/.config/opencode/
```

If `node_modules` or `package.json` are in `~/.config/opencode/`, remove them:
```bash
sudo rm -rf ~/.config/opencode/node_modules
sudo rm -f ~/.config/opencode/package.json ~/.config/opencode/package-lock.json
```

## Config files owned by root

This happens if you ran `opencode` or edited config files with `sudo`.

```bash
sudo chown -R $USER:$USER ~/.config/opencode/
```

## `opencode run` exits immediately with no code changes

This is expected behaviour. `opencode run` is not an agentic loop — it exits
after a single model response. Use `ollama launch opencode` (TUI mode) instead.

## Wrong model selected (cloud variant, authentication error)

`ollama launch opencode` presents a model menu. Scroll past the "Recommended"
cloud models to the "More" section and select your local `qwen3.5-16k`.

If the model string in `opencode.json` matches a cloud variant name, Ollama
will select the cloud version. Use `qwen3.5-16k` (your saved local model name)
to avoid ambiguity.

## `config.json` conflict with `opencode.json`

If you have both `~/.config/opencode/config.json` and `opencode.json`,
OpenCode may read the wrong one. Keep only `opencode.json` and remove
`config.json` if it exists:

```bash
ls ~/.config/opencode/
rm ~/.config/opencode/config.json   # if present
```

## pytest not found

```bash
pip install pytest --break-system-packages
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## `python` command not found

```bash
sudo apt install python-is-python3 -y
```
