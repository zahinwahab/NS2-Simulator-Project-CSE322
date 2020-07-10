BEGIN {
	max_node = 2000;
	nSentPackets = 0.0 ;		
	nReceivedPackets = 0.0 ;
	rTotalDelay = 0.0 ;
	max_pckt = 10000;

	header = 20;	

	idHighestPacket = 0;
	idLowestPacket = 100000;
	rStartTime = 10000.0;
	rEndTime = 0.0;
	nReceivedBytes = 0;

	nDropPackets = 0.0;

	total_energy_consumption = 0;

	temp = 0;
	
	for (i=0; i<max_node; i++) {
		energy_consumption[i] = 0;		
	}

	total_retransmit = 0;
	for (i=0; i<max_pckt; i++) {
		retransmit[i] = 0;		
	}

}

{
	strEvent = $1 ;			rTime = $2 ;
	node = $3 ;
	strAgt = $4 ;			idPacket = $6 ;
	strType = $7 ;			nBytes = $8;

	energy = $13;			total_energy = $14;
	idle_energy_consumption = $16;	sleep_energy_consumption = $18; 
	transmit_energy_consumption = $20;	receive_energy_consumption = $22; 
	num_retransmit = $30;
	
	sub(/^_*/, "", node);
	sub(/_*$/, "", node);

	if (energy == "[energy") {
		energy_consumption[node] = (idle_energy_consumption + sleep_energy_consumption + transmit_energy_consumption + receive_energy_consumption);
	}

	if ( strAgt == "AGT"   &&   strType == "cbr") {
		
		if (idPacket > idHighestPacket) idHighestPacket = idPacket;
		if (idPacket < idLowestPacket) idLowestPacket = idPacket;
		if(rTime>rEndTime) rEndTime=rTime;
		if(rTime<rStartTime) rStartTime=rTime;

		
		if ( strEvent == "s" ) {
			nSentPackets += 1 ;	rSentTime[ idPacket ] = rTime ;
		}
		if ( strEvent == "r" && idPacket >= idLowestPacket) {
			
			
			nReceivedPackets += 1 ;		nReceivedBytes += (nBytes-header);
			rReceivedTime[ idPacket ] = rTime ;
			rDelay[idPacket] = rReceivedTime[ idPacket] - rSentTime[ idPacket ];
			rTotalDelay += rDelay[idPacket]; 
		}
	}
	if ( strAgt == "AGT"   &&   strType == "tcp") {
		if (idPacket > idHighestPacket) idHighestPacket = idPacket;
		if (idPacket < idLowestPacket) idLowestPacket = idPacket;
		if(rTime>rEndTime) rEndTime=rTime;
		if(rTime<rStartTime) rStartTime=rTime;

		
		if ( strEvent == "s" ) {
			nSentPackets += 1 ;	rSentTime[ idPacket ] = rTime ;
		}
		if ( strEvent == "r" && idPacket >= idLowestPacket) {
			nReceivedPackets += 1 ;		nReceivedBytes += (nBytes);
			rReceivedTime[ idPacket ] = rTime ;
			rDelay[idPacket] = rReceivedTime[ idPacket] - rSentTime[ idPacket ];
			rTotalDelay += rDelay[idPacket]; 
		}
	}

	if( strEvent == "D"   &&   strType == "cbr" ) {
	
		#if(rTime>rEndTime) rEndTime=rTime;
		nDropPackets += 1;
	}
	if( strEvent == "D"   &&   strType == "tcp" ) {
		#if(rTime>rEndTime) rEndTime=rTime;
		
		nDropPackets += 1;
	}
	if( strType == "tcp" )
	{
#		printf("%d \n", idPacket);
#		printf("%d %15d\n", idPacket, num_retransmit);
		retransmit[idPacket] = num_retransmit;		
	}
	if(rTime>rEndTime) rEndTime=rTime;

}

END {
	rTime = rEndTime - rStartTime ;
	rThroughput = nReceivedBytes*8 / rTime;
	rPacketDeliveryRatio = nReceivedPackets / nSentPackets * 100 ;
	rPacketDropRatio = nDropPackets / nSentPackets * 100;
	#printf("sent packets: %d \nreceived: %d \ndroppped: %d \n",nSentPackets,nReceivedPackets,nDropPackets);

	for(i=0; i<max_node;i++) {
		total_energy_consumption += energy_consumption[i];
	}
	if ( nReceivedPackets != 0 ) {
		rAverageDelay = rTotalDelay / nReceivedPackets ;
	}

	printf( "%15.2f\n%15.5f\n%15.2f\n%15.2f\n", rThroughput, rAverageDelay, rPacketDeliveryRatio, rPacketDropRatio) ;
	printf("%15.5f\n", total_energy_consumption);

}
