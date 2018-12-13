classdef UDPClient < handle
    %UDPCLIENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = public, SetAccess = protected)
        port;
    end
    
    properties (Access = private)
        serverIface;       % NetworkInterface object (Java)
        inetAddress;       % InetAddress object (Java)
        soTimeout = 10;    % Timeout (ms) for datagramSocket object (Java)
        rxTimer;           % Timer object
        rxBuffer;          % Receive buffer
        rxBufferSize = 20; % Maximum number of elements in rxBuffer
        dpBuffer;          % Receive byte buffer for datagram packet (length of MTU)
        dataPacket;        % DatagramPacket object (Java)
        dataSocket;        % DatagramSocket object (Java)
        socketOpened;      % Flag to indicate if socket/port is still open
        running;           % Flag to indicate if receiving is started
    end
    
    methods
        function obj = UDPClient(varargin)
            
        end
        
    end
end

