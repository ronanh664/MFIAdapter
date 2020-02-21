#ifndef __DWF_LOG_H__
#define __DWF_LOG_H__

#ifdef __GNUC__
#define EV_CHECK_FMT(a,b) __attribute__((format(printf, a, b)))
#define EV_NORETURN __attribute__((noreturn))
#else
#define EV_CHECK_FMT(a,b)
#define EV_NORETURN
#endif

#define _EVENT_ERR_ABORT ((int)0xaabbccdd)

void event_err(int eval, const char *fmt, ...) EV_CHECK_FMT(2, 3) EV_NORETURN;
void event_warn(const char *fmt, ...) EV_CHECK_FMT(1, 2);
void event_msg(const char *fmt, ...) EV_CHECK_FMT(1, 2);

#undef EV_CHECK_FMT

#ifdef __GNUC__
#define __FUNC__     ((const char*)(__PRETTY_FUNCTION__))
#elif defined (__STDC_VERSION__) && __STDC_VERSION__ >= 19901L
#define __FUNC__     ((const char*)(__func__))
#else
#define __FUNC__     ((const char*)(__FUNCTION__))
#endif

#define ERROR(fmt, arg...)  event_err(1, "[ERROR],%s" fmt, __FUNC__, ##arg)
#define WARN(fmt, arg...)   event_warn("[WARN],%s" fmt, __FUNC__, ##arg)
#define INFO(fmt, arg...)   event_msg("[INFO],%s:" fmt, __FUNC__, ##arg)

//#define __DWF_DEBUG_ON_
#ifdef __DWF_DEBUG_ON_
#define PRINTF(fmt, arg...) event_msg("[PRINT],%s:" fmt, __FUNC__, ##arg)
#else
#define PRINTF(fmt, arg...)
#endif

#define UNUSED(_x) (void)(_x)
#endif