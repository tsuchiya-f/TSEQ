# This TSC script is intended for use together with the matlab script
# plot_sid_timing.m and does the following:
#
# 1. Subscribes to all to all subunit (lp, lf, hf, mime) telemetry.
# 2. Merges groups of telemetry (based on grouping flags) into single chunks.
# 3. Prepends a sync word (0xEB90EB90EB90), the PRID, CUC packet creation
#    time, and the AUX field of the first packet in the group to the chunk.
# 4. Appends the raw science data (no rpwi header) from all packets in the
#    group to the chunk.
# 5. Sends each completed chunk to any clients listening on localhost:7900
#
# The CUC packet creation time represents the time when the packet was sent,
# which usually does not match the time of the sample science data well, or at
# all.

set packets_per_prid_per_sid [dict create]
set group_store_per_prid [dict create]
set first_packet_rcvd_per_prid [dict create]

set lp_packets_per_sid [dict create]
set lf_packets_per_sid [dict create]
set hf_packets_per_sid [dict create]
set mime_packets_per_sid [dict create]
set lp_group_store {}
set lf_group_store {}
set hf_group_store {}
set mime_group_store {}
set lp_first_packet_rcvd 0
set lf_first_packet_rcvd 0
set hf_first_packet_rcvd 0
set mime_first_packet_rcvd 0
set sockChan 0

## Get sequence control flags from packet
#
# @param pkt Reference to packet.
#
# @return Sequence control flags as integer.
proc getgroupingflags {pkt} {
	return [::utope::tmprop [gettmcacheid $pkt] groupingFlags]
}

## Get science data from packet.
#
# @param header Flag indicating if header is present or not.
# @param pkt Reference to packet.
#
# @return Science data from packet as a 8-bit signed integer list.
proc getsciencedata {header pkt} {
	set rawdata [getrawdata $pkt]

	set rawbindata [hextobin $rawdata]

	set hdr_len 6
	set dfh_len 10
	set rpwi_hdr_len 8
	set n_skip [expr {$hdr_len + $dfh_len + $rpwi_hdr_len}]
	set rauxlen 0

	if {$header == 1} {
		#binary scan $rawbindata c16c1I1c1 nothing rsid rdeltatime rauxlen
		binary scan $rawbindata c16c1I1c2c1 nothing rsid rdeltatime seqcount rauxlen
		set raux {}
		binary scan $rawbindata c22c$rauxlen nothing raux

		incr n_skip [expr {$rauxlen}]
	}

	set n_mydata [expr {[string length $rawbindata] - $n_skip - 2}]
	binary scan $rawbindata c${n_skip}c${n_mydata}c2 nothing mydata crc

	return $mydata
}

## Get PUS CUC time from packet data
#
# @param pkt Reference to packet.
#
# @return CUC time from PUS packet as a 8-bit signed integer list.
proc get_cuc_time {pkt} {
	set raw_data [getrawdata $pkt]

	set raw_bindata [hextobin $raw_data]

	set cuc_time_offset [expr 6 + 4]
	set cuc_time_len [expr 4 + 2]

	binary scan $raw_bindata c${cuc_time_offset}c${cuc_time_len} discard cuc_time

	return $cuc_time
}

## Get PRID from PUS packet data
#
# @param pkt Reference to packet.
#
# @return PRID from PUS packet.
proc get_prid {pkt} {
	set raw_data [getrawdata $pkt]

	set raw_bindata [hextobin $raw_data]

	binary scan $raw_bindata S1c* packet_id discard

	set prid_shift 4
	set prid_bits 7
	set prid_mask [expr {((1 << $prid_bits) - 1) << $prid_shift}]

	set prid [expr {($packet_id & $prid_mask) >> $prid_shift}]

	return $prid
}

## Get rpwi science packet from PUS packet data
#
# @param pkt Reference to packet.
#
# @return rpwi science packet from PUS packet as a 8-bit signed integer list.
proc get_rpwi_science_data {pkt} {
	set raw_data [getrawdata $pkt]

	set raw_bindata [hextobin $raw_data]

	set hdr_len 6
	set dfh_len 10
	set crc_len 2
	set pus_headers_len [expr {$hdr_len + $dfh_len}]
	set rpwi_data_len [expr {[string length $raw_bindata] - $pus_headers_len - $crc_len}]

	binary scan $raw_bindata c${pus_headers_len}c${rpwi_data_len}c${crc_len} pus_headers rpwi_science_packet crc

	return $rpwi_science_packet
}

## Get SID from packet.
#
# @param pkt Reference to packet.
#
# @return SID from packet as a 8-bit signed integer.
proc get_sid {pkt} {
	set raw_data [getrawdata $pkt]
	set raw_bindata [hextobin $raw_data]

	binary scan $raw_bindata c16c1 pus_headers rpwi_sid

	return $rpwi_sid
}

## Accept client connection to server.
#
# This functions is intended to be passed as the callback command in the socket
# server initialisation call.
#
# Currently overwrites the global socket channel based on the latest connected
# client, hence connecting more than one client does not work.
#
# @param channel New socket channel to associate with the client.
# @param addr Address of the connecting client.
# @param addr Port of the connecting client.
proc acceptConnection { channel addr port } {
	global sockChan

	syslog -src TEST "Accept $channel connection from $addr on port $port"

	# Flush automatically after every output
	fconfigure $channel -buffering none
	# Send raw bytes
	fconfigure $channel -encoding binary
	# Avoid injecting carriage return before 0x10 bytes
	fconfigure $channel -translation binary

	set sockChan $channel
}

## Send data to a socket channel.
#
# The data will be sent in string format, delimited by spaces.
#
# @param channel Socket channel to send data to.
# @param data Data to send.
proc sendData {channel data} {
	set rawbytes [binary format c* $data]
	if {[catch {puts -nonewline $channel $rawbytes} err]} {
		syslog -src TEST "Failed to send data: $err"
		return
	}
}

## Get science data from packets and send to client.
#
# Uses packet sequence control flags to determine sequencing. Stand alone
# packets are sent directly, whereas sequenced packets are accumulated and sent
# as a recombined set of packets.
#
# This is intended to be registered as a trace callback whenever the packet
# variable is updated by write.
#
# @param pkt Reference to packet.
# @param unused_idx Unused (index into array if tracing array).
# @param unused_op Unused (operation being performed on packet variable).
proc processPacket {pkt_ref unused_idx unused_op} {
	global sockChan

	global packets_per_prid_per_sid
	global group_store_per_prid
	global first_packet_rcvd_per_prid

	# need to grab variable from outer scope here
	upvar $pkt_ref pkt

	set myrawdata [getrawdata $pkt]

	if {[llength $myrawdata] == 0} {
		# Skip processing zero-length data, for some reason this is
		# received at initialization.
		return
	}

	set prid [get_prid $pkt]
	set sid [get_sid $pkt]

	if {[dict exists $packets_per_prid_per_sid $prid $sid] == 0} {
		dict set packets_per_prid_per_sid $prid $sid 0
	}

	if {[dict exists $first_packet_rcvd_per_prid $prid] == 0} {
		dict set first_packet_rcvd_per_prid $prid 0
	}

	switch [getgroupingflags $pkt] {
		1 { # first packet
			if {[dict get $first_packet_rcvd_per_prid $prid]} {
				syslog -src TEST "Sequence error, unexpected first packet"
				syslog -src TEST "prid $prid, sid $sid"
			}
			dict set first_packet_rcvd_per_prid $prid 1
			dict set group_store_per_prid $prid {}
			dict lappend group_store_per_prid $prid [expr 0xEB]
			dict lappend group_store_per_prid $prid [expr 0x90]
			dict lappend group_store_per_prid $prid [expr 0xEB]
			dict lappend group_store_per_prid $prid [expr 0x90]
			dict lappend group_store_per_prid $prid [expr 0xEB]
			dict lappend group_store_per_prid $prid [expr 0x90]
			dict lappend group_store_per_prid $prid $prid
			dict lappend group_store_per_prid $prid {*}[get_cuc_time $pkt]
			dict lappend group_store_per_prid $prid {*}[get_rpwi_science_data $pkt]
		}

		0 { # continuation packet
			if {[dict get $first_packet_rcvd_per_prid $prid]} {
				dict lappend group_store_per_prid $prid {*}[getsciencedata 0 $pkt]
			} else {
				syslog -src TEST "Sequence error, unexpected coninuation packet"
				syslog -src TEST "prid $prid, sid $sid"
				dict set group_store_per_prid $prid {}
			}

		}

		2 { # last packet
			set last_packet_id [gettmcacheid $pkt]
			if {[dict get $first_packet_rcvd_per_prid $prid]} {
				dict lappend group_store_per_prid $prid {*}[getsciencedata 0 $pkt]
				dict set packets_per_prid_per_sid $prid $sid [expr {[dict get $packets_per_prid_per_sid $prid $sid] + 1}]

				sendData $sockChan [dict get $group_store_per_prid $prid]
				syslog -src TEST "length group_store: [llength [dict get $group_store_per_prid $prid]]"
				syslog -src TEST "prid $prid sid $sid, [dict get $packets_per_prid_per_sid $prid $sid] total packets"
				dict set first_packet_rcvd_per_prid $prid 0
			}
		}

		3 { # standalone packet
			dict set group_store_per_prid $prid {}
			dict lappend group_store_per_prid $prid [expr 0xEB]
			dict lappend group_store_per_prid $prid [expr 0x90]
			dict lappend group_store_per_prid $prid [expr 0xEB]
			dict lappend group_store_per_prid $prid [expr 0x90]
			dict lappend group_store_per_prid $prid [expr 0xEB]
			dict lappend group_store_per_prid $prid [expr 0x90]
			dict lappend group_store_per_prid $prid $prid
			dict lappend group_store_per_prid $prid {*}[get_cuc_time $pkt]
			dict lappend group_store_per_prid $prid {*}[get_rpwi_science_data $pkt]

			dict set packets_per_prid_per_sid $prid $sid [expr {[dict get $packets_per_prid_per_sid $prid $sid] + 1}]

			sendData $sockChan [dict get $group_store_per_prid $prid]
			syslog -src TEST "length group_store: [llength [dict get $group_store_per_prid $prid]]"
			syslog -src TEST "prid $prid sid $sid, [dict get $packets_per_prid_per_sid $prid $sid] total packets"
			dict set first_packet_rcvd_per_prid $prid 0
		}

		default {
			syslog -src TEST "strange packet with grouping flag: [getgroupingflags $pkt]. id: [gettmcacheid $pkt]"

			dict set first_packet_rcvd_per_prid $prid 0
		}
	}
}

set acceptSock [socket -server acceptConnection 7900]

trace add variable ::lp_tm write processPacket
trace add variable ::lf_tm write processPacket
trace add variable ::hf_tm write processPacket
trace add variable ::mime_tm write processPacket

subscribepacket 79000 referby lp_tm
subscribepacket 79001 referby lf_tm
subscribepacket 79002 referby hf_tm
subscribepacket 79003 referby mime_tm

vwait forever

return
