#ifndef __DWF_CLIENT_API_EXTERN_H__
#define __DWF_CLIENT_API_EXTERN_H__

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Functionality:
//	To create a download instance.
// Parameters:
//  	0) [in] id: identify download file position in server;
//  	1) [in] version: software version, start from 1;
//  	2) [in] setbit: if we set setbit false, we will download in default file path,
//				and location will be ignored, else download from location;
//  	3) [in] packsize: UDP package size, 4KB~60KB;
//  	4) [in] pIpAddress: server IP address;
//  	5) [in] mServPort: server port;
// Returned value:
//  	Success: a pointer of download instance;
//	Failure:
//		NULL;

void *yuneec_download_instance_new(const char *id, int version, bool setbit,
                                   int packsize, const char *pIpAddress, int mServPort);

// Functionality:
//	To connect to server and request file list and so on.
// Parameters:
//  	0) [in] pDown: a pointer of download instance;
//  	1) [in] extMsgType: extern message type;
//  	2) [in] pJSONBuf: a buffer store file list packaged by JSON;
//  	3) [in] mJSONBufsize: JSON buffer size;
//  	4) [in] timeoutMsec: timeout in milliseconds;
// Returned value:
//  	Success:  0;
//	Failure: -1;
//		we can get error info through func yuneec_download_error_print();

int  yuneec_download_get_jsonlist(void *pDown, int extMsgType,
                                  char *pJSONBuf, int mJSONBufsize, int timeoutMsec);

// Functionality:
//	  To connect to server and request file list based on time.
// here the extMsgType only support:
// DWF_EX_GET_FIVE_MIN, DWF_EX_GET_TEN_MIN, DWF_EX_GET_THIRTY_MIN, DWF_EX_GET_SIXTY_MIN;

int  yuneec_download_basetime_get_jsonlist(void *pDown, int extMsgType,
        char *pJSONBuf, int mJSONBufsize, int timeoutMsec);


// Functionality:
//	  To pause download a file.
// Parameters:
//	  0) [in] pDown: a pointer of download instance;
// Returned value:
//	  Success:	0;
//	  Failure: -1;
//		  we can get error info through func yuneec_download_error_print();

int  yuneec_download_file_pause(void *pDown);

// Functionality:
//	  To resume download a file.
// Parameters:
//	  0) [in] pDown: a pointer of download instance;
// Returned value:
//	  Success:  0;
//	  Failure: -1;
//		 we can get error info through func yuneec_download_error_print();

int  yuneec_download_file_resume(void *pDown);

// Functionality:
//	  To quit download a file.
// Parameters:
//	  0) [in] pDown: a pointer of download instance;
// Returned value:
//	  Success:	0;
//	  Failure: -1;
//		 we can get error info through func yuneec_download_error_print();

int  yuneec_download_file_quit(void *pDown);

// Functionality:
//	To delete file in server.
// Parameters:
//	0) [in] pDown: a pointer of download instance;
//  	2) [in] pJSONBuf: a buffer store file list packaged by JSON;
//  	3) [in] mJSONBufsize: JSON buffer size;
//  	4) [in] timeoutMsec: timeout in milliseconds;
// Returned value:
//			Success:  0;
//			Failure: -1;
//				we can get error info through func yuneec_download_error_print();

int  yuneec_download_file_delete(void *pDown, char *jsonBuf,
                                 int jsonBufsize, int timeoutMsec);

// Functionality:
//	To download a file.
// Parameters:
//  	0) [in] pDown: a pointer of download instance;
//  	1) [in] pFileName: a name of a file will be downloaded, such as "YUN00001.JPG";
//  	2) [in] pLocation: local file store location;
//  	3) [in] timeoutMsec: timeout in milliseconds;
// Returned value:
//  	Success:  0;
//	Failure: -1;
//		we can get error info through func yuneec_download_error_print();

int  yuneec_download_file_start(void *pDown, const char *pFileName,
                                const char *pLocation, int timeoutMsec);

// Functionality:
//	  To print error info.
// Parameters:
//	  0) [in] pDown: a pointer of download instance;
// Returned value:
//	  Success:  print error message;
//

const char *yuneec_download_error_print(void *pDown);

// Functionality:
//		To get download process.
// Parameters:
//		0) [in] pDown: a pointer of download instance;
// Returned value:
//		Success:  download process;
//

int yuneec_download_get_progress(void *pDown);


// Functionality:
//	  To destroy a download instance.
// Parameters:
//	  0) [in] pDown: a pointer of download instance;
// Returned value:
//		none

void yuneec_download_instance_destroy(void *pDown);

#ifdef __cplusplus
}
#endif

#endif
