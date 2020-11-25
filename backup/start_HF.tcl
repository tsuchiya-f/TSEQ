#Connection test	
tcsend LWC17001 checks ALL
waittime 1

#Mode change to Sci
tcsend LWC08032 {LWP95001 SCIENCE_MODE} {LWP95002 0} {LWP99005 NORMAL_SUBMODE} checks ALL
waittime 1

#Disable HK for HF
tcsend LWC03006 {LWP31000 HF_REG} checks ALL
waittime 1

#Set HK higher rate	
tcsend LWC03130 {LWP31000 HF_REG} {LWP32000 1} checks ALL
waittime 1

#Enable HK for HF
tcsend LWC03005 {LWP31000 HF_REG} checks ALL
waittime 1

#Power ON HF
tcsend LWC08052 {LWP95000 HF} checks ALL
waittime 5

#Enable HF only
tcsend LWC08041 {LWP93000 IGNORE} {LWP92000 IGNORE} {LWP91000 ENABLE} checks ALL
