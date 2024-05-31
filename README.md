# Aidan's Setup Scripts for his (and your?) servers

### OpenVPN

- Download the configuration with `curl -O https://raw.githubusercontent.com/aidan-lemay/setup-scripts/main/openvpn.sh`
- Make the script executable with `chmod +x openvpn.sh`
- Run the script with `sudo ./openvpn.sh`
- Clients are assigned addresses in the 192.168.31.0 range
- If you want to add a device on your network to your route, add it in `/etc/openvpn/server.conf` with the line `push "route xxx.xxx.x.x 255.255.255.0"`

#### Configuration
- Output files are written to `~/openvpn/`
- Server configuration is written to `/etc/openvpn/server.conf`
- 

#### Control
- Restart the openvpn server after changes to configurations with `sudo systemctl restart openvpn@server`
- Check openvpn server logs with `sudo systemctl status openvpn@server`
