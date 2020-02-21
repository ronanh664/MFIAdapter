#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <iostream>
#include <dirent.h>
#include <errno.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>

#include "dwf_log.h"
#include "dwf_client_api.h"

namespace yuneec
{

ERROR_MSG_PRINT_t debug_error[] =
{
    { DWF_ERR_NONE, "success!"},
    { DWF_ERR_CRC,  "packet data checksum error!"},
    { DWF_ERR_TOTAL_CRC, "whole file crc error!"},
    { DWF_ERR_FILE_NOT_EXIST, "request file not exist in server!"},
    { DWF_ERR_FILE_TOO_BIG, "download file too big"},
    { DWF_ERR_APP_CREATE_FILE, "app create file failed"},
    { DWF_ERR_CAM_OPEN_FILE, "camera open file failed"},
    { DWF_ERR_PAUSE, "pause download file failed"},
    { DWF_ERR_RESTART, "restart download file failed"},
    { DWF_ERR_RESPONSE_FILELIST, "not receive filelist from server"},
    { DWF_ERR_QUIT, "cancel download file failed"},
    { DWF_ERR_BAD_PARAMETER, "invalid input parameter"},
    { DWF_ERR_TIMEOUT, "packet send timeout"},
    { DWF_ERR_WRONG_SOCKFD, "wrong sockfd"},
    { DWF_ERR_CONFIG, "configure error"},
    { DWF_ERR_DELETE_FILE, "delete file error"},
    { DWF_ERR_STOP_DOWNLOAD_FILE, "stop download file success"}
};

CDownLoad::CDownLoad(
    const char *id,
    int  version,
    bool setbit,
    int  packsize,
    const char *pservaddr,
    int serport):
    errnum(DWF_ERR_NONE),
    downProgress(0),
    running(0),
    sockfd(-1),
    servport(serport),
    fp(nullptr),
    readfds(),
    gotCfgAckFromServFlag(false),
    gotPauseAckFromServFlag(false),
    gotRestartAckFromServFlag(false),
    gotQuitAckFromServFlag(false),
    gotJsonAckFromServFlag(false),
    gotDelAckFromServFlag(false),
    breakPoint(0),
    filesize(0),
    totalTimeout(0),
    peeraddrLen(sizeof(sockaddr_in)),
#ifdef UDP
    pkgDataList(),
    pkgCtrlList(),
#endif
    asyncPauseEventAction(false),
    asyncRestartEventAction(false),
    asyncStopEventAction(false),
    syncDownloadExitFlag(false),
    pauseClockTick(0),
    restartClockTick(0),
    offset(0),
    seqNo(0),
    seqNoLastRecv(0),
    softwareVerConfig(version),
    userDefConfig(setbit),
    userDefPacksize(packsize), //userDefPacksize<=65535 userDefPacksize(2bytes)
    userDefBlocks(DWF_DEF_BLOCKS),
    userCurBlockIdx(0)
{
    DWF_MEMSET(filename,    DWF_MAX_FILENAME);
    DWF_MEMSET(absFileName, DWF_MAX_FILENAME);
    DWF_MEMSET(storagePath, DWF_MAX_FILEPATH);
    DWF_MEMSET(&peeraddr,   sizeof(peeraddr));
    DWF_MEMSET(&servaddr,   sizeof(servaddr));
    DWF_MEMSET(jsonFileListBuf,    DWF_JSON_BUFFSIZE);
    DWF_MEMSET(userDefLocation, DWF_MAX_FILEPATH);
    servaddr.sin_family = AF_INET;
    servaddr.sin_port   = htons(servport);
    servaddr.sin_addr.s_addr = inet_addr(pservaddr);
    if(userDefConfig && id)
    {
        strncpy(userDefLocation, id, DWF_MAX_FILEPATH - 1);
    }
}

CDownLoad::~CDownLoad()
{
    if(fp)
    {
        fclose(fp);
        fp = nullptr;
    }
#ifdef UDP
    while(!pkgDataList.empty())
    {
        pkgDataList.pop_front();
    }
    while(!pkgCtrlList.empty())
    {
        pkgCtrlList.pop_front();
    }
#endif
    event_socket_release();
}

int
CDownLoad::send_msg_data_to_camera(
    uint8_t  marker,
    uint8_t  msgtype,
    const char *payload,
    uint32_t payloadLen)
{
    int sendLen = -1;
    sndPacket.packData(marker, msgtype, ++seqNo, offset, payload, payloadLen);
    sendLen = sndPacket.pktSendto(sockfd,
                                  pktHeadSize + ntohl(sndPacket.getPayloadLen()) + 4/*crcsum*/,
                                  (sockaddr *)&servaddr, sizeof(servaddr));
#ifdef UDP
    pkgDataList.push_back(sndPacket);
#endif
    sndPacket.unpackData();
    return sendLen;
}

int
CDownLoad::send_msg_ack_to_camera(
    uint8_t  marker,
    uint8_t  msgtype,
    uint8_t  ackflg,
    uint16_t ack,
    uint16_t extype)
{
    int sendLen = -1;
    sndPacket.packCtrl(marker, msgtype, ++seqNo, offset, ackflg, ack, extype);
    sendLen = sndPacket.pktSendto(sockfd,
                                  pktHeadSize + ntohl(sndPacket.getPayloadLen()) + 4/*crcsum*/,
                                  (sockaddr *)&servaddr, sizeof(servaddr));
#ifdef UDP
    pkgCtrlList.push_back(sndPacket);
#endif
    sndPacket.unpackData();
    return sendLen;
}

int
CDownLoad::double_dup_check(void)
{
    int  num = 0;
    char left[32]  = {'\0'};
    char right[32] = {'\0'};
    char newfile[DWF_MAX_FILENAME] = {'\0'};
    int  ret = 0;

    if(access(absFileName, F_OK) == 0)
    {
        sscanf(filename, "%[^.].%s", left, right);
        do
        {
            snprintf(newfile, DWF_MAX_FILENAME, "%s%s(%d).%s", storagePath, left, ++num, right);
            if((ret = access(newfile, F_OK)) != 0)
            {
                break;
            }
        }
        while(ret == 0);
        snprintf(absFileName, DWF_MAX_FILENAME, "%s", newfile);
    }
    return 0;
}

void
CDownLoad::event_set_file_storage_path(
    const char *path)
{
     size_t pathLen = strlen(path);
    memset(storagePath, '\0', DWF_MAX_FILEPATH);
    strcpy(storagePath, path);

     if(storagePath[pathLen - 1] != '/')
     {
         storagePath[pathLen] = '/';
     }
}

int
CDownLoad::event_data_recvfrom(
    int        sockfd,
    sockaddr  *peeraddr,
    socklen_t *peeraddrLen)
{
    return rcvPacket.pktRecvfrom(sockfd, peeraddr, peeraddrLen);
}
int
CDownLoad::event_data_read(int sockfd, int count,int timeout) //us
{
    return rcvPacket.pktRead(sockfd, count,timeout);
}

void
CDownLoad::event_remove_file(void)
{
    if(access(absFileName, F_OK) == 0)
    {
        remove(absFileName);
    }
}

int
CDownLoad::event_send_name_to_server(
    const char *downFileName)
{
    memset(filename,    '\0', DWF_MAX_FILENAME);
    memset(absFileName, '\0', DWF_MAX_FILENAME);
    snprintf(filename, DWF_MAX_FILENAME, "%s", downFileName);
    snprintf(absFileName, DWF_MAX_FILENAME, "%s%s", storagePath, filename);

    return send_msg_data_to_camera(1, 0x02/*DWF_FILE_SIZE_GET*/, (char *)downFileName, (uint32_t)strlen(downFileName));
    
}

int
CDownLoad::event_crcsum_check(
    CPacket &packet)
{
    int result = 0;
    uint32_t crcsum = 0;
    int  packetlen = 0;
    packetlen = (int)packet.getRawDataCRCLen();
    if(packetlen > userDefPacksize + pktHeadSize+4 || packetlen < pktHeadSize+4)
    {
        perror("packet getRawDataCRCLen error");
        return -1;
    }
    generate_buff_crc32(0, (uint8_t *)packet.getRawData(), packet.getRawDataCRCLen(), crcsum);
    PRINTF("checksum: %u, getCrcData: %u\n", crcsum, packet.getCrcData());
    if(!crc32_equal(crcsum, packet.getCrcData()))
    {
        printf("crc error\n");
        result = -1;
        errnum = DWF_ERR_CRC;
        if(send_msg_ack_to_camera(packet.getMsgMark(), packet.getMsgType(), true, DWF_ACK_CRC_ERR) < 0)
        {
            perror("send_msg_ack_to_camera error");
        }
    }
    return result;
}

int
CDownLoad::event_ack_from_camera_check(
    CPacket &packet)
{
    uint16_t acktype = packet.getAckType();
//    printf("[%s:%d] MsgType = %02x, acktype = %04x\n", __func__, __LINE__, packet.getMsgType(),acktype);
    if(packet.getAckFlag())
    {
        if(acktype == DWF_ACK_CRC_OK)
        {
            return 1;
        }
        if(packet.getMsgType() == DWF_FILE_SIZE_GET)
        {
            if(acktype == DWF_ACK_CRC_ERR)
            {
                errnum = DWF_ERR_CRC;
            }
            else if(acktype == DWF_ACK_FILE_NOT_EXIST)
            {
                errnum = DWF_ERR_FILE_NOT_EXIST;
            }
            else if(acktype == DWF_ACK_OTH_ERR)
            {
                errnum = DWF_ERR_CAM_OPEN_FILE;
            }
            if(errnum != DWF_ERR_NONE)
            {
                WARN("an ack error happened\n");
                return -1;
            }
        }
        else if(packet.getMsgType() == DWF_FILE_QUIT)
        {
            if(fp)
            {
                fclose(fp);
                fp = nullptr;
            }
            gotQuitAckFromServFlag = true;
            running = 1;
        }
        else if(packet.getMsgType() == DWF_FILE_CONFIG)
        {
            gotCfgAckFromServFlag = true;
        }
        else if(packet.getMsgType() == DWF_FILE_LIST_DEL)
        {
            gotDelAckFromServFlag = true;
        }
        return 1;
    }
    return 0;
}

#ifdef UDP
void
CDownLoad::event_timer_check()
{
    if(!pkgDataList.empty())
    {
        pkgDataList.front().pktSendto(sockfd, pktHeadSize +
                                      ntohl(pkgDataList.front().getPayloadLen()) + 4/*crcsum*/,
                                      (sockaddr *)&servaddr, sizeof(servaddr));
    }
    else if(!pkgCtrlList.empty())
    {
        pkgCtrlList.front().pktSendto(sockfd, pktHeadSize +
                                      ntohl(pkgCtrlList.front().getPayloadLen()) + 4/*crcsum*/,
                                      (sockaddr *)&servaddr, sizeof(servaddr));
    }
}

int
CDownLoad::event_packet_seqnum_check()
{
    if(rcvPacket.getSeqNo() < seqNoLastRecv)
    {
        return -1;
    }
    seqNoLastRecv = rcvPacket.getSeqNo();

    bool endLoop = false;
    while(!pkgDataList.empty() && !endLoop)
    {
        if(pkgDataList.front().getSeqNo(pkgDataList.front()) <= seqNoLastRecv)
        {
            pkgDataList.pop_front();
        }
        else
        {
            endLoop = true;
        }
    }
    endLoop = false;
    while(!pkgCtrlList.empty() && !endLoop)
    {
        if(pkgCtrlList.front().getSeqNo(pkgCtrlList.front()) <= seqNoLastRecv)
        {
            pkgCtrlList.pop_front();
        }
        else
        {
            endLoop = true;
        }
    }
    return 0;
}
#endif

void
CDownLoad::process_data_appfile_list_get(
    CPacket &packet)
{
    if((packet.getMsgMark() == 0) || (packet.getMsgMark() == 2))
    {
        /*more fragment, we request next fragment*/
        if(offset != packet.getOffset())
        {
            return;
        }
        memcpy(jsonFileListBuf + offset, packet.getPayload(), packet.getPayloadLen());
        offset += packet.getPayloadLen();
        if (++userCurBlockIdx < userDefBlocks) {
            return;
        }
        userCurBlockIdx = 0;
        send_msg_ack_to_camera(packet.getMsgMark(), 0x00/*DWF_FILE_LIST_GET*/);
    }
    else if((packet.getMsgMark() == 1) || (packet.getMsgMark() == 3))
    {
        /*last or whole fragment*/
        gotJsonAckFromServFlag = true;
        memcpy(jsonFileListBuf + offset, packet.getPayload(), packet.getPayloadLen());
        offset = 0;
    }
}

int
CDownLoad::process_data_appfile_size_get(
    CPacket &packet)
{
    if(fp)
    {
        return 0;  /*ignore double msg*/
    }
    // Don't save to a new file if a same file has existed, but remove the same one directly.
    //double_dup_check();
    event_remove_file();
    fp = fopen(absFileName, "w+");

    if(nullptr == fp)
    {
        perror("open file error");
        send_msg_ack_to_camera(1, 0x02/*DWF_FILE_SIZE_GET*/, true, DWF_ACK_OTH_ERR);
        return -1;
    }
    memcpy(&filesize, packet.getPayload(), sizeof(filesize));
    return send_msg_ack_to_camera(1, 0x03/*DWF_FILE_START*/);
}

int
CDownLoad::process_data_appfile_start(
    CPacket &packet)
{
#if 0
    if(!fp || asyncPauseEventAction
           || gotPauseAckFromServFlag
           || gotQuitAckFromServFlag
           || (offset != packet.getOffset()))
    {
        return 0;
    }
#endif
#if 0
    struct timeval start, end;
    memset(&start, 0, sizeof(start));
    memset(&end, 0, sizeof(end));
    int timestamp = 0;
    gettimeofday(&start, NULL);
#endif

//    if (fp) {
//        fseek(fp, SEEK_SET, offset);
//    }
    if(((packet.getMsgMark() == 1) || (packet.getMsgMark() == 3)) && fp)      /*last or only one*/
    {
        downProgress = 100;
        fwrite(packet.getPayload(), packet.getPayloadLen(), 1, fp);
        fflush(fp);
        fclose(fp);
        fp = nullptr;
//        printf("[%s:%d]download file complete\n", __func__, __LINE__);
        return send_msg_ack_to_camera(1, 0x07/*DWF_FILE_QUIT*/);
    }

    if (fp) {
        downProgress = (int) (100 * ((1.0 * offset) / filesize));
        fwrite(packet.getPayload(), packet.getPayloadLen(), 1, fp);
        offset += packet.getPayloadLen();
    }
    #if 0
    gettimeofday(&end, NULL);
    timestamp = (end.tv_sec - start.tv_sec) * 1000000 + (end.tv_usec - start.tv_usec);
    printf("timestamp = %d\n",timestamp);
    #endif
    if (++userCurBlockIdx < userDefBlocks) {
        return 0;
    }
    userCurBlockIdx = 0;
    return send_msg_ack_to_camera(1, 0x03/*DWF_FILE_START*/);
}

void
CDownLoad::process_data_appfile_pause(
    CPacket &packet)
{
    uint32_t bkpoint = 0;
    memcpy(&bkpoint, packet.getPayload(), packet.getPayloadLen());
    breakPoint = ntohl(bkpoint);
    gotPauseAckFromServFlag = true;
    asyncPauseEventAction = false;
    offset = breakPoint;
}

int
CDownLoad::process_data_appfile_resume(
    CPacket &packet)
{
    gotRestartAckFromServFlag = true;
    asyncRestartEventAction = false;

    if(!fp || asyncPauseEventAction
           || gotPauseAckFromServFlag
           || gotQuitAckFromServFlag
           || (offset != packet.getOffset()))
    {
        return 0;
    }
    //fseek(fp, SEEK_SET, offset);

    if(((packet.getMsgMark() == 1) || (packet.getMsgMark() == 3)) && fp)      /*last or only one*/
    {
        downProgress = 100;
        fwrite(packet.getPayload(), packet.getPayloadLen(), 1, fp);
        fflush(fp);
        fclose(fp);
        fp = nullptr;
        return send_msg_ack_to_camera(1, 0x07/*DWF_FILE_QUIT*/);
    }

    downProgress = (int)(100 * ((1.0 * offset) / filesize));
    fwrite(packet.getPayload(), packet.getPayloadLen(), 1, fp);
    offset += packet.getPayloadLen();
    if (++userCurBlockIdx < userDefBlocks) {
        return 0;
    }
    userCurBlockIdx = 0;
    return send_msg_ack_to_camera(1, 0x06);
}

int
CDownLoad::event_base_process_data()
{
    //printf("[%s:%d] MsgType = %02x\n", __func__, __LINE__,rcvPacket.getMsgType());
    if(event_crcsum_check(rcvPacket) < 0)
    {
        WARN("data crcsum error!\n");
        return -1;
    }

    switch(rcvPacket.getMsgType())
    {
        case DWF_FILE_CONFIG:
            break;
        case DWF_FILE_LIST_GET:
            process_data_appfile_list_get(rcvPacket);
            break;
        case DWF_FILE_LIST_DEL:
            break;
        case DWF_FILE_SIZE_GET:
            process_data_appfile_size_get(rcvPacket);
            break;
        case DWF_FILE_START:
            process_data_appfile_start(rcvPacket);
            break;
        case DWF_FILE_CRC:
            break;
        case DWF_FILE_PAUSE:
            process_data_appfile_pause(rcvPacket);
            break;
        case DWF_FILE_RESTART:
            process_data_appfile_resume(rcvPacket);
            break;
        case DWF_FILE_QUIT:
            break;
        default:
        {
            WARN("unknown message type\n");
            break;
        }
    }
    return 0;
}

int
CDownLoad::event_base_process_ctrl()
{
//    printf("[%s:%d] MsgType = %02x\n", __func__, __LINE__,rcvPacket.getMsgType());
    if(event_crcsum_check(rcvPacket) < 0)
    {
        WARN("data crcsum error!\n");
        return -1;
    }
    if(event_ack_from_camera_check(rcvPacket) != 0)
    {
        //INFO("ack mesage!\n");
        return 0;
    }

    switch(rcvPacket.getMsgType())
    {
        case DWF_FILE_LIST_GET:         // 0x00
        case DWF_FILE_LIST_DEL:         // 0x01
        case DWF_FILE_SIZE_GET:         // 0x02
        case DWF_FILE_START:            // 0x03
        case DWF_FILE_CRC:              // 0x04
        case DWF_FILE_PAUSE:            // 0x05
        case DWF_FILE_RESTART:          // 0x06
        case DWF_FILE_QUIT:             // 0x07
        case DWF_FILE_CONFIG:           // 0x11
            break;
        default:
        {
            WARN("unknown message type\n");
            break;
        }
    }
    return 0;
}

#ifdef UDP
void
CDownLoad::event_download_loop(void)
{
    int  result   = -1;
    int  recvLen  =  0;
    int  maxfd    =  0;
    int  count    =  0;
    //int  timemsec = 100;
    //int  headSize = pktHeadSize + 4;
    struct timeval downTimeout;

#if debug
    struct timeval start, end;
    int timestamp = 0;
#endif
    maxfd = (maxfd > sockfd) ? maxfd : sockfd;

    do
    {
        yuneec_async_event_status_check();
        downTimeout.tv_sec = 1;
        downTimeout.tv_usec = 0;

        FD_ZERO(&readfds);
        FD_SET(sockfd, &readfds);
#if debug
        gettimeofday(&start, NULL);
#endif
        result = select(maxfd + 1, &readfds, NULL, NULL, &downTimeout);
        //printf("[%s:%d]==>result = %d\n",__func__,__LINE__,result);
        if(DWF_UNLIKELY(result < 0))
        {
            ERROR("select error!\n");
        }
        else if(result == 0)
        {
            if(!gotPauseAckFromServFlag)
            {
                count++;
            }
            //event_timer_check();
            continue; /*timeout*/
        }
        else
        {
            if(!FD_ISSET(sockfd, &readfds))
            {
                continue;
            }

            count = 0;  /*reset count to zero*/
            recvLen = event_data_recvfrom(sockfd, (sockaddr *)&peeraddr, &peeraddrLen);
            //printf("[%s:%d] recvLen = %d\n", __func__, __LINE__, recvLen);
#if debug
            gettimeofday(&end, NULL);
            timestamp = (end.tv_sec - start.tv_sec) * 1000000 + (end.tv_usec - start.tv_usec);
            printf("[%s:%d] times:%d.%dms\n", __func__, __LINE__, (timestamp / 1000), (timestamp % 1000));
#endif
            if(DWF_UNLIKELY(recvLen < 0))
            {
                if((errno != EAGAIN) || (errno != EINTR))
                {
                    ERROR("receive data from server error!\n");
                }
                continue;
            }
            else if(recvLen == 0)
            {
                /*ignored, peer close socket*/
            }
            else
            {
#if 0
                if((recvLen != ((int)rcvPacket.getPayloadLen() + headSize))
                        || (event_packet_seqnum_check() < 0))
                {
                    //INFO("old message,ignored!\n");
                    continue;
                }
#endif
                //printf("[%s:%d]receive data from app:seqNO = %d,reqType = %02x, msgType = %02x,MsgMark = %02x\n",
                //       __func__, __LINE__, rcvPacket.getSeqNo(), rcvPacket.getReqType(), rcvPacket.getMsgType(), rcvPacket.getMsgMark());
                switch(rcvPacket.getReqType())
                {
                    case DWF_DATA:
                        event_base_process_data();
                        break;
                    case DWF_CTRL:
                        event_base_process_ctrl();
                        break;
                    default:
                        WARN("unknown message request type!\n");
                        continue;
                }
            }
        }
    }
    //while((result == 0) && (count * timemsec < totalTimeout));
    while((result == 0) && (count < 5));
    if(count  >= 5)
    {
        errnum = DWF_ERR_TIMEOUT;
    }
}
#else
void
CDownLoad::event_download_loop(void)
{
    int  recvLen  =  0;
    int times = 0;
    do
    {
        yuneec_async_event_status_check();
        recvLen = event_data_recvfrom(sockfd,(sockaddr *)&peeraddr, &peeraddrLen);
        //printf("[%s:%d] recvLen = %d\n",__func__,__LINE__,recvLen);
        if(recvLen < 0)
        {
            if((errno != EINTR)||(errno != EAGAIN))
            {
                printf("receive data from server error!\n");
            }
            times++;
            continue;
        }
        else if(recvLen == 0)
        {
            //continue;
            //printf("socket closed\n");
            break;
        }
        else
        {
            PRINTF("receive data from app:seqNO = %d,reqType = %02x, msgType = %02x,MsgMark = %02x\n",
                   rcvPacket.getSeqNo(), rcvPacket.getReqType(), rcvPacket.getMsgType(), rcvPacket.getMsgMark());
            switch(rcvPacket.getReqType())
            {
                case DWF_DATA:
                    event_base_process_data();
                    break;
                case DWF_CTRL:
                    event_base_process_ctrl();
                    break;
                default:
                    WARN("unknown message request type!\n");
                    continue;
            }
        }
        // If errno != EINTR (recvLen < 0), it will loop endlessly here
        // because there's also a while loop at the place of it being called.
    }while(/*errno==EINTR && */recvLen < 0 && (times < 5));
    if(recvLen == 0)
    {
        errnum = DWF_ERR_SOCK_CLOSE;
    }
    if(times >= 5)
    {
        printf("timeout.\n");
        errnum = DWF_ERR_TIMEOUT;
    }

}
#endif

int
CDownLoad::event_request_list(
    int   extMsgType,
    char *outBuf,
    int   outBufsize)
{
    if((!outBuf) || (outBufsize <= 0))
    {
        WARN("bad input parameter!\n");
        errnum = DWF_ERR_BAD_PARAMETER;
        return -1;
    }
    gotJsonAckFromServFlag = false;
    userCurBlockIdx = 0;
    memset(jsonFileListBuf, 0, DWF_JSON_BUFFSIZE);
    send_msg_ack_to_camera(1, 0x00/*DWF_FILE_LIST_GET*/, false, DWF_ACK_NONE, extMsgType);

    while((errnum == DWF_ERR_NONE) && !gotJsonAckFromServFlag)
    {
        event_download_loop();
        if(DWF_ERR_SOCK_CLOSE == errnum)
        {
            printf("[%s:%d] socket closed\n",__func__,__LINE__);
            return -1;
        }
    }

    if(!gotJsonAckFromServFlag)
    {
        errnum = DWF_ERR_RESPONSE_FILELIST;
        return -1;
    }
    int josn_size = (int)strlen(jsonFileListBuf);
    memcpy(outBuf, jsonFileListBuf, (josn_size <= outBufsize) ? josn_size : outBufsize);
    // The msg will ask to release the resource on server side.
    send_msg_ack_to_camera(1, 0x00/*DWF_FILE_LIST_GET*/, true, DWF_ACK_CRC_OK, extMsgType);
    return 0;
}

void
CDownLoad::event_delete_list(void)
{
    send_msg_ack_to_camera(1, 0x01/*DWF_FILE_LIST_DEL*/);
    event_download_loop();
}

int
CDownLoad::make_socket_nonblocking(
    int sockFd)
{
    int oflags = fcntl(sockFd, F_GETFL, 0);
    if(oflags < 0)
    {
        WARN("get socket flags error!\n");
        return -1;
    }
    oflags |= O_NONBLOCK;

    int ret = fcntl(sockFd, F_SETFL, oflags);
    if(ret < 0)
    {
        WARN("set socket nonblock error!\n");
        return -1;
    }
    return 0;
}

const char *
CDownLoad::yuneec_error_msg_print(void)
{
    if((errnum < DWF_ERR_NONE) || (errnum > DWF_ERR_NUM_MAX))
    {
        return "unknown error!";
    }

    return debug_error[errnum].err_msg;
}

int
CDownLoad::event_socket_init(void)
{
    if (sockfd >= 0) {
        return sockfd;
    }
#ifdef UDP
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
#else
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    struct timeval tv;
    tv.tv_sec = 3;
    tv.tv_usec = 0;
    setsockopt(sockfd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
    setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
#endif

    if(DWF_UNLIKELY(sockfd < 0))
    {
        WARN("socket error!\n");
        return -1;
    }
#if 1
    //add by litao
#if 0
    int on = 1;
    if(setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, (char *)&on, sizeof(on)) != 0)
    {
        ERROR("setsockopt nodely error");
    }
#endif
#if 1
//    int nZero = 0;
//    if(setsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, (char *)&nZero, sizeof(int)) != 0)
//    {
//        ERROR("setsockopt error");
//    }
//    if(setsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, (char *)&nZero, sizeof(int)) != 0)
//    {
//        ERROR("setsockopt error");
//    }
    int nRecvBuf = 1 * 1024 * 1024; // default 8688
    if(setsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, (const char *)&nRecvBuf, sizeof(nRecvBuf)) != 0)
    {
        ERROR("setsockopt error");
    }
    int nSendBuf = 64 * 1024; //default 8688
    if(setsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, (const char *)&nSendBuf, sizeof(nSendBuf)) != 0)
    {
        ERROR("setsockopt error");
    }
#endif

    if(connect(sockfd, (struct sockaddr *)&servaddr, sizeof(struct sockaddr)) < 0)
    {
        WARN("Connect error");
        close(sockfd);
        sockfd = -1;
        return -1;
    }
#endif

#ifdef OSX
    int set = 1;
    if(DWF_UNLIKELY(setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE,
                               (char *)&set, sizeof(int))) != 0)
    {
        WARN("setopt error\n");
        close(sockfd);
        sockfd = -1;
        return -1;
    }
#endif

    //return (make_socket_nonblocking(sockfd) < 0) ? -1 : 0;
    return sockfd;
}

void
CDownLoad::event_socket_release(void)
{
    syncDownloadExitFlag = true;
    if(sockfd >= 0)
    {
        close(sockfd);
        sockfd = -1;
    }
}

int
CDownLoad::event_pause_flag_check(int eventFlag, int pes, int timeout)
{
    if(!eventFlag && ((pes * pauseClockTick++) > timeout))
    {
        pauseClockTick = 0;
        return -1;
    }
    return 0;
}

int
CDownLoad::event_restart_flag_check(int eventFlag, int pes, int timeout)
{
    if(!eventFlag && ((pes * restartClockTick++) > timeout))
    {
        restartClockTick = 0;
        return -1;
    }
    return 0;
}

void
CDownLoad::yuneec_async_event_status_check()
{
    if(asyncPauseEventAction && (event_pause_flag_check(gotPauseAckFromServFlag,
                                                        100/*ms*/, 5000) < 0))
    {
        errnum = DWF_ERR_PAUSE;
        asyncPauseEventAction = false;
    }
    else if(asyncRestartEventAction && (event_restart_flag_check(gotRestartAckFromServFlag,
                                                                 100/*ms*/, 5000) < 0))
    {
        errnum = DWF_ERR_RESTART;
        asyncRestartEventAction = false;
    }
}

int
CDownLoad::yuneec_download_progress_get() const
{
    if(asyncStopEventAction)
    {
        return -1;
    }
    return (downProgress == 0) ? 1 : downProgress;
}

int
CDownLoad::yuneec_download_config(
    int   timeoutMsec)
{
    char packet_buff[DWF_MAX_FILEPATH + 8] = { 0 };
    if(userDefConfig)
    {
        memcpy(packet_buff, userDefLocation, strlen(userDefLocation) + 1);
    }
    uint32_t *pPayload = (uint32_t *)&packet_buff[DWF_MAX_FILEPATH];
    *pPayload  = (userDefConfig & 0x1) << 31;
    *pPayload |= (softwareVerConfig & 0x7fff) << 16;
    *pPayload |= userDefPacksize & 0xffff;
    *pPayload  = htonl(*pPayload);
    pPayload++;
    *pPayload  = userDefBlocks & 0xffff;
    *pPayload  = htonl(*pPayload);

    if(send_msg_data_to_camera(1, 0x11/*DWF_FILE_CONFIG*/, packet_buff, sizeof(packet_buff)) < 0)
    {
        perror("send_msg_data_to_camera error");
    }
    totalTimeout = timeoutMsec;
    event_download_loop();
    return 0;
}

int
CDownLoad::yuneec_download_request(
    int   extMsgType,
    char *jsonBuf,
    int   jsonBufsize,
    int   timeoutMsec)
{
    int result = 0;
    errnum = DWF_ERR_NONE;
    if(event_socket_init() < 0)
    {
        WARN("invalid socket fd!\n");
        errnum = DWF_ERR_WRONG_SOCKFD;
        return -errnum;
    }

    offset = 0;
    yuneec_download_config(timeoutMsec);
    if((errnum != DWF_ERR_NONE) || !gotCfgAckFromServFlag)
    {
        WARN("config error (%d, %d)!\n",errnum,gotCfgAckFromServFlag);
        errnum = DWF_ERR_CONFIG;
        event_socket_release();
        return -errnum;
    }

    if(event_request_list(extMsgType, jsonBuf, jsonBufsize) < 0)
    {
        WARN("bad response list!\n");
        result = -errnum;
    }
    event_socket_release();
    return result;
}

int
CDownLoad::yuneec_download_pause(void)
{
    if(sockfd < 0)
    {
        WARN("wrong sockfd!\n");
        errnum = DWF_ERR_WRONG_SOCKFD;
        return -errnum;
    }
    send_msg_ack_to_camera(1, 0x05/*DWF_FILE_PAUSE*/);
    asyncPauseEventAction = true;
    return 0;
}

int
CDownLoad::yuneec_download_resume(void)
{
    if(sockfd < 0)
    {
        WARN("wrong sockfd!\n");
        errnum = DWF_ERR_WRONG_SOCKFD;
        return -errnum;
    }
    offset = breakPoint;
    userCurBlockIdx = 0;
    send_msg_ack_to_camera(1, 0x06/*DWF_FILE_RESTART*/);
    asyncRestartEventAction = true;
    gotPauseAckFromServFlag = false;
    return 0;
}

int
CDownLoad::yuneec_download_delete(
    const char *jsonBuf,
    int   jsonBufsize,
    int   timeoutMsec)
{
    errnum = DWF_ERR_NONE;
    if(event_socket_init() < 0)
    {
        WARN("invalid socket fd!\n");
        errnum = DWF_ERR_WRONG_SOCKFD;
        return -errnum;
    }

    yuneec_download_config(timeoutMsec);
    if((errnum != DWF_ERR_NONE) || !gotCfgAckFromServFlag)
    {
        WARN("config error (%d, %d)!\n",errnum,gotCfgAckFromServFlag);
        errnum = DWF_ERR_CONFIG;
        event_socket_release();
        return -errnum;
    }
    gotDelAckFromServFlag = false;
    send_msg_data_to_camera(1, 0x01, jsonBuf, jsonBufsize);
    event_download_loop();

    if((errnum != DWF_ERR_NONE) || !gotDelAckFromServFlag)
    {
        WARN("delete error (%d, %d)!\n",errnum,gotDelAckFromServFlag);
        errnum = DWF_ERR_DELETE_FILE;
        return -errnum;
    }
    event_socket_release();
    return 0;
}

int
CDownLoad::yuneec_download_quit(void)
{
    if(sockfd < 0)
    {
        WARN("wrong sockfd!\n");
        errnum = DWF_ERR_WRONG_SOCKFD;
        return -errnum;
    }
    asyncStopEventAction = true;
    send_msg_ack_to_camera(1, 0x07/*DWF_FILE_QUIT*/);
    //errnum = DWF_ERR_STOP_DOWNLOAD_FILE;

    while(!syncDownloadExitFlag)
    {
        usleep(50000);
    }
    event_socket_release();
    return 0;
}

int
CDownLoad::yuneec_download_file(
    const char *downFileName,
    const char *location,
    int         timeoutMsec)
{
    errnum = DWF_ERR_NONE;
    if(!downFileName || !location)
    {
        WARN("invalid input parameter!\n");
        errnum = DWF_ERR_BAD_PARAMETER;
        return -errnum;
    }
    if(event_socket_init() < 0)
    {
        WARN("invalid socket fd!\n");
        errnum = DWF_ERR_WRONG_SOCKFD;
        return -errnum;
    }

    offset = 0;
    event_set_file_storage_path(location);
    yuneec_download_config(timeoutMsec);
    if((errnum != DWF_ERR_NONE) || !gotCfgAckFromServFlag)
    {
        WARN("config error (%d, %d)!\n",errnum,gotCfgAckFromServFlag);
        errnum = DWF_ERR_CONFIG;
        event_socket_release();
        return -errnum;
    }

    gotQuitAckFromServFlag = false;
    asyncStopEventAction = false;
    syncDownloadExitFlag = false;
    downProgress = 0;
    userCurBlockIdx = 0;
    event_send_name_to_server(downFileName);
    while((errnum == DWF_ERR_NONE) && !gotQuitAckFromServFlag)
    {
        event_download_loop();
        if(DWF_ERR_SOCK_CLOSE == errnum)
        {
            printf("[%s:%d] socket closed\n",__func__,__LINE__);
            event_socket_release();
            break;
        }
    }
    if(errnum != DWF_ERR_NONE || asyncStopEventAction)
    {
        if(fp)
        {
            INFO("local file has not been closed yet, close it firstly.");
            fclose(fp);
            fp = nullptr;
        }
        event_remove_file();
    }
    else
    {
        struct stat statbuf;
        memset(&statbuf, 0, sizeof(statbuf));
        stat(absFileName, &statbuf);
        if (statbuf.st_size == 0)
        {
            event_remove_file();
            errnum = DWF_ERR_FILE_NOT_EXIST;
        }
    }

    syncDownloadExitFlag = true;
    if (asyncStopEventAction) {
        errnum = DWF_ERR_STOP_DOWNLOAD_FILE;
    }
    return -errnum;
}

}
