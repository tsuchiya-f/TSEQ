syslog -src INIT_A "=============================================================================="
syslog -src INIT_A "Shut down INSTRUMENT"
syslog -src INIT_A "=============================================================================="

setup_and_connect_sis

::CncProto::sendcnc SIS_TC "TRANSFER REMOTE"
waittime 3.0000

::CncProto::sendcnc SIS_TC "spwcloselink 1,100,n"
waittime 1.0000

::CncProto::sendcnc SIS_TC "PFEswitchOffLimiter 1 1"
waittime 1.0000

::CncProto::sendcnc SIS_TC "PFEswitchOffPsu 1 1"
waittime 1.0000

::CncProto::sendcnc SIS_TC "TRANSFER LOCAL"
waittime 1.0000

