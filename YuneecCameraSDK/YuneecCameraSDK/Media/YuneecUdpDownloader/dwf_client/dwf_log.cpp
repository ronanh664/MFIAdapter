#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include "dwf_log.h"

#define EVENT_LOG_DEBUG 0
#define EVENT_LOG_MSG   1
#define EVENT_LOG_WARN  2
#define EVENT_LOG_ERR   3

static void warn_helper(int severity, const char *errstr, const char *fmt, va_list ap);
static void event_log(int severity, const char *msg);
static void event_exit(int errcode) EV_NORETURN;


static void
event_exit(int errcode)
{
    if (errcode == _EVENT_ERR_ABORT) {
        abort();
    } else {
        exit(errcode);
    }
}

void
event_err(int eval, const char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    warn_helper(EVENT_LOG_ERR, strerror(errno), fmt, ap);
    va_end(ap);
    event_exit(eval);
}

void
event_warn(const char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    warn_helper(EVENT_LOG_WARN, strerror(errno), fmt, ap);
    va_end(ap);
}

void
event_msg(const char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    warn_helper(EVENT_LOG_MSG, NULL, fmt, ap);
    va_end(ap);
}

static void
warn_helper(int severity, const char *errstr, const char *fmt, va_list ap)
{
    char buf[1024];
    size_t len;

    if (fmt != NULL) {
        vsnprintf(buf, sizeof(buf), fmt, ap);
    } else {
        buf[0] = '\0';
    }

    if (errstr) {
        len = strlen(buf);
        if (len < sizeof(buf) - 3) {
            snprintf(buf + len, sizeof(buf) - len, ": %s", errstr);
        }
    }

    event_log(severity, buf);
}

static void
event_log(int severity, const char *msg)
{
    const char *severity_str;
    switch (severity) {
    case EVENT_LOG_DEBUG:
        severity_str = "debug";
        break;
    case EVENT_LOG_MSG:
        severity_str = "msg";
        break;
    case EVENT_LOG_WARN:
        severity_str = "warn";
        break;
    case EVENT_LOG_ERR:
        severity_str = "err";
        break;
    default:
        severity_str = "???";
        break;
    }
    (void)fprintf(stderr, "[DownloadFile-%s] %s\n", severity_str, msg);
}
