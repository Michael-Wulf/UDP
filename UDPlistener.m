function UDPlistener(udpServerObj, eventData)
%UDPLISTENER Summary of this function goes here
%   Detailed explanation goes here

    if ( strcmpi(eventData.EventName, 'DataReceived') )
        tempValue = udpServerObj.getPacket();
        disp(tempValue);
    end
end

