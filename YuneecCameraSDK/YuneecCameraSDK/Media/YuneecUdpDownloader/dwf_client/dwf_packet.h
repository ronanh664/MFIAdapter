#ifndef __DWF_PACKAGE_H__
#define __DWF_PACKAGE_H__

#include <stdint.h>
#include <stdio.h>
#include <netinet/in.h>
#include <sys/uio.h>

const int pktHeadSize = 20;    // packet header size
const int pktDataSize = 16390; // packet data size(include head size) (64*1024+20+4)/4=16390

typedef union {
    uint32_t udata[pktDataSize]; // data info
    char data[pktDataSize * 4];
} unRaw_t;

namespace yuneec
{
class CPacket
{
public:
    CPacket();
    ~CPacket();
    // data/ctrl related
    uint8_t  getReqType();
    uint8_t  getMsgMark();
    uint8_t  getMsgType();
    uint32_t getSeqNo();
    uint32_t getSeqNo(CPacket &packet);
    uint32_t getUserId();
    uint32_t getOffset();
    uint32_t getPayloadLen();
    uint32_t getTimeStamp();
    uint32_t getCrcData();
    uint32_t getTime();
    char    *getPayload();
    char    *getRawData();
    uint32_t getRawDataCRCLen();
    void     packData(uint8_t marker, uint8_t msgtype, uint32_t seqno,
                      uint32_t offset, const char *payload, uint32_t payloadLen);
    void     packCtrl(uint8_t marker, uint8_t msgtype, uint32_t ackno,
                      uint32_t offset, uint8_t ackflg, uint16_t ack, uint16_t extype);
    void     unpackData();
    int      pktSendto(int sockfd, int sendLen, sockaddr *peeraddr, socklen_t peeraddrLen);
    int 	 pktRecvfrom(int sockfd, sockaddr *peeraddr, socklen_t *peeraddrLen);
    int      pktRead(int sockfd, int count, int timeout);
    int      recv_peek(int fd, const void *buf, int count);
    int      readn(int fd, void *buf, int count, int timeout);
    int      writen(int fd, void *buf, int count);
    // ctrl related
    uint8_t  getAckFlag();
    uint16_t getExternMsgType();
    uint16_t getAckType();
    uint32_t getAckSeqNo();

private:
    unRaw_t  rawData;
    uint64_t startTime;
    uint32_t userID;
private:
    CPacket &operator=(const CPacket &);
};

int  crc32_equal(const uint32_t &param1, const uint32_t &param2);
void generate_buff_crc32(uint32_t starter, const uint8_t *inbuf,
                         uint32_t bufsize, uint32_t &result);
void generate_file_crc32(FILE *fp, uint32_t &result);
}

#endif