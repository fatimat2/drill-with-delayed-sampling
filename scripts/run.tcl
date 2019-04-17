# Copyright (c) 2015, The Board of Trustees of The Leland Stanford Junior 
# University. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# * Neither the name of copyright holder nor the names of the contributors may 
#   be used to endorse or promote products derived from this software without 
#   specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

source "tcp-common-opt-flows.tcl"

set ns [new Simulator]
set sim_start [clock seconds]

set sim_end [lindex $argv 0]
set link_rate [lindex $argv 1]
set mean_link_delay [lindex $argv 2]
set host_delay [lindex $argv 3]
set queueSize [lindex $argv 4]
set load [lindex $argv 5]
set connections_per_pair [lindex $argv 6]
set meanFlowSize [lindex $argv 7]
set paretoShape [lindex $argv 8]
set flow_cdf [lindex $argv 9]

#### Transport settings options
set ackRatio [lindex $argv 14]
set max_rto [lindex $argv 15]
set initWindow [lindex $argv 16]
set min_rto [lindex $argv 17]
set prob_cap_ [lindex $argv 18] ; # Threshold of consecutive timeouts to trigger probe mode

#### topology
set topology_spt [lindex $argv 10]
set topology_tors [lindex $argv 11]
set topology_spines [lindex $argv 12]
set topology_x [lindex $argv 13]

set enableTrace [lindex $argv 19]
### result file
if {$enableTrace != 0} {
    set tracefile [open [lindex $argv 22]trace.tr w]
    $ns trace-all $tracefile
    Classifier/MultiPath set a_log 0
} else {
    set flowlog [open [lindex $argv 22]flow.tr w]
    Classifier/MultiPath set a_log 1
}

#### Packet size is in bytes.
set pktSize 1460
#### trace frequency
#set queueSamplingInterval 0.0001

################# Transport Options ####################
Agent/TCP set ecn_ 1
Agent/TCP set old_ecn_ 1
Agent/TCP set packetSize_ $pktSize
Agent/TCP/FullTcp set segsize_ $pktSize
Agent/TCP set slow_start_restart_ true
Agent/TCP set windowOption_ 0
Agent/TCP set minrto_ $min_rto
Agent/TCP set maxrto_ $max_rto
Agent/TCP set rtxcur_init_ $min_rto;

Agent/TCP/FullTcp set interval_ 0.000006

Agent/TCP set window_ 1000000
Agent/TCP set windowInit_ $initWindow
Agent/TCP/FullTcp/Sack set clear_on_timeout_ false;
Agent/TCP/FullTcp/Sack set sack_rtx_threshmode_ 2;
Agent/TCP/FullTcp set segsperack_ $ackRatio;
Agent/TCP/FullTcp set prob_cap_ $prob_cap_;
Agent/TCP/FullTcp set prio_scheme_ 2;

if {$ackRatio > 2} {
    Agent/TCP/FullTcp set spa_thresh_ [expr ($ackRatio - 1) * $pktSize]
}

Agent/TCP set tcpTick_ 0.000001

Agent/TCP/FullTcp set spa_thresh_ 0
Agent/TCP/FullTcp set nodelay_ true; # disable Nagle
Agent/TCP/FullTcp set dynamic_dupack_ 1000000; #disable dupack

if {$queueSize > $initWindow } {
    Agent/TCP set maxcwnd_ [expr $queueSize - 1];
} else {
    Agent/TCP set maxcwnd_ $initWindow
}

set myAgent "Agent/TCP/FullTcp/Sack";

Agent/TCP set ecnhat_ true
Agent/TCPSink set ecnhat_ true

################# Switch Options ######################
Queue set limit_ $queueSize

Queue/DropTail set queue_in_bytes_ true
Queue/DropTail set mean_pktsize_ [expr $pktSize+40]

############## Multipathing ###########################
$ns rtproto DV
Agent/rtProto/DV set advertInterval [expr 200*$sim_end]
Node set multiPath_ 1

Classifier/MultiPath set mp_proto [lindex $argv 20]
Classifier/MultiPath set samplingDelay [lindex $argv 21]ms

############# Topoplgy #########################
set S [expr $topology_spt * $topology_tors] ; #number of servers
set UCap [expr $link_rate * $topology_spt / $topology_spines / $topology_x] ; #uplink rate

puts "UCap: $UCap"

for {set i 0} {$i < $S} {incr i} {
    set s($i) [$ns node]
}

for {set i 0} {$i < $topology_tors} {incr i} {
    set n($i) [$ns node]
}

for {set i 0} {$i < $topology_spines} {incr i} {
    set a($i) [$ns node]
}

############ Edge links ##############
for {set i 0} {$i < $S} {incr i} {
    set j [expr $i/$topology_spt]
    $ns duplex-link $s($i) $n($j) [set link_rate]Gb [expr $host_delay + $mean_link_delay] DropTail
}

############ Core links ##############
for {set i 0} {$i < $topology_tors} {incr i} {
    for {set j 0} {$j < $topology_spines} {incr j} {
        $ns duplex-link $n($i) $a($j) [set UCap]Gb $mean_link_delay DropTail
    }
}

#############  Agents ################
set lambda [expr ($link_rate*$load*1000000000)/($meanFlowSize*8.0/1460*1500)]
#set lambda [expr ($link_rate*$load*1000000000)/($mean_npkts*($pktSize+40)*8.0)]
puts "Arrival: Poisson with inter-arrival [expr 1/$lambda * 1000] ms"
puts "FlowSize: Pareto with mean = $meanFlowSize, shape = $paretoShape"

set flow_gen 0
set flow_fin 0
set init_fid 0
for {set j 0} {$j < $S } {incr j} {
    puts "($j)- "
    for {set i 0} {$i < $S } {incr i} {
        if {$i != $j} {
            set agtagr($i,$j) [new Agent_Aggr_pair]
            $agtagr($i,$j) setup $s($i) $s($j) "$i $j" $connections_per_pair $init_fid "TCP_pair"
            if {$enableTrace == 0} {
                $agtagr($i,$j) attach-logfile $flowlog
            }
            #For Poisson/Pareto
            $agtagr($i,$j) set_PCarrival_process [expr $lambda/($S - 1)] $flow_cdf [expr 17*$i+1244*$j] [expr 33*$i+4369*$j]

            $ns at 0.1 "$agtagr($i,$j) warmup 0.5 5"
            $ns at 1 "$agtagr($i,$j) init_schedule"

            #set init_fid [expr $init_fid + $connections_per_pair * 4];
        }
    }
}

puts "Simulation started!"

$ns at 30 "finish"
$ns run
