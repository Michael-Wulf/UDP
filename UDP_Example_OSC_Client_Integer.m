% Example for a simple UDP client that sends out an OSC Message with one integer
%
% Create a simple UDP client sending on the loopback interface on port
% 11724 to port 11725. Use an TCP/UDP test tool (e.g. Packet Sender
% https://packetsender.com) or an OSC compatible tool to receive the UDP
% datagrams or the encapsulated OSC message...
%
% ------------------------------------------------------------------------------
% Author:  Michael Wulf
%          Cold Spring Harbor Laboratory
%          Kepecs Lab
%          One Bungtown Road
%          Cold Spring Harboor
%          NY 11724, USA
%
% Date:    12/04/2018
% Version: 1.0.0
% ------------------------------------------------------------------------------

% Add path for OSCMessage implementation
addpath(genpath('../OSCMessage'));

% Create a UDP instance on the loopback interface on a random port
udpClient = UDP('interface', 'lo', 'port', 11724);

% Don't add a listener funtion

% Just open the UDP instance without start receiving
udpClient.open();

% Create a datagram struct with the necessary fields 
datagram.remoteIP   = '127.0.0.1';
datagram.remotePort = 11725;
datagram.data       = [];

% Set some values to be sent out via UDP
cntr = 0;
iterations = 0;

% Create some data and send it via UDP
while(iterations < 2)
    % Create a new OSCMessage
    msg = OSCMessage();
    msg.addInt32(int32(cntr));
    
    % Convert it to a byte array and store it into the datagram's payload part
    datagram.data = msg.toByteArray();
    
    % Send datagram via UDP
    udpClient.sendDatagram(datagram);
    
    % Change payload value....
    cntr = cntr + 1;
    if (mod(cntr, 60) == 0)
        cntr = 0;
        iterations = iterations+1;
    end
    pause(1);
end

% Don't forget to close and delete the UDP instance!
% Call those two commands from the command window!!!
udpClient.close();
delete(udpClient);