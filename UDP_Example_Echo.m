% Example for an echoing UDP implementation
%
% Create a simple UDP instance listening on the loopback interface on port
% 11724. Use an TCP/UDP test tool (e.g. Packet Sender
% https://packetsender.com) to send single UDP datagrams to this instance.
% The instance will echo the incoming data back to the sender...
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
addlistener(udpServer, 'DataReceived', @UDP_Example_Echo_Listener);

% Start the server
udpServer.start();

% Don't forget to close and delete the UDP instance!
% Call those two commands from the command window!!!
%udpServer.stop();
%delete(udpServer);