syslog "Connection Test"
tcsend LWC17001 checks ALL
syslog "Science mode"
tcsend LWC08032 {LWP95001 SCIENCE_MODE} {LWP95002 0} {LWP99005 NORMAL_SUBMODE} checks ALL
waittime 10.0000
syslog "Setting new trip levels"
tcsend LWC08056 {LWP99015 SET_OVV_37} {LWP99016 220} checks ALL
waittime 1.0000
tcsend LWC08056 {LWP99015 SET_OVV_975} {LWP99016 220} checks ALL
waittime 1.0000
tcsend LWC08056 {LWP99015 SET_OVV_N975} {LWP99016 220} checks ALL
waittime 1.0000
tcsend LWC08056 {LWP99015 SET_OVC_LP_37} {LWP99016 220} checks ALL
waittime 1.0000
tcsend LWC08056 {LWP99015 SET_OVC_LP_975} {LWP99016 220} checks ALL
waittime 1.0000
tcsend LWC08056 {LWP99015 SET_OVC_LP_N975} {LWP99016 220} checks ALL
waittime 1.0000
tcsend LWC08056 {LWP99015 SET_OVC_LF_37} {LWP99016 220} checks ALL
waittime 1.0000
tcsend LWC08056 {LWP99015 SET_OVC_LF_975} {LWP99016 220} checks ALL
waittime 1.0000
tcsend LWC08056 {LWP99015 SET_OVC_HF_37} {LWP99016 220} checks ALL
waittime 1.0000
tcsend LWC08056 {LWP99015 SET_OVC_HF_975} {LWP99016 220} checks ALL
waittime 1.0000
syslog "Reset any trip"
tcsend LWC08057 checks ALL
waittime 1.0000


syslog "Get HF HK every second"
tcsend LWC03006 {LWP31000 HF_REG} checks ALL
tcsend LWC03130 {LWP31000 HF_REG} {LWP32000 1} checks ALL
tcsend LWC03005 {LWP31000 HF_REG} checks ALL

syslog "Power on HF"
tcsend LWC08052 {LWP95000 HF} checks ALL
waittime 10.0000
