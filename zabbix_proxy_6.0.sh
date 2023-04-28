#  Version:        1.0
#  Author:         bygalacos
#  Github:         github.com/bygalacos
#  Creation Date:  22.12.2022
#  Purpose/Change: Initial script development

# Check if running as root
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run this script as root"
  exit 1
fi

# Check if running on CentOS
if [[ $(grep -Ei 'centos|red hat' /etc/*release) ]]; then
  # Install Zabbix proxy & MariaDB on CentOS
  clear
  setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
  yum install -y ca-certificates
  rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/$(rpm -E %{rhel})/x86_64/zabbix-release-6.0-4.el$(rpm -E %{rhel}).noarch.rpm
  curl -s https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash /dev/stdin --mariadb-server-version=10.6
  clear
  yum install -y zabbix-proxy-mysql zabbix-sql-scripts zabbix-selinux-policy mariadb-server
  systemctl start mariadb && systemctl enable mariadb
  clear

  # Connect to MySQL and create the zabbix_proxy database
  mysql -u root <<EOF
	CREATE DATABASE zabbix_proxy CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
	GRANT ALL PRIVILEGES ON zabbix_proxy.* TO zabbix@localhost IDENTIFIED BY 'zabbix';
EOF

  # Import Schema & Data
  echo "Importing data. This may take a while..."
  cat /usr/share/zabbix-sql-scripts/mysql/proxy.sql | mysql --default-character-set=utf8mb4 zabbix_proxy
  echo "Import completed!"

  # Get IP Address of Zabbix Server
  if [ -z "$1" ]; then
    read -p "Enter the IP address of the Zabbix server: " server_ip
  else
    server_ip=$1
  fi
  hostname=$(hostname)

  # Replace Server, Hostname, DBHost and DBPassword in Zabbix Proxy configuration file
  sed -i "s/Server=127.0.0.1/Server=$server_ip/g" /etc/zabbix/zabbix_proxy.conf
  sed -i "s/Hostname=Zabbix proxy/Hostname=$hostname/g" /etc/zabbix/zabbix_proxy.conf
  # DBUser & DBName already specified.
  sed -i "s/# DBHost=localhost/DBHost=localhost/g" /etc/zabbix/zabbix_proxy.conf
  sed -i "s/# DBPassword=/DBPassword=zabbix/g" /etc/zabbix/zabbix_proxy.conf

  # Restart Zabbix Proxy
  systemctl restart zabbix-proxy && systemctl enable zabbix-proxy
  clear
  systemctl status zabbix-proxy
fi

# Check if running on Ubuntu
if [[ $(grep -Ei 'ubuntu' /etc/*release) ]]; then
  # Install Zabbix proxy & MariaDB on Ubuntu
  clear
  apt-get update
  apt-get install -y ca-certificates
  wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu$(lsb_release -rs)_all.deb
  dpkg -i zabbix-release_* && rm -rf zabbix-release_*
  curl -s https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash /dev/stdin --mariadb-server-version=10.6
  clear
  apt-get update
  apt-get install -y zabbix-proxy-mysql zabbix-sql-scripts mariadb-common mariadb-server-10.6 mariadb-client-10.6
  systemctl start mariadb && systemctl enable mariadb
  clear

  # Connect to MySQL and create the zabbix_proxy database
  mysql -u root <<EOF
	CREATE DATABASE zabbix_proxy CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
	GRANT ALL PRIVILEGES ON zabbix_proxy.* TO zabbix@localhost IDENTIFIED BY 'zabbix';
EOF

  # Import Schema & Data
  echo "Importing data. This may take a while..."
  cat /usr/share/zabbix-sql-scripts/mysql/proxy.sql | mysql --default-character-set=utf8mb4 zabbix_proxy
  echo "Import completed!"

  # Get IP Address of Zabbix Server
  if [ -z "$1" ]; then
    read -p "Enter the IP address of the Zabbix server: " server_ip
  else
    server_ip=$1
  fi
  hostname=$(hostname)

  # Replace Server, Hostname, DBHost and DBPassword in Zabbix Proxy configuration file
  sed -i "s/Server=127.0.0.1/Server=$server_ip/g" /etc/zabbix/zabbix_proxy.conf
  sed -i "s/Hostname=Zabbix proxy/Hostname=$hostname/g" /etc/zabbix/zabbix_proxy.conf
  # DBUser & DBName already specified.
  sed -i "s/# DBHost=localhost/DBHost=localhost/g" /etc/zabbix/zabbix_proxy.conf
  sed -i "s/# DBPassword=/DBPassword=zabbix/g" /etc/zabbix/zabbix_proxy.conf

  # Restart Zabbix Proxy
  systemctl restart zabbix-proxy && systemctl enable zabbix-proxy
  clear
  systemctl status zabbix-proxy
fi