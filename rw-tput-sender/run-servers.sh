### 
# @Descripttion: 
 # @version: 0.1
 # @Author: lwg
 # @Date: 2019-12-04 09:57:05
 # @LastEditors: lwg
 # @LastEditTime: 2019-12-11 20:28:41
 ###
#!/usr/bin/env bash
source $(dirname $0)/../scripts/utils.sh
source $(dirname $0)/../scripts/mlx_env.sh
export HRD_REGISTRY_IP="192.168.3.112"

drop_shm

num_server_threads=16

blue "Reset server QP registry"
sudo pkill memcached
memcached -l 0.0.0.0 1>/dev/null 2>/dev/null &
sleep 1

blue "Starting $num_server_threads server threads"

flags="
	--num_threads $num_server_threads \
	--dual_port 0 \
  --use_uc 0 \
	--is_client 0 \
	--size 64 \
	--postlist 1 \
	--do_read 1
"

# Check for non-gdb mode
if [ "$#" -eq 0 ]; then
  sudo -E numactl --cpunodebind=0 --membind=0 ../build/rw-tput-sender $flags
fi

# Check for gdb mode
if [ "$#" -eq 1 ]; then
  sudo -E gdb -ex run --args ../build/rw-tput-sender $flags
fi
