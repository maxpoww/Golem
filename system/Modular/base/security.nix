# base/security — the hardening every Golem carries, stage 0.
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

  # Sudo hygiene (no NOPASSWD anywhere on an install, see users.nix):
  # explain itself once, and don't leave a long-lived unlocked timestamp.
  security.sudo.extraConfig = ''
    Defaults lecture = once
    Defaults timestamp_timeout = 15
  '';

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
  };
}
