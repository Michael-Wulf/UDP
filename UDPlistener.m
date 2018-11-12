function UDPlistener(src, eventData)
%UDPLISTENER Summary of this function goes here
%   Detailed explanation goes here

    if ( strcmpi(eventData.EventName, 'DataReceived') )
        tempValue = src.getPacket()
    end
end

