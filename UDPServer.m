classdef UDPServer < handle
    %UDPSERVER Summary of this class goes here
    %   Detailed explanation goes here
    % EXAMPLE
    %
        
    properties (Access = public)
        
    end
    
    properties (GetAccess = public, SetAccess = protected)
        interface;    % Network interface the server listens on
        ip;           % IP-address the server listens on
        ipv6;         % IP-address the server listens on
        port;         % UDP-port the server listens to (required property)
        MTU;          % Maximum transfer unit
        timerInterval % Timer interval in ms to check for incoming data
    end
    
    properties (Access = private)
        serverIface;    % NetworkInterface object (Java)
        inetAddress;    % InetAddress object (Java)
        rxTimer;        % Timer object
        rxBuffer;       % Receive byte buffer (length of MTU)
        dataPacket;     % DatagramPacket object (Java)
        dataSocket;     % DatagramSocket object (Java)
        socketOpened;   % Flag to indicate if socket/port is still open
    end
    
    methods (Access = public)
        function obj = UDPServer(varargin)
            %UDPSERVER Create a UDPServer object for receiving messages
            %   Detailed explanation goes here
            
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
            obj.rxBuffer = uint8(zeros(1, obj.MTU));
            
            % Create a datagram packet
            obj.dataPacket = DatagramPacket(obj.rxBuffer, obj.MTU);
            
            % Flag to indicate if port is opened
            obj.socketOpened = 0;
            
            % Check if port is free!
            try
                obj.dataSocket = DatagramSocket(obj.port, obj.inetAddress);
                obj.dataSocket.close();
            catch ME
                switch (ME.identifier)
                    % Check for Java exceptions
                    case 'MATLAB:Java:GenericException'
                        excobj = ME.ExceptionObject;
                        switch (class(excobj))
                            case 'java.net.BindException'
                                warning('Unable to open UDP port %d! Port is already in use...', obj.port);
                            otherwise
                                disp(class(excobj));
                        end
                        rethrow(ME);
                        % Check for MATLAB exceptions
                    otherwise
                        try
                            obj.dataSocket.close();
                        catch
                        end
                        rethrow(ME);
                end
            end
            
            % Timer interval
            obj.timerInterval = 10;
            
            % Set and initialze timer
            obj.rxTimer = timer;
            obj.rxTimer.StartDelay = 0;
            obj.rxTimer.Period     = 0.01;
            obj.rxTimer.ExecutionMode = 'fixedSpacing';
            
            obj.rxTimer.TimerFcn   = {@UDPServerTimerCallback, ds, dp};
            
            %start(rx_timer);
            
            
            
        end
        
        function delete(obj)
            if ( obj.socketOpened )
                try
                    obj.dataSocket.close()
                catch ME
                    rethrow(ME)
                end
            end
        end
        
        function start(obj)
            % Open port
            % start timer
        end
                
        function obj = stop(obj)
            
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
    
    methods (Access = private)
    end
    
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
        end
    end
end

