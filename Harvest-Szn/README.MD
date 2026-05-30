# Harvest-Szn

> Windows System Inventory & Audit Collection Payload for Hak5 Bash Bunny

![Version](https://img.shields.io/badge/version-1.0-blue)
![Platform](https://img.shields.io/badge/platform-Windows%2011-success)
![Device](https://img.shields.io/badge/device-Bash%20Bunny-orange)

---

## Overview

**Harvest-Szn** is a Windows-focused Bash Bunny payload designed to automate system inventory collection and host auditing tasks during authorized security assessments, asset management activities, and laboratory testing.

The payload leverages the Bash Bunny's **HID** and **STORAGE** capabilities to execute a PowerShell-based collection script and store gathered information directly on the device for later analysis.

---

## Author

**Author:** Hackazillarex
**Version:** 1.0

---

## Features

### System Information

* Computer name
* Operating system details
* Windows build information
* Hardware manufacturer and model
* Physical memory statistics
* CPU information

### Network Enumeration

* Active network adapters
* MAC addresses
* IP configuration
* Default gateways
* DNS configuration

### User & Group Discovery

* Local user accounts
* Account status information
* Local groups
* Group membership details

### Environment Analysis

* Environment variables
* User profile information
* System configuration data

### System Activity

* Running processes
* Running services
* Recently installed software
* PowerShell history (when available)

### Remote Access Artifacts

* RDP connection history
* Related configuration data

### Logging & Error Handling

* Timestamped output files
* Dedicated error logging
* Structured report generation

---

## Payload Information

| Property     | Value             |
| ------------ | ----------------- |
| Title        | Harvest-Szn       |
| Author       | Hackazillarex     |
| Version      | 1.0               |
| Category     | Audit / Inventory |
| Target       | Windows           |
| Tested On    | Windows 11        |
| Attack Modes | HID, STORAGE      |

---

## How It Works

### Stage 1 — Initialization

The Bash Bunny:

* Configures HID and STORAGE attack modes
* Mounts the Bash Bunny storage volume
* Creates the required loot directories
* Prepares the execution environment

### Stage 2 — Collection

The PowerShell collection script:

* Identifies the Bash Bunny storage volume
* Creates timestamped output files
* Collects host inventory information
* Records discovered configuration data
* Generates structured audit logs

### Stage 3 — Storage

Collected information is written to:

```text
loot/
└── Harvest-Szn/
    ├── system_info_YYYYMMDD_HHMMSS.txt
    ├── errors_YYYYMMDD_HHMMSS.txt
    └── loot_YYYYMMDD_HHMMSS.txt
```

### Stage 4 — Completion

The payload finalizes execution and indicates completion using Bash Bunny LED states.

---

## LED Status Indicators

| LED State | Description                   |
| --------- | ----------------------------- |
| SETUP     | Initializing payload          |
| STAGE1    | Preparing execution           |
| STAGE2    | Collecting system information |
| CLEANUP   | Finalizing operations         |
| FINISH    | Payload completed             |

---

## Requirements

### Hardware

* Hak5 Bash Bunny

### Target System

* Windows 10 / Windows 11
* PowerShell support
* Appropriate permissions for inventory collection

---

## Output Files

### System Report

Contains collected inventory and audit information:

```text
system_info_YYYYMMDD_HHMMSS.txt
```

### Error Report

Contains execution errors and exceptions:

```text
errors_YYYYMMDD_HHMMSS.txt
```

### Collection Log

Contains raw execution output:

```text
loot_YYYYMMDD_HHMMSS.txt
```

---

## Project Structure

```text
Harvest-Szn/
├── payload.txt
├── payload.ps1
├── README.md
└── loot/
    └── Harvest-Szn/
```

---

## Notes

* Output files are timestamped to prevent overwriting previous runs.
* Error handling is implemented throughout the collection process.
* Results may vary depending on Windows version and available PowerShell modules.
* Some information may require elevated privileges depending on target configuration.

---

## Disclaimer

This project is intended for use in authorized security assessments, audit engagements, training environments, and defensive security operations only.

Users are solely responsible for ensuring they have proper authorization before executing this payload on any system or network.

---

## License

Provided for educational, research, and authorized security testing purposes.

Use responsibly.
