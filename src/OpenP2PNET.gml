#define net_init
///net_init(name,key,port,connectiontype,interval,maxpeers);
globalvar net_vars;
var net_name, net_key, net_lanport, net_pubport, net_pubtype, net_interval, net_maxpeers;
var net_peer_id, net_peer_key, net_peer_ip, net_peer_port, net_peer_nettype, net_peer_name, net_peer_ping, net_peer_lastping, net_peer_pingrecv, net_peer_type, net_peer_socket;
var net_cmdlist, net_msglist, net_idcounter;
var net_devicemaster, net_devicemasterid, net_lanserver, net_pubserver, net_timer;

net_name = argument0;
net_key = argument1;
net_lanport = 6510;
net_pubport = argument2;
net_pubtype = argument3;
net_interval = argument4;
net_maxpeers = argument5;

//Serverlists
net_peer_id = ds_list_create();         //Local ID of the clien
net_peer_key = ds_list_create();        //Key: unique ID of the client
net_peer_ip = ds_list_create();         //IP
net_peer_port = ds_list_create();       //Port
net_peer_nettype = ds_list_create();    //Nettype: type of connection (NET_*: UDP, TCP, BROADCAST, HTTP)
net_peer_name = ds_list_create();       //Name: Human-readable ID of the client
net_peer_ping = ds_list_create();       //Last ping time: time to receive an answer of an "empty" package
net_peer_lastping = ds_list_create();   //Last time a ping was sent
net_peer_pingrecv = ds_list_create();   //Last time a ping answer was received
net_peer_type = ds_list_create();       //Type of connection (NETTYPE_*: LAN, EXT, PEER)
net_peer_socket = ds_list_create();     //Socket ID of the connection

net_idcounter = 0;

//Commands
net_cmdlist = ds_list_create();

//Recieved message hashes
net_msglist = ds_list_create();

//LAN
net_devicemaster = true;
net_devicemasterid = -1;
net_lanserver = network_create_server(network_socket_udp, net_lanport, net_maxpeers);
if (net_lanserver<0) {
    while (net_devicemasterid<0) net_devicemasterid = net_connect(NET_UDP, "127.0.0.1", 6510);
    net_devicemaster = false;
    while (net_lanserver<0) {
        net_lanport++;
        net_lanserver = network_create_server(network_socket_udp, net_lanport, net_maxpeers);
    }
} else {
    //Public
    net_pubserver = network_create_server(net_pubtype, net_pubport, net_maxpeers);
}

net_timer = 0;

net_vars = ds_map_create()
ds_map_add(net_vars, "net_name", net_name);
ds_map_add(net_vars, "net_key", net_key);
ds_map_add(net_vars, "net_lanport", net_lanport);
ds_map_add(net_vars, "net_pubport", net_pubport);
ds_map_add(net_vars, "net_pubtype", net_pubtype);
ds_map_add(net_vars, "net_interval", net_interval);
ds_map_add(net_vars, "net_maxpeers", net_maxpeers);
ds_map_add(net_vars, "net_peer_id", net_peer_id);
ds_map_add(net_vars, "net_peer_key", net_peer_key);
ds_map_add(net_vars, "net_peer_ip", net_peer_ip);
ds_map_add(net_vars, "net_peer_port", net_peer_port);
ds_map_add(net_vars, "net_peer_nettype", net_peer_nettype);
ds_map_add(net_vars, "net_peer_name", net_peer_name);
ds_map_add(net_vars, "net_peer_ping", net_peer_ping);
ds_map_add(net_vars, "net_peer_lastping", net_peer_lastping);
ds_map_add(net_vars, "net_peer_pingrecv", net_peer_pingrecv);
ds_map_add(net_vars, "net_peer_type", net_peer_type);
ds_map_add(net_vars, "net_peer_socket", net_peer_socket);
ds_map_add(net_vars, "net_cmdlist", net_cmdlist);
ds_map_add(net_vars, "net_msglist", net_msglist);
ds_map_add(net_vars, "net_idcounter", net_idcounter);           //R/W
ds_map_add(net_vars, "net_devicemaster", net_devicemaster);
ds_map_add(net_vars, "net_devicemasterid", net_devicemasterid);
ds_map_add(net_vars, "net_lanserver", net_lanserver);
ds_map_add(net_vars, "net_pubserver", net_pubserver);
ds_map_add(net_vars, "net_timer", net_timer);                   //R/W


#define net_run
globalvar net_vars;
var net_interval;
var net_peer_id, net_peer_key, net_peer_ip, net_peer_port, net_peer_nettype, net_peer_name, net_peer_ping, net_peer_lastping, net_peer_pingrecv, net_peer_type, net_peer_socket;
var net_cmdlist;
var net_devicemaster, net_devicemasterid, net_timer;
//Download vars
net_interval =          ds_map_find_value(net_vars, "net_interval");
net_peer_id =           ds_map_find_value(net_vars, "net_peer_id");
net_peer_key =          ds_map_find_value(net_vars, "net_peer_key");
net_peer_ip =           ds_map_find_value(net_vars, "net_peer_ip");
net_peer_port =         ds_map_find_value(net_vars, "net_peer_port");
net_peer_nettype =      ds_map_find_value(net_vars, "net_peer_nettype");
net_peer_name =         ds_map_find_value(net_vars, "net_peer_name");
net_peer_ping =         ds_map_find_value(net_vars, "net_peer_ping");
net_peer_lastping =     ds_map_find_value(net_vars, "net_peer_lastping");
net_peer_pingrecv =     ds_map_find_value(net_vars, "net_peer_pingrecv");
net_peer_type =         ds_map_find_value(net_vars, "net_peer_type");
net_peer_socket =       ds_map_find_value(net_vars, "net_peer_socket");
net_cmdlist =           ds_map_find_value(net_vars, "net_cmdlist");
net_devicemaster =      ds_map_find_value(net_vars, "net_devicemaster");
net_devicemasterid =    ds_map_find_value(net_vars, "net_devicemasterid");
net_timer =             ds_map_find_value(net_vars, "net_timer");
var outputlist = ds_list_create();

if (net_timer==0) {
    ds_list_clear(outputlist);
    net_push(NET_BROADCAST, -1, 6510, "-1", MSG_INFO, outputlist);
    if (net_devicemaster==false) {
        ds_list_clear(outputlist);
        net_send(net_devicemasterid, MSG_PEERREQUEST, outputlist);
    }
    net_timer = net_interval;
}
net_timer--;
for (var i=0; i<ds_list_size(net_peer_lastping); i++) {
    if (get_timer()-ds_list_find_value(net_peer_lastping, i)>net_interval/room_speed*1000000){// || ds_list_find_value(net_peer_ping, i)==0) {
        ds_list_clear(outputlist);
        ds_list_add(outputlist, get_timer());
        var _id = ds_list_find_value(net_peer_id, i);
        net_send(_id, MSG_PING, outputlist);
        ds_list_replace(net_peer_lastping, i, get_timer());
    }
}

if (ds_list_size(net_cmdlist)>0) {
    repeat (ds_list_size(net_cmdlist)) {
        var execlist, timer;
        execlist = ds_list_find_value(net_cmdlist, 0);
        timer = ds_list_find_value(execlist, 1);
        if (timer>0) {
            ds_list_replace(execlist, 1, timer-1);
            continue;
        }
        switch (ds_list_find_value(execlist, 0)) {
            case CMD_PING:
                var _id = ds_list_find_value(net_cmdlist, 1);
                if (ds_list_find_index(net_peer_id, _id)<0) break;
                ds_list_clear(outputlist);
                ds_list_add(outputlist, get_timer());
                net_send(_id, MSG_PING, outputlist);
                break;
        }
        ds_list_destroy(execlist);
        ds_list_delete(net_cmdlist, 0);
    }
}

ds_list_destroy(outputlist);

//Upload vars
ds_map_replace(net_vars, "net_timer", net_timer);

#define net_receive
///net_receive(eventtype,ds_list,ip,port,socket)
/******************
** RETURN VALUES **
*******************
**   1: Message correctly handled
**   0: Error
**  -1: Unknown protocol
**  -2: OPENP2PNET implementation is outdated
** any: Unknown OPENP2PNET Message, return value is message type
*/
globalvar net_vars;
var net_key;
var net_peer_id, net_peer_key, net_peer_ip, net_peer_port, net_peer_nettype, net_peer_name, net_peer_ping, net_peer_lastping, net_peer_pingrecv, net_peer_type, net_peer_socket;
var net_msglist, net_idcounter;
var net_lanserver, net_pubserver;
//Download vars
net_key =               ds_map_find_value(net_vars, "net_key");
net_peer_id =           ds_map_find_value(net_vars, "net_peer_id");
net_peer_key =          ds_map_find_value(net_vars, "net_peer_key");
net_peer_ip =           ds_map_find_value(net_vars, "net_peer_ip");
net_peer_port =         ds_map_find_value(net_vars, "net_peer_port");
net_peer_nettype =      ds_map_find_value(net_vars, "net_peer_nettype");
net_peer_name =         ds_map_find_value(net_vars, "net_peer_name");
net_peer_ping =         ds_map_find_value(net_vars, "net_peer_ping");
net_peer_lastping =     ds_map_find_value(net_vars, "net_peer_lastping");
net_peer_pingrecv =     ds_map_find_value(net_vars, "net_peer_pingrecv");
net_peer_type =         ds_map_find_value(net_vars, "net_peer_type");
net_peer_socket =       ds_map_find_value(net_vars, "net_peer_socket");
net_msglist =           ds_map_find_value(net_vars, "net_msglist");
net_idcounter =         ds_map_find_value(net_vars, "net_idcounter");
net_lanserver =         ds_map_find_value(net_vars, "net_lanserver");
net_pubserver =         ds_map_find_value(net_vars, "net_pubserver");
var recvlist, recvip, recvport, recvsocket, recvmsg, recvtype, recvkey, recvname, recvtokey, recvsignature, recvtime, recvhash, datalist, datastart;

recvlist = argument1;
if (string_copy(ds_list_find_value(recvlist, 0), 1, 12)!="[OPENP2PNET]") return -1;
if (string_delete(ds_list_find_value(recvlist, 0), 1, 12)!="[v0.1.0.0]") return -2;
recvip = argument2;
recvport = argument3;
recvsocket = argument4;
recvmsg = real(ds_list_find_value(recvlist, 1));
recvtype = real(ds_list_find_value(recvlist, 2));
recvkey = ds_list_find_value(recvlist, 3);
recvname = ds_list_find_value(recvlist, 4);
recvsignature = ds_list_find_value(recvlist, 5);
recvtokey = ds_list_find_value(recvlist, 6);
recvtime = ds_list_find_value(recvlist, 7);
datastart = 8;

//Check signature
//pass

//(Dis)connections
switch (recvtype) {
    case NET_TCP:
    case NET_TCPRAW:
        if (argument0!=network_type_data) {
            if (argument0==network_type_connect) {
                //Connect
                net_idcounter++;
                ds_map_replace(net_vars, "net_idcounter", net_idcounter);
                ds_list_add(net_peer_id, net_idcounter);
                ds_list_add(net_peer_key, "?");
                ds_list_add(net_peer_ip, recvip);
                ds_list_add(net_peer_port, recvport);
                ds_list_add(net_peer_nettype, NET_TCP); //Since you can't run a raw server, and all other protocols are connectionless, it must be built-in TCP
                ds_list_add(net_peer_name, "?");
                ds_list_add(net_peer_ping, 0);
                ds_list_add(net_peer_lastping, 0);
                ds_list_add(net_peer_pingrecv, 0);
                ds_list_add(net_peer_type, NETTYPE_PEER);
                ds_list_add(net_peer_socket, recvsocket);
            } else {
                //Disconnect
                pos = ds_list_find_index(net_peer_socket, recvsocket);
                ds_list_delete(net_peer_id, pos);
                ds_list_delete(net_peer_key, pos);
                ds_list_delete(net_peer_ip, pos);
                ds_list_delete(net_peer_port, pos);
                ds_list_delete(net_peer_nettype, pos);
                ds_list_delete(net_peer_name, pos);
                ds_list_delete(net_peer_ping, pos);
                ds_list_delete(net_peer_lastping, pos);
                ds_list_delete(net_peer_pingrecv, pos);
                ds_list_delete(net_peer_type, pos);
                ds_list_delete(net_peer_socket, pos);
            }
            return 1;
        } else {
            var pos = ds_list_find_index(net_peer_socket, recvsocket);
            if (pos>=0) {
                if (string_copy(ds_list_find_value(net_peer_key, pos), 1, 1)=="?") ds_list_replace(net_peer_key, pos, recvkey);
                if (ds_list_find_value(net_peer_name, pos)=="?") ds_list_replace(net_peer_name, pos, recvname);
            }
        }
        break;
    case NET_UDP:
        if (recvsocket==net_lanserver || recvsocket==net_pubserver) {
            //Connect (Src: incoming)
            var socket = -1;
            while (socket<0) socket = network_create_socket(network_socket_udp);
            recvsocket = socket;
            net_idcounter++;
            ds_map_replace(net_vars, "net_idcounter", net_idcounter);
            ds_list_add(net_peer_id, net_idcounter);
            ds_list_add(net_peer_key, recvkey);
            ds_list_add(net_peer_ip, recvip);
            ds_list_add(net_peer_port, recvport);
            ds_list_add(net_peer_nettype, NET_UDP);
            ds_list_add(net_peer_name, recvname);
            ds_list_add(net_peer_ping, 0);
            ds_list_add(net_peer_lastping, 0);
            ds_list_add(net_peer_pingrecv, 0);
            ds_list_add(net_peer_type, NETTYPE_PEER);
            ds_list_add(net_peer_socket, recvsocket);
        } else if (ds_list_find_value(net_peer_key, ds_list_find_index(net_peer_socket, recvsocket))=="?") {
            //Connect (Src: outgoing)
            var pos = ds_list_find_index(net_peer_socket, recvsocket);
            ds_list_replace(net_peer_key, pos, recvkey);
            ds_list_replace(net_peer_name, pos, recvname);
        }
        break;
}

//Modify vars when forwared message
while (recvmsg==MSG_FORWARD) {
    recvip = ds_list_find_value(recvlist, datastart);
    recvport = real(ds_list_find_value(recvlist, datastart+1));
    if (string_copy(ds_list_find_value(recvlist, datastart+2), 1, 12)!="[OPENP2PNET]") return -1;
    if (string_delete(ds_list_find_value(recvlist, datastart+2), 1, 12)!="[v0.1.0.0]") return -2;
    recvmsg = real(ds_list_find_value(recvlist, datastart+3));
    recvtype = real(ds_list_find_value(recvlist, datastart+4));
    recvkey = ds_list_find_value(recvlist, datastart+5);
    recvname = ds_list_find_value(recvlist, datastart+6);
    recvsignature = ds_list_find_value(recvlist, datastart+7);
    recvtokey = ds_list_find_value(recvlist, datastart+8);
    recvtime = ds_list_find_value(recvlist, datastart+9);
    datastart += 10;
    
    //Add current peer in chain
    if (ds_list_find_index(net_peer_key, recvkey)<0) net_connect(recvtype, recvip, recvport);
    
    //Quit when no message provided
    if (ds_list_size(recvlist)==datastart) return 1;
}

//Discard when known
var hashstr = "";
for (i=datastart-2; i<ds_list_size(recvlist); i++) {
    hashstr += ds_list_find_value(recvlist, i);
}
recvhash = sha1_string_unicode(hashstr);

if (ds_list_find_index(net_msglist, recvhash)>=0) {
    return 1;
} else {
    ds_list_add(net_msglist, recvhash);
}

//To be forwarded
if (recvtokey!=net_key && recvtokey!="-1") {
    var fwdlist = ds_list_create();
    ds_list_copy(fwdlist, recvlist);
    ds_list_insert(fwdlist, 0, recvip);
    ds_list_insert(fwdlist, 1, recvport);
    if (ds_list_find_index(net_peer_key, recvtokey)==-1 || ds_list_find_index(net_peer_key, recvkey)<0) {
        for (var i=0; i<ds_list_size(net_peer_key); i++) {
            net_send(ds_list_find_value(net_peer_id, i), MSG_FORWARD, fwdlist);
        }
    } else {
        net_send(recvtokey, recvmsg, recvlist);
    }
    ds_list_destroy(fwdlist);
    return 1;
}

switch (recvmsg) {
    case MSG_CONN:
        ///SERVER
        return 1;
        
    case MSG_DISCONN:
        ///SERVER
        net_disconnect(recvkey);
        return 1;
        
    case MSG_PING:
        ///SERVER
        datalist = ds_list_create();
        pos = ds_list_find_index(net_peer_socket, recvsocket);
        ds_list_add(datalist, ds_list_find_value(recvlist, datastart));
        net_send(ds_list_find_value(net_peer_id, pos), MSG_PONG, datalist);
        ds_list_destroy(datalist);
        return 1;
        
    case MSG_PONG:
        ///CLIENT
        pos = ds_list_find_index(net_peer_socket, recvsocket);
        ds_list_replace(net_peer_ping, pos, round((get_timer()-real(ds_list_find_value(recvlist, datastart)))/1000));
        ds_list_replace(net_peer_pingrecv, pos, get_timer());
        return 1;
        
    case MSG_INFOREQUEST:
        ///SERVER
        datalist = ds_list_create();
        pos = ds_list_find_index(net_peer_socket, recvsocket);
        net_send(ds_list_find_value(net_peer_id, pos), MSG_INFO, datalist);
        ds_list_destroy(datalist);
        return 1;
        
    case MSG_INFO:
        ///CLIENT
        pos = ds_list_find_index(net_peer_socket, recvsocket);
        ds_list_replace(net_peer_type, pos, NETTYPE_EXT);
        return 1;
        
    case MSG_PEERREQUEST:
        ///SERVER
        var transfer_key, transfer_ip, transfer_port, transfer_nettype;
        transfer_key = ds_list_create();
        ds_list_copy(transfer_key, net_peer_key);
        transfer_ip = ds_list_create();
        ds_list_copy(transfer_ip, net_peer_ip);
        transfer_port = ds_list_create();
        ds_list_copy(transfer_port, net_peer_port);
        transfer_nettype = ds_list_create();
        ds_list_copy(transfer_nettype, net_peer_nettype);
        
        datalist = ds_list_create();
        ds_list_add(datalist, ds_list_write(transfer_key));
        ds_list_add(datalist, ds_list_write(transfer_ip));
        ds_list_add(datalist, ds_list_write(transfer_port));
        ds_list_add(datalist, ds_list_write(transfer_nettype));
        pos = ds_list_find_index(net_peer_socket, recvsocket);
        net_send(ds_list_find_value(net_peer_id, pos), MSG_PEERTRANSFER, datalist);
        ds_list_destroy(datalist);
        ds_list_destroy(transfer_key);
        ds_list_destroy(transfer_ip);
        ds_list_destroy(transfer_port);
        ds_list_destroy(transfer_nettype);
        return 1;
        
    case MSG_PEERTRANSFER:
        ///CLIENT
        var transfer_key, transfer_ip, transfer_port, transfer_nettype;
        transfer_key = ds_list_create();
        transfer_ip = ds_list_create();
        transfer_port = ds_list_create();
        transfer_type = ds_list_create();
        
        ds_list_read(transfer_key, ds_list_find_value(recvlist, datastart));
        ds_list_read(transfer_ip, ds_list_find_value(recvlist, datastart+1));
        ds_list_read(transfer_port, ds_list_find_value(recvlist, datastart+2));
        ds_list_read(transfer_nettype, ds_list_find_value(recvlist, datastart+3));
        
        pos = ds_list_find_index(transfer_key, net_key);
        ds_list_delete(transfer_key, pos);
        ds_list_delete(transfer_ip, pos);
        ds_list_delete(transfer_port, pos);
        ds_list_delete(transfer_nettype, pos);
        
        for (var i=0; i<ds_list_size(transfer_key); i++) {
            if (ds_list_find_index(net_lan_key, ds_list_find_value(lantransfer_key, i))<0) {
                var nettype, ip, port;
                nettype = ds_list_find_value(transfer_nettype, i);
                ip = ds_list_find_value(transfer_ip, i);
                port = ds_list_find_value(transfer_port, i);
                net_connect(nettype,ip,port);
                show_debug_message("Added peer on "+ip+":"+string(port));
            }
        }
        
        ds_list_destroy(transfer_key);
        ds_list_destroy(transfer_ip);
        ds_list_destroy(transfer_port);
        ds_list_destroy(transfer_nettype);
        return 1;
        
    default:
        return recvmsg;
}

#define net_connect
///net_connect(conntype,url,port);
globalvar net_vars;
var net_peer_id, net_peer_key, net_peer_ip, net_peer_port, net_peer_nettype, net_peer_name, net_peer_ping, net_peer_lastping, net_peer_pingrecv, net_peer_type, net_peer_socket;
var net_idcounter;
net_peer_id =           ds_map_find_value(net_vars, "net_peer_id");
net_peer_key =          ds_map_find_value(net_vars, "net_peer_key");
net_peer_ip =           ds_map_find_value(net_vars, "net_peer_ip");
net_peer_port =         ds_map_find_value(net_vars, "net_peer_port");
net_peer_nettype =      ds_map_find_value(net_vars, "net_peer_nettype");
net_peer_name =         ds_map_find_value(net_vars, "net_peer_name");
net_peer_ping =         ds_map_find_value(net_vars, "net_peer_ping");
net_peer_lastping =     ds_map_find_value(net_vars, "net_peer_lastping");
net_peer_pingrecv =     ds_map_find_value(net_vars, "net_peer_pingrecv");
net_peer_type =         ds_map_find_value(net_vars, "net_peer_type");
net_peer_socket =       ds_map_find_value(net_vars, "net_peer_socket");
net_idcounter =         ds_map_find_value(net_vars, "net_idcounter");
net_idcounter++;
ds_map_replace(net_vars, "net_idcounter", net_idcounter);

var socket, conntype, url, port;
socket = -1;
conntype = argument0;
url = argument1;
port = argument2;
while (socket<0) {
    switch (argument0) {
        case NET_BROADCAST:
        case NET_UDP:
            socket = network_create_socket(network_socket_udp);
            break;
        case NET_TCP:
        case NET_TCPRAW:
            socket = network_create_socket(network_socket_tcp);
            break;
        case NET_HTTP:
            socket = 0;
            break;
    }
}

if (conntype==NET_TCP || conntype==NET_TCPRAW) {
    var conn, i;
    conn = -1;
    i = 0;
    while (conn<-1) {
        if (conntype==NET_TCP) {
            if (i>=5) return -1;
            conn = network_connect(socket, url, port);
        } else {
            conn = network_connect_raw(socket, url, port);
        }
        i++;
    }
}

ds_list_add(net_peer_id, net_idcounter);
ds_list_add(net_peer_key, "?");
ds_list_add(net_peer_ip, url);
ds_list_add(net_peer_port, port);
ds_list_add(net_peer_nettype, conntype);
ds_list_add(net_peer_name, "?");
ds_list_add(net_peer_ping, 0);
ds_list_add(net_peer_lastping, 0);
ds_list_add(net_peer_pingrecv, 0);
ds_list_add(net_peer_type, NETTYPE_EXT);
ds_list_add(net_peer_socket, socket);

switch (argument0) {
    case NET_UDP:
        var buffer = ds_list_create();
        net_send(net_idcounter, MSG_CONN, buffer);
        ds_list_destroy(buffer);
        break;
    case NET_TCP:
    case NET_TCPRAW:
    case NET_BROADCAST:
    case NET_HTTP:
        break;
}

return net_idcounter;

#define net_disconnect
///net_disconnect(_id);
globalvar net_vars;
var net_peer_id, net_peer_key, net_peer_ip, net_peer_port, net_peer_nettype, net_peer_name, net_peer_ping, net_peer_lastping, net_peer_pingrecv, net_peer_type, net_peer_socket;
net_peer_id =           ds_map_find_value(net_vars, "net_peer_id");
net_peer_key =          ds_map_find_value(net_vars, "net_peer_key");
net_peer_ip =           ds_map_find_value(net_vars, "net_peer_ip");
net_peer_port =         ds_map_find_value(net_vars, "net_peer_port");
net_peer_nettype =      ds_map_find_value(net_vars, "net_peer_nettype");
net_peer_name =         ds_map_find_value(net_vars, "net_peer_name");
net_peer_ping =         ds_map_find_value(net_vars, "net_peer_ping");
net_peer_lastping =     ds_map_find_value(net_vars, "net_peer_lastping");
net_peer_pingrecv =     ds_map_find_value(net_vars, "net_peer_pingrecv");
net_peer_type =         ds_map_find_value(net_vars, "net_peer_type");
net_peer_socket =       ds_map_find_value(net_vars, "net_peer_socket");
var _id, pos, type;
_id = argument0;
pos = ds_list_find_index(net_peer_id, _id);
if (pos<0) return -1;
type = ds_list_find_value(net_peer_nettype, pos);

switch (type) {
    case NET_UDP:
        var buffer = ds_list_create();
        net_send(_id, MSG_DISCONN, buffer);
        ds_list_destroy(buffer);
    case NET_TCP:
    case NET_TCPRAW:
    case NET_BROADCAST:
        var socket = ds_list_find_value(net_peer_socket, pos);
        network_destroy(socket);
        break;
    case NET_HTTP:
        break;
}

ds_list_delete(net_peer_id, pos);
ds_list_delete(net_peer_key, pos);
ds_list_delete(net_peer_ip, pos);
ds_list_delete(net_peer_port, pos);
ds_list_delete(net_peer_nettype, pos);
ds_list_delete(net_peer_name, pos);
ds_list_delete(net_peer_ping, pos);
ds_list_delete(net_peer_lastping, pos);
ds_list_delete(net_peer_pingrecv, pos);
ds_list_delete(net_peer_type, pos);
ds_list_delete(net_peer_socket, pos);

#define net_push
///net_push(conntype,url,port,key,msgtype,datalist)
globalvar net_vars;
var net_peer_id, net_peer_key, net_peer_ip, net_peer_port, net_peer_nettype, net_peer_name, net_peer_ping, net_peer_lastping, net_peer_pingrecv, net_peer_type, net_peer_socket;
var net_idcounter;
net_peer_id =           ds_map_find_value(net_vars, "net_peer_id");
net_peer_key =          ds_map_find_value(net_vars, "net_peer_key");
net_peer_ip =           ds_map_find_value(net_vars, "net_peer_ip");
net_peer_port =         ds_map_find_value(net_vars, "net_peer_port");
net_peer_nettype =      ds_map_find_value(net_vars, "net_peer_nettype");
net_peer_name =         ds_map_find_value(net_vars, "net_peer_name");
net_peer_ping =         ds_map_find_value(net_vars, "net_peer_ping");
net_peer_lastping =     ds_map_find_value(net_vars, "net_peer_lastping");
net_peer_pingrecv =     ds_map_find_value(net_vars, "net_peer_pingrecv");
net_peer_type =         ds_map_find_value(net_vars, "net_peer_type");
net_peer_socket =       ds_map_find_value(net_vars, "net_peer_socket");
net_idcounter =         ds_map_find_value(net_vars, "net_idcounter");
net_idcounter++;
ds_map_replace(net_vars, "net_idcounter", net_idcounter);
var socket, conntype, url, port, key;
socket = -1;
conntype = argument0;
url = argument1;
port = argument2;
key = argument3;
while (socket<0) {
    switch (argument0) {
        case NET_BROADCAST:
        case NET_UDP:
            socket = network_create_socket(network_socket_udp);
            break;
        case NET_TCP:
        case NET_TCPRAW:
            socket = network_create_socket(network_socket_tcp);
            break;
        case NET_HTTP:
            socket = 0;
            break;
    }
}
if (argument0==NET_TCP || argument0==NET_TCPRAW) {
    var conn, i;
    conn = -1;
    i = 0;
    while (conn<0) {
        if (argument0==NET_TCP) {
            if (i>=5) return -1;
            conn = network_connect(socket, url, port);
        } else {
            conn = network_connect_raw(socket, url, port);
        }
        i++;
    }
}
ds_list_add(net_peer_id, net_idcounter);
ds_list_add(net_peer_key, key);
ds_list_add(net_peer_ip, url);
ds_list_add(net_peer_port, port);
ds_list_add(net_peer_nettype, conntype);
ds_list_add(net_peer_name, "?");
ds_list_add(net_peer_ping, 0);
ds_list_add(net_peer_lastping, 0);
ds_list_add(net_peer_pingrecv, 0);
ds_list_add(net_peer_type, NETTYPE_PEER);
ds_list_add(net_peer_socket, socket);

net_send(net_idcounter, argument4, argument5);

net_disconnect(net_idcounter);

#define net_send
///net_send(id,msgtype,datalist)
globalvar net_vars;
var net_key, net_name;
var net_peer_id, net_peer_key, net_peer_ip, net_peer_port, net_peer_nettype, net_peer_name, net_peer_ping, net_peer_lastping, net_peer_pingrecv, net_peer_type, net_peer_socket;
net_key =               ds_map_find_value(net_vars, "net_key");
net_name =              ds_map_find_value(net_vars, "net_name");
net_peer_id =           ds_map_find_value(net_vars, "net_peer_id");
net_peer_key =          ds_map_find_value(net_vars, "net_peer_key");
net_peer_ip =           ds_map_find_value(net_vars, "net_peer_ip");
net_peer_port =         ds_map_find_value(net_vars, "net_peer_port");
net_peer_nettype =      ds_map_find_value(net_vars, "net_peer_nettype");
net_peer_name =         ds_map_find_value(net_vars, "net_peer_name");
net_peer_ping =         ds_map_find_value(net_vars, "net_peer_ping");
net_peer_lastping =     ds_map_find_value(net_vars, "net_peer_lastping");
net_peer_pingrecv =     ds_map_find_value(net_vars, "net_peer_pingrecv");
net_peer_type =         ds_map_find_value(net_vars, "net_peer_type");
net_peer_socket =       ds_map_find_value(net_vars, "net_peer_socket");

var destid, pos, msgtype, datalist;
var destkey, conntype, url, port, socket, buffer, str_;
destid = argument0;
pos = ds_list_find_index(net_peer_id, destid);
if (pos<0) return -1;

destkey = ds_list_find_value(net_peer_key, pos);
conntype = ds_list_find_value(net_peer_nettype, pos);
url = ds_list_find_value(net_peer_ip, pos);
port = ds_list_find_value(net_peer_port, pos);
socket = ds_list_find_value(net_peer_socket, pos);
msgtype = argument1;
datalist = argument2;

switch (conntype) {
    case NET_BROADCAST:
    case NET_UDP:
    case NET_TCP:
    case NET_TCPRAW:
        buffer = buffer_create(1, buffer_grow, 1);
        buffer_seek(buffer, buffer_seek_start, 0);
        buffer_write(buffer, buffer_string, "[OPENP2PNET][v0.1.0.0]");
        buffer_write(buffer, buffer_string, string(msgtype));
        buffer_write(buffer, buffer_string, string(conntype));
        buffer_write(buffer, buffer_string, net_key);
        buffer_write(buffer, buffer_string, net_name);
        buffer_write(buffer, buffer_string, "-1"); //Signature
        //Hash from here
        buffer_write(buffer, buffer_string, destkey);
        buffer_write(buffer, buffer_string, get_time_string());
        for (var i=0; i<ds_list_size(datalist); i++) {
            buffer_write(buffer, buffer_string, string(ds_list_find_value(datalist, i)));
        }
        switch (conntype) {
            case NET_BROADCAST:
                network_send_broadcast(socket, port, buffer, buffer_get_size(buffer));
                break;
            case NET_UDP:
                network_send_udp(socket, url, port, buffer, buffer_get_size(buffer));
                break;
            case NET_TCP:
            case NET_TCPRAW:
                network_send_packet(socket, buffer, buffer_get_size(buffer));
                break;
        }
        buffer_delete(buffer);
        break;
    case NET_HTTP:
        str_ = url+"?OP2PNdata_0=[OPENP2PNET][v0.1.0.0]";
        str_ += "&OP2PNdata_1="+string(msgtype);
        str_ += "&OP2PNdata_2="+string(conntype);
        str_ += "&OP2PNdata_3="+net_key;
        str_ += "&OP2PNdata_4="+net_name;
        str_ += "&OP2PNdata_5="+"-1";
        //Hash
        str_ += "&OP2PNdata_6="+destkey;
        str_ += "&OP2PNdata_7="+get_time_string();
        for (var i=0; i<ds_list_size(datalist); i++) {
            str_ += "&OP2PNdata_"+string(i+8)+"="+string(ds_list_find_value(datalist, i));
        }
        http_get(str_);
        break;
}

#define net_buffer_to_dslist
///net_buffer_to_dslist(buffer,ds_list)
var size = buffer_get_size(argument0);
var buffer = buffer_create(size, buffer_fixed, 1);
buffer_copy(argument0, 0, size, buffer, 0);
var list = argument1;

buffer_seek(buffer, buffer_seek_start, 0);
while (buffer_tell(buffer)<size) {
    var val = buffer_read(buffer, buffer_string);
    ds_list_add(list, val);
}

buffer_delete(buffer);

return list;

#define net_string_to_dslist
///net_string_to_dslist(string,ds_list)
var str_ = argument0;
var listnlchr = false;
var list = argument1;
ds_list_add(list, "");

for (var i=1; i<=string_length(str_); i++) {
    var char = string_char_at(str_, i);
    if (char==chr(10)) {
        if (listnlchr==true) break;
        listnlchr = true;
        ds_list_add(list, "");
    } else {
        listnlchr = false;
        var pos = ds_list_size(list)-1;
        ds_list_replace(list, pos, ds_list_find_value(list, pos)+char);
    }
}
ds_list_delete(list, ds_list_size(list)-1);
return list;

#define net_exec
///netcommand(command,argument0,argument1,etc.)
/***********************
** AVAILABLE COMMANDS **
************************
**
** CMD_PING; ID
**
**
*/
globalvar net_vars;
var net_cmds;
net_cmds =              ds_map_find_value(net_vars, "net_cmds");
if (argument_count>=1) {
    var list;
    list = ds_list_create();
    for (var i=0; i<argument_count; i++) ds_list_add(list, argument[i]);
    ds_list_add(net_cmds, list);
}