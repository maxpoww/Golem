# The highest refresh rate, in Hz, that a screen's EDID names anywhere: its
# range of rates and its timings, in the first block and in every CTA-861
# and DisplayID extension. Reads one byte a line (od -An -v -tu1 -w1);
# prints 0 when it cannot be read.
{ b[n++] = $1 + 0 }

function up(hz) { if (hz > top) top = hz }

# An 18-byte detailed timing (EDID, CTA-861): its rate; 0 for none or an
# interlaced one (the compositor never uses those).
function dtd(at,   clk, ht, vt) {
  clk = b[at] + b[at+1] * 256
  if (clk == 0 || int(b[at+17] / 128) % 2) return 0
  ht = b[at+2] + int(b[at+4] / 16) * 256 + b[at+3] + (b[at+4] % 16) * 256
  vt = b[at+5] + int(b[at+7] / 16) * 256 + b[at+6] + (b[at+7] % 16) * 256
  return (ht && vt) ? clk * 10000 / (ht * vt) : 0
}

# A 20-byte DisplayID timing, its clock in `unit` Hz (type I: 10 kHz,
# type VII: 1 kHz), every field stored minus one.
function did(at, unit,   clk, ht, vt) {
  if (int(b[at+3] / 16) % 2) return 0
  clk = (b[at] + b[at+1] * 256 + b[at+2] * 65536 + 1) * unit
  ht = b[at+4] + b[at+5] * 256 + 1 + b[at+6] + b[at+7] * 256 + 1
  vt = b[at+12] + b[at+13] * 256 + 1 + b[at+14] + b[at+15] * 256 + 1
  return clk / (ht * vt)
}

END {
  if (n < 128) { print 0; exit }
  # The first block: four descriptors, each a timing or a range of rates
  # (0xFD; its byte 4 bit 1 adds 255 to the highest).
  for (at = 54; at <= 108; at += 18) {
    if (b[at] || b[at+1]) up(dtd(at))
    else if (b[at+3] == 253) up(b[at+6] + (int(b[at+4] / 2) % 2) * 255)
  }
  # CTA-861 short video codes over 75 Hz (progressive, 720 lines and up).
  split("41 100 47 120 63 120 64 100 70 100 71 120 77 100 78 120 84 100 85 120 91 100 92 120 117 100 118 120 119 100 120 120", v, " ")
  for (i = 1; (i + 1) in v; i += 2) vic[v[i]] = v[i+1]
  for (base = 128; base + 128 <= n; base += 128) {
    if (b[base] == 2) {
      # CTA-861: data blocks up to byte d (a Video Data Block, tag 2, lists
      # codes; 129-192 are 1-64 marked native), then detailed timings.
      d = b[base+2]
      for (at = base + 4; at < base + d && at < base + 127; at += 1 + len) {
        len = b[at] % 32
        if (int(b[at] / 32) == 2)
          for (j = at + 1; j <= at + len; j++) {
            c = b[j]
            if (c >= 129 && c <= 192) c -= 128
            if (c in vic) up(vic[c])
          }
      }
      if (d >= 4)
        for (at = base + d; at + 18 <= base + 127; at += 18) {
          if (!(b[at] || b[at+1])) break
          up(dtd(at))
        }
    } else if (b[base] == 112) {
      # DisplayID: data blocks of tag, revision, length, payload.
      end = base + 5 + b[base+2]
      if (end > base + 127) end = base + 127
      for (at = base + 5; at + 3 <= end; at += 3 + len) {
        t = b[at]
        len = b[at+2]
        if (t == 0 && len == 0) break
        if (t == 3 || t == 34)
          for (j = at + 3; j + 20 <= at + 3 + len; j += 20) up(did(j, t == 3 ? 10000 : 1000))
        else if (t == 9 && len >= 12) up(b[at+14])
        else if (t == 37 && len >= 9) up(b[at+10] + (b[at+11] % 4) * 256)
      }
    }
  }
  printf "%d\n", top + 0.5
}
