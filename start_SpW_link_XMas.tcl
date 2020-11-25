set SPW_LINK 2

::CncProto::sendcnc SIS_TC "TRANSFER REMOTE"
::CncProto::sendcnc SIS_TC "gensettcspaceroutingtag $SPW_LINK"
::CncProto::sendcnc SIS_TC "spwopenlink $SPW_LINK,100,y"
::CncProto::sendcnc SIS_TC "spwstartlink $SPW_LINK"
