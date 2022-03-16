function UDP_Example_Server_Listener(udpObj, eventData)
%UDP_EXAMPLE_SERVER_LISTENER Example for a UDP listener waiting for DataReceived events to occur
% 
% -------------------------------------------------------------------------
% Author:  Michael Wulf
%          Washington University in St. Louis
%          Kepecs Lab
%
% Date:    03/16/2022
% Version: 1.0.1
% GitHub:  https://github.com/Michael-Wulf/UDP
% -------------------------------------------------------------------------
    
     % Check for only DataReceived events
    if ( strcmpi(eventData.EventName, 'DataReceived') )
        % Read the first element from the receive buffer of the UDPServer object 
        datagram = udpObj.getDatagram();
        fprintf('Received datagram info:\n');
        fprintf('Remote host: %s \n', datagram.remoteIP);
        fprintf('Remote port: %d \n', datagram.remotePort);
        fprintf('Number of received bytes: %d \n', datagram.length);
        fprintf('Received bytes (hex): ');
        fprintf('%02X ', datagram.data);
        fprintf('\n\n');
        
        if ( udpObj.available() )
            disp('Still more datagrams in receive buffer!');
        else
            disp('Last datagram read from receive buffer!');
        end
    end
end

