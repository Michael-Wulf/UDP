function UDP_Example_OSC_Server_Integer_Listener(udpObj, eventData)
%UDP_EXAMPLE_SERVER_LISTENER Example for a UDP listener waiting for DataReceived events to occure
    
     % Check for only DataReceived events
    if ( strcmpi(eventData.EventName, 'DataReceived') )
        % When this event is raised, there must be at least one datagram
        % available in the receive buffer...
        
        % Read the first element from the receive buffer of the UDPServer object 
        datagram = udpObj.getDatagram();
        
        % Convert the payload of the datagram into an OSCMessage
        msg = OSCMessage(datagram.data);
        
        % Create an empty vector for the int32 and int64 values of the message
        values = [];
        
        if (~isempty(msg.typeTagList))
            % Iterate through all TypeTags of the OSCMessage
            for cntr = 1:1:length(msg.typeTagList)
                % Take current TypeTag
                currType = msg.typeTagList{cntr};
                
                % Check that it is an int32 or int63 value
                if ( (currType == OSCTypes.Int32) || (currType == OSCTypes.Int64))
                    
                    % Take the TypeTag's corresponting attribute from the message
                    % Cast it to int64 so that we can store it in the same vector
                    values = [values int64(msg.attributeList{cntr})]; %#ok<AGROW>
                    
                end
            end
        end
        
        % Make some outputs concerning the UDP datagram
%         fprintf('Received datagram info:\n');
%         fprintf('Remote host: %s \n', datagram.remoteIP);
%         fprintf('Remote port: %d \n', datagram.remotePort);
%         fprintf('Number of received bytes: %d \n', datagram.length);
         fprintf('Received bytes (hex): ');
         fprintf('%02X ', datagram.data);
%         fprintf('\n\n');
        
        % Make some outputs of the content of the OSCMessage
%         fprintf('OSC address: %s\n', msg.address);
%         fprintf('Number of received attributes: %d\n', length(msg.typeTagList));
%         fprintf('Number of received integer values in OSCMessage: %d\n', length(values));
        if (~isempty(values))
            fprintf('Received values: ');
            for cntr = 1:1:length(values)
                fprintf('%d', values(cntr));
                if(cntr < length(values))
                    fprintf(',');
                end
            end
            fprintf('\n');
        end
        
        
%         if ( udpObj.available() )
%             disp('Still more datagrams in receive buffer!');
%         else
%             disp('Last datagram read from receive buffer!');
%         end
%         fprintf('\n');
%         fprintf('\n');
    end
end

