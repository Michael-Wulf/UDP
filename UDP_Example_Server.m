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
% Date:    03/16/2022
% Version: 1.0.1
% GitHub:  https://github.com/Michael-Wulf/UDP
% -------------------------------------------------------------------------

% Create a UDP instance listening on the loopback on port 63110
udpServer = UDP('interface', 'lo', 'port', 63110);

% Add listener funtion
addlistener(udpServer, 'DataReceived', @UDP_Example_Server_Listener);

% Start the server
udpServer.start();

% Don't forget to close and delete the UDP instance!
% Call those two commands from the command window!!!
%udpServer.stop();
%delete(udpServer);