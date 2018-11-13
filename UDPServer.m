classdef UDPServer < handle
    % UDPSERVER Implementation of a UDP-Server based on Java DatagramSockets
    % 
    % This class implements a UDP server based on Java classes. To avoid polling
    % the underlying datagramSocket implementation to check for received data
    % packets, this class also implements a timer-based mechanism to
    % periodically check for existing data. For a simplified access of the
    % received data, this class implements an event DataReceived which is raised
    % whenever new data is available.
    %
    % Examples
    % --------
    % Example 1:
    %  % Create a UDP server on the loopback interface (172.0.0.1) on port 11724
    %  udpServer = UDPServer('port', 11724);
    %  % Add a listener ti the DataReceived event
    %  addlistener(udpServer, 'DataReceived', @UDPlistener);
    %  % Start the server
    %  udpServer.start();
    %  
    %  ...
    %  
    %  % Stop the server
    %  udpServer.stop();
    %  % delete the object -> call destructor
    %  delete(udpServer);
    % 
    %  % Implementation of the event listener
    %  function UDPlistener(udpServerObj, eventData)
    %    if ( strcmpi(eventData.EventName, 'DataReceived') )
    %      tempValue = udpServerObj.getPacket();
    %    end
    %  end
    %  
    % 
    % Example 2:
    %  % Create a UDP server on the interface eth0 on port 11724
    %  udpServer = UDPServer('interface', 'eth0', 'port', 11724);
    %
    % Example 3:
    %  % Create/bind a UDP server on the ip address 192.168.1.112 on port 11724
    %  udpServer = UDPServer('ip', '192.168.1.112', 'port', 11724);
    %
    %
    % --------------------------------------------------------------------------
    % Author:  Michael Wulf
    %          Cold Spring Harbor Laboratory
    %          Kepecs Lab
    %          One Bungtown Road
    %          Cold Spring Harboor
    %          NY 11724, USA
    % 
    % Date:    11/12/2018
    % Version: 1.0.0
    % --------------------------------------------------------------------------
        
    properties (Access = public)
    end
    
    properties (GetAccess = public, SetAccess = protected)
        interface;          % Network interface the server listens on
        ip;                 % IPv4-address the server listens on
        ipv6;               % IPv6-address the server listens on
        port;               % UDP-port the server listens on (required property)
        MTU;                % Maximum transfer unit (default: 1500 byte)
        timerInterval = 20; % Interval (ms) to check for new data (default: 20 ms)
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
    
    events
        % DATARECEIVED Event that is raised whenever new data is received by
        % the UDP server.
        % A valid listener function must have the following signature:
        % function_name(serverObject, eventData)
        % 
        % Example:
        % Implementation of a event listener function
        % function UDPlistener(udpServerObj, eventData)
        %   if ( strcmpi(eventData.EventName, 'DataReceived') )
        %     tempValue = udpServerObj.getPacket();
        %   end
        % end
        %
        % % Add listener
        % addlistener(udpServer, 'DataReceived', @UDPlistener);
        DataReceived;
    end
    
    methods (Access = public)
        function obj = UDPServer(varargin)
            %UDPSERVER Create a UDPServer object for receiving messages
            %
            % A UDPServer object can be specified for a given interface (e.g.
            % 'eth0') or an IP address (e.g. 192.168.1.112, IPv4 and IPv6 
            % addresses are both valid) and the server will be bound to e
            % specified port (required argument)
            %
            % For this constructor, the following properties can be specified:
            %
            % - 'port': The UDP port the server will listen on (required)
            %     - data type: numeric, scalar
            %     - required property
            %     - only ports between 1025 and 65535 are allowed
            %
            % - 'interface': The network interface the server will be bound to
            %     - datatype: char-vector (string)
            %     - not required property
            %     - if not specified, the interface will be automatically be
            %     determined by the given IP address. If alos no IP address is
            %     specified, the loopback interface ('lo', 127.0.0.1) will be
            %     used.
            %     Call UDPServer.availableInterfaces() for a list of available
            %     interfaces of the current system.
            %
            % - 'ip': The IP address (IPv4 or IPv6) the server will be bound to
            %     - datatype: char-vector (string)
            %     - not required property
            %     - if not specified, the IP address will be automatically be
            %     determined by the given interface. If also no interface is
            %     specified, the loopback address (127.0.0.1, 'lo') will be
            %     used.
            %
            % Examples
            % --------
            % Example 1:
            %  % Create a UDP server on the loopback interface (172.0.0.1) on port 11724
            %  udpServer = UDPServer('port', 11724);
            % 
            % Example 2:
            %  % Create a UDP server on the interface eth0 on port 11724
            %  udpServer = UDPServer('interface', 'eth0', 'port', 11724);
            %
            % Example 3:
            %  % Create/bind a UDP server on the ip address 192.168.1.112 on port 11724
            %  udpServer = UDPServer('ip', '192.168.1.112', 'port', 11724);
            
            % Necessary Java imports
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            import java.net.*;
            import java.io.*;
            import java.util.*;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Check input arguments - START
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if (nargin == 0)
                error('UDPServer constructor requires at least the port value!');
            end
            
            if ( mod(nargin, 2) ~= 0 )
                error('UDPServer constructor requires name/value pairs of arguements!');
            end
            
            % Specify the needed arguments and default values
            validNames        = {'interface', 'ip', 'port'};
            defaultValues     = {'lo', '127.0.0.1', []};
            requiredArguments = {'port'};
            
            properties = struct();
            
            for cntr=1:2:nargin
                % get name and value of frst pair
                currName  = strtrim(varargin{cntr});
                currValue  = varargin{cntr+1};
                if (ischar(currValue))
                    currValue = strtrim(currValue);
                end
                
                id = find(strcmpi(validNames, currName), 1);
                
                if (isempty(id))
                    error(['Unknown property ''' currName '''!']);
                end
                
                properties.(currName) = currValue;
            end
            
            % Get all specified properties
            fNames = fieldnames(properties);
            
            % Check required arguments
            if (~isempty(requiredArguments))
                for cntr = 1:1:length(requiredArguments)
                    currProperty = requiredArguments{cntr};
                    if (isempty(find(strcmpi(fNames, currProperty), 1)))
                        error(['Required property ''' currProperty ''' missing!']);
                    end
                end
            end
            
            % Set defaults
            defaults = {};
            for cntr = 1:1:length(validNames)
                currProperty = validNames{cntr};
                if (~isfield(properties, currProperty))
                    defaults(end+1) = {currProperty}; %#ok<AGROW>
                    properties.(currProperty) = defaultValues{cntr};
                end
            end
            
            properties.defaults = defaults;
            
            clear defaults fNames currName currValue currProperty;
            
            % check port value
            % port must be numeric
            if (~isnumeric(properties.port))
                error('Property ''port'' must be a scalar integer between 1024 to 65535');
            end
            
            % port must be an integer value
            if ( mod(properties.port, 1) ~= 0 )
                error('Property ''port'' must be a positive integer between 1024 to 65535');
            end
            
            % port must be between 1024 and 65535
            if ( (properties.port < 1024) || (properties.port > 65535) )
                error('Property ''port'' must be a positive integer between 1024 to 65535');
            end
            
            % check interface value
            % interface must be a string
            if (~ischar(properties.interface))
                error('Property ''interface'' must be a string defining the network interface (e.g. lo, eth0...)');
            end
            
            % check ip value
            ipVersion = 0;
            if (~ischar(properties.ip))
                error('Property ''ip'' must be a string defining the ip address the UDP server should be bind to (e.g. ''127.0.0.1'' (loopback lo), 192.168.1.1 - IPv6 addresses are also valid)');
            end
            
            if ( strfind(properties.ip,'.') )
                %IPv4
                ipVersion = 4;
                
                ipElements = strsplit(properties.ip, '.');
                if ( length(ipElements) ~= 4 )
                    error(['Specified IP address (' properties.ip ') has the wrong format!']); 
                end
                ipElements = cellfun(@str2num, ipElements, 'UniformOutput', false);
                
                if ( find(cellfun(@isempty, ipElements), 1) )
                    error(['Specified IP address (' properties.ip ') has the wrong format!']); 
                end
                
                ipElements = cell2mat(ipElements);
                if ( ~isempty(find(ipElements > 255, 1)) || ~isempty(find(ipElements < 0, 1)) || ~isempty(find(mod(ipElements, 1), 1)) )
                    error(['Specified IP address (' properties.ip ') has the wrong format!']); 
                end
                ipElements = uint8(ipElements);

            elseif ( strfind(properties.ip,':') )
                %IPv6 format
                
                ipVersion = 6;
                
                % Split string at colons and check that there are 8
                % parts...
                ipElements = strsplit(properties.ip, ':');
                if ( length(ipElements) ~= 8 )
                    error(['Format of specified IPv6 address (' properties.ip ') not supported!' ...
                           'Please enter all 16 byte as hex values in the format X:X:X:X:X:X:X:X']); 
                end
                
                % Convert hexadecimal notation to decimal form
                try
                    ipElements = cellfun(@hex2dec, ipElements, 'UniformOutput', false);
                catch ME
                    error(['Format of specified IPv6 address (' properties.ip ') not supported!' ...
                           'Please enter all 16 byte as hex values in the format X:X:X:X:X:X:X:X']);
                end
                
                % Empty elements mean that the IPv6 address was not entered
                % as hexa-decimal values
                if ( find(cellfun(@isempty, ipElements), 1) )
                    error(['Suppressed or shortened elements in IPv6 address format (' properties.ip ') not supported!' ...
                           'Please enter all 16 byte as hex values in the format X:X:X:X:X:X:X:X']);
                end
                
                % Convert cell array to matrix/vector
                ipElements = cell2mat(ipElements);
                
                % Check that only 16-bit values were entered (uint16 < 65536)
                if ( ~isempty(find(ipElements > 65535, 1)) )
                    error(['Format of specified IPv6 address (' properties.ip ') not supported!' ...
                           'Please enter all 16 byte as hex values in the format X:X:X:X:X:X:X:X']); 
                end
                
                % Now convert 8 x 16-bit values to 16 x 8-bit values
                
                ipElementsTemp = ipElements;
                
                ipElements = uint8(zeros(1, 16));
                
                for cntr=1:1:length(ipElementsTemp)
                    id = 2 * (cntr-1) + 1;
                    currHextet       = ipElementsTemp(cntr);
                    ipElements(id)   = uint8(bitand(bitshift(currHextet, -8), 255));
                    ipElements(id+1) = uint8(bitand(currHextet, 255));
                end
                clear currHextet ipElementsTemp;
            end
            
            clear requiredArguments validNames defaultValues;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Check input arguments - END
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Now, depending on what arguments were passed, try to find the
            % correct network interface...
            
            if (isempty(find(strcmpi(properties.defaults, 'interface'), 1))) 
                % No 'interface' string in properties.defaults:
                % -> interface was not passed
                useDefaultIface = 0;
            else
                % 'interface' string in properties.defaults:
                % -> interface was passed
                useDefaultIface = 1;
            end
            
            if (isempty(find(strcmpi(properties.defaults, 'ip'), 1))) 
                % No 'ip' string in properties.defaults:
                % -> ip address was not passed
                useDefaultIP = 0;
            else
                % 'ip' string in properties.defaults:
                % -> ip address was passed
                useDefaultIP = 1;
            end
            
            searchByIface = 0;
            searchByIP    = 0; 
            
            if (  ((useDefaultIface) &&  (useDefaultIP)) || ...
                 ((~useDefaultIface) &&  (useDefaultIP)) || ...
                 ((~useDefaultIface) && (~useDefaultIP)) )
                searchByIface = 1;
            else
                searchByIP = 1;
            end
            
            clear useDefaultIface useDefaultIP;
            
            % Init flag to search for interface
            ifaceFound = 0;
            
            if (searchByIface)
                % Try to find interface by name
                obj.serverIface = NetworkInterface.getByName(properties.interface);
                if (isempty(obj.serverIface))
                    error(['Specified interface ''' properties.interface ''' does not exist!']);
                end
                % Set flag
                ifaceFound = 1;
                
            elseif (searchByIP)
                % Convert byte array with the IP address into an
                % InetAddress object
                inet = InetAddress.getByAddress(ipElements);
                
                % Try to find interface by IP
                obj.serverIface = NetworkInterface.getByInetAddress(inet);
                if (isempty(obj.serverIface))
                    error(['Specified interface ''' properties.ip ''' does not exist!']);
                end
                
                % Set flag and leave while-loop
                ifaceFound = 1;
            end
            
            if (~ifaceFound)
                if (searchByIface)
                    ME = MException('UDPServer:interfaceNotFound', ...
                    'Interface %s not found on system', properties.interface);
                    throw(ME);
                elseif (searchByIP)
                    ME = MException('UDPServer:interfaceNotFound', ...
                    'Interface %s not found on system', properties.ip);
                    throw(ME);
                end
            end
            
            clear ifaceFound currIface
            
            % Set properties to the object...
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Set port
            obj.port = properties.port;
            
            % Set IP addresses
            obj.ip   = '';
            obj.ipv6 = '';
            
            % Check that interface has at least one valid IP address
            inetEnum = obj.serverIface.getInetAddresses();
            if ( isempty(inetEnum) )
                ME = MException('UDPServer:noInterfaceAddressFound', ...
                    'Interface %s has no inet address', server_iface_name);
                throw(ME);
            end
            
            obj.inetAddress = [];
            
            % Interate through all IP addresses
            while ( inetEnum.hasMoreElements() )
                currInet = inetEnum.nextElement();
                % Cast to string
                tempString = char(currInet);
                
                if ( strcmpi(class(currInet), 'java.net.Inet4Address') )
                    obj.ip = tempString(2:end);
                    
                    if ( ipVersion < 6)
                        obj.inetAddress = currInet;
                    end
                    
                elseif ( strcmpi(class(currInet), 'java.net.Inet6Address') )
                    obj.ipv6 = tempString(2:end);
                    if ( ipVersion == 6)
                        obj.inetAddress = currInet;
                    end
                    
                end
            end
            clear inetEnum currInet tempString;
            
            % Set interface name
            obj.interface = char(obj.serverIface.getName());
            
            % Set MTU
            if ( obj.serverIface.isLoopback() )
                obj.MTU = 1500;
            else
                obj.MTU = obj.serverIface.getMTU();
            end
            
            % Create an empty byte 
            obj.dpBuffer = uint8(zeros(1, obj.MTU));
            
            % Create a datagram packet that will be used for temp. storin
            % received data
            obj.dataPacket = DatagramPacket(obj.dpBuffer, obj.MTU);
            
            % Create rxBuffer
            obj.rxBuffer = cell(0);
            
            % Reset flag to indicate if port is opened
            obj.socketOpened = 0;
            
            % Check if port is free!
            try
                obj.dataSocket = DatagramSocket(obj.port, obj.inetAddress);
                obj.dataSocket.close();
            catch ME
                warning('Unable to create/bind a DatagramSocket to interface or port!');
                switch (ME.identifier)
                    % Check for Java exceptions
                    case 'MATLAB:Java:GenericException'
                        excobj = ME.ExceptionObject;
                        switch (class(excobj))
                            case 'java.net.BindException'
                                warning('Port %d is already in use!', obj.port);
                            otherwise
                                warning('Something went wrong... Java-Exception: %s', class(excobj))
                        end
                        
                    % Check for MATLAB exceptions
                    otherwise
                        % Try to close the port at least...
                        try
                            obj.dataSocket.close();
                        catch
                            % Do nothing...
                        end
                        
                end
                % rethrow the Exception
                rethrow(ME);
            end
            
            % Intialize timer properties
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Create timer object
            obj.rxTimer = timer;
            % Specifying a tag for the timer
            obj.rxTimer.Tag = sprintf('Timer UDP server port %d', obj.port);
            % Equidistant firing
            obj.rxTimer.ExecutionMode = 'fixedRate';
            % No start delay
            obj.rxTimer.StartDelay = 0;
            % Timer interval
            obj.rxTimer.Period = obj.timerInterval / 1000;
            % Timer callback
            obj.rxTimer.TimerFcn = {@obj.rxTimerCallback};
            % Reset flag to indicate if timer is running
            obj.running = 0;
        end
        
        function setMTU(obj, mtu)
            %SETMTU Setting the maximum transfer unit
            
            % Check attributes
            validateattributes(mtu, {'numeric'}, {'real', 'positive', '<=', 1500}, 'setMTU', 'tu');
            
            if ( (obj.running) || (obj.socketOpened) )
                warning('Unable to set mtu property while server is running!');
                return;
            end
            
            % Set property
            obj.MTU  = mtu;
            
            % Create new an empty byte array
            obj.dpBuffer = uint8(zeros(1, obj.MTU));
            
            % Create a datagram packet that will be used for temp. storin
            % received data
            obj.dataPacket = DatagramPacket(obj.dpBuffer, obj.MTU);
        end
        
        function setTimerInterval(obj, interval)
            %SETTIMERINTERVAL Adjust the interval of the timer
            
            % Check attributes
            validateattributes(interval, {'numeric'}, {'real', 'positive', '>=', 20}, 'setTimerInterval', 'interval');
            
            if (obj.running)
                warning('Unable to set timer interval while server is running!');
                return;
            end
            
            % Set property
            obj.timerInterval  = interval;
            
            % Adjust timer...
            obj.rxTimer.Period = obj.timerInterval / 1000;
        end
        
        function start(obj)
            %START Start the UDP server and listen on specified port!
            
            % Necessary Java imports
            import java.net.*;
            
            % Check that at least one event listener is registered
            if ( ~event.hasListener(obj, 'DataReceived') )
                warning('No listener defined for UDPserver...');
            end
        
            % Open UDP DatagramSocket on specified port and interface...
            if (obj.socketOpened == 0)
                try
                    obj.dataSocket = DatagramSocket(obj.port, obj.inetAddress);
                    disp(['Opening UDP port ' num2str(obj.port)]);
                catch ME
                    warning('Unable to create/bind a DatagramSocket to interface or port!');
                    switch (ME.identifier)
                        % Check for Java exceptions
                        case 'MATLAB:Java:GenericException'
                            excobj = ME.ExceptionObject;
                            switch (class(excobj))
                                case 'java.net.BindException'
                                    warning('Port %d is already in use!', obj.port);
                                otherwise
                                    warning('Something went wrong... Java-Exception: %s', class(excobj))
                            end
                            
                        % Check for MATLAB exceptions
                        otherwise
                            % Try to close the port at least...
                            try
                                obj.dataSocket.close();
                                obj.socketOpened = 0;
                            catch
                                % Do nothing...
                            end
                            
                    end
                    % rethrow the Exception
                    rethrow(ME);
                end
            end
            
            % Set flag to indicate that the server was opened
            obj.socketOpened = 1;
            
            % Set read timeout...
            obj.dataSocket.setSoTimeout(10);
                
            % If timer was already running, switch it off!
            if ( strcmpi(obj.rxTimer.Running, 'on') )
                stop(obj.rxTimer);
                obj.running = 0;
            end
            
            start(obj.rxTimer);
            obj.running = 1;
        end
                
        function stop(obj)
            %START Start the UDP server and close the specified port!
            
            % Necessary Java imports
            import java.net.*;
            
            % First we have to stop the timer
            stop(obj.rxTimer);
            obj.running = 0;
            
            % Now close the UDP port
            if (obj.socketOpened)
                try
                    obj.dataSocket.close();
                    obj.socketOpened = 0;
                catch ME
                    warning('Unable to close the DatagramSocket (Java UDP implementation)!');
                    % Rethrow the Exception
                    rethrow(ME);
                end
            end
        end
        
        function packet = getPacket(obj)
            %GETPACKET Get the first received packet from the server's buffer
            %
            % A packet is a MATLAB struct with the following fields:
            % packet.remoteIP:   IP address of the remote host
            % packet.remotePort: The UDP port of the remote host that was used to send this packet
            % packet.length:     The length of the payload (number of bytes)
            % packet.data:       The data field (payload) of the packet (datatype: byte/uint8)
            
            if (length(obj.rxBuffer) > 0) %#ok<ISMT>
                packet = obj.rxBuffer{1};
                obj.rxBuffer(1) = [];
            else
                packet = [];
            end
        end
        
        function delete(obj)
            %DELETE Destructor of this class
            %
            % Cecks that the UDP port is closed and the timer is deleted
            
            %disp('UDPServer destructor');
            
            % Necessary Java imports
            import java.net.*;
            
            % First, stop the rxTimer
            if (obj.running == 1)
                stop(obj.rxTimer);
            end
            
            % Delete the timer object - free ressources
            delete(obj.rxTimer);
            %disp('Stopping timer... ')
            
            % Now close the socket/port
            if ( obj.socketOpened )
                obj.dataSocket.close()
                disp(['Closing UDP port ' num2str(obj.port)]);
            end
        end % delete function -> destructor!
    end % public methods
    
    methods (Access = private)
        function rxTimerCallback(udpObj, timerObj, eventData)
            %rxTimerCallback Callback function for internally used timer object
            
            dataReceived = 0;
            % Try to access the datagramSocket
            try
                 udpObj.dataSocket.receive(udpObj.dataPacket);
                 dataReceived = 1;
            catch ME
                switch (ME.identifier)
                    % Check for Java exceptions
                    case 'MATLAB:Java:GenericException'
                        excobj = ME.ExceptionObject;
                        switch (class(excobj))
                            case 'java.net.SocketTimeoutException'
                                %disp('TimeOut');
                            otherwise
                                disp(class(excobj));
                        end
                        
                        % Check for MATLAB exceptions
                    otherwise
                        udpObj.dataSocket.close();
                        rethrow(ME);
                end
            end
            
            if (dataReceived)
                % Get some values from the received datagramPacket and
                % store them in a struct
                receivedPacket.remoteIP   = char(udpObj.dataPacket.getAddress().toString());
                receivedPacket.remotePort = udpObj.dataPacket.getPort();
                receivedPacket.length     = udpObj.dataPacket.getLength();
                % Check data field of received packet
                if (receivedPacket.length > 0)
                    data       = uint8(udpObj.dataPacket.getData());
                    receivedPacket.data = data(1:receivedPacket.length);
                    clear data;
                else
                    receivedPacket.data = [];
                end
                
                % Store temporary struct in the rxBuffer of the UDPServer object
                udpObj.rxBuffer{end+1} = receivedPacket;
                
                % Delete temp struct
                clear receivedPacket;
                
                % Check if rxBuffer is "full"
                numPackets = length(udpObj.rxBuffer);
                if ( numPackets > udpObj.rxBufferSize )
                    warning('UDPServer rxBuffer full! Dropping older packets...');
                    udpObj.rxBuffer(1:(numPackets-udpObj.rxBufferSize)) = [];
                end
                
                % Finally, call all attached listeners!
                notify(udpObj, 'DataReceived');
            end
        end % rxTimerCallback
    end % private methods
    
    methods (Static)
        function ifaces = availableInterfaces()
            %AVAILABLEINTERFACES lists all available network interfaces
            % The output argument is a n-by-3 cell array with the following
            % structure:
            % <Interface name>, <IP address>, <Description>
            
            % Necessary Java includes
            import java.net.*;
            
            % Get an enumeration object of all existing network interfaces
            ifaceEnum = NetworkInterface.getNetworkInterfaces();
            
            % Prepare output cell array
            ifaces = cell(1,2);
            ifaces(1,1) = {'Name'};
            ifaces(1,2) = {'IP address'};
            ifaces(1,3) = {'Description'};
            
            % Iterate through all available network interfaces
            while (ifaceEnum.hasMoreElements)
                currIface  = ifaceEnum.nextElement;
                ifaces(end+1,1) = currIface.getName(); %#ok<AGROW>
                ifaces(end,  2) = currIface.getInterfaceAddresses().toString();
                ifaces(end,  3) = currIface.toString();
            end 
        end % availableInterfaces()
    end % static methods
end % classdef