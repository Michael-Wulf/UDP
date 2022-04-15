% Example for a simple UDP based client
%
% Create a simple UDP client sending on the loopback interface on port
% 63110. Use an TCP/UDP test tool (e.g. Packet Sender
% https://packetsender.com) to receive the UDP datagrams.
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

% Create a UDP instance on the loopback interface on port 63110
udpClient = UDP('interface', 'lo', 'port', 63110);

% Don't add a listener funtion

% Just open the UDP instance without start receiving
udpClient.open();

datagram.remoteIP   = '127.0.0.1';
datagram.remotePort = 63111;
datagram.data       = [];

cntr = 0;
while(1)
    
    datagram.data = uint8('Data: ');
    datagram.data = [datagram.data, uint8(cntr)];
    udpClient.sendDatagram(datagram);
    
    cntr = mod( (cntr + 1), 256);
    
    pause(1);
end

% Don't forget to close and delete the UDP instance!
% Call those two commands from the command window!!!
%udpClient.close();
%delete(udpClient);