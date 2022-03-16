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
% Date:    03/16/2022
% Version: 1.0.1
% GitHub:  https://github.com/Michael-Wulf/UDP
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