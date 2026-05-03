# Setup Guide

Complete instructions to reproduce the Harness Over Model experiment from
scratch on a fresh Windows 11 / WSL2 machine.

## Prerequisites

- Windows 11 with WSL2 enabled
- Ubuntu 24.04 installed from the Microsoft Store
- At least 20 GB free disk space
- An internet connection for initial downloads

---

## Step 0: Enable WSL2 and install Ubuntu (skip if already done)

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

This enables WSL2 and installs Ubuntu in one step. Reboot when prompted.

After rebooting, Ubuntu will launch and ask you to create a username and
password. Once that's done, verify WSL2 is active:

```powershell
wsl --list --verbose
# Should show Ubuntu with VERSION 2
```

If you already have WSL1, upgrade it:
```powershell
wsl --set-version Ubuntu 2
wsl --set-default-version 2
```

Open the Ubuntu app (from the Start menu or by typing `wsl` in a terminal)
for all remaining steps.

---

## Step 1: Install Ollama in WSL

Open your WSL terminal and run:

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Verify the install:
```bash
ollama --version
```

Start the Ollama server (it may start automatically as a service):
```bash
ollama serve &
```

---

## Step 2: Download and configure the model

Pull the base Qwen3.5-9B model (~6.6 GB):
```bash
ollama pull qwen3.5
```

Save a version with an extended context window:
```bash
ollama run qwen3.5
```

Inside the Ollama REPL, type:
```
/set parameter num_ctx 16384
/save qwen3.5-16k
/bye
```

Verify the saved model appears:
```bash
ollama list
# Should show: qwen3.5-16k   ...   6.6 GB
```

---

## Step 3: Install OpenCode

```bash
curl -fsSL https://opencode.ai/install | sh
```

This installs OpenCode to `~/.opencode/bin/opencode`. Add it to PATH:
```bash
echo 'export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verify:
```bash
opencode --version
# Should show: 1.14.28 or similar
```

---

## Step 4: Configure OpenCode

Create the config file:
```bash
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen3.5:latest",
  "permission": {
    "bash": { "*": "allow", "rm": "ask" },
    "edit": "allow",
    "read": "allow"
  },
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen3.5:latest": { "tools": true },
        "qwen3.5-16k": { "tools": true }
      }
    }
  }
}
EOF
```

Fix ownership if needed:
```bash
sudo chown -R $USER:$USER ~/.config/opencode/
```

---

## Step 5: Install Python and other dependencies

```bash
sudo apt install python-is-python3 sqlite3 -y
pip install pytest --break-system-packages
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

`sqlite3` is required by the runner script to capture OpenCode session IDs
for transcript extraction.

---

## Step 6: Clone this repository

```bash
cd ~
git clone https://github.com/MattBecker92/767_OpenCode_Experiment.git
cd 767_OpenCode_Experiment
```

---

## Step 7: Verify the baseline

```bash
cd project
python -m pytest tests/ -v
```

Expected output: **2 failures, 8 passes** (the planted bugs are present).

Then run the scorer:
```bash
cd ~/767_OpenCode_Experiment
bash eval/check.sh baseline
```

Expected output: **0 / 5** (nothing has been fixed yet).

---

## Step 8: Run the experiment

Each iteration follows the same pattern:

```bash
cd ~/767_OpenCode_Experiment
bash runner/run_hybrid.sh iter_0
```

The script will:
1. Reset the project to its buggy baseline
2. Install the iteration's AGENTS.md (or none for iter_0)
3. Print each task prompt and wait for you to paste it into OpenCode
4. After all 5 tasks, automatically score and capture the transcript

The script runs 5 tasks. Human-readable versions of the first three are in
`tasks/`; all five are embedded in the runner script itself.

**To open OpenCode for each task, use a second terminal:**
```bash
cd ~/767_OpenCode_Experiment/project
ollama launch opencode
# Select qwen3.5-16k from the menu
```

> **Important:** Use `ollama launch opencode` (the TUI), not `opencode run`.
> The `opencode run` command exits after a single model response and will not
> complete any multi-step task. The TUI keeps the tool-execution loop alive
> for as long as the agent needs.

---

## Troubleshooting

See [docs/setup-troubleshooting.md](docs/setup-troubleshooting.md) for
solutions to common issues including:

- "Big Pickle / OpenCode Zen" appearing instead of local model
- Config files owned by root
- opencode run exiting immediately with no tool calls
- Wrong model (cloud variant) being selected
