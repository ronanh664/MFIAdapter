#ifndef __DWF_CLIENT_API_H__
#define __DWF_CLIENT_API_H__

#include <list>
#include <stdio.h>
#include <stdint.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include "dwf_packet.h"
#include "dwf_manage.h"

#define DWF_JSON_BUFFSIZE 1024*1024

using namespace std;

typedef struct _ERROR_MSG_PRINT_E {
    int err_num;
    const char *err_msg;
} ERROR_MSG_PRINT_t;

namespace yuneec
{
class CDownLoad
{

public:
    CDownLoad(const char *id, int version, bool setbit,
              int packsize, const char *pservaddr, int serport);
    ~CDownLoad();

public:
    int  yuneec_download_request(int extMsgType, char *jsonBuf, int jsonBufsize, int timeoutMsec);
    int  yuneec_download_file(const char *filename, const char *location, int timeoutMsec);
    int  yuneec_download_pause(void);
    int  yuneec_download_resume(void);
    int  yuneec_download_quit(void);
    int  yuneec_download_delete(const char *jsonBuf, int jsonBufsize, int timeoutMsec);
    int  yuneec_download_progress_get() const;
    int  yuneec_download_config(int timeoutMsec);
    void yuneec_async_event_status_check();
    const char *yuneec_error_msg_print(void);

private:
    int  event_send_name_to_server(const char *dwfFilename);
    void event_download_loop();
    int  event_request_list(int extMsgType, char *outbuf, int outBufsize);
    void event_delete_list();
    void event_set_file_storage_path(const char *path);
    void event_get_process(int *process);
    void event_remove_file(void);
    int  event_data_recvfrom(int sockfd, sockaddr *peeraddr, socklen_t *peeraddrLen);
    int  event_data_read(int sockfd, int count, int timeout);
    int  event_crcsum_check(CPacket &packet);
    int  event_ack_from_camera_check(CPacket &packet);
#ifdef UDP
    void event_timer_check();
    int  event_packet_seqnum_check();
#endif
    int  event_pause_flag_check(int eventFlag, int pes, int timeout);
    int  event_restart_flag_check(int eventFlag, int pes, int timeout);

private:
    void process_data_appfile_list_get(CPacket &packet);
    int  process_data_appfile_size_get(CPacket &packet);
    int  process_data_appfile_start(CPacket &packet);
    void process_data_appfile_pause(CPacket &packet);
    int  process_data_appfile_resume(CPacket &packet);

private:
    int  send_msg_data_to_camera(uint8_t marker, uint8_t msgtype,
                                 const char *payload, uint32_t payloadLen);
    int  send_msg_ack_to_camera(uint8_t marker, uint8_t msgtype,
                                uint8_t ackflg = false, uint16_t ack = DWF_ACK_NONE,
                                uint16_t extype = DWF_EX_GET_ALL);
    int  double_dup_check(void);
    int  event_base_process_data(void);
    int  event_base_process_ctrl(void);
    int  make_socket_nonblocking(int sockFd);
    int  event_socket_init(void);
    void event_socket_release(void);


public:
    int  	  errnum;
    int       downProgress;
    int       running;
private:
    int       sockfd;
    int       servport;
    char  	  filename[DWF_MAX_FILENAME];
    char      absFileName[DWF_MAX_FILENAME];
    FILE     *fp;
    char      storagePath[DWF_MAX_FILEPATH];
    fd_set    readfds;
    bool      gotCfgAckFromServFlag;
    bool      gotPauseAckFromServFlag;
    bool      gotRestartAckFromServFlag;
    bool      gotQuitAckFromServFlag;
    bool      gotJsonAckFromServFlag;
    bool      gotDelAckFromServFlag;
    char      jsonFileListBuf[DWF_JSON_BUFFSIZE];
    uint32_t  breakPoint;
    int       recvdLen;
    int       filesize;
    int       totalTimeout;
    CPacket   sndPacket;
    CPacket   rcvPacket;

private:
    socklen_t      peeraddrLen;
    sockaddr_in    peeraddr;
    sockaddr_in    servaddr;
    sockaddr_in    tcp_servaddr;
#ifdef UDP
    list<CPacket>  pkgDataList;
    list<CPacket>  pkgCtrlList;
#endif
    bool           asyncPauseEventAction;
    bool           asyncRestartEventAction;
    bool           asyncStopEventAction;
    bool           syncDownloadExitFlag;
    int            pauseClockTick;
    int            restartClockTick;

    // packet related
private:
    uint32_t  offset;
    uint32_t  seqNo;
    uint32_t  seqNoLastRecv;
    int 	  softwareVerConfig;
    bool      userDefConfig;
    int       userDefPacksize;
    int       userDefBlocks;
    int       userCurBlockIdx;
    char      userDefLocation[DWF_MAX_FILEPATH];

private:
    CDownLoad(const CDownLoad &);
    CDownLoad &operator=(const CDownLoad &);
};
}


#endif
