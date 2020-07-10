BEGIN {
	
	nSentPackets = 0.0 ;		
	nReceivedPackets = 0.0 ;
	nEnqueuedPackets = 0.0;
	nDequeuedPackets = 0.0;
	nDroppedPackets = 0.0;
	idHighestPacket = 0;
	idLowestPacket = 100000;
	rStartTime = 10000.0;
	rEndTime = 0.0;
	nReceivedBytes = 0;
	rTotalDelay = 0.0 ;
	max_pkt = 10000;
	max_node = 2000;
	for (i=0; i<max_pkt; i++) {
		rSentTime[i] = 0.0;
		rReceivedTime[i] = 0.0;
		rDelay[i] = 0.0;		
	}
	
	
	for (i=0; i<max_node; i++) {
			for (j=i+1; j<max_node; j++) {
				size[i*max_node+j] = 0;
			}
			
	}
	
	

}

{
#	event = $1;    time = $2;    node = $3;    type = $4;    reason = $5;    node2 = $5;    
#	packetid = $6;    mac_sub_type=$7;    size=$8;    source = $11;    dest = $10;    energy=$14;

	strEvent = $1 ;			rTime = $2 ;
	srcNode = $3 ;
	destNode = $4 ;			pktName = $5 ;
	pktSize = $6 ;			srcPkt = $9 ;
	destPkt = $10 ;
	seqNum = $11 ;			pktID = $12 ;
	
	
	sub(/^_*/, "", node);
	sub(/_*$/, "", node);
	
	if (  strEvent == "+" ) {
		src = int ($3) ;
		dest = int ($4) ;
		if ( src > dest ) {
			size[(dest*max_node)+src]++;
			printf("%f  %d\n",rTime,size[(dest*max_node)+src]) >> "file_"$4"_"$3".dat";
		}
		if ( src < dest ) {
			size[(src*max_node)+dest]++;
			printf("%f  %d\n",rTime,size[(src*max_node)+dest]) >> "file_"$3"_"$4".dat";
		#	printf("%f  %d\n",rTime,[(src*max_node)+dest]) >> "file_$3_$4.dat";
		}

	}
	if (  strEvent == "-" ) {
		src = int ($3) ;
		dest = int ($4) ;
		if ( src > dest ) {
			size[(dest*max_node)+src]--;
			printf("%f  %d\n",rTime,size[(dest*max_node)+src]) >> "file_"$4"_"$3".dat";
		}
		if ( src < dest ) {
			size[(src*max_node)+dest]--;
			printf("%f  %d\n",rTime,size[(src*max_node)+dest]) >> "file_"$3"_"$4".dat";
		#	printf("%f  %d\n",rTime,[(src*max_node)+dest]) >> "file_$3_$4.dat";
		}

	}
	if (  pktName == "tcp" || pktName == "cbr" ) {
		if(rTime>rEndTime) rEndTime=rTime;
		if(rTime<rStartTime) rStartTime=rTime;
		src = int ($3) ;
		dest = int ($4) ;
		srcAddr = int ($9) ;
		destAddr = int ($10);
			#	printf("%d:--> %f %f %f %f\n",pktID,src,dest,srcAddr, destAddr);

		if (pktID > idHighestPacket) idHighestPacket = pktID;
		if (pktID < idLowestPacket) idLowestPacket = pktID;

		
		if ( strEvent == "r" && pktID >= idLowestPacket) {

			
			
			if(destAddr == dest) {

			#printf("%1.2f %1.2f %1.2f %1.2f\n",pktID,destPkt,destAddr,rTime);
			rReceivedTime[ pktID ] = rTime ;
			nReceivedPackets += 1 ;		nReceivedBytes += pktSize;
			rDelay[ pktID ] = rReceivedTime[ pktID ] - rSentTime[ pktID ];
			rTotalDelay+=rDelay[ pktID ];	
			}
			
		
		 }		

		if (strEvent == "+") {
			
		if(srcAddr == src) {
			#printf("%1.2f %1.2f %1.2f %1.2f\n",pktID,srcNode,src,rTime);
			rSentTime[ pktID ] = rTime ;
			nSentPackets += 1 ;		
			}	
			nEnqueuedPackets++;
		}
		if (strEvent == "-") {
			nDequeuedPackets++;
		}
		if (strEvent == "d") {
			nDroppedPackets++;
		}
	}

	
	

	
}

END {
	#nSentPackets = nReceivedPackets + nDroppedPackets;
	rTime = rEndTime - rStartTime ;
	rThroughput = nReceivedBytes*8 / rTime;
	rPacketDeliveryRatio = nReceivedPackets / nSentPackets * 100 ;
	rPacketDropRatio = (nDroppedPackets) / nSentPackets * 100;
	#printf("iterating over the packets\n");
	#printf("%d %d",idLowestPacket,idHighestPacket);
	for (i=idLowestPacket; i<=idHighestPacket; i++) {
			
	#	printf( "i: %15.5f sent time: %15.5f received time: %15.5f delay: %15.5f \n",i, rSentTime[i],rReceivedTime[i], rDelay[i]) ;
	}
	if ( nReceivedPackets != 0 ) {
		rAverageDelay = rTotalDelay / nReceivedPackets ;
	}
	printf( "%15.5f \n", rAverageDelay ) ;
	printf( "%15.2f\n%15.5f \n%15.5f\n", rThroughput,rPacketDeliveryRatio,rPacketDropRatio) ;
	

}


