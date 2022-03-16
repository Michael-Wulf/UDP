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
% Date:    03/16/2022
% Version: 1.0.1
% GitHub:  https://github.com/Michael-Wulf/UDP
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