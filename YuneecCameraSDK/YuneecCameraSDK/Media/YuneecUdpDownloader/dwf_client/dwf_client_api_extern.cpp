#include "dwf_client_api.h"
#include "dwf_client_api_extern.h"

using namespace yuneec;

#define DOWNLOAD_FILE_WORKER(pDown, filename, location, timeoutMsec, func) \
	do{\
		if(!pDown){\
			fprintf(stderr, "[%s:%d],bad parameter!\n",__FUNCTION__, __LINE__);\
			return -1;\
		} return ((CDownLoad*)pDown)->func(filename, location, timeoutMsec);\
	}while(0);

#define DOWNLOAD_CMD_CALLER(pDown, func) \
	do{\
		if(!pDown){\
			fprintf(stderr, "[%s:%d],bad parameter!\n",__FUNCTION__, __LINE__);\
			return -1;\
		} return ((CDownLoad*)pDown)->func();\
	}while(0);

void *
yuneec_download_instance_new(
    const char *id,
    int         version,
    bool        setbit,
    int         packsize,
    const char *pIpAddress,
    int         servPort)
{
    if (setbit && (!id || !pIpAddress)) {
        fprintf(stderr, "bad parameter!\n");
        return NULL;
    }
    void *pDown = new (std::nothrow) CDownLoad(id, version, setbit, packsize, pIpAddress, servPort);

    if (pDown == NULL) {
        fprintf(stderr, "instance create error!\n");
        return NULL;
    }
    return pDown;
}

int
yuneec_download_get_jsonlist(
    void   *pDown,
    int     extMsgType,
    char   *pJsonBuf,
    int     jsonBufsize,
    int     timeoutMsec)
{
    //printf("================%s:%d\n",__func__,__LINE__);
    if (!pDown || !pJsonBuf || (jsonBufsize <= 0)) {
        fprintf(stderr, "bad parameter!\n");
        return -1;
    }
    return ((CDownLoad *)pDown)->yuneec_download_request(extMsgType,
            pJsonBuf, jsonBufsize, timeoutMsec);
}

int
yuneec_download_basetime_get_jsonlist(
    void   *pDown,
    int     extMsgType,
    char   *pJsonBuf,
    int     jsonBufsize,
    int     timeoutMsec)
{
    return yuneec_download_get_jsonlist(pDown, extMsgType, pJsonBuf, jsonBufsize, timeoutMsec);
}

int
yuneec_download_file_start(
    void       *pDown,
    const char *filename,
    const char *location,
    int         timeoutMsec)
{
    DOWNLOAD_FILE_WORKER(pDown, filename, location, timeoutMsec, yuneec_download_file);
}

int
yuneec_download_file_pause(
    void *pDown)
{
    DOWNLOAD_CMD_CALLER(pDown, yuneec_download_pause);
}

int
yuneec_download_file_resume(
    void *pDown)
{
    DOWNLOAD_CMD_CALLER(pDown, yuneec_download_resume);
}

int
yuneec_download_file_quit(
    void *pDown)
{
    DOWNLOAD_CMD_CALLER(pDown, yuneec_download_quit);
}

int
yuneec_download_file_delete(
    void *pDown,
    char *jsonBuf,
    int   jsonBufsize,
    int   timeoutMsec)
{
    if (!pDown || !jsonBuf) {
        fprintf(stderr, "bad parameter!\n");
        return -1;
    }
    return ((CDownLoad *)pDown)->yuneec_download_delete(jsonBuf, jsonBufsize, timeoutMsec);
}

const char *
yuneec_download_error_print(
    void *pDown)
{
    if (!pDown) {
        fprintf(stderr, "bad parameter!\n");
        return "";
    }
    return ((CDownLoad *)pDown)->yuneec_error_msg_print();
}

int
yuneec_download_get_progress(
    void *pDown)
{
    DOWNLOAD_CMD_CALLER(pDown, yuneec_download_progress_get);
}

void
yuneec_download_instance_destroy(
    void *pDown)
{
    if (pDown) {
        delete ((CDownLoad *)pDown);
    }
    pDown = NULL;
}



