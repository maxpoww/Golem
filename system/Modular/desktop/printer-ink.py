"""golem-printer-ink <hp device uri>: the ink an HP printer tells, a line
each: <kind> TAB <percent left>. The kind is HPLIP's agent type: 1 black,
2 tri-colour, 3 photo, 4 cyan, 5 magenta, 6 yellow (base/codes.py has
the rest).

For the printers that do not tell CUPS (most HP inkjets over USB): HPLIP's
own device code asked directly. hp-levels and hp-info start HPLIP's tray
icon (through D-Bus) and look on the internet for an HPLIP update every
time they run; this does neither. Exit 2: the printer did not answer — off,
busy with a print (the print holds it), or stuck on a sheet.

Run by the dock's Printers page (launcher printers_page.rs).
"""

import os
import site
import sys

hplip = os.environ["GOLEM_HPLIP"]
site.addsitedir(os.path.join(hplip, os.environ["GOLEM_SITE"]))
sys.path.insert(0, os.path.join(hplip, "share", "hplip"))

from base import device, g  # noqa: E402

g.log.set_level("error")

try:
    d = device.Device(sys.argv[1], disable_dbus=True)
    d.open()
    try:
        d.queryDevice(quick=False)
    finally:
        d.close()
except Exception as e:  # HPLIP raises its own Error, and anything below it
    print("golem-printer-ink: %s" % (e,), file=sys.stderr)
    sys.exit(2)

for i in range(1, 32):
    kind = d.dq.get("agent%d-type" % i)
    if kind is None:
        break
    print("%s\t%s" % (kind, d.dq.get("agent%d-level" % i)))
