#ifndef __DWF_MANAGE_H__
#define __DWF_MANAGE_H__

#include <stdint.h>

// DWF(download file)

using namespace std;

#define  DWF_MAX_PAYLOAD      (1024*64)
#define  DWF_MAX_FILENAME     (1024)
#define  DWF_MAX_FILEPATH     (1024)
#define  DWF_MAX_THM_FILESIZE (1024*120)
#define  DWF_DEF_BLOCKS       (2048)

#define DWF_DATA  0X00
#define DWF_CTRL  0X01

typedef enum {
    DWF_FILE_LIST_GET = 0X00, 	// query whole file
    DWF_FILE_LIST_DEL = 0X01, 	// delete file
    DWF_FILE_SIZE_GET = 0X02,	// check file exist or not and buffer is full?
    DWF_FILE_START    = 0X03,	// downloading file
    DWF_FILE_CRC      = 0X04,	// request whole file CRC
    DWF_FILE_PAUSE    = 0X05,	// pause
    DWF_FILE_RESTART  = 0X06,	// restart
    DWF_FILE_QUIT     = 0X07,	// cancel or quit cmd
    DWF_FILE_CONFIG   = 0X11,   // config download path and version info
    DWF_FILE_NUM_MAX
} downMsgtype_t;

typedef enum {
    DWF_EX_GET_NONE 	   = 0X00, 	// none get files list
    DWF_EX_GET_ALL 		   = 0X01, 	// get all type files list
    DWF_EX_GET_JPG 		   = 0X02, 	// get jpeg main file list
    DWF_EX_GET_JPG_THM 	   = 0X03,	// get jpeg main and thm file list
    DWF_EX_GET_DNG     	   = 0X04,	// get dng file list
    DWF_EX_GET_MP4         = 0X05,	// get mp4 file list
    DWF_EX_GET_MP4_THM 	   = 0X06,	// get mp4 main and thm file list
    DWF_EX_GET_MAIN 	   = 0X07,	// get all main file list
    DWF_EX_GET_FIVE_MIN    = 0X08,	// get all main file list in 5 minutes
    DWF_EX_GET_TEN_MIN     = 0X09,	// get all main file list in 10 minutes
    DWF_EX_GET_THIRTY_MIN  = 0X0A,	// get all main file list in 30 minutes
    DWF_EX_GET_SIXTY_MIN   = 0X0B,	// get all main file list in 60 minutes
    DWF_EX_GET_NUM_MAX
} downExMsgtype_t;

typedef enum {
    DWF_ACK_NONE  			= 0XFB00,	//
    DWF_ACK_FILE_EXIST		= 0XFB01,   //
    DWF_ACK_FILE_NOT_EXIST	= 0XFB02,
    DWF_ACK_CRC_ERR			= 0XFB03,
    DWF_ACK_CRC_OK			= 0XFB04,
    DWF_ACK_FILE_TOO_BIG 	= 0XFB05,
    DWF_ACK_OTH_ERR 		= 0XFB06,	// other type error,such as pointer is NULL
    DWF_ACK_NUM_MAX
} downAckcode_t;

typedef enum {
    DWF_ERR_NONE    		   = 0X00,
    DWF_ERR_CRC     		   = 0X01,
    DWF_ERR_TOTAL_CRC          = 0X02,
    DWF_ERR_FILE_NOT_EXIST	   = 0X03,
    DWF_ERR_FILE_TOO_BIG       = 0X04,
    DWF_ERR_APP_CREATE_FILE	   = 0X05,
    DWF_ERR_CAM_OPEN_FILE	   = 0X06,
    DWF_ERR_PAUSE              = 0X07,
    DWF_ERR_RESTART     	   = 0X08,
    DWF_ERR_RESPONSE_FILELIST  = 0X09,
    DWF_ERR_QUIT   			   = 0X0A,
    DWF_ERR_BAD_PARAMETER      = 0X0B,
    DWF_ERR_TIMEOUT            = 0X0C,
    DWF_ERR_WRONG_SOCKFD       = 0X0D,
    DWF_ERR_CONFIG             = 0X0E,
    DWF_ERR_DELETE_FILE        = 0X0F,
    DWF_ERR_STOP_DOWNLOAD_FILE = 0X10,
    DWF_ERR_SOCK_CLOSE         = 0X11,
    DWF_ERR_NUM_MAX
} downErrCode_t;


#define  DWF_SERVER_PORT    (9800)
#define  DWF_PATH_DIR       "/tmp/SD0/DCIM/100MEDIA/"


#if defined __GNUC__
#define  likely(x)   __builtin_expect(!!(x), 1)
#define  unlikely(x) __builtin_expect(!!(x), 0)
#else
#define  likely(x)   (x)
#define  unlikely(x) (x)
#endif

#define  DWF_LIKELY(x)				 likely(x)
#define  DWF_UNLIKELY(x)			 unlikely(x)

#ifdef  __IPHONE_OS_VERSION_MIN_REQUIRED
#ifndef  OSX
#define OSX
#endif
#endif

#define  DWF_MEMSET(pointer,size)  memset(pointer, '\0', size);

#endif
