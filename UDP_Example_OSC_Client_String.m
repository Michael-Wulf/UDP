% Example for a simple UDP client that sends out an OSC Message with one integer
%
% Create a simple UDP client sending on the loopback interface on port
% 63110 to port 63111. Use an TCP/UDP test tool (e.g. Packet Sender
% https://packetsender.com) or an OSC compatible tool to receive the UDP
% datagrams or the encapsulated OSC message...
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

% Add path for OSCMessage implementation
addpath(genpath('../OSCMessage'));

% Create a UDP instance on the loopback interface on port 63110
udpClient = UDP('interface', 'lo', 'port', 63110);

% Don't add a listener funtion

% Just open the UDP instance without start receiving
udpClient.open();

% Create a datagram struct with the necessary fields 
datagram.remoteIP   = '127.0.0.1';
datagram.remotePort = 63111;
datagram.data       = [];

% Set some values to be sent out via UDP
cntr = 1;
stop = 0;

% Create some data and send it via UDP
while(stop == 0)
    % Create a new OSCMessage
    msg = OSCMessage();
    
    % Generate payload as string
    currString = ['This is string # ' num2str(cntr)]
    
    % Add string to message
    msg.addString(currString);
    
    % Convert OSCMessage to byte array and store it into the datagram's payload part
    datagram.data = msg.toByteArray();
    
    % Send datagram via UDP
    udpClient.sendDatagram(datagram);
    
    % Change payload value....
    cntr = cntr + 1;
    
    if (mod(cntr, 11) == 0)
        stop = 1;
    end
    pause(1);
end

% Don't forget to close and delete the UDP instance!
% Call those two commands from the command window!!!
udpClient.close();
delete(udpClient);