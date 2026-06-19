#!/usr/bin/env node

import { copyFileSync, existsSync, mkdirSync, readdirSync, rmSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const skillName = "computer-use-repair";
const currentFile = fileURLToPath(import.meta.url);
const repoRoot = resolve(dirname(currentFile), "..");
const source = join(repoRoot, "skill", skillName);
const codexHome = process.env.CODEX_HOME || join(homedir(), ".codex");
const target = join(codexHome, "skills", skillName);

function copyDirectory(from, to) {
  mkdirSync(to, { recursive: true });

  for (const entry of readdirSync(from)) {
    const sourcePath = join(from, entry);
    const targetPath = join(to, entry);
    const stat = statSync(sourcePath);

    if (stat.isDirectory()) {
      copyDirectory(sourcePath, targetPath);
    } else if (stat.isFile()) {
      mkdirSync(dirname(targetPath), { recursive: true });
      copyFileSync(sourcePath, targetPath);
    }
  }
}

if (!existsSync(join(source, "SKILL.md"))) {
  console.error(`Skill source not found: ${source}`);
  process.exit(1);
}

mkdirSync(dirname(target), { recursive: true });
if (existsSync(target)) {
  rmSync(target, { recursive: true, force: true });
}

copyDirectory(source, target);

console.log(`Installed ${skillName} to ${target}`);
console.log("Restart Codex Desktop to refresh skill discovery.");
