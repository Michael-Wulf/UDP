% Example for a simple UDP based server
%
% Create a simple UDP server listening on the loopback interface on port
% 11724. Use an TCP/UDP test tool (e.g. Packet Sender
% https://packetsender.com) to send single UDP datagrams to the server.
%
% ------------------------------------------------------------------------------
% Author:  Michael Wulf
%          Cold Spring Harbor Laboratory
%          Kepecs Lab
%          One Bungtown Road
%          Cold Spring Harboor
%          NY 11724, USA
%
% Date:    11/13/2018
% Version: 1.0.0
% ------------------------------------------------------------------------------

% Create a UDP instance listening on the loopback on port 11724
udpServer = UDP('interface', 'lo', 'port', 11724);

% Add listener funtion
addlistener(udpServer, 'DataReceived', @UDP_Example_OSC_Server_Integer_Listener);

% Start the server
udpServer.start();

% Don't forget to close and delete the UDP instance!
% Call those two commands from the command window!!!
%udpServer.stop();
%delete(udpServer);