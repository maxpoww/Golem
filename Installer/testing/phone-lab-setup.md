# Phone lab driver — one-time setup (Pixel 8 Pro, Debian terminal)

Turn the Pixel into a **portable lab driver**: a Claude Code session that
finds a booted lab machine over the network, tests it, and pushes the
records to the repo — so the dev box (or any machine) can be tested
without the machine that drives the lab being up. No ISO changes: the
same round-3 stick works everywhere; the phone is the brain.

The whole design in one line: **the repo (github.com/maxpoww/Golem) is
the shared memory.** The phone pushes records; the dev-box Claude pulls
them. See [phone-lab-driver.md](phone-lab-driver.md) for how the phone
session actually runs a test once this setup is done.

## Do this once, on the phone

Open the Pixel's **Linux Terminal** (Settings → System → Developer
options → Linux development environment, or the Terminal app). That's a
Debian VM. Everything below runs inside it.

1. **Node + Claude Code.**
   ```sh
   sudo apt update && sudo apt install -y nodejs npm git openssh-client
   node --version        # want >= 18; if apt's is older, use nodesource
   npm install -g @anthropic-ai/claude-code
   ```
   If apt's node is too old:
   ```sh
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

2. **Log Claude Code in.** Run `claude` once; follow the login flow in the
   phone's browser (same account as the dev box). This is the step most
   likely to need a second try on mobile — persevere, it's one-time.

3. **Clone the repo** (this carries the lab playbook + all records):
   ```sh
   git clone https://github.com/maxpoww/Golem.git ~/Golem
   ```
   Pushing needs a GitHub credential — set up a personal-access-token
   (HTTPS) or `gh auth login` once, so `git push` works unattended.

4. **The lab SSH key.** The phone must hold the `golem-vm-loop` private
   key (already trusted by every stick). Copy `~/.ssh/id_ed25519` from the
   dev box to the phone's `~/.ssh/id_ed25519` (via LocalSend, or paste it
   — it's 399 bytes). Then:
   ```sh
   chmod 600 ~/.ssh/id_ed25519
   ```
   The public half is already baked into the ISO, so this key opens
   `root@` on any booted medium. Guard it — it is the lab's trust anchor.

5. **Network check.** The phone must be on the **home wifi**
   (192.168.1.0/24), not cellular, or it cannot see the lab machines.
   Confirm the Debian VM sees the LAN:
   ```sh
   ip -4 addr | grep 192.168.1    # should show an address on the subnet
   ```
   (If the Debian VM is NAT'd off the phone and can't reach the LAN, that
   is the one thing that can sink this plan — test it early. Worst case,
   the phone reaches the machines but from a different subnet; sort the
   VM's networking before relying on it.)

## The handshake, each test (full detail in phone-lab-driver.md)

1. On the phone: `cd ~/Golem && git pull` — always start synced.
2. Boot the machine under test from the normal round-3 stick.
3. On the phone: `claude` — tell it which machine is booting; it does the
   census + rehearsal, writes the record, commits, pushes.
4. Reboot that machine back to normal.
5. On the dev box: say hello to me; I `git pull` and read what the phone
   pushed. Caught up.

## The one rule that protects everything

Only one Claude drives at a time, and **pull before you drive, push when
you're done.** If both sessions edit without syncing, the records diverge
and you get merge conflicts. The repo is the single source of truth;
treat a push as "handing over the baton."
