% Example for a simple UDP based client
%
% Create a simple UDP client sending on the loopback interface on port
% 63110 to port 63111. Use an TCP/UDP test tool (e.g. Packet Sender
% https://packetsender.com) to receive the UDP datagrams.
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

% Add path for OSCMessage implementation
addpath(genpath('../OSCMessage'));

% Create a UDP instance on the loopback interface on a port 63110
udpClient = UDP('interface', 'lo', 'port', 63110);

% Don't add a listener funtion

% Just open the UDP instance without start receiving
udpClient.open();

datagram.remoteIP   = '127.0.0.1';
datagram.remotePort = 63111;
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