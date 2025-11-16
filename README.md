# 🚀 Claude Code Workflow (CCW)

<div align="center">

[![Version](https://img.shields.io/badge/version-v5.5.0-blue.svg)](https://github.com/ding113/Claude-Code-Workflow/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey.svg)]()

**Languages:** [English](README.md) | [中文](README_CN.md)

</div>

---

**Claude Code Workflow (CCW)** transforms AI development from simple prompt chaining into a robust, context-first orchestration system. It solves execution uncertainty and error accumulation through structured planning, deterministic execution, and intelligent multi-model orchestration.

> **🎉 Version 5.5: Interactive Command Guide & Enhanced Documentation**
>
> **Core Improvements**:
> - ✨ **Command-Guide Skill** - Interactive help system with CCW-help and CCW-issue triggers
> - ✨ **Enhanced Command Descriptions** - All 69 commands updated with detailed functionality descriptions
> - ✨ **5-Index Command System** - Organized by category, use-case, relationships, and essentials
> - ✨ **Smart Recommendations** - Context-aware next-step suggestions for workflow guidance
>
> See [CHANGELOG.md](CHANGELOG.md) for full details.

> 📚 **New to CCW?** Check out the [**Getting Started Guide**](GETTING_STARTED.md) for a beginner-friendly 5-minute tutorial!

---

## ✨ Core Concepts

CCW is built on a set of core principles that differentiate it from traditional AI development approaches:

- **Context-First Architecture**: Pre-defined context gathering eliminates execution uncertainty by ensuring agents have the correct information *before* implementation.
- **TOON-First State Management**: Task states live in `.task/IMPL-*.toon` bundles that encode the same structure with 30-60% fewer tokens (benchmarked in `tests/integration/toon-format.test.ts`), eliminating state drift while extending context capacity.
- **Autonomous Multi-Phase Orchestration**: Commands chain specialized sub-commands and agents to automate complex workflows with zero user intervention.
- **Multi-Model Strategy**: Leverages the unique strengths of different AI models (Gemini for analysis, Codex for implementation) for superior results.
- **Hierarchical Memory System**: A 4-layer documentation system provides context at the appropriate level of abstraction, preventing information overload.
- **Specialized Role-Based Agents**: A suite of agents (`@code-developer`, `@test-fix-agent`, etc.) mirrors a real software team to handle diverse tasks.

### 🧾 TOON Format Benefits

The IMPL-001 → IMPL-004 migration moved every workflow artifact to TOON as the canonical format. Compared with equivalent JSON dumps, TOON bundles consistently save 30-60% tokens (see `tests/integration/toon-format.test.ts`), allowing more history per request while staying human-readable. Utilities in `src/utils/toon.ts` keep JSON interoperability through `autoDecode()` so legacy task files continue to work without manual conversion.

---

## ⚙️ Installation

For detailed installation instructions, please refer to the [**INSTALL.md**](INSTALL.md) guide.

### **🚀 Quick One-Line Installation**

**Windows (PowerShell):**
```powershell
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.ps1" -UseBasicParsing).Content
```

**Linux/macOS (Bash/Zsh):**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ding113/Claude-Code-Workflow/main/install-remote.sh)
```

### **✅ Verify Installation**
After installation, open **Claude Code** and check if the workflow commands are available by running:
```bash
/workflow:session:list
```
If the slash commands (e.g., `/workflow:*`) are recognized, the installation was successful.

---

## 🛠️ Command Reference

CCW provides a rich set of commands for managing workflows, tasks, and interacting with AI tools. For a complete list and detailed descriptions of all available commands, please see the [**COMMAND_REFERENCE.md**](COMMAND_REFERENCE.md) file.

For a detailed technical specification of every command, see the [**COMMAND_SPEC.md**](COMMAND_SPEC.md).

---

### 💡 **Need Help? Use the Interactive Command Guide**

CCW includes a built-in **command-guide skill** to help you discover and use commands effectively:

- **`CCW-help`** - Get interactive help and command recommendations
- **`CCW-issue`** - Report bugs or request features with guided templates

The command guide provides:
- 🔍 **Smart Command Search** - Find commands by keyword, category, or use-case
- 🤖 **Next-Step Recommendations** - Get suggestions for what to do after any command
- 📖 **Detailed Documentation** - View parameters, examples, and best practices
- 🎓 **Beginner Onboarding** - Learn the top 14 essential commands with a guided learning path
- 📝 **Issue Reporting** - Generate standardized bug reports and feature requests

**Example Usage**:
```
User: "CCW-help"
→ Interactive menu with command search, recommendations, and documentation

User: "What's next after /workflow:plan?"
→ Recommends /workflow:execute, /workflow:action-plan-verify, with workflow patterns

User: "CCW-issue"
→ Guided template generation for bugs, features, or questions
```

---

## 🚀 Getting Started

The best way to get started is to follow the 5-minute tutorial in the [**Getting Started Guide**](GETTING_STARTED.md).

Here is a quick example of a common development workflow:

1.  **Create a Plan** (automatically starts a session):
    ```bash
    /workflow:plan "Implement JWT-based user login and registration"
    ```
2.  **Execute the Plan**:
    ```bash
    /workflow:execute
    ```
3.  **Check Status** (optional):
    ```bash
    /workflow:status
    ```

---

## 🤝 Contributing & Support

- **Repository**: [GitHub - Claude-Code-Workflow](https://github.com/ding113/Claude-Code-Workflow)
- **Issues**: Report bugs or request features on [GitHub Issues](https://github.com/ding113/Claude-Code-Workflow/issues).
- **Discussions**: Join the [Community Forum](https://github.com/ding113/Claude-Code-Workflow/discussions).

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
