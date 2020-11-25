syslog "Set HF Cfg0"
tcsend LWC08054 {LWP94000 HF} {LWP99010 0} checks ALL
waittime 10.0000

syslog "Enable HF"
tcsend LWC08041 {LWP93000 IGNORE} {LWP92000 IGNORE} {LWP91000 ENABLE} checks ALL

