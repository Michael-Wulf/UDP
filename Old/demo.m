import java.net.*;


% Get an enumeration object of all existing network interfaces
iface_enum = NetworkInterface.getNetworkInterfaces();

% Take only the specified interface
iface_found = 0;
while (iface_enum.hasMoreElements)
    curr_iface = iface_enum.nextElement;
    disp(curr_iface.getName());
    
    
end

ds = DatagramSocket()