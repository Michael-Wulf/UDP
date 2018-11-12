port = 4711;
interface = 'lo';
udpServer = UDPServer('interface', interface, 'port', port);
addlistener(udpServer, 'DataReceived', @UDPlistener);
udpServer.setTimerInterval(20);
udpServer.start();