classdef UDP < handle
    % UDP Implementation of a User Datagram Protocol (UDP) client/server based on Java DatagramSockets
    % 
    % This class implements a UDP client/server object based on Java classes.
    % To avoid polling the underlying datagramSocket implementation to check
    % for received data packets, this class also implements a timer-based
    % mechanism to periodically check for newly received data. For a simplified 
    % access of the received data, this class implements an event DataReceived
    % which is raised whenever new data is available.
    %
    % Examples
    % --------
    % Example 1:
    %  % Create a UDP instance on the loopback interface
    %  % and listen on a random port
    %  udpServer = UDP();
    %  Check port
    %  disp(num2str(udpServer.port()));
    %  Check interface 
    %  disp(udpServer.interface());
    %  Check IP address
    %  disp(udpServer.ip());
    %
    % Example 2:
    %  % Create a UDP instance on the loopback interface (172.0.0.1) and listen
    %  % on port 63110
    %  udpServer = UDP('port', 63110);
    %  % Add a listener to the DataReceived event
    %  addlistener(udpServer, 'DataReceived', @UDPlistener);
    %  % Start the UDP instance
    %  udpServer.start();
    %  
    %  ...
    %  
    %  % Stop the UDP instance
    %  udpServer.stop();
    %  % delete the object -> call destructor
    %  delete(udpServer);
    % 
    %  % Implementation of the event listener
    %  function UDPlistener(udpObj, eventData)
    %    if ( strcmpi(eventData.EventName, 'DataReceived') )
    %      tempValue = udpObj.getPacket();
    %    end
    %  end
    %  
    % 
    % Example 3:
    %  % Create/bind a UDP instance on the interface eth0 and listen on port
    %  % 63110
    %  udpServer = UDP('interface', 'eth0', 'port', 63110);
    %
    % Example 4:
    %  % Create/bind a UDP instance on the IP address 192.168.1.112 and listen
    %  % on port 63110
    %  udpServer = UDP('ip', '192.168.1.112', 'port', 63110);
    %
    %
    % ---------------------------------------------------------------------
    % Author:  Michael Wulf
    %          Washington University in St. Louis
    %          Kepecs Lab
    % 
    % Date:    04/15/2022
    % Version: 1.0.4
    % GitHub:  https://github.com/Michael-Wulf/UDP
    % 
    % Copyright (C) 2022 Michael Wulf
    %
    % This program is free software; you can redistribute it and/or
    % modify it under the terms of the GNU General Public License
    % as published by the Free Software Foundation; either version 2
    % of the License, or (at your option) any later version.
    % 
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    % 
    % You should have received a copy of the GNU General Public License
    % along with this program; if not, write to the Free Software
    % Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
    % MA  02110-1301, USA.
    % ---------------------------------------------------------------------
        
    properties (Access = public)
    end
    
    properties (GetAccess = public, SetAccess = protected)
        interfaceName;      % Network interface name used by the UDP instance
        ip;                 % IPv4-address used by the UDP instance
        ipv6;               % IPv6-address used by the UDP instance
        port;               % UDP port used by the UDP instance (server: listening on: client: sending on)
        MTU;                % Maximum transfer unit (default: 1500 byte)
        timerInterval = 50; % Interval (ms) to check for new data (default: 50 ms)
    end
    
    properties (Access = private)
        netInterface;      % NetworkInterface object (Java)
        inetAddress;       % InetAddress object (Java)
        soTimeout = 1;     % Timeout (ms) for datagramSocket object (Java)
        rxTimer;           % Timer object
        rxBuffer;          % Receive buffer
        rxBufferSize = 20; % Maximum number of elements in rxBuffer
        dpRxBuffer;        % Receive byte buffer for datagram packet (length of MTU)
        dpTxBuffer;        % Receive byte buffer for datagram packet (length of MTU)
        dataPacketRx;      % DatagramPacket object (Java) for receiving datagrams
        dataPacketTx;      % DatagramPacket object (Java) for transmitting datagrams
        dataSocket;        % DatagramSocket object (Java)
        socketOpened;      % Flag to indicate if socket/port is still open
        running;           % Flag to indicate if receiving is started
    end
    
    events
        % DATARECEIVED Event that is raised whenever new data is received by the UDP instance.
        %
        % A valid listener function must have the following signature:
        % function_name(udpObject, eventData)
        % 
        % Example:
        % Implementation of a event listener function
        % function UDPlistener(udpObj, eventData)
        %   if ( strcmpi(eventData.EventName, 'DataReceived') )
        %     tempValue = udpObj.getPacket();
        %   end
        % end
        %
        % % Add listener
        % addlistener(udpObj, 'DataReceived', @UDPlistener);
        DataReceived;
    end
    
    methods (Access = public)
        function obj = UDP(varargin)
            %UDP Create a UDP instance for receiving and sending datagrams
            %
            % An UDP object can be specified for a given interface (e.g.
            % 'eth0') or an IP address (e.g. 192.168.1.112, IPv4 and IPv6 
            % addresses are both valid) and the UDP instance will be bound
            % to an UDP port
            %
            % For this constructor, the following properties can be specified:
            % - 'interface': The network interface the UDP object will be bound to
            %     - datatype: char-vector (string)
            %     - not required property
            %     - if not specified, the interface will be automatically be
            %     determined by the given IP address. If also no IP address is
            %     specified, the loopback interface ('lo', 127.0.0.1) will be
            %     used.
            %     Call UDP.availableInterfaces() for a list of available
            %     interfaces of the current system.
            %
            % - 'ip': The IP address (IPv4 or IPv6) the UDP object will be bound to
            %     - datatype: char-vector (string)
            %     - not required property
            %     - if not specified, the IP address will be automatically be
            %     determined by the given interface. If also no interface is
            %     specified, the loopback address (127.0.0.1, 'lo') will be
            %     used.
            %
            % - 'port': The UDP port used by the UDP object for receiving (listening) and transmitting datagrams
            %     - data type: numeric, scalar
            %     - not required property
            %     - only ports between 1025 and 65535 are allowed
            %     - if not specified, a random prt will be chosen by the
            %     underlying Java UDP implementation and can be read
            %     through the red-only property 'port' of the UDP object
            %
            % Examples
            % --------
            % Example 2:
            %  % Create a UDP instance on the loopback interface (127.0.0.1) on port 63110
            %  udpServer = UDP('port', 63110);
            % 
            % Example 3:
            %  % Create a UDP instance on the interface eth0 on port 63110
            %  udpServer = UDP('interface', 'eth0', 'port', 63110);
            %
            % Example 4:
            %  % Create/bind a UDP server on the ip address 192.168.1.112 on port 63110
            %  udpServer = UDP('ip', '192.168.1.112', 'port', 63110);
            
            % Necessary Java imports
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            import java.net.*;
            import java.io.*;
            import java.util.*;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Check input arguments - START
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if ( mod(nargin, 2) ~= 0 )
                error('UDP constructor requires name/value pairs of arguements!');
            end
            
            % Specify the needed arguments and default values
            validNames        = {'interface', 'ip', 'port'};
            %defaultValues     = {'lo', '127.0.0.1', []};
            defaultValues     = {'', '', []};
            requiredArguments = {};
            
            % Create properties struct for storing all of the constructor's properties
            properties = struct();
            
            % Check specified property names
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
            if (~isempty(properties.port))
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
                
                
            else
                % No port specified -> let the system decide
            end
            
            % check interface value
            if (~isempty(properties.interface))
                % interface must be a string
                if (~ischar(properties.interface))
                    error('Property ''interface'' must be a string defining the network interface (e.g. lo, eth0...)');
                end
            else
                % No interface specified -> wildcard interface (0.0.0.0)
            end
            
            % check ip value
            ipVersion = 0;
            if (~isempty(properties.ip))
                if (~ischar(properties.ip))
                    error('Property ''ip'' must be a string defining the ip address the UDP instance should be bind to (e.g. ''127.0.0.1'' (loopback lo), 192.168.1.1 - IPv6 addresses are also valid)');
                end
                
                
                ipElements = UDP.convertIPAddress(properties.ip);
                
                if ( isempty(ipElements) )
                    error(['Specified IP4 address (' properties.ip ') could not be parsed!']);
                    
                elseif ( length(ipElements) == 4 )
                    ipVersion = 4;
                    
                elseif ( length(ipElements) == 16 )
                    ipVersion = 6;
                    
                end
               
            else
                % No interface specified -> wildcard interface (0.0.0.0)
            end
            % Clearing some stuff
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
            useWildcard   = 0;
            
            if ( (useDefaultIface) &&  (useDefaultIP) )
                useWildcard = 1;
            elseif ( (useDefaultIface) &&  (~useDefaultIP) )
                if ( strcmpi(properties.ip, '0.0.0.0') )
                    useWildcard = 1;
                else
                    searchByIP = 1;
                end
            elseif ( (~useDefaultIface) &&  (useDefaultIP) )
                searchByIface = 1;
            elseif ( (~useDefaultIface) &&  (~useDefaultIP) )
                searchByIface = 1;
            end
            
            % Clear some things
            clear useDefaultIface useDefaultIP;
            
            % Init flag to search for interface
            ifaceFound = 0;
            
            % Initialize the interface to an empty value...
            obj.netInterface = [];
            
            if (searchByIface)
                % Try to find interface by name
                obj.netInterface = NetworkInterface.getByName(properties.interface);
                if (isempty(obj.netInterface))
                    error(['Specified interface ''' properties.interface ''' does not exist!']);
                end
                % Set flag
                ifaceFound = 1;
                
            elseif (searchByIP)
                % Convert byte array with the IP address into an
                % InetAddress object
                inet = InetAddress.getByAddress(ipElements);
                
                % Try to find interface by IP
                obj.netInterface = NetworkInterface.getByInetAddress(inet);
                if (isempty(obj.netInterface))
                    error(['Specified interface ''' properties.ip ''' does not exist!']);
                end
                
                % Set flag and leave while-loop
                ifaceFound = 1;
            end
            
            if ( (~ifaceFound) && (~useWildcard) )
                if (searchByIface)
                    ME = MException('UDP:interfaceNotFound', ...
                    'Interface %s not found on system', properties.interface);
                    throw(ME);
                elseif (searchByIP)
                    ME = MException('UDP:interfaceNotFound', ...
                    'IP address %s not found on system', properties.ip);
                    throw(ME);
                end
            end
            
            clear ifaceFound currIface
            
            % Set properties to the object...
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Set port (even blank)
            obj.port = properties.port;
            
            % Set IP addresses
            obj.ip   = '';
            obj.ipv6 = '';
            
            % Check that interface has at least one valid IP address
            if (~useWildcard)
                inetEnum = obj.netInterface.getInetAddresses();
                if ( isempty(inetEnum) )
                    ME = MException('UDP:noInterfaceAddressFound', ...
                        'Interface %s has no inet address', properties.interface);
                    throw(ME);
                end
                
                obj.inetAddress = [];
                
                % Iterate through all IP addresses
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
            else
                % If the wildcard address should be used, use the IPv4
                % version 0.0.0.0!
                obj.inetAddress = InetAddress.getByAddress(uint8(zeros(1,4)));
                tempString = char(obj.inetAddress);
                obj.ip = tempString(2:end);
                
                % Clear tempString
                clear tempString;
            end
            
            % Set interface name
            if (~useWildcard)
                obj.interfaceName = char(obj.netInterface.getName());
            else
                obj.interfaceName = 'Wildcard address (all interfaces)';
            end
            
            % Set MTU
            if ( (useWildcard) || (obj.netInterface.isLoopback()) )
                obj.MTU = 1500;
            else
                obj.MTU = obj.netInterface.getMTU();
            end
            
            % Create an empty byte buffer for the receiving datagramPacket
            obj.dpRxBuffer = uint8(zeros(1, obj.MTU));
            
            % Create a datagram packet that will be used for temp. storing
            % received data
            obj.dataPacketRx = DatagramPacket(obj.dpRxBuffer, obj.MTU);
            
            % Create an empty byte buffer for the transmitting datagramPacket
            obj.dpTxBuffer = uint8(zeros(1, obj.MTU));
            
            % Create a datagram packet that will be used for temp. storin
            % transmitted data
            obj.dataPacketTx = DatagramPacket(obj.dpTxBuffer, obj.MTU);
            
            % Create rxBuffer
            obj.rxBuffer = cell(0);
            
            % Reset flag to indicate if port is opened
            obj.socketOpened = 0;
            
            % Check if port is free!
            if ( isempty(obj.port) )
                if (useWildcard)
                    try
                        % Try to create a DatagramSocket without any
                        % parameters -> system chooses port and uses
                        % wildcard address
                        obj.dataSocket = DatagramSocket();
                        
                        % Now that we came so far, save the port chosen by the system...
                        obj.port = obj.dataSocket.getLocalPort();
                        
                        % ... and close the port again!
                        obj.dataSocket.close();
                    catch ME
                        warning('Unable to create a UDP object on a random port!');
                        switch (ME.identifier)
                            % Check for Java exceptions
                            case 'MATLAB:Java:GenericException'
                                excobj = ME.ExceptionObject;
                                switch (class(excobj))
                                    case 'java.net.BindException'
                                        warning('Port is already in use!');
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
                    
                else
                    % No wildcard address is to be used
                    % Unfortunately, there is no option to open a random
                    % port if we just have the inetAddress object. We have
                    % to iterate through all possible ports and see if we
                    % find an open port...
                    
                    % Take only ports that can not be registered with the
                    % IANA... 49152 to 65535...
                    minPort = 49152;
                    maxPort = 65535;
                    for portCntr = minPort:1:maxPort
                        try
                            obj.dataSocket = DatagramSocket(portCntr, obj.inetAddress);
                            
                            % Now that we came so far, save the port chosen by the system...
                            obj.port = obj.dataSocket.getLocalPort();
                            
                            % ... and close the port again!
                            obj.dataSocket.close();
                            
                            % Finally, jump out of the for loop...
                            break;
                        catch ME
                            switch (ME.identifier)
                                % Check for Java exceptions
                                case 'MATLAB:Java:GenericException'
                                    excobj = ME.ExceptionObject;
                                    switch (class(excobj))
                                        case 'java.net.BindException'
                                            % This is the usual message when port is already in use...
                                            continue;
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
                    end
                    
                    % Check if a free port was found...
                    if ( isempty(obj.port) )
                        ME = MException('UDP:noFreePortFound', ...
                        'Could not find a free UDP port for IP address %s on system', obj.ip);
                        throw(ME);
                    end
                end
                
            else
                % A port was specified -> even if we have to use the
                % wildcard address, we can use the "normal" contrsuctor
                % because it allows us to use the IP address 0.0.0.0 for a
                % wildcard address...
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
            end
            
            % Intialize timer properties
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Create timer object
            obj.rxTimer = timer;
            % Specifying a tag for the timer
            obj.rxTimer.Tag = sprintf('Timer UDP instance port %d', obj.port);
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
                warning('Unable to set mtu property while UDP instance is opened/running!');
                return;
            end
            
            % Set property
            obj.MTU  = mtu;
            
            % Create an empty byte buffer for the receiving datagramPacket
            obj.dpRxBuffer = uint8(zeros(1, obj.MTU));
            
            % Create a datagram packet that will be used for temp. storin
            % received data
            obj.dataPacketRx = DatagramPacket(obj.dpRxBuffer, obj.MTU);
            
            % Create an empty byte buffer for the transmitting datagramPacket
            obj.dpTxBuffer = uint8(zeros(1, obj.MTU));
            
            % Create a datagram packet that will be used for temp. storin
            % transmitted data
            obj.dataPacketTx = DatagramPacket(obj.dpTxBuffer, obj.MTU);
        end
        
        function setTimerInterval(obj, interval)
            %SETTIMERINTERVAL Adjust the interval of the timer
            
            % Check attributes
            validateattributes(interval, {'numeric'}, {'real', 'positive', '>=', 20}, 'setTimerInterval', 'interval');
            
            if (obj.running)
                warning('Unable to set timer interval UDP instance is running!');
                return;
            end
            
            % Set property
            obj.timerInterval  = interval;
            
            % Adjust timer...
            obj.rxTimer.Period = obj.timerInterval / 1000;
        end
        
        function start(obj)
            %START Start the UDP instance and listen on specified port!
            
            % Necessary Java imports
            import java.net.*;
            
%             % Check that at least one event listener is registered
%             if ( ~event.hasListener(obj, 'DataReceived') )
%                 warning('No listener defined for UDP instance...');
%             end
%             
%             % Open UDP DatagramSocket on specified port and interface...
%             if (obj.socketOpened == 0)
%                 try
%                     obj.dataSocket = DatagramSocket(obj.port, obj.inetAddress);
%                     disp(['Opening UDP port ' num2str(obj.port)]);
%                     
%                     
%                 catch ME
%                     warning('Unable to create/bind a DatagramSocket to interface or port!');
%                     switch (ME.identifier)
%                         % Check for Java exceptions
%                         case 'MATLAB:Java:GenericException'
%                             excobj = ME.ExceptionObject;
%                             switch (class(excobj))
%                                 case 'java.net.BindException'
%                                     warning('Port %d is already in use!', obj.port);
%                                 otherwise
%                                     warning('Something went wrong... Java-Exception: %s', class(excobj))
%                             end
%                             
%                             % Check for MATLAB exceptions
%                         otherwise
%                             % Try to close the port at least...
%                             try
%                                 obj.dataSocket.close();
%                                 obj.socketOpened = 0;
%                             catch
%                                 % Do nothing...
%                             end
%                             
%                     end
%                     % rethrow the Exception
%                     rethrow(ME);
%                 end
%             end
%             
%             % Set flag to indicate that the socket was opened
%             obj.socketOpened = 1;
%             
%             % Set read timeout...
%             obj.dataSocket.setSoTimeout(obj.soTimeout);
            
            obj.open();
                
            % Start timer only if it wasn't started before...
            if ( strcmpi(obj.rxTimer.Running, 'off') )
                start(obj.rxTimer);
                obj.running = 1;
            end
        end
                
        function stop(obj)
            %STOP Stop the UDP instance and close the specified port!
            
            % Necessary Java imports
            import java.net.*;
            
            % First we have to stop the timer
            stop(obj.rxTimer);
            obj.running = 0;
            
            % Now close the UDP port
            obj.close();
%             if (obj.socketOpened)
%                 try
%                     obj.dataSocket.close();
%                     obj.socketOpened = 0;
%                     disp(['Closing UDP port ' num2str(obj.port)]);
%                 catch ME
%                     warning('Unable to close the DatagramSocket (Java UDP implementation)!');
%                     % Rethrow the Exception
%                     rethrow(ME);
%                 end
%             end
        end
        
        function open(obj)
            % OPEN Opens the UDP instance on the pre-defiened
            % port/interface without starting to listen on that! The
            % instance will not react to any incoming datagrams!!!
            
            % Necessary Java imports
            import java.net.*;
            
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
            
            % Set flag to indicate that the socket was opened
            obj.socketOpened = 1;
            
            % Set read timeout...
            obj.dataSocket.setSoTimeout(obj.soTimeout);
        end
        
        function close(obj)
            % CLOSE Closes the UDP instance.
            % If the the instance's start function was called before, this 
            % function will not affect the associated timer object! This could
            % cause error during the timer's callback function whicht will
            % keep on trying to access the UDP instance!
            % If the start method was called before, use the stop method
            % instead of sing this (close) method!
            
            % Necessary Java imports
            import java.net.*;
            
            if (obj.running == 1)
                warning('Associated timer to the UDP instance is still running...');
            end
            
            if ( obj.socketOpened == 1 )
                try
                    obj.dataSocket.close();
                    obj.socketOpened = 0;
                    disp(['Closing UDP port ' num2str(obj.port)]);
                catch ME
                    warning('Unable to close the DatagramSocket (Java UDP implementation)!');
                    % Rethrow the Exception
                    rethrow(ME);
                end
            end
        end
        
        function status = isopen(obj)
            % ISOPEN Gtes the current status of the UDP port
            status = obj.socketOpened;
        end
        
        function datagram = getDatagram(obj)
            %GETDATAGRAM Get the first received datagram from the UDP instance's receive buffer
            %
            % A datagram is a MATLAB struct with the following fields:
            % datagram.remoteIP:   IP address of the remote host
            % datagram.remotePort: The UDP port of the remote host that was used to send this datagram
            % datagram.length:     The length of the payload (number of bytes)
            % datagram.data:       The data field (payload) of the datagram (datatype: byte/uint8)
            
            % Necessary Java imports
            import java.net.*;
            
            if (length(obj.rxBuffer) > 0) %#ok<ISMT>
                datagram = obj.rxBuffer{1};
                obj.rxBuffer(1) = [];
            else
                datagram = [];
            end
        end
        
        function sendDatagram(obj, varargin)
            %SENDDATAGRAM Send a datagram via this UDP instance
            % A datagram mus be given as a struct with the following fiels:
            % - datagram.remoteIP: IP address of the remote host as a sttring (e.g. '127.0.0.1')
            % - datagram.remotePort: The remote UDP port (port where the other application is listening on)
            % - datagram.data: Payload of the datagram; must be an uint vector!
            
            
            % Necessary Java imports
            import java.net.*;
            
            % First check if the port is open!
            if ( obj.socketOpened == 0 )
                warning('Can''t send anything via a closed UDP port... Open it first!');
            end
            
            % Specify some values to check the arguments
            requiredFieldnames = {'remoteIP', 'remotePort', 'data'};
            validFieldnames    = [requiredFieldnames, {'length'}]; %#ok<NASGU>
            
            txDatagram.remoteIP   = '';
            txDatagram.remotePort = [];
            txDatagram.length     = 0;
            txDatagram.data       = uint8([]);
            
            if ( nargin < 2)
                warning('No datagram passed to be sent!')
                
            elseif ( nargin == 2)
                % Just one argument -> datagram as a struct
                if ( isstruct(varargin{1}) )
                    tempStruct = varargin{1};
                    tempFNames = fieldnames(tempStruct);
                    for cntr=1:1:length(requiredFieldnames)
                        if (isempty(find(strcmpi(tempFNames, requiredFieldnames{cntr}), 1)))
                            warning(['Required fieldname ''' requiredFieldnames{cntr} ''' missing in datagram struct to be sent!']);
                            return;
                        end
                    end
                    if ( ~ischar(tempStruct.remoteIP) )
                        warning('remote IP address must be specified as string!');
                        return;
                    end
                    
                    % Store IP address
                    txDatagram.remoteIP = tempStruct.remoteIP;
                    
                    if ( ~isnumeric(tempStruct.remotePort) )
                        warning('Remote port must be specified as numerical value!');
                        return;
                    elseif ( mod(tempStruct.remotePort, 1) ~= 0 )
                        warning('Remote port must be an integer value between 1 and 65535!');
                        return;
                    elseif ( (tempStruct.remotePort < 1) || (tempStruct.remotePort > 65535) )
                        warning('Remote port must be an integer value between 1 and 65535!');
                        return;
                    end
                    
                    % Store port
                    txDatagram.remotePort = tempStruct.remotePort;
                    
                    if ( isempty(tempStruct.data) )
                        txDatagram.data = uint8([]);
                    elseif ( ~isa(txDatagram.data, 'uint8') )
                        warning('Data inside the datagram must be a uint8 vector!');
                        return;
                    elseif ( isa(tempStruct.data, 'uint8') )
                        txDatagram.data = tempStruct.data;
                    end
                    
                else
                    warning('Passed datagram must be a struct!');
                    return;
                end
            end
            
            txDatagram.length = length(txDatagram.data);
            
            
            
            % Clear tx buffer array
            obj.dpTxBuffer = uint8(zeros(1, obj.MTU));
            obj.dpTxBuffer(1:txDatagram.length) = txDatagram.data;
            
            
            % Bind buffer and length of buffer to the DatagramPacket object
            obj.dataPacketTx = DatagramPacket(obj.dpTxBuffer, obj.MTU);
            
            % Set data length attribute of DatagramPAcket
            obj.dataPacketTx.setLength(txDatagram.length);
            
            % Set IP address
            ipElements = UDP.convertIPAddress(txDatagram.remoteIP);
            inet = InetAddress.getByAddress(ipElements);
            obj.dataPacketTx.setAddress(inet);
            
            % Set port
            obj.dataPacketTx.setPort(txDatagram.remotePort);
            
            % Send the datagram
            try
                obj.dataSocket.send(obj.dataPacketTx);
            catch ME
                disp(ME)
                switch (ME.identifier)
                    % Check for Java exceptions
                    case 'MATLAB:Java:GenericException'
                        excMessage = char(ME.ExceptionObject.getMessage);
                        if (contains(excMessage, 'Network is unreachable'))
                            warning('Remote not accessible: %s:%d', txDatagram.remoteIP, txDatagram.remotePort);
                        else
                            warning('Something went wrong... Java-Exception: %s Message: ', class(ME.ExceptionObject), excMessage);
                        end
                        
                        % Check for MATLAB exceptions
                    otherwise
                        warning('Something went wrong! %s %s', ME.identifier, ME.message);
                end
            end
        end
        
        function numDatagrams = available(obj)
            %AVAILABLE Indicates how many received datagrams are in the receive buffer
            
            % Just return the length of rxBuffer
            numDatagrams = length(obj.rxBuffer);
        end
        
        function delete(obj)
            %DELETE Destructor of this class
            %
            % Cecks that the UDP port is closed and the timer is deleted
            
            %disp('UDP destructor');
            
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
            if ( obj.socketOpened == 1)
                obj.dataSocket.close()
                disp(['Closing UDP port ' num2str(obj.port)]);
            end
        end % delete function -> destructor!
    end % public methods
    
    methods (Access = private)
        function rxTimerCallback(udpObj, timerObj, eventData) %#ok<INUSD>
            %rxTimerCallback Callback function for internally used timer object
            
            dataReceived = 0;
            % Try to access the datagramSocket
            try
                 udpObj.dataSocket.receive(udpObj.dataPacketRx);
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
                receivedDatagram.remoteIP   = char(udpObj.dataPacketRx.getAddress().toString());
                if ( length(receivedDatagram.remoteIP) > 1 )
                    % Remove the leading '/'...
                    receivedDatagram.remoteIP   = receivedDatagram.remoteIP(2:end);
                end
                receivedDatagram.remotePort = udpObj.dataPacketRx.getPort();
                receivedDatagram.length     = udpObj.dataPacketRx.getLength();
                % Check data field of received packet
                if (receivedDatagram.length > 0)
                    % Convert and truncate the received payload%
                    % udpObj.dataPacketRx.getData() delivers the data NOT as an
                    % unsigned value (even though we specified the receive
                    % buffer as uint8...)!!! That's why we have to cast it
                    % again...
                    data = typecast(udpObj.dataPacketRx.getData(), 'uint8');
                    receivedDatagram.data = data(1:receivedDatagram.length);
                    clear data;
                else
                    receivedDatagram.data = [];
                end
                
                % Store temporary struct in the rxBuffer of the UDP instance
                udpObj.rxBuffer{end+1} = receivedDatagram;
                
                % Delete temp struct
                clear receivedDatagram;
                
                % Check if rxBuffer is "full"
                numDatagrams = length(udpObj.rxBuffer);
                if ( numDatagrams > udpObj.rxBufferSize )
                    warning('UDP instance''s rxBuffer full! Dropping older datagrams...');
                    udpObj.rxBuffer(1:(numDatagrams-udpObj.rxBufferSize)) = [];
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
        
        function ipElements = convertIPAddress(ipString)
            %CONVERTIPADDRESS Convert an IP address as a string into a byte
            %array
            
            ipElements = [];
           
            if ( ~ischar(ipString) )
                warning('Specified IP address must be a string!');
                return;
            end
            
            
            if ( contains(ipString,'.') )
                %IPv4 format
                
                ipElements = strsplit(ipString, '.');
                if ( length(ipElements) ~= 4 )
                    warning(['Specified IPv4 address (' ipString ') has the wrong format!']);
                    return;
                end
                ipElements = cellfun(@str2num, ipElements, 'UniformOutput', false);
                
                if ( find(cellfun(@isempty, ipElements), 1) )
                    warning(['Specified IPv4 address (' ipString ') has the wrong format!']);
                    return;
                end
                
                ipElements = cell2mat(ipElements);
                if ( ~isempty(find(ipElements > 255, 1)) || ~isempty(find(ipElements < 0, 1)) || ~isempty(find(mod(ipElements, 1), 1)) )
                    warning(['Specified IPv4 address (' properties.ip ') has the wrong format!']);
                    return;
                end
                ipElements = uint8(ipElements);
                
            elseif ( contains(ipString,':') )
                %IPv6 format
                
                % Split string at colons and check that there are 8
                % parts...
                ipElements = strsplit(ipString, ':');
                if ( length(ipElements) ~= 8 )
                    warning(['Format of specified IPv6 address (' ipString ') not supported!' ...
                        'Please enter all 16 byte as hex values in the format X:X:X:X:X:X:X:X']);
                    return;
                end
                
                % Convert hexadecimal notation to decimal form
                try
                    ipElements = cellfun(@hex2dec, ipElements, 'UniformOutput', false);
                catch ME %#ok<NASGU>
                    warning(['Format of specified IPv6 address (' ipString ') not supported!' ...
                        'Please enter all 16 byte as hex values in the format X:X:X:X:X:X:X:X']);
                    return;
                end
                
                % Empty elements mean that the IPv6 address was not entered
                % as hexa-decimal values
                if ( find(cellfun(@isempty, ipElements), 1) )
                    warning(['Suppressed or shortened elements in IPv6 address format (' ipString ') not supported!' ...
                        'Please enter all 16 byte as hex values in the format X:X:X:X:X:X:X:X']);
                    return;
                end
                
                % Convert cell array to matrix/vector
                ipElements = cell2mat(ipElements);
                
                % Check that only 16-bit values were entered (uint16 < 65536)
                if ( ~isempty(find(ipElements > 65535, 1)) )
                    error(['Format of specified IPv6 address (' ipString ') not supported!' ...
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
        end
    end % static methods
end % classdef