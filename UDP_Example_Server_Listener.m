function UDP_Example_Server_Listener(udpObj, eventData)
%UDP_EXAMPLE_SERVER_LISTENER Example for a UDP listener waiting for DataReceived events to occure
    
    % Check for only DataReceived events
    if ( strcmpi(eventData.EventName, 'DataReceived') )
        % Read the first element from the receive buffer of the UDPServer object 
        tempValue = udpObj.getDatagram();
        disp(tempValue);
        
        if ( udpObj.available() )
            disp('Still more datagrams in receive buffer!');
        else
            disp('Last datagram read from receive buffer!');
        end
    end
end

