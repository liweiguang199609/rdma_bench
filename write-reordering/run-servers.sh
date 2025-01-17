### 
# @Descripttion: 
 # @version: 0.1
 # @Author: lwg
 # @Date: 2019-12-04 09:57:05
 # @LastEditors: lwg
 # @LastEditTime: 2019-12-11 17:06:20
 ###
#!/usr/bin/env bash

source $(dirname $0)/../scripts/utils.sh
source $(dirname $0)/../scripts/mlx_env.sh
#export HRD_REGISTRY_IP="akalianode-1.rdma.fawn.apt.emulab.net"
export HRD_REGISTRY_IP="192.168.3.112"

drop_shm
exe="../build/write-reordering"
chmod +x $exe

blue "Reset server QP registry"
sudo pkill memcached

# Spawn memcached, but wait for it to start
memcached -l 0.0.0.0 1>/dev/null 2>/dev/null &
while ! nc -z localhost 11211; do sleep .1; done
echo "Server: memcached server is open for business on port 11211"

# Check for non-gdb mode
if [ "$#" -eq 0 ]; then
  sudo -E numactl --cpunodebind=0 --membind=0 $exe --is_client 0
fi

# Check for gdb mode
if [ "$#" -eq 1 ]; then
  sudo -E gdb -ex run --args $exe --is_client 0
fi
