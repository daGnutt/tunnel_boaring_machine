# Tunnel Boring Machine
The Tunnel Boring Machine is a SSH-tunnel manager. It is designed to assist giving access into a system not publicly exposed to the internet, but that still have access to the internet.

It does require a publicly exposed SSH server somewhere. 

## Installation
1. Clone the repository
2. Copy the *template.conf* to whatever configurationname you want.
3. Modify the configuration.
4. Run the `./tbm.sh -c <configurationfile>`
    1. The system will ask if you want to generate the ssh-key if it is missing
    2. It will offer you to install the ssh-key to the remote server, and limit it's access.
5. Schedule the `./tbm.sh -c <configurationfile>` to run however often you want, in any way you want.
   I personally use it to run every 15 minutes via a CRON-job.

## How does it work?
The TBM script will connect to your configured username/domainname using the specified SSH-key, and will look in the _tunnel_remoteside_port_file_ for a numerical value. If the value is 0, it will make sure the tunnel is closed. If it is another numerical value, it will open a SSH-backtunnel connection to that port on your remote ssh server, to your local server.

Once the tunnel is up, you can perform a SSH-connection to your local machine, via your remote host on the _tunnel_localside_port_ to access the machine running the TBM script.

## Template Configuration
The template configuration is used to prepare the TBM on how to connect to your endpoint.
```bash
# Remote Server
username="user"
domainname="example.com"
sshkey="./testkey"

# DNS server used to get a A record for the domainname.
# Use external DNS server, this is to enable tunnler to as long as a route
# to internet works, even if local dns services are down
dnsserver="8.8.8.8"

#Local Side Destionation for Tunnel
tunnel_localside_ip="127.0.0.1"
tunnel_localside_port="22"

#Remote Side Tunnel port
tunnel_remoteside_port_file="~/.ssh/tunnelport"

#Configuration of Output
output_log=1
output_console=1
logfile=tbmlog.log
```