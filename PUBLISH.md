# Publish To GitHub

This repository is ready to publish. The current environment does not have GitHub CLI (`gh`) installed or authenticated.

## Option 1: GitHub CLI

Install and authenticate GitHub CLI, then run from this repository root:

```powershell
gh auth login
gh repo create computer-use-repair --public --source . --remote origin --push --description "Codex skill for diagnosing and repairing Browser and Computer Use runtime issues on Windows"
```

## Option 2: GitHub Web UI

1. Create a new empty GitHub repository named `computer-use-repair`.
2. Copy its HTTPS remote URL.
3. Run:

```powershell
git remote add origin https://github.com/<owner>/computer-use-repair.git
git push -u origin main
```

Replace `<owner>` with your GitHub username or organization.
