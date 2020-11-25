syslog "Disable HF"
tcsend LWC08042 {LWP93100 IGNORE} {LWP92100 IGNORE} {LWP91100 DISABLE} checks ALL
waittime 1.0000

syslog "HF Power Off"
tcsend LWC08053 {LWP95000 HF} checks ALL

