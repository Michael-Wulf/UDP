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

% Add path for OSCMessage implementation
addpath(genpath('../OSCMessage'));

% Create a UDP instance on the loopback interface on a random port
udpClient = UDP('interface', 'lo', 'port', 11724);

% Don't add a listener funtion

% Just open the UDP instance without start receiving
udpClient.open();

datagram.remoteIP   = '127.0.0.1';
datagram.remotePort = 11725;
datagram.data       = [];

cntr = 0;

iterations = 0;

while(iterations < 1)
    msg = OSCMessage();
    msg.setAddress('threat');
    msg.addInt32(int32(cntr));
    
    datagram.data = msg.toByteArray();
    
    udpClient.sendDatagram(datagram);
    cntr = cntr + 1;
    if (mod(cntr, 10) == 0)
        cntr = 0;
        iterations = iterations+1;
    end
    pause(1);
end

% Don't forget to close and delete the UDP instance!
% Call those two commands from the command window!!!
udpClient.close();
delete(udpClient);