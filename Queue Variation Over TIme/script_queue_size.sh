rm -rf queueSize
mkdir queueSize
ns wired.tcl #$nodes $flows $packets_per_sec
awk -f extra.awk traceFile.tr > debug.out
for i in *.dat
	do
		gnuplot -c "plotGraph.sh" "Queue_Time" "Time" "QueueSize" "$i" "QueueSize_Time_$i"	
	done

mv *.dat queueSize



