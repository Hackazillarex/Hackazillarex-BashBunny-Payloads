# Window-Shopping

**Hak5 Bash Bunny Payload — RedTeam Auditing**

Generates a OneDrive sharing link for the target's Desktop folder and emails it to a specified address via Outlook. Gives persistent remote access to browse the target's Desktop through OneDrive — no malware, no Defender triggers, just native Windows features.

## How It Works

1. Opens PowerShell (non-elevated) and locates the OneDrive-synced Desktop folder
2. Invokes the OneDrive share dialog via the Shell.Application COM object
3. Navigates the share dialog with HID keystrokes to copy the sharing link
4. Opens Outlook via Windows search and composes a new email
5. Types the recipient, subject, and body, then pastes the link from clipboard
6. Sends the email and dismisses the "forgot attachment?" prompt
7. Clears the clipboard and cleans up

## Requirements

- **Target OS:** Windows 10 / 11
- **OneDrive:** Signed in and syncing the Desktop folder
- **Outlook:** Running (new Outlook or classic — no COM dependency)
- **Hardware:** Hak5 Bash Bunny (Mark I or II)
- **Attack Mode:** HID only (no STORAGE needed)

## Configuration

Edit the variables at the top of `payload.txt`:

```bash
EXFIL_EMAIL="youremail@example.com"   # Where to send the link
EMAIL_SUBJECT="Project Files"          # Email subject line
EMAIL_BODY="Link attached."            # Email body text
```

## Installation

1. Plug in the Bash Bunny in arming mode (switch 3)
2. Copy `payload.txt` to `/payloads/switch1/` or `/payloads/switch2/`
3. Eject, flip to the payload switch position, and plug into the target

## LED Status

| LED | Stage |
|-----|-------|
| SETUP | Initializing HID |
| STAGE1 | Opening PowerShell |
| STAGE2 | Locating OneDrive Desktop & opening share dialog |
| STAGE3 | Copying sharing link |
| STAGE4 | Opening Outlook |
| STAGE5 | Composing email |
| STAGE6 | Sending email |
| CLEANUP | Clearing clipboard |
| FINISH | Done |

## Timing Adjustments

The payload uses conservative delays. If the target machine is fast, you can reduce the `QUACK DELAY` values. Key delays to tune:

- **Stage 2** — `QUACK DELAY 5000` after opening share dialog (wait for dialog to load)
- **Stage 4** — `QUACK DELAY 3000` after opening Outlook (wait for app to focus)
- **Stage 5** — `QUACK DELAY 1500` after Ctrl+N (wait for compose window)

## Notes

- No Defender bypass needed — the payload uses only native OneDrive and Outlook functionality
- No STORAGE mode — eliminates the auto-play / trash folder popup issue
- No Outlook COM — works with both new Outlook (web-app) and classic Outlook
- The share dialog tab count (9 tabs) was mapped on Windows 11 — may need adjustment on other versions
- The "forgot attachment?" dismiss may not appear on all Outlook configurations; the extra Enter is harmless if it doesn't

## Author

**Hackazillarex**
- GitHub: [@Hackazillarex](https://github.com/Hackazillarex)
- YouTube: [@Hackazillarex](https://youtube.com/@Hackazillarex)
- TikTok: [@hackazillarex](https://tiktok.com/@hackazillarex)

## Disclaimer

This payload is intended for authorized red team engagements and security auditing only. Unauthorized use against systems you do not own or have permission to test is illegal. Use responsibly.
