# Claude OS (Linux)

A custom bootc image built on Bazzite (KDE Plasma, Intel/AMD graphics). GitHub builds it daily on top of
the latest Bazzite, so it keeps getting Bazzite's updates with the Claude OS changes applied on top.

## What it adds to Bazzite

- OS name "Claude OS" in About this System and the boot menu
- Your logo as the launcher icon, About page logo and boot splash (from `build_files/branding/logo.png`)
- The `cos` command: `setup`, `update`, `health`, `status`, `rollback`, `clean`, `export`, `import`
- A default app list installed by `cos setup` (`system_files/usr/share/claudeos/flatpaks.list`)

## Setup

1. **Install stock Bazzite on the mini PC.** Download the Desktop / Intel / KDE image from bazzite.gg,
   write it to a USB stick and install it.
2. **Create the repo.** On GitHub open `ublue-os/image-template`, choose "Use this template", name it
   `claude-os`, keep it Public. Then open the Actions tab and enable workflows.
3. **Add the signing key** (the build fails without it). In a terminal:
   ```bash
   COSIGN_PASSWORD="" cosign generate-key-pair
   ```
   In the repo: Settings > Secrets and variables > Actions > New repository secret, name it
   `SIGNING_SECRET`, paste the contents of `cosign.key`. Keep `cosign.pub`; never upload `cosign.key`.
4. **Add your logo** as `build_files/branding/logo.png` (optional).
5. **Upload these files.** In the repo: Add file > Upload files, then drag in `Containerfile`,
   `image-template.env`, `README.md`, `cosign.pub`, and the `build_files` and `system_files` folders. Commit.
6. **Wait for the build.** Actions tab, "Build container image", green tick (roughly 10 to 20 minutes).
7. **Switch the mini PC to it:**
   ```bash
   sudo bootc switch ghcr.io/<your-github-username>/claude-os
   systemctl reboot
   ```
8. **First run:** open Konsole and run `cos setup`.

## Installing from a Claude OS ISO instead

Do steps 2 to 6 above first (the image has to exist before an ISO can be made from it), and include the
`disk_config` folder in the upload.

1. Edit `disk_config/iso.toml` in the repo: replace `YOUR-GITHUB-USERNAME` with your username (lowercase).
2. Actions tab > "Build disk images" > Run workflow > platform `amd64` > Run.
3. When it finishes, open the run and download the `anaconda-iso` artifact under Artifacts (a zip with the ISO).
4. Write the ISO to a USB stick, boot the mini PC from it and install. You create your user in the installer.
5. If the PC does not boot afterwards with Secure Boot on, turn Secure Boot off in the BIOS, boot, then
   enrol the Universal Blue key (on Bazzite this is `ujust enroll-secure-boot-key`) and turn it back on.

## Remote access from Windows

On the mini PC, once:

```bash
cos remote enable     # SSH + Sunshine, then create the Sunshine login at https://localhost:47990
```

On the Windows rig (needs the updated `cos.ps1` in `C:\ClaudeOS\bin`), once:

```powershell
cos link <mini-pc-ip> <linux-user>   # key login, "ssh claudeos" alias, installs Moonlight
cos pair                             # enter the shown PIN in the Sunshine page that opens
```

Day to day: `cos connect` (desktop), `cos ssh` (terminal), `cos files` (home folder as Z:),
`cos run health` (run cos on the mini PC), `cos wake` (wake-on-LAN).

Sunshine streams the session that is logged in on the mini PC, so turn on auto-login if it runs without a
keyboard. `cos remote rdp` sets up KDE's RDP server instead, for `cos rdp` / the Windows Remote Desktop client.

## Undo

`cos rollback` then reboot returns to the previous image. To go back to plain Bazzite:
`sudo bootc switch ghcr.io/ublue-os/bazzite:stable`.

## Changing things later

Edit files in the repo and commit. GitHub rebuilds the image, and `cos update` on the mini PC pulls it.
