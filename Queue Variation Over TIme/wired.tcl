
set ns [new Simulator]
set NumSenders 50

set NumReceivers 1




set BufSize 100

set PktSize 1024 

#set winSize 200

#in seconds

set Duration 50 

#create all nodes: note that the order of creating the nodes matter

for {set i 1} {$i <= $NumSenders} {incr i} {

    set s($i) [$ns node]

}

set r1 [$ns node]

set d1 [$ns node]

 

 

#open the nam trace file

set nf [open out.nam w]

$ns namtrace-all $nf

 

#open the traffic trace file to record all events

set nd [open traceFile.tr w]

$ns trace-all $nd

 

#define a finish procedure

proc finish {} {

    global ns nf nd qtf

    $ns flush-trace

    close $nf

    close $nd

    close $qtf

    #start nam

    #exec nam out.nam &

    exit 0

}

 

#link the nodes

  Queue/RED set thresh_ 20

    Queue/RED set maxthresh_ 60



Queue/RED set queue_in_bytes_ false

Queue/RED set gentle_ false

 

for {set i 1} {$i <= $NumSenders} {incr i} {

    $ns duplex-link $s($i) $r1 10Mb 100ms DropTail

    $ns queue-limit $s($i) $r1 $BufSize

}

#r1 d1 and d1 r1 are different

$ns duplex-link $r1 $d1 3Mb 100ms RED

$ns queue-limit $r1 $d1 $BufSize

 

#trace the queue: note that link r1 d1 is different from d1 r1

set redq [[$ns link $r1 $d1] queue]

set qtf [open queue.txt w]

$redq trace curq_

$redq trace ave_

$redq attach $qtf

 

#set up TCP connections

for {set i 1} {$i <= $NumSenders} {incr i} {

    set tcp($i) [new Agent/TCP]

    $ns attach-agent $s($i) $tcp($i)

    set sink($i) [new Agent/TCPSink]

    $ns attach-agent $d1 $sink($i)

    $ns connect $tcp($i) $sink($i)

    $tcp($i) set fid_ $i

    $tcp($i) set packetSize_ $PktSize

    #$tcp($i) set window_ $winSize

    #set up FTP over TCP connection as traffic source

    set ftp($i) [new Application/FTP]

    $ftp($i) attach-agent $tcp($i)

    $ftp($i) set type_ FTP

}

 

#schedule events for the FTP agents

set StartTime [expr [ns-random]  / 2147483647.0 / 100]

puts "starttime $StartTime"

#temporarily set to 2

for {set i 1} {$i <= $NumSenders} {incr i}  {

    $ns at $StartTime "$ftp($i) start"

    $ns at $Duration+$StartTime "$ftp($i) stop"

}

#ensure the ftp application have enough time to finish, so we +1

$ns at $Duration+$StartTime+1 "finish"

 

#run the simulation

$ns run


