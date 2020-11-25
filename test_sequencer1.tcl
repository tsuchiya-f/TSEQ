syslog "Connection Test"
tcsend LWC17001 checks ALL
syslog "Science mode"
tcsend LWC08032 {LWP95001 SCIENCE_MODE} {LWP95002 0} {LWP99005 NORMAL_SUBMODE} checks ALL
waittime 1.0000
syslog "Setting new trip levels"
tcsend LWC08056 {LWP99015 SET_OVV_37} {LWP99016 220} checks ALL
tcsend LWC08056 {LWP99015 SET_OVV_975} {LWP99016 220} checks ALL
tcsend LWC08056 {LWP99015 SET_OVV_N975} {LWP99016 220} checks ALL
tcsend LWC08056 {LWP99015 SET_OVC_LP_37} {LWP99016 220} checks ALL
tcsend LWC08056 {LWP99015 SET_OVC_LP_975} {LWP99016 220} checks ALL
tcsend LWC08056 {LWP99015 SET_OVC_LP_N975} {LWP99016 220} checks ALL
tcsend LWC08056 {LWP99015 SET_OVC_LF_37} {LWP99016 220} checks ALL
tcsend LWC08056 {LWP99015 SET_OVC_LF_975} {LWP99016 220} checks ALL
tcsend LWC08056 {LWP99015 SET_OVC_HF_37} {LWP99016 220} checks ALL
tcsend LWC08056 {LWP99015 SET_OVC_HF_975} {LWP99016 220} checks ALL
syslog "Reset any trip"
tcsend LWC08057 checks ALL
waittime 1.0000


syslog "Power on HF"
tcsend LWC08052 {LWP95000 HF} checks ALL
waittime 3.0000

# Place you start code here

#syslog "Set HF Cfg6"
#tcsend LWC08054 {LWP94000 HF} {LWP99010 6} checks ALL
#waittime 10.0000

#syslog "Enable HF"
#tcsend LWC08041 {LWP93000 IGNORE} {LWP92000 IGNORE} {LWP91000 ENABLE} checks ALL

# #----------------------------------------
#
# # From here to start the sequencer

 syslog "Power on LP"
 tcsend LWC08052 {LWP95000 LP} checks ALL
 waittime 3.0000
 syslog "Power on LF"
 tcsend LWC08052 {LWP95000 LF} checks ALL
 waittime 3.0000
 syslog "Start sequencer 1"
 tcsend LWC08032 {LWP95001 SCIENCE_MODE} {LWP95002 1} {LWP99005 NORMAL_SUBMODE} checks ALL



