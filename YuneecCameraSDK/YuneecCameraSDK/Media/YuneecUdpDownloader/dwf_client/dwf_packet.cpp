#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <errno.h>
#include "dwf_packet.h"
#include "dwf_log.h"

namespace yuneec
{

static const int RECVING_TIMEOUT = 3000000; // 3 seconds

static const uint32_t CRC32_Table[256] =
{
	0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA,
	0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
	0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988,
	0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
	0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE,
	0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
	0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC,
	0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5,
	0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172,
	0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B,
	0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940,
	0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
	0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116,
	0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
	0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924,
	0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D,
	0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A,
	0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
	0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818,
	0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01,
	0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E,
	0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457,
	0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C,
	0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
	0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2,
	0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB,
	0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0,
	0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
	0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086,
	0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
	0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4,
	0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD,
	0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A,
	0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683,
	0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8,
	0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
	0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE,
	0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7,
	0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC,
	0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5,
	0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252,
	0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
	0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60,
	0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79,
	0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236,
	0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F,
	0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04,
	0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
	0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A,
	0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713,
	0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38,
	0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21,
	0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E,
	0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
	0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C,
	0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
	0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2,
	0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB,
	0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0,
	0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
	0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6,
	0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF,
	0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94,
	0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D
};

int
crc32_equal(
    const uint32_t &param1,
    const uint32_t &param2)
{
	return (param1 == param2) ? 1 : 0;
}

void
generate_buff_crc32(
    uint32_t	   starter,
    const uint8_t *inbuf,
    uint32_t	   bufsize,
    uint32_t	   &result)
{
	const uint8_t *p = inbuf;
	uint32_t crc = starter ^ 0xffffffff;

	while((bufsize--) && (p != NULL))
	{
		crc = CRC32_Table[(crc ^ *p++) & 0xff] ^ (crc >> 8);
	}
	result = crc ^ 0xffffffff;
}

void
generate_file_crc32(
    FILE	  *fp,
    uint32_t &result)
{
	uint32_t size	 = 1024;
	uint32_t readLen = 0;
	uint32_t crc	 = 0;
	uint32_t crcret  = 0;
	uint8_t  crc32Buf[size];
	memset(crc32Buf, 0, sizeof(crc32Buf));

	while((readLen = fread(crc32Buf, sizeof(uint8_t), size, fp)) > 0)
	{
		generate_buff_crc32(crc, crc32Buf, readLen, crcret);
		crc    = crcret;
	}
	result = crc;
}

CPacket::CPacket()
{
	timeval tv;
	gettimeofday(&tv, 0);
	startTime = tv.tv_sec * 1000000ULL + tv.tv_usec;
	srand(startTime);
	userID = 1 + (uint32_t)((1 << 20) * (double(rand()) / RAND_MAX));
}

CPacket::~CPacket()
{

}

uint8_t
CPacket::getReqType()
{
	return rawData.udata[0] >> 31;			  /* bit 0*/
}

uint8_t
CPacket::getMsgMark()
{
	return (rawData.udata[0] >> 29) & 0x03;  /* bit 1~2*/
}

uint8_t
CPacket::getMsgType()
{
	return (rawData.udata[0] >> 24) & 0x1F;  /* bit 3~7*/
}

uint32_t
CPacket::getSeqNo()
{
	return rawData.udata[0] & 0x00FFFFFF;    /* bit 8~31*/
}

uint32_t
CPacket::getSeqNo(CPacket &packet)
{
	return ntohl(packet.rawData.udata[0]) & 0xFFFFFF;    /* bit 8~31*/
}

uint32_t
CPacket::getUserId()
{
	return rawData.udata[1];
}

uint32_t
CPacket::getOffset()
{
	return rawData.udata[2];
}

char *
CPacket::getPayload()
{
	return rawData.data + pktHeadSize;
}

uint32_t
CPacket::getPayloadLen()
{
	return rawData.udata[3];
}

char *
CPacket::getRawData()
{
	return rawData.data;
}

uint32_t
CPacket::getRawDataCRCLen()
{
	return pktHeadSize + getPayloadLen();
}

uint32_t
CPacket::getTimeStamp()
{
	return rawData.udata[4];
}

uint32_t
CPacket::getCrcData()
{
	// convert crcsum into host order
	uint32_t crcsum_ = 0;
	memcpy(&crcsum_, rawData.data + pktHeadSize + getPayloadLen(), sizeof(crcsum_));
	crcsum_	= ntohl(crcsum_);
	return crcsum_;
}

uint32_t
CPacket::getTime()
{
	timeval tv;
	gettimeofday(&tv, 0);
	return tv.tv_sec * 1000000ULL + tv.tv_usec;
}

void
CPacket::packData(
    uint8_t     marker,
    uint8_t     msgtype,
    uint32_t    seqno,
    uint32_t    offset,
    const char *payload,
    uint32_t    payloadLen)
{
	memset(&rawData, 0, sizeof(rawData));
	rawData.udata[0]  = 0;				/*set bit0 = 0*/
	rawData.udata[0] |= marker << 29;	/*set bit1-2 = marker*/
	rawData.udata[0] |= msgtype << 24;	/*set bit3-7 = msgtype*/
	rawData.udata[0] |= seqno;			/*set bit8-31 = seqno*/
	rawData.udata[1]  = userID;
	rawData.udata[2]  = offset;
	rawData.udata[3]  = payloadLen;
	rawData.udata[4]  = getTime() - startTime;

	memcpy(rawData.data + pktHeadSize, payload, payloadLen);
	uint32_t crcsum = 0;
	generate_buff_crc32(0, (uint8_t *)rawData.data, pktHeadSize + payloadLen, crcsum);

    //printf("[%s:%d]crcsum = %u crclen = %d\n",__func__,__LINE__,crcsum,(pktHeadSize + payloadLen));
	// convert crcsum into network order
	crcsum = htonl(crcsum);
	memcpy(rawData.data + pktHeadSize + payloadLen, (char *)&crcsum, sizeof(crcsum));
    
	// convert packet header into network order
	for(int i = 0; i < 5; i++)
	{
		rawData.udata[i] = htonl(rawData.udata[i]);
	}
}

void
CPacket::packCtrl(
    uint8_t  marker,
    uint8_t  msgtype,
    uint32_t ackno,
    uint32_t offset,
    uint8_t  ackflg,
    uint16_t ack,
    uint16_t extype)
{
	memset(&rawData, 0, sizeof(rawData));
	rawData.udata[0]  = 1 << 31;		/*set bit0 = 1*/
	rawData.udata[0] |= marker << 29;	/*set bit1-2 = marker*/
	rawData.udata[0] |= msgtype << 24;	/*set bit3-7 = msgtype*/
	rawData.udata[0] |= ackno;			/*set bit8-31 = seqno*/
	rawData.udata[1]  = userID;
	rawData.udata[2]  = offset;
	rawData.udata[3]  = 4;				/*payloadLen is fixed on 4 Bytes*/
	rawData.udata[4]  = getTime() - startTime;

	uint32_t crcsum_  = 0;
	uint32_t payload_ = 0;
	payload_  = ackflg << 31;			/*set ackflag, bit0*/
	payload_ |= extype << 16;			/*set extern type, bit1-15*/
	payload_ |= ack;					/*set ack data*/
	memcpy((char *)&rawData.udata[5], (char *)&payload_, sizeof(payload_));

	generate_buff_crc32(0, (uint8_t *)rawData.data, pktHeadSize + 4, crcsum_);
    //printf("[%s:%d]crcsum = %u,crclen = %d\n",__func__,__LINE__,crcsum_,(pktHeadSize + 4));
	memcpy((char *)&rawData.udata[6], (char *)&crcsum_, sizeof(crcsum_));
	// convert packet data into network order
	for(int i = 0; i < 7; i++)
	{
		rawData.udata[i] = htonl(rawData.udata[i]);
	}
}

void
CPacket::unpackData()
{
	// convert packet header into host order
	for(int i = 0; i < 5; i++)
	{
		rawData.udata[i] = ntohl(rawData.udata[i]);
	}

	if(getReqType() == 1)
	{
		rawData.udata[5] = ntohl(rawData.udata[5]);
	}
}

int
CPacket::pktSendto(
    int 	  sockfd,
    int       sendLen,
    sockaddr *peeraddr,
    socklen_t peeraddrLen)
{


#ifdef UDP
    int sndlen = ::sendto(sockfd, rawData.data,sendLen, 0, peeraddr, peeraddrLen);
    if(sndlen < 0)
    {
        return -1;
    }
    return sndlen;
#else
	UNUSED(peeraddr);
	UNUSED(peeraddrLen);
#if 0
	int sndlen = ::send(sockfd, rawData.data, sendLen, 0);
	if(sndlen < 0)
	{
		perror("send error");
        return -1;
	}
    if(sndlen == 0)
    {
        return 0;
    }
	return sndlen;
#else
    int writelen = writen(sockfd, rawData.data, sendLen);
    if(writelen < 0)
    {
        perror("writen error");
        return -1;
    }
    //printf("[%s:%d] writelen = %d\n",__func__,__LINE__,writelen);
    return writelen;
#endif
#endif
}
int
CPacket::writen(int fd, void *buf, int count)
{
    int nleft = count;
    int nwrite = 0;
    char * ptr = (char*)buf;

    while(nleft > 0)
    {
        if((nwrite = write(fd, ptr, nleft)) <= 0)
        {
            if(nwrite < 0 && EINTR == errno)
                nwrite = 0;
            else
                return -1;
        }
        nleft -= nwrite;
        ptr += nwrite;
    }
    return count;
}
int
CPacket::readn(int fd, void *buf, int count, int timeout)
{
    int nleft = count;
    int nread;
    char *bufp = (char *)buf;
    struct timeval tv;
    tv.tv_sec = timeout / 1000000;
    tv.tv_usec = timeout % 1000000;
    fd_set fds;

    while(nleft > 0)
    {
        FD_ZERO(&fds);
        FD_SET(fd, &fds);

        if(select(fd + 1, &fds, NULL, NULL, &tv) <= 0 || !FD_ISSET(fd, &fds))
        {
            return -1; // not return 0 here to distinguish the case socket being closed
        }
        if((nread = read(fd, bufp, nleft)) < 0)
        {
            if (EINTR == errno || EWOULDBLOCK == errno || EAGAIN == errno)
            {
                continue;
            }
            WARN("read error, errno = %d, strerr = %s", errno, strerror(errno));
            return -1;
        }
        else if(nread == 0)
        {
            printf("client is closed !\n");
            return count - nleft;
        }
        bufp += nread;
        nleft -= nread;
    }
    return count;
}
int 
CPacket::recv_peek(int fd, const void *buf, int count)
{
	int ret = 0;
	while(1)
	{
		ret = recv(fd, (void *)buf, count, MSG_PEEK);
		if(ret == -1)
		{
			if(errno == EINTR)
			{
				continue;
			}
		}
		return ret;
	}
	return -1;
}

int
CPacket::pktRecvfrom(
    int 	   sockfd,
    sockaddr  *peeraddr,
    socklen_t *peeraddrLen)
{
#ifdef UDP
    int recvLen = ::recvfrom(sockfd, rawData.data, sizeof(rawData.data), 0, peeraddr, peeraddrLen);
    if(recvLen < 0)
    {
        return -1;
    }
    return recvLen;
#else
	UNUSED(peeraddr);
	UNUSED(peeraddrLen);
#if 0
	int recvLen = ::recv(sockfd, rawData.data, sizeof(rawData.data), 0);
	if(recvLen <= 0)
	{
		perror("recv error");
        return -1;
	}
	unpackData();
	return recvLen;
#else
    //unsigned int header[5];
    int recvlen;//= recv_peek(sockfd, (char*)&header[0],pktHeadSize);
    int payloadlen = 0;
    int readlen = 0;
    memset(&rawData, 0, sizeof(rawData));
    recvlen = readn(sockfd, rawData.udata, pktHeadSize, RECVING_TIMEOUT);
    //printf("[%s:%d]recvlen = %d\n",__func__,__LINE__,recvlen);
    if(recvlen < 0)
    {
        printf("recv_peek error\n");
        return -1;
    }
    if(recvlen == 0)
    {
        return 0;
    }
    payloadlen = ntohl(rawData.udata[3]);
    //printf("[%s:%d]payloadlen = %d\n",__func__,__LINE__,payloadlen);
    if(payloadlen < 4)
    {
        printf("parse payloadlen error\n");
        return -1;
    }
    readlen = readn(sockfd, rawData.data+pktHeadSize, payloadlen+4, RECVING_TIMEOUT);
    //printf("[%s:%d]readlen = %d\n",__func__,__LINE__,readlen);
    if(readlen < 0 )
        return -1;
    if(readlen != payloadlen+4)
    {
        printf("read packet size is not Completly\n");
        return 0;
    }
    unpackData();
    //printf("[%s:%d]readlen = %d,PayloadLen = %u\n",__func__,__LINE__,readlen,getPayloadLen());
    return (readlen+recvlen);
#endif
#endif
}
int
CPacket::pktRead(
    int sockfd,
    int count,
    int timeout)
{
	int len = 0;
	int ret = 0;
	fd_set rfds;
	int retval = 0;
	struct timeval tv;
	FD_ZERO(&rfds);
	while(len < count)
	{
		FD_SET(sockfd, &rfds);
		tv.tv_sec = (timeout / 1000000);
		tv.tv_usec = (timeout % 1000000);
		retval = select(sockfd + 1, &rfds, NULL, NULL, &tv);
		if(retval < 0)
		{
			perror("read error");
			return -1;
		}
		else if(retval == 0)
		{
			break;
		}
		else
		{
			if(FD_ISSET(sockfd, &rfds))
			{
				ret = read(sockfd, rawData.data + len, count - len);
				len += ret > 0 ? ret : 0;
				if(len >= count)
				{
					unpackData();
					return len;
				}
			}
			else
			{
				usleep(10);
			}
		}
	}
	unpackData();
	return len;
}

uint8_t
CPacket::getAckFlag()
{
	return rawData.udata[5] >> 31;
}

uint16_t
CPacket::getExternMsgType()
{
	return (rawData.udata[5] >> 16) & 0x7FFF;
}

uint16_t
CPacket::getAckType()
{
	return rawData.udata[5] & 0xFFFF;
}

uint32_t
CPacket::getAckSeqNo()
{
	return rawData.udata[0] & 0x00FFFFFF;  /* bit 8~31*/
}

}

