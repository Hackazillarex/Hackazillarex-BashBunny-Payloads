# ZillaPeas
Author: Hackazillarex
Version: 1.0

## Overview

**ZillaPeas** is a Bash Bunny payload designed for automated Windows security auditing and post-exploitation simulation in controlled environments. It integrates HID automation with removable storage access to execute a predefined auditing workflow.

This project is intended for **authorized security testing, penetration testing labs, and red team simulations only**.

---

## ⚠️ Legal & Ethical Notice

This tool is provided strictly for:

- Authorized penetration testing
- Security research in controlled environments
- Defensive security validation

Unauthorized use against systems you do not own or have explicit permission to test is illegal and unethical. The author assumes no liability for misuse.

---

## Features

- Automated Windows PowerShell execution via HID injection
- Launches elevated PowerShell session (UAC interaction required)
- Executes custom payload scripts from attached storage
- Temporary system security configuration changes for testing scenarios
- Automatic restoration of system security settings after execution
- LED status indicators for stage tracking (Bash Bunny)

---

## Architecture

ZillaPeas relies on a **fixed USB payload structure**:

BashBunny (USB Drive)
├── payloads
├── tooling
│ └── winPEASx64_ofs.exe <-- you are responsible for putting the .exe there. I will not provide it.
└── loot
└── WinPeas
└── results.txt

## Target

- Windows 10 / Windows 11 (Tested on Windows 11)

---

## Attack Modes

- HID (Human Interface Device emulation)
- STORAGE (USB mass storage payload delivery)

---

## Workflow Summary

ZillaPeas performs the following high-level steps:

1. Initializes HID + Storage attack modes
2. Creates local loot directory for potential output collection
3. Launches an elevated PowerShell session (requires user approval)
4. Executes a payload script from the device storage
5. Runs configured auditing actions
6. Restores Windows Defender and SmartScreen settings
7. Ends execution and resets device state

---

### Loot Directory
/root/udisk/loot/WinPeas



