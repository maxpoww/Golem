# base/security — the hardening every Standard carries, stage 0.
#
# The audit (2026-09-26) found the security surface was real but scattered and
# had no home of its own: firewall (network.nix), key-only SSH (ssh.nix),
# rebuild-scoped sudo (users.nix), the seal (golem-seal.nix). This leaf is the
# missing floor — brute-force defence, sane sudo, and a conservative kernel/
# network sysctl set.
#
# DELIBERATELY CONSERVATIVE. This machine is a developer's daily driver and,
# during the lab phase, is reached over SSH by the dev box. So this leaf does
# NOT do the things that would bite that:
#   • no kernel.yama.ptrace_scope — Max debugs live (waveview/Hyprland SEGVs);
#     ptrace across processes must keep working.
#   • no disabling systemd-coredump — a crash's core is how those SEGVs get
#     read; we keep cores.
#   • no unprivileged-BPF / kexec lockdown — too easy to break a desktop tool
#     with no attacker in this threat model.
# What it DOES is the boring, high-value floor that breaks nothing.
{ lib, ... }:

{
  # Brute-force defence. SSH is already key-only (ssh.nix), so the lab door
  # (key auth, never a failed password) is never counted and never banned;
  # sshguard only sheds the internet's password-spray noise. Lighter than
  # fail2ban (no python), which matters on the minimal.
  services.sshguard.enable = true;
  # It follows the journal from this boot's start, and finding that in a month of
  # journal reads most of it: 97 MB and 1400 seeks of a spinning disk, just as the
  # desktop starts (ASUS, 2026-10-31). On a disk idle otherwise, a minute and a half in;
  # SSH is key-only, so nothing is at stake meanwhile.
  systemd.services.sshguard = {
    wantedBy = lib.mkForce [ ];
    serviceConfig.IOSchedulingClass = "idle";
  };
  systemd.timers.sshguard = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "90s"; AccuracySec = "10s"; };
  };

  # Sudo hygiene (no NOPASSWD anywhere on an install, see users.nix):
  # explain itself once, and don't leave a long-lived unlocked timestamp.
  security.sudo.extraConfig = ''
    Defaults lecture = once
    Defaults timestamp_timeout = 15
  '';
  # Only the admin group may even run sudo (the owner is in it; any other
  # account, or a service user, gets "permission denied" before sudo parses
  # a single argument — sudo's own bugs, like 2025's chroot one, stay shut).
  security.sudo.execWheelOnly = true;
  # /tmp starts empty at every boot: what a session left there (downloads
  # opened from the browser, previews, other programs' scratch) does not
  # outlive it. Nothing of Standard's keeps anything there.
  boot.tmp.cleanOnBoot = true;

  # Conservative kernel + network hardening. Merges with core.nix's sysctls
  # (fq/bbr/printk) — disjoint keys, no conflict. Every value here is a
  # standard, desktop-safe hardening default.
  boot.kernel.sysctl = {
    # (kernel.kptr_restrict is already NixOS's default hardening at 1 — left
    # alone: overriding to 2 risks Max's perf_event_open profiling tooling.)
    "kernel.dmesg_restrict" = lib.mkDefault 1;
    # Network floor: reverse-path filtering, SYN cookies, no redirects or
    # source-routed packets, log martians.
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1;

    # THE QUIET HARDENING (the security study, 2026-11-12): what costs the
    # owner nothing — no prompt, no lost feature, no measurable speed — and
    # closes doors attackers use. Each is a KSPP / secureblue / Kicksecure
    # recommendation that a desktop never notices.
    # No loading a new kernel from a running one (Standard never kexecs).
    "kernel.kexec_load_disabled" = 1;
    # The BPF JIT's output hardened against JIT spraying.
    "net.core.bpf_jit_harden" = 2;
    # A program cannot make the kernel load a TTY line discipline module.
    "dev.tty.ldisc_autoload" = 0;
    # No opening another user's FIFO or file in a sticky shared folder
    # (/tmp tricks that turn a root program against itself).
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    # userfaultfd, a kernel-exploit staple, for privileged users only (the
    # kernel's own user-mode-only flag still works for everyone).
    "vm.unprivileged_userfaultfd" = 0;
    # This machine routes nothing for others: no ICMP redirects sent.
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    # TIME-WAIT assassination (RFC 1337).
    "net.ipv4.tcp_rfc1337" = 1;
  };

  # No merging of the kernel's memory caches (an overflow in one cannot land
  # in another's objects), and a shuffled page allocator. Both cost a few MB
  # and nothing a person can feel. (Memory zeroed on allocation and a random
  # kernel stack offset are already the kernel's defaults.)
  boot.kernelParams = [ "slab_nomerge" "page_alloc.shuffle=1" ];

  # Network protocols and filesystems no desktop uses, which any program could
  # otherwise make the kernel load by opening a socket or mounting a crafted
  # image — where kernel bugs keep being found (DCCP, SCTP, RDS, TIPC and the
  # ham-radio stack all had root exploits). Blacklisted, not removed: an admin
  # who needs one still loads it by name (modprobe sctp).
  boot.blacklistedKernelModules = [
    "dccp" "sctp" "rds" "tipc" "n_hdlc" "ax25" "netrom" "rose" "x25" "atm"
    "appletalk" "psnap" "p8022" "p8023" "llc2" "ieee802154_socket" "rxrpc"
    "cramfs" "freevxfs" "jffs2" "hfs" "vivid"
  ];
}
