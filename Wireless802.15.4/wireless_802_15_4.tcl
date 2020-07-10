
if { $argc != 4 } {
    puts "Please pass parameters properly"
	puts "Format : ns <tcl filename> <#nodes> <#flows> <#packets per sec> <transmission range multiplier>"
	puts "Example : ns wireless_802_15_4.tcl 25 10 500 2"
	exit 0;
    }
proc attach-cbr-traffic { node sink size interval rate } {
	#Get an instance of the simulator
	set ns [Simulator instance]

	#Create a UDP agent and attach it to the node
	set source [new Agent/UDP]
	
	$ns attach-agent $node $source

	#Create an Expoo traffic agent and set its configuration parameters
	set traffic [new Application/Traffic/CBR]
	$traffic set packetSize_ $size
	$traffic set interval_ $interval
    $traffic set rate_ $rate    
        # Attach traffic source to the traffic generator
    $traffic attach-agent $source
	#Connect the source and the sink
	$ns connect $source $sink
	return $traffic
}
proc attach-cbr-traffic-tcp { node sink interval rate } {
	#Get an instance of the simulator
	set ns [Simulator instance]

	#Create a UDP agent and attach it to the node
	set source [new Agent/TCP]
	$source set windowOption_ 99
	$ns attach-agent $node $source

	#Create an Expoo traffic agent and set its configuration parameters
	set traffic [new Application/Traffic/CBR]
	$traffic set interval_ $interval
    $traffic set rate_ $rate     
        # Attach traffic source to the traffic generator
    $traffic attach-agent $source
	#Connect the source and the sink
	$ns connect $source $sink
	return $traffic
}
#####################Variables to be used for changing stuff around
set isTCP 1
set num_random_flow [lindex $argv 1]
set num_node [lindex $argv 0]
set txRangeMult [lindex $argv 3]
set cbr_size 64 ; 
set cbr_rate 11.0Mb
set cbr_pckt_per_sec [lindex $argv 2]
set cbr_interval [expr 1.0/$cbr_pckt_per_sec] ;# ?????? 1 for 1 packets per second and 0.1 for 10 packets per second
set x_dim [expr 150*$num_node/25] ; #[lindex $argv 1]
set y_dim [expr 150*$num_node/25] ; #[lindex $argv 1]
set time_duration 5 ; #[lindex $argv 5] ;#50
set start_time 10 ;#100
set parallel_start_gap 0.0
set cross_start_gap 0.0
#set val(stop) 35;	

set val(chan) Channel/WirelessChannel ;# channel type
set val(prop) Propagation/TwoRayGround ;# radio-propagation model
set val(netif) Phy/WirelessPhy/802_15_4 ;# network interface type
set val(mac) Mac/802_15_4 ;# MAC type
#set val(mac) SMac/802_15_4 ;# MAC type
set val(ifq) Queue/DropTail/PriQueue ;# interface queue type
set val(ll) LL ;# link layer type
set val(ant) Antenna/OmniAntenna ;# antenna model
set val(ifqlen) 100 ;# max packet in ifq
set val(rp) AODV ;# routing protocol
set val(energymodel) EnergyModel;
set val(initialenergy) 100;


Mac/802_15_4 set dataRate_ 11Mb


set time_duration 5 ; #[lindex $argv 5] ;#50
set start_time 0 ;#100
set extra_time 10 ;#10

set src Agent/UDP
set sink Agent/Null



Mac/802_15_4 set syncFlag_ 1

Mac/802_15_4 set dutyCycle_ cbr_interval

set nm out.nam
set tr traceFile.tr
set topo_file topology.txt

#
# Initialize ns
#
set ns [new Simulator]
set tracefd [open $tr w]
$ns trace-all $tracefd

#
#Initializing nam
#
set namtrace [open $nm "w"]
$ns namtrace-all-wireless $namtrace $x_dim $y_dim

set topofile [open $topo_file "w"]
#[expr *$txRangeMult]
set dist(5m)  7.69113e-06
set dist(9m)  2.37381e-06
set dist(10m) 1.92278e-06
set dist(11m) 1.58908e-06
set dist(12m) 1.33527e-06
set dist(13m) 1.13774e-06
set dist(14m) 9.81011e-07
set dist(15m) 8.54570e-07
set dist(16m) 7.51087e-07
set dist(20m) 4.80696e-07
set dist(25m) 3.07645e-07
set dist(30m) 2.13643e-07
set dist(35m) 1.56962e-07
set dist(40m) 1.20174e-07
set dist(50m) 7.69113e-08
set dist(75m) 3.41828e-08
set dist(100m) 1.42681e-08
set dist(125m) 5.8442e-09
set dist(150m) 2.81838e-09
set dist(175m) 1.52129e-09
set dist(200m) 8.91754e-10
set dist(225m) 5.56717e-10
set dist(250m) 3.65262e-10
set dist(500m) 2.28289e-11
set dist(1000m) 1.42681e-12
if {$txRangeMult==1} {
Phy/WirelessPhy set CSThresh_ $dist(25m)
Phy/WirelessPhy set RXThresh_ $dist(25m)
}
if {$txRangeMult==2} {
Phy/WirelessPhy set CSThresh_ $dist(50m)
Phy/WirelessPhy set RXThresh_ $dist(50m)
}
if {$txRangeMult==3} {
Phy/WirelessPhy set CSThresh_ $dist(75m)
Phy/WirelessPhy set RXThresh_ $dist(75m)
}
if {$txRangeMult==4} {
Phy/WirelessPhy set CSThresh_ $dist(100m)
Phy/WirelessPhy set RXThresh_ $dist(100m)
}
if {$txRangeMult==5} {
Phy/WirelessPhy set CSThresh_ $dist(125m)
Phy/WirelessPhy set RXThresh_ $dist(125m)
}
# set up topography object
set topo [new Topography] ;# This is needed for wireless
$topo load_flatgrid $x_dim $y_dim; #Setting a 2D space for the nodes

#CREATE GOD
create-god [expr $num_node ]




$ns node-config -adhocRouting $val(rp) -llType $val(ll) \
	     -macType $val(mac)  -ifqType $val(ifq) \
	     -ifqLen $val(ifqlen) -antType $val(ant) \
	     -propType $val(prop) -phyType $val(netif) \
	     -channel  [new $val(chan)] -topoInstance $topo \
	     -agentTrace ON -routerTrace OFF\
	     -macTrace ON \
	     -movementTrace OFF \
             -energyModel $val(energymodel) \
             -initialEnergy $val(initialenergy) \
             -rxPower 35.28e-3 \
             -txPower 31.32e-3 \
	     -idlePower 712e-6 \
	     -sleepPower 144e-9


puts "starting node creation"
for {set i 0} {$i < [expr $num_node]} {incr i} { ;#Creating $num_node number of nodes 
	set node_($i) [$ns node] ;#Creating node

	$node_($i) random-motion 0 ;#Setting random motion off for making static
}

puts "nodes creation complete"
set i 0;
while {$i < $num_node } {

	#Set random position for nodes
	set x_pos [expr int($x_dim*rand())] ;#random settings
	set y_pos [expr int($y_dim*rand())] ;#random settings

	$node_($i) set X_ $x_pos
	$node_($i) set Y_ $y_pos
	$node_($i) set Z_ 0.0

	puts -nonewline $topofile "$i x: [$node_($i) set X_] y: [$node_($i) set Y_] \n"
	incr i;
}; 

#creating flows
if {$isTCP == 0} {
for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	set null_($i) [new Agent/Null]

}

set max [expr $num_node-1]

set i 0
while {$i < $num_random_flow } {
	set x [expr int($max*rand())]
	set y [expr int($max*rand())]
	if {$x != $y} {
	$ns attach-agent $node_($x) $null_($i)	
	set source_($i) [attach-cbr-traffic $node_($y) $null_($i) 200 $cbr_interval $cbr_rate]
	puts -nonewline $topofile " Src: $y Dest: $x\n"
	incr i;
	}
	}
} else {
	set tcp [new Agent/TCP]


for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	set sink_($i) [new Agent/TCPSink]

}
set max [expr $num_node-1]
set i 0
while {$i < $num_random_flow } {
	set x [expr int($max*rand())]
	set y [expr int($max*rand())]
	if {$x != $y} {
	$ns attach-agent $node_($x) $sink_($i)	
	set source_($i) [attach-cbr-traffic-tcp $node_($y) $sink_($i) $cbr_interval $cbr_rate]
	puts -nonewline $topofile " Src: $y Dest: $x\n"
	incr i;
	}
	}

}
set start_time 0
for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	set start_time [expr $start_time+0.5]
	$ns at $start_time "$source_($i) start"
	#puts "$i at $startTime"
	#set endTime [expr $startTime+$duration]
	#$ns at $endTime "$source_($i) stop"
}

for {set i 0} {$i < [expr $num_node] } {incr i} {
    $ns at [expr $start_time+$time_duration] "$node_($i) reset";
}
$ns at [expr $start_time+$time_duration +$extra_time] "finish"
$ns at [expr $start_time+$time_duration +$extra_time] "$ns nam-end-wireless [$ns now]; puts \"NS Exiting...\"; $ns halt"

$ns at [expr $start_time+$time_duration/2] "puts \"half of the simulation is finished\""
$ns at [expr $start_time+$time_duration] "puts \"end of simulation duration\""

#puts "done starting all flows at $startTime "
#set endTime [expr $startTime+0.5]
#for {set i 0} {$i < [expr $num_random_flow]} {incr i} {
	#set endTime [expr $endTime+0.5]
	#$ns at $endTime "$source_($i) stop"
	#puts "$i at $endTime"
#}
##set finishTime [expr $endTime+0.5]
#$ns at $finishTime "finish"

puts "flow creation and movement complete"
######################################################################Flows created

# Tell nodes when the simulation ends


proc finish {} {
	puts "finishing"
	global ns tracefd namtrace topofile nm
	$ns flush-trace
	close $tracefd
	close $namtrace
	close $topofile
    #  exec nam $nm &
        exit 0
}


for {set i 0} {$i < [expr $num_node]  } { incr i} {
	$ns initial_node_pos $node_($i) 4
}

puts "Starting Simulation..."
$ns run 
