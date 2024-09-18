#!/bin/bash
#this script combines nmap commands and run them one by one 

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if Nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "Nmap could not be found. Please install Nmap and try again."
    exit 1
fi

# Prompt the user for an IP address
read -p "Enter the IP address: " ip_address

# Check if a valid IP address format is entered
if [[ ! $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid IP address format"
    exit 1
fi

# Run the Nmap commands one by one and save output to files
echo "Running Initial TCP Nmap scan..."
nmap  -sV -oN initial_$ip_address.txt "$ip_address"

echo "Running Full TCP Nmap scan..."
nmap  -sV -A -p- -oN full_$ip_address.txt "$ip_address"

echo "Running Full UDP Nmap scan..."
nmap -sU -p- -oN udp_$ip_address.txt "$ip_address"

echo "Running Nmap NSE vulnerability scan..."
nmap "$ip_address" --script vuln -oN vuln_$ip_address.txt

# Extract open ports from each scan file
initial_ports=$(grep 'open' initial_$ip_address.txt | awk '{print $1}' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
full_tcp_ports=$(grep 'open' full_$ip_address.txt | awk '{print $1}' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
udp_ports=$(grep 'open' udp_$ip_address.txt | awk '{print $1}' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

# Combine all ports into a single variable, removing duplicates
all_ports=$(echo "$initial_ports,$full_tcp_ports,$udp_ports" | tr ',' '\n' | sort -n | uniq | tr '\n' ',' | sed 's/,$//')

# Output the ports
echo "Open ports: $all_ports"

# Optionally, save the ports to a file
echo "$all_ports" > open_ports_$ip_address.txt
echo " -sC -A on all ports found"



echo "All scans completed. Open ports saved to open_ports_$ip_address.txt , you can use these ports to further enumurate Ex: nmap -sC -A -p 22,80 etc "
