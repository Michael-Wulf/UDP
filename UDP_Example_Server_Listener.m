function UDP_Example_Server_Listener(udpObj, eventData)
%UDP_EXAMPLE_SERVER_LISTENER Example for a UDP listener waiting for DataReceived events to occur
% 
% -------------------------------------------------------------------------
% Author:  Michael Wulf
%          Washington University in St. Louis
%          Kepecs Lab
%
% Date:    04/15/2022
% Version: 1.0.2
% GitHub:  https://github.com/Michael-Wulf/UDP
%
% Copyright (C) 2022 Michael Wulf
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
% MA  02110-1301, USA.
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

