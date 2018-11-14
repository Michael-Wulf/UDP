% Example for a simple UDP based client
%
% Create a simple UDP client sending on the loopback interface on port
% 11724. Use an TCP/UDP test tool (e.g. Packet Sender
% https://packetsender.com) to receive the UDP datagrams.
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

% Create a UDP instance on the loopback interface on a random port
udpClient = UDP('interface', 'lo', 'port', 11724);

% Don't add a listener funtion

% Just open the UDP instance without start receiving
udpClient.open();

datagram.remoteIP   = '127.0.0.1';
datagram.remotePort = 11725;
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