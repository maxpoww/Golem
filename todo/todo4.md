# todo4 — S4 System controls

<!-- Coarse on purpose — break down on entry. Each control = an OPTIONS
     module (collector → provider → surface). -->

- [ ] Survey the D-Bus/system landscape: NetworkManager, BlueZ, PipeWire/
      wpctl, logind/UPower, wlr-output — what each collector listens to
- [ ] wi-fi module (list/join networks)
- [ ] bluetooth module (pair/connect)
- [ ] audio module (output/input picker, volume)
- [ ] brightness + power/battery module
- [ ] displays module (arrangement, scale)
- [ ] Decide surface pattern: topbar pills vs a "system" box (keep coherent)
