#!/bin/bash

#The metrics to be calculated
throughput=0.0
delay=0.0
delivery_ratio=0.0
drop_ratio=0.0
mkdir Graphs
cd Graphs
rm -rf throughput.dat
rm -rf delay.dat
rm -rf delivery_ratio.dat
rm -rf drop_ratio.dat


cd ..
#temp files to store the points for the graphs
th=Graphs/throughput.dat #for throughput
d=Graphs/delay.dat #for end-to-end delay 
de=Graphs/delivery_ratio.dat #for delivery ratio
dr=Graphs/drop_ratio.dat #for drop ratio

simulate()
{
	wirednodes=$1
	flows=$2	
	wirelessnodes=$3
	

	throughput=0.0
	delay=0.0
	delivery_ratio=0.0
	drop_ratio=0.0
	

	
	r=1
	it=1
	itf=1.0
	while [ $r -le $it ]
	do
	echo "Iteration $(($r + 0)) starting"
	echo "iterating with $wirednodes wired nodes, $flows flows and $wirelessnodes wireless nodes"
	
	ns wired_cum_wireless.tcl $wirednodes $flows $wirelessnodes 
	awk -f AWK_wired_wireless.awk traceFile.tr > output.out
	i=0
	while read val
	do
	
	if [ $i = 0 ]; then
		throughput=$(echo "scale=5; $throughput+$val/$itf" | bc)
	elif [ $i = 1 ]; then
		delay=$(echo "scale=5; $delay+$val/$itf" | bc)
	elif [ $i = 2 ]; then
		delivery_ratio=$(echo "scale=5; $delivery_ratio+$val/$itf" | bc)
	elif [ $i = 3 ]; then
		drop_ratio=$(echo "scale=5; $drop_ratio+$val/$itf" | bc)
	fi
	
	let i=$(($i+1))
	done < output.out 
	echo "Iteration $(($r + 0)) finished"
	rm -rf out.nam
	rm -rf traceFile.tr
	r=$(($r+1))
	done
	
	
	echo "Throughput     : $throughput"
	echo "Delay          : $delay"
	echo "Delivery Ratio : $delivery_ratio"
	echo "Drop Ratio     : $drop_ratio"
}
	

#		Varies number of nodes
#		Takes the outputs and stores them in tmp files
#		Then plots graphs



#		Varies transmission range
#		Takes the outputs and stores them in tmp files
#		Then plots graphs


wirednodes()
{
	for(( iteration=20;iteration<=100;iteration+=20))
	do
		echo "Simulating with $iteration wired nodes"
		simulate $iteration 10 20
		echo "$iteration $throughput" >> $th
		echo "$iteration $delay" >> $d
		echo "$iteration $delivery_ratio" >> $de
		echo "$iteration $drop_ratio" >> $dr
	done
	gnuplot -c "plotGraph.sh" "WiredNodes_Throughput" "WiredNodes" "Throughput" "$th" "WiredNodes_Throughput"
	gnuplot -c "plotGraph.sh" "WiredNodes_Delay" "WiredNodes" "Delay" "$d" "WiredNodes_Delay"
	gnuplot -c "plotGraph.sh" "WiredNodes_DeliveryRatio" "WiredNodes" "Delivery ratio" "$de" "WiredNodes_DeliveryRatio"
	gnuplot -c "plotGraph.sh" "WiredNodes_DropRatio" "WiredNodes" "Drop ratio" "$dr" "WiredNodes_DropRatio"
	#exec xgraph $th

}

#		Varies number of flows
#		Takes the outputs and stores them in tmp files
#		Then plots graphs


flows()
{
	for(( iteration=10;iteration<=50;iteration+=10))
	do
		echo "Simulating with $iteration flows"
		simulate 20 $iteration 20
		echo "$iteration $throughput" >> $th
		echo "$iteration $delay" >> $d
		echo "$iteration $delivery_ratio" >> $de
		echo "$iteration $drop_ratio" >> $dr
	done
	gnuplot -c "plotGraph.sh" "Flows_Throughput" "Flows" "Throughput" "$th" "Flows_Throughput"
	gnuplot -c "plotGraph.sh" "Flows_Delay" "Flows" "Delay" "$d" "Flows_Delay"
	gnuplot -c "plotGraph.sh" "Flows_DeliveryRatio" "Flows" "Delivery ratio" "$de" "Flows_DeliveryRatio"
	gnuplot -c "plotGraph.sh" "Flows_DropRatio" "Flows" "Drop ratio" "$dr" "Flows_DropRatio"
	#exec xgraph $th


}


#		Varies number of packets per second
#		Takes the outputs and stores them in tmp files
#		Then plots graphs

wirelessnodes()
{
	for(( iteration=20;iteration<=100;iteration+=20))
	do
		echo "Simulating with $iteration wireless nodes"
		simulate 20 10 $iteration
		echo "$iteration $throughput" >> $th
		echo "$iteration $delay" >> $d
		echo "$iteration $delivery_ratio" >> $de
		echo "$iteration $drop_ratio" >> $dr
	done
	gnuplot -c "plotGraph.sh" "WirelessNodes_Throughput" "Packets" "Throughput" "$th" "WirelessNodes_Throughput"
	gnuplot -c "plotGraph.sh" "WirelessNodes_Delay" "Packets" "Delay" "$d" "WirelessNodes_Delay"
	gnuplot -c "plotGraph.sh" "WirelessNodes_DeliveryRatio" "Packets" "Delivery ratio" "$de" "WirelessNodes_DeliveryRatio"
	gnuplot -c "plotGraph.sh" "WirelessNodes_DropRatio" "Packets" "Drop ratio" "$dr" "WirelessNodes_DropRatio"
	#./plotGraph.sh "Packets_per_Sec"
	#exec xgraph $th


}


#		Starting point of the script
echo "Running Wired Cum Wireless simulation"
echo "Which do you want on x-axis?"
echo "1. #wired nodes  2.  #wireless nodes 3.#flows "
read choice

if [ $choice = "1" ]; then
	wirednodes
elif [ $choice = "3" ]; then
	flows
elif [ $choice = "2" ]; then
	wirelessnodes
fi
rm -rf traceFile.tr
rm -rf out.nam
