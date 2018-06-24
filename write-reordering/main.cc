#include <gflags/gflags.h>
#include <stdlib.h>
#include <string.h>
#include <thread>
#include <vector>
#include "libhrd_cpp/hrd.h"

DEFINE_uint64(is_client, 0, "Is this process a client?");

static constexpr size_t kAppBufSize = 1000;

static void memory_barrier() { asm volatile("" ::: "memory"); }
static void lfence() { asm volatile("lfence" ::: "memory"); }
static void sfence() { asm volatile("sfence" ::: "memory"); }
static void mfence() { asm volatile("mfence" ::: "memory"); }

void run_server() {
  struct hrd_conn_config_t conn_config;
  conn_config.num_qps = 1;
  conn_config.use_uc = 0;
  conn_config.prealloc_buf = nullptr;
  conn_config.buf_size = kAppBufSize;
  conn_config.buf_shm_key = 3185;

  auto* cb = hrd_ctrl_blk_init(0 /* id */, 0 /* port */, 0 /* numa */,
                               &conn_config, nullptr /* dgram config */);

  char srv_name[kHrdQPNameSize];
  sprintf(srv_name, "server");
  char clt_name[kHrdQPNameSize];
  sprintf(clt_name, "client");

  hrd_publish_conn_qp(cb, 0, srv_name);
  printf("main: Server %s published. Waiting for client %s\n", srv_name,
         clt_name);

  hrd_qp_attr_t* clt_qp = nullptr;
  while (clt_qp == nullptr) {
    clt_qp = hrd_get_published_qp(clt_name);
    if (clt_qp == nullptr) usleep(200000);
  }

  printf("main: Server %s found client! Connecting..\n", srv_name);
  hrd_connect_qp(cb, 0, clt_qp);

  // This garbles the server's qp_attr - which is safe
  hrd_publish_ready(srv_name);
  printf("main: Server %s READY\n", srv_name);

  uint64_t seed = 0xdeadbeef;

  while (true) {
    size_t loc_1 = hrd_fastrand(&seed) % (kAppBufSize / sizeof(size_t));
    size_t loc_2 = hrd_fastrand(&seed) % (kAppBufSize / sizeof(size_t));

    if (loc_1 >= loc_2) continue;

    auto* ptr = reinterpret_cast<volatile size_t*>(cb->conn_buf);
    size_t val_1 = ptr[loc_1];
    memory_barrier();
    lfence();
    sfence();
    mfence();
    size_t val_2 = ptr[loc_2];
    if (val_2 > val_1) {
      printf("violation %zu %zu %zu %zu\n", loc_1, loc_2, val_1, val_2);
    } else {
      // printf("ok\n");
    }
  }
}

void run_client() {
  hrd_conn_config_t conn_config;
  conn_config.num_qps = 1;
  conn_config.use_uc = 0;
  conn_config.prealloc_buf = nullptr;
  conn_config.buf_size = kAppBufSize;
  conn_config.buf_shm_key = 3185;

  auto* cb = hrd_ctrl_blk_init(0 /* id */, 0 /* port */, 0 /* numa */,
                               &conn_config, nullptr /* dgram config */);

  char srv_name[kHrdQPNameSize];
  sprintf(srv_name, "server");
  char clt_name[kHrdQPNameSize];
  sprintf(clt_name, "client");

  hrd_publish_conn_qp(cb, 0, clt_name);
  printf("main: Client %s published. Waiting for server %s\n", clt_name,
         srv_name);

  hrd_qp_attr_t* srv_qp = nullptr;
  while (srv_qp == nullptr) {
    srv_qp = hrd_get_published_qp(srv_name);
    if (srv_qp == nullptr) usleep(200000);
  }

  printf("main: Client %s found server. Connecting..\n", clt_name);
  hrd_connect_qp(cb, 0, srv_qp);
  printf("main: Client %s connected!\n", clt_name);

  hrd_wait_till_ready(srv_name);

  struct ibv_send_wr wr, *bad_send_wr;
  struct ibv_sge sge;
  struct ibv_wc wc;
  size_t ctr = 0;

  while (true) {
    auto* ptr = reinterpret_cast<volatile size_t*>(&cb->conn_buf[0]);
    for (size_t i = 0; i < kAppBufSize / sizeof(size_t); i++) {
      ptr[i] = ctr;
    }
    ctr++;

    // Post a batch
    wr.opcode = IBV_WR_RDMA_WRITE;
    wr.num_sge = 1;
    wr.next = nullptr;
    wr.sg_list = &sge;

    wr.send_flags = IBV_SEND_SIGNALED;

    sge.addr = reinterpret_cast<uint64_t>(cb->conn_buf);
    sge.length = kAppBufSize;
    sge.lkey = cb->conn_buf_mr->lkey;

    wr.wr.rdma.remote_addr = srv_qp->buf_addr;
    wr.wr.rdma.rkey = srv_qp->rkey;

    int ret = ibv_post_send(cb->conn_qp[0], &wr, &bad_send_wr);
    rt_assert(ret == 0);
    hrd_poll_cq(cb->conn_cq[0], 1, &wc);
  }
}

int main(int argc, char* argv[]) {
  gflags::ParseCommandLineFlags(&argc, &argv, true);

  if (FLAGS_is_client == 1) {
    run_client();
  } else {
    run_server();
  }

  return 0;
}
