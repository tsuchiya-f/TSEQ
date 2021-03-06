syslog "Disable HF"
tcsend LWC08042 {LWP93100 IGNORE} {LWP92100 IGNORE} {LWP91100 DISABLE} checks ALL
waittime 1.0000

syslog "Set new HF Cfg6 (LWP8205 0x0133 -> 0x0132, Sigma-Delta HK Disable)"
tcsend LWC08136 {LWP94200 6} {LWP82000 774} {LWP82003 60} {LWP820BE 3} {LWP820B0 0x0} {LWP820B1 0x0} {LWP820B2 0x2103} {LWP820B3 383} {LWP820B4 257} {LWP820B5 0x0132} {LWP820B6 0x01FF} {LWP820B7 0x0} {LWP820B8 0x0} {LWP820B9 0x0} {LWP820BA 0xF401} {LWP820BB 0x0} {LWP820BC 0x0} {LWP820BD 0x0} checks ALL
waittime 1.0000

tcsend LWC08040 {LWP94000 HF} checks ALL
waittime 1.0000

tcsend LWC08054 {LWP94000 HF} {LWP99010 6} checks ALL
waittime 10.0000

syslog "Enable HF"
tcsend LWC08041 {LWP93000 IGNORE} {LWP92000 IGNORE} {LWP91000 ENABLE} checks ALL

waittime 90.0000

syslog "Disable HF"
tcsend LWC08042 {LWP93100 IGNORE} {LWP92100 IGNORE} {LWP91100 DISABLE} checks ALL
waittime 1.0000

syslog "Set new HF Cfg6 (LWP8205 0x0132 -> 0x0133, Sigma-Delta HK Enable)"
tcsend LWC08136 {LWP94200 6} {LWP82000 774} {LWP82003 60} {LWP820BE 3} {LWP820B0 0x0} {LWP820B1 0x0} {LWP820B2 0x2103} {LWP820B3 383} {LWP820B4 257} {LWP820B5 0x0133} {LWP820B6 0x01FF} {LWP820B7 0x0} {LWP820B8 0x0} {LWP820B9 0x0} {LWP820BA 0xF401} {LWP820BB 0x0} {LWP820BC 0x0} {LWP820BD 0x0} checks ALL
waittime 1.0000

tcsend LWC08040 {LWP94000 HF} checks ALL
waittime 1.0000

tcsend LWC08054 {LWP94000 HF} {LWP99010 6} checks ALL
waittime 10.0000

syslog "Enable HF"
tcsend LWC08041 {LWP93000 IGNORE} {LWP92000 IGNORE} {LWP91000 ENABLE} checks ALL
