### 
# @Descripttion: 
 # @version: 0.1
 # @Author: lwg
 # @Date: 2019-12-04 09:57:05
 # @LastEditors: lwg
 # @LastEditTime: 2019-12-11 19:25:36
 ###
#!/usr/bin/env bash
source $(dirname $0)/../scripts/utils.sh
source $(dirname $0)/../scripts/mlx_env.sh
#export HRD_REGISTRY_IP="fawn-pluto0"
export HRD_REGISTRY_IP="192.168.3.112"

drop_shm

num_server_threads=1

blue "Reset server QP registry"
sudo pkill memcached
memcached -l 0.0.0.0 1>/dev/null 2>/dev/null &
sleep 1

blue "Starting $num_server_threads server threads"

flags="
	--num_threads $num_server_threads \
	--dual_port 0 \
	--is_client 0 \
	--size 16 \
	--postlist 16
"

# Check for non-gdb mode
if [ "$#" -eq 0 ]; then
  sudo -E numactl --cpunodebind=0 --membind=0 ../build/ud-sender $flags
fi

# Check for gdb mode
if [ "$#" -eq 1 ]; then
  sudo -E gdb -ex run --args ../build/ud-sender $flags
fi
