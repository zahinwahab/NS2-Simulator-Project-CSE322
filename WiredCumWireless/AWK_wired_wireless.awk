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
	max_pkt = 30000;
	
	for (i=0; i<max_pkt; i++) {
		rSentTime[i] = 10000.0;
		rReceivedTime[i] = 0.0;
		rDelay[i] = 0.0;		
	}
	
	

}

{
#	event = $1;    time = $2;    node = $3;    type = $4;    reason = $5;    node2 = $5;    
#	packetid = $6;    mac_sub_type=$7;    size=$8;    source = $11;    dest = $10;    energy=$14;

	strEvent = $1 ;			rTime = $2 ;
	wired_srcNode = $3 ;
	wired_destNode = $4 ;			wired_pktName = $5 ;
	wired_pktSize = $6 ;			wired_srcPkt = $9 ;
	wired_destPkt = $10 ;
	wired_seqNum = $11 ;			wired_pktID = $12 ;

	
	wireless_node = $3 ;
	wireless_strAgt = $4 ;			wireless_pktID = $6 ;
	wireless_strType = $7 ;			wireless_pktSize = $8;
	
	
	sub(/^_*/, "", node);
	sub(/_*$/, "", node);
	
	
	if (  wired_pktName == "tcp" ) {

		if(rTime>rEndTime) rEndTime=rTime;
		if(rTime<rStartTime) rStartTime=rTime;
		src = int ($3) ;
		dest = int ($4) ;
		srcAddr = int ($9) ;
		destAddr = int ($10);
				
		if (wired_pktID > idHighestPacket) idHighestPacket = wired_pktID;
		if (wired_pktID < idLowestPacket) idLowestPacket = wired_pktID;
		
		if ( strEvent == "r" && pktID >= idLowestPacket) {

			
			
			#printf("%1.2f %1.2f %1.2f %1.2f\n",pktID,destPkt,destAddr,rTime);
			#rReceivedTime[ wired_pktID ] = rTime ;
			#nReceivedPackets += 1 ;		nReceivedBytes += wired_pktSize;
			#rDelay[ wired_pktID ] = rReceivedTime[ wired_pktID ] - rSentTime[ wired_pktID ];
			#rTotalDelay+=rDelay[ wired_pktID ];	
			
			
		
		 }
		if (strEvent == "+") {
			
			if(rTime < rSentTime[ wired_pktID ]) {
 				nSentPackets += 1;
				#printf("blabla sent :         %d       %f\n",wired_pktID,rTime); #>> debug2.out;
				 rSentTime[ wired_pktID ] = rTime ;
			}
		
		}
		
		if (strEvent == "d") {
			nDroppedPackets++;
		}
	}
if (   (wireless_strAgt == "AGT"   &&   wireless_strType == "tcp" )  ) {

		if(rTime>rEndTime) rEndTime=rTime;
		if(rTime<rStartTime) rStartTime=rTime;
		
				

		if (wireless_pktID > idHighestPacket) idHighestPacket = wireless_pktID;
		if (wireless_pktID < idLowestPacket) idLowestPacket = wireless_pktID;
		
		if ( strEvent == "r" && wireless_pktID >= idLowestPacket) {

			
			
		#	printf("received :         %d       %f\n",wireless_pktID,rTime);
			#printf("%1.2f %1.2f %1.2f %1.2f\n",pktID,destPkt,destAddr,rTime);
			rReceivedTime[ wireless_pktID ] = rTime ;
			nReceivedPackets += 1 ;		nReceivedBytes += wireless_pktSize;
			rDelay[ wireless_pktID ] = rReceivedTime[ wireless_pktID ] - rSentTime[ wireless_pktID ];
			rTotalDelay+=rDelay[ wireless_pktID ];	
			
			
		
		 }		
		
		
		
		if (strEvent == "D") {
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
	#printf("lowest packet: %d  highest packet: %d\n",idLowestPacket,idHighestPacket);
	#printf ( "sent : %d received: %d droppped: %d \n",nSentPackets,nReceivedPackets,nDroppedPackets);
	for (i=idLowestPacket; i<=idHighestPacket; i++) {
			
	#	printf( "i: %15.5f sent time: %15.5f received time: %15.5f delay: %15.5f \n",i, rSentTime[i],rReceivedTime[i], rDelay[i]) ;
	}
	if ( nReceivedPackets != 0 ) {
		rAverageDelay = rTotalDelay / nReceivedPackets ;
	}
	printf( "%15.5f \n", rThroughput ) ;
	printf( "%15.2f\n %15.5f \n %15.5f\n", rAverageDelay,rPacketDeliveryRatio,rPacketDropRatio) ;
	

}


