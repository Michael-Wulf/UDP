% Example for a simple UDP based server
%
% Create a simple UDP server listening on the loopback interface on port
% 63110. Use an TCP/UDP test tool (e.g. Packet Sender
% https://packetsender.com) to send single UDP datagrams to the server.
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

% Create a UDP instance listening on the loopback on port 63110
udpServer = UDP('interface', 'lo', 'port', 63110);

% Add listener funtion
addlistener(udpServer, 'DataReceived', @UDP_Example_OSC_Server_Integer_Listener);

% Start the server
udpServer.start();

% Don't forget to close and delete the UDP instance!
% Call those two commands from the command window!!!
%udpServer.stop();
%delete(udpServer);