//
//  FFMpegDemuxerImp.m
//  FFMpegDemuxer
//
//  Copyright © 2016 tbago. All rights reserved.
//

#import "FFMpegDemuxerImp.h"
#include "FFMpegCommon.h"

#ifdef DEBUG
#define DNSLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DNSLog(format, ...)
#endif

#define FMT_PROB_DATA_SIZE 1*1024*1024 //1M

static int64_t          sLastDemuxerPacketTime           = 0;
static const int64_t    kRtspTimeOutValueInMillisecond   = 2000;
static BOOL             stopRead = NO;

void ffmpeg_log(void* avcl, int level, const char *fmt, va_list vl);

static int demuxerInterruptCallback(void *ctx)
{
    int64_t currentTime = av_gettime_relative();
//    NSLog(@"current time:%zd", current_time/1000);
    int64_t timeDifferent = (currentTime - sLastDemuxerPacketTime) / 1000;     ///< to ms
    if (timeDifferent > kRtspTimeOutValueInMillisecond && sLastDemuxerPacketTime != 0) {
        return 1;
    }
    else if(stopRead) {
        return 1;
    }
    else {
        return 0;
    }
}

@interface FFMpegDemuxerImp()
{
    AVFormatContext * _formatContext;
    AVRational      _timeBase;
}
@property (strong, nonatomic) MovieInfo         *movieInfo;                 ///< current file movie info
@property (nonatomic) BOOL                      fileEof;                    ///< read end of file
@property (nonatomic) BOOL                      opened;
@property (copy, nonatomic) NSData              *storeExtraData;
@end

@implementation FFMpegDemuxerImp

- (instancetype)init {
    self = [super init];
    if (self) {
        _formatContext = NULL;
        _timeBase = av_make_q(1, 10000000);
        
        [self innerInitFFMpeg];
    }
    return self;
}

- (BOOL)openFileByPath:(NSString *)filePath {
    self.opened = NO;
    [self closeInputFile];
    
    av_log_set_callback(ffmpeg_log);
    
    AVInputFormat* format = NULL;
    
    if ([filePath hasPrefix:@"rtsp://"]) {
        format = av_find_input_format("rtsp");
    }
    
    ///< check file format by probe data
    if (format == NULL)
    {
        AVProbeData probeData;
        memset(&probeData, 0, sizeof(probeData));
        uint32_t bufferSize = FMT_PROB_DATA_SIZE+AVPROBE_PADDING_SIZE;

        NSFileHandle          *readFileHandle = NULL;
        readFileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        if (readFileHandle == NULL) {
            NSLog(@"cannot create file handle by file:%@", filePath);
            return NO;
        }
        NSData *fileData = [readFileHandle readDataOfLength:bufferSize];
        if (fileData.length == 0) {
            NSLog(@"file or stream is not have enough data");
            return NO;
        }
        
        probeData.buf      = (uint8_t *)fileData.bytes;
        probeData.buf_size = (uint32_t)fileData.length;
        probeData.filename = [[filePath lastPathComponent] UTF8String];
        format = av_probe_input_format(&probeData, 1);
    }

    if (format == NULL) {
        NSString *fileExt = [filePath pathExtension];
        if ([fileExt isEqualToString:@"mod"] || [fileExt isEqualToString:@"vob"]) {
            format = av_find_input_format("mpeg");
        }
        else if ([fileExt isEqualToString:@"mp3"]) {
            format = av_find_input_format("mp3");
        }
        else if ([fileExt isEqualToString:@"tod"]
                 ||[fileExt isEqualToString:@"mts"]
                 || [fileExt isEqualToString:@"m2ts"]
                 || [fileExt isEqualToString:@"tp"]
                 || [fileExt isEqualToString:@"ts"]
                 || [fileExt isEqualToString:@"trp"]
                 || [fileExt isEqualToString:@"m2t"])
        {
            format = av_find_input_format("mpegts");
        }
        else if([fileExt isEqualToString:@"png"]
                || [fileExt isEqualToString:@"tiff"]
                || [fileExt isEqualToString:@"tif"]
                || [fileExt isEqualToString:@"ppm"])
        {
            format = av_find_input_format("image2");
        }
        if ([fileExt isEqualToString:@"mpeg"]
            || [fileExt isEqualToString:@"mpg"]
            || [fileExt isEqualToString:@"evo"]
            || [fileExt isEqualToString:@"vdr"])
        {
            format = av_find_input_format("mpeg");
        }
        else if ([fileExt isEqualToString:@"264"]
                 || [fileExt isEqualToString:@"h264"]) {
            format = av_find_input_format("h264");
        }
        else if ([fileExt isEqualToString:@"mxf"]
                 || [fileExt isEqualToString:@"MXF"]) {
            format = av_find_input_format("mxf");
        }
    }
    
    if (format == NULL) {
        DNSLog(@"Cannot find input stream format");
        return NO;
    }

    sLastDemuxerPacketTime = av_gettime_relative();
    _formatContext = avformat_alloc_context();
    _formatContext->interrupt_callback.callback = demuxerInterruptCallback;
    _formatContext->interrupt_callback.opaque   = NULL;
    // set max timeout to 300ms for demux reading packet to avoid packet lost issue
    _formatContext->max_delay = 300000;
    stopRead = NO;
    int ret = avformat_open_input(&_formatContext, [filePath UTF8String], format, NULL);
    if (ret != 0) {
        DNSLog(@"Open input failed");
        return NO;
    }

    if (_formatContext != NULL) {
        avformat_find_stream_info(_formatContext, NULL);
    }
    
    [self buildMovieInfo:filePath];
    
    self.fileEof = NO;
    self.opened  = YES;
    stopRead = NO;
    
    return YES;
}

- (void)closeInputFile {
    if (_formatContext != NULL) {
        avformat_preclose_input(&_formatContext);
        avformat_close_input(&_formatContext);
        _formatContext = NULL;
    }
    stopRead = NO;
}

- (uint32_t)getMovieCount {
    return 1;
}

- (MovieInfo *)getMovieInfoByIndex:(uint32_t)index {
    if (index == 0) {
        return self.movieInfo;
    }
    return NULL;
}

- (CompassedFrame *)readFrame {
    if (!self.opened) {
        return NULL;
    }
    
    AVPacket pkt;
    int ret = 0;
    bool bHasPkt = NO;
    StreamType readStramType = UnknownStream;
    
    do{
        ret = av_read_frame(_formatContext, &pkt);
        sLastDemuxerPacketTime = av_gettime_relative();
        if (ret < 0)
        {
            if (AVERROR(EAGAIN) == ret) {
                continue;
            }
            else {
                self.fileEof = YES;
                break;
            }
        }
        else {
            ///< check is video frame or audio frame
            ///< for now only support video and audio frame, also not support multi video audio stream
            AVStream *stream = _formatContext->streams[pkt.stream_index];
            enum AVMediaType mediaType = stream->codec->codec_type;
            
            if (mediaType == AVMEDIA_TYPE_VIDEO) {
                readStramType = VideoStream;
                bHasPkt = YES;
                break;
            }
            else if (mediaType == AVMEDIA_TYPE_AUDIO) {
                readStramType = AudioStream;
                bHasPkt = YES;
                break;
            }
            else {
                continue;
            }
        }
    } while(true);
    
    if (bHasPkt && readStramType != UnknownStream)
    {
        AVStream *stream = _formatContext->streams[pkt.stream_index];
        AVRational timeBase = stream->time_base;
        CompassedFrame *compassedFrame = nil;
        
        if (stream->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            compassedFrame                    = [[CompassedFrame alloc] init];
            compassedFrame.streamType         = readStramType;
            compassedFrame.keyFrame           = pkt.flags & AV_PKT_FLAG_KEY;
            compassedFrame.presentTimeStamp   = av_rescale_q(pkt.pts, timeBase, _timeBase);
            compassedFrame.decompassTimeStamp = av_rescale_q(pkt.dts, timeBase, _timeBase);
            compassedFrame.position           = pkt.pos;
            compassedFrame.duration           = av_rescale_q(pkt.duration, timeBase, _timeBase);
            
            compassedFrame.frameData          = [[NSData alloc] initWithBytes:pkt.data length:pkt.size];

            [self paraseH264DataToGetCameraExtraData:pkt.data h264ByteLength:pkt.size];
            if (self.storeExtraData != nil) {
                compassedFrame.extraData          = self.storeExtraData;
            }
        }
        av_free_packet(&pkt);

        return compassedFrame;
    }
    return NULL;
}

- (BOOL)eof {
    return self.fileEof;
}

- (void)stopReading {
    stopRead = YES;
}

- (void)paraseH264DataToGetCameraExtraData:(uint8_t*) h264Byte
                            h264ByteLength:(uint32_t) h264ByteLength
{
    if (h264ByteLength < 4) {
        return;
    }
    uint64_t cursor = 0;
    uint64_t nal_unit_length = 0;
    uint8_t  nal_unit_type = 0;
    
//    if (*(int*)(h264Byte+(h264ByteLength-4))== 0xffffffff)
    {
        do {
            nal_unit_length = [self GetOneNalUnit:&nal_unit_type
                                          pBuffer:h264Byte+cursor
                                       bufferSize:h264ByteLength-cursor];
            if (nal_unit_type == 12) {
                uint8_t *nalDataIndex = h264Byte+cursor;
                
                const uint32_t nalHeaderDataLength = 5;    ///< remove h264 nalu header (0x00 0x00 0x00 0x01 0x12)
                uint32_t nalDataLength = (uint32_t)(nal_unit_length - nalHeaderDataLength);
                
                uint8_t *tempBuffer = (uint8_t *)malloc(nalDataLength);
                memcpy(tempBuffer, nalDataIndex+nalHeaderDataLength, nalDataLength);
                uint32_t realDataLength = [self removeEmulationPrevention:tempBuffer
                                                                     size:nalDataLength];
                
                self.storeExtraData = [[NSData alloc] initWithBytes:tempBuffer length:realDataLength];
                
                free(tempBuffer);
                break;
            }
            cursor += nal_unit_length;
        } while (cursor < h264ByteLength);
    }
}

- (uint64_t) GetOneNalUnit:(uint8_t *) pNaluType
                   pBuffer:(uint8_t *) pBuffer
                bufferSize:(uint64_t) bufferSize
{
    uint32_t pos = 0;
    uint32_t tempValue = 0;
    
    for (uint32_t code = 0xffffffff; pos < 4; pos++) {
        tempValue = pBuffer[pos];
        code = (code<<8)|tempValue;
    }
    
    *pNaluType = pBuffer[pos++] & 0x1F;
    for (uint32_t code=0xffffffff; pos < bufferSize; pos++) {
        tempValue = pBuffer[pos];
        if ((code=(code<<8)|tempValue) == 0x00000001) {
            break; //next start code is found
        }
    }
    if (pos == bufferSize) {
        // next start code is not found, this must be the last nalu
        return bufferSize;
    } else {
        return pos-4+1;
    }
}

- (int32_t)removeEmulationPrevention:(uint8_t*) pdata
                                size:(int32_t) size
{
    unsigned char *readPtr, *writePtr;
//    unsigned char byte;
    unsigned int i,tmp;
    unsigned int zeroCount;
    tmp = size;
    readPtr = writePtr = pdata;
    zeroCount = 0;
    for (i = tmp; i--;)
    {
        if ((zeroCount == 2) && (*readPtr == 0x03))
        {
            /* emulation prevention byte shall be followed by one of the
             * following bytes: 0x00, 0x01, 0x02, 0x03. This implies that
             * emulation prevention 0x03 byte shall not be the last byte
             * of the stream. */
            // if ( (i == 0) || (*(readPtr+1) > 0x03) ){
            //LOGV("last byte shall not be 0x03\n");
            // return 0xFFFF;
            //}
            /* do not write emulation prevention byte */
            readPtr++;
            zeroCount = 0;
        }
        else
        {
            /* NAL unit shall not contain byte sequences 0x000000,
             * 0x000001 or 0x000002 */
            if ( (zeroCount == 2) && (*readPtr <= 0x02) ){
                //LOGV("nal unit shall not contain byte 0x000000,0x000001,0x000002\n");
                return 0xFFFF;
                
            }
            
            if (*readPtr == 0) {
                zeroCount++;
            }
            else {
                zeroCount = 0;
            }
            *writePtr++ = *readPtr++;
        }
    }
    
    /* (readPtr - writePtr) indicates number of "removed" emulation
     * prevention bytes -> subtract from stream buffer size */
    return (size - (unsigned char)(readPtr - writePtr));
}

#pragma mark - private method

- (void)innerInitFFMpeg {
    av_register_all();
    avformat_network_init();
    
    av_log_set_level(AV_LOG_QUIET);
}

- (void)buildMovieInfo:(NSString *) filePath {
    self.movieInfo.name = [[filePath lastPathComponent] stringByDeletingPathExtension];
    if (_formatContext->iformat->name != NULL) {
        self.movieInfo.format = [NSString stringWithUTF8String:_formatContext->iformat->name];
    }
    else {
        self.movieInfo.format = @"unknown";
    }
    
    ///< store movie meta data
    if (_formatContext->metadata != NULL) {
        AVDictionaryEntry *t = NULL;
        t = av_dict_get(_formatContext->metadata, "", t, AV_DICT_IGNORE_SUFFIX);
        while (t != NULL)
        {
            if (t->key != NULL && t->value != NULL)
            {
                NSString *keyString = [NSString stringWithUTF8String:t->key];
                NSString *valueString = [NSString stringWithUTF8String:t->value];
                [self.movieInfo addMetaDataToMovieInfo:keyString value:valueString];
            }
            t = av_dict_get(_formatContext->metadata, "", t, AV_DICT_IGNORE_SUFFIX);
        }
    }
    
    ///< build stream info
    for (uint32_t i = 0; i < _formatContext->nb_streams; i++) {
        AVStream* avStream = _formatContext->streams[i];
        StreamInfo *streamInfo = [[StreamInfo alloc] init];
        streamInfo.streamId = avStream->id;
        
        AVDictionaryEntry *tag = av_dict_get(avStream->metadata, "language", NULL, 0);
        if (tag != NULL && tag->value != NULL) {
            streamInfo.language = [NSString stringWithUTF8String:tag->value];
        }
        else {
            streamInfo.language = @"eng";
        }
        
        if (avStream->duration != AV_NOPTS_VALUE) {
            int64_t duration = av_rescale_q(avStream->duration, avStream->time_base, gGloabalTimeBase);
            if (duration > 0) {
                avStream->duration = duration/1000;
            }
        }
        
        AVCodecContext *pContext = avStream->codec;
        enum AVMediaType mediaType = avStream->codec->codec_type;
        
        if (mediaType == AVMEDIA_TYPE_VIDEO) {
            streamInfo.streamType  = VideoStream;
            streamInfo.width       = pContext->width;
            streamInfo.height      = pContext->height;
            streamInfo.pixelFormat = FFMpegPixelFormatToMediaPixelFormat(pContext->pix_fmt);
            
            ///< get video frame rate
            streamInfo.framerateNumerator   = avStream->time_base.num;
            streamInfo.framerateDenominator = avStream->time_base.den;
            if (![self isValidFramerate:streamInfo.framerateNumerator framerateDenominator:streamInfo.framerateDenominator]) {
                ///< use 30 as framerate
                streamInfo.framerateNumerator   = 30;
                streamInfo.framerateDenominator = 1;
            }
            
            if (pContext->sample_aspect_ratio.num == 0) {
                streamInfo.pixelAspectRatioNumerator = 0;
                streamInfo.pixelAspectRatioDenominator = 0;
            }
            else {
                streamInfo.pixelAspectRatioNumerator = pContext->sample_aspect_ratio.num;
                streamInfo.pixelAspectRatioNumerator = pContext->sample_aspect_ratio.den;
            }
            
            streamInfo.codecTag = pContext->codec_tag;
            streamInfo.bitsPerCodedSample = pContext->bits_per_coded_sample;
        }
        else if (mediaType == AVMEDIA_TYPE_AUDIO) {
            streamInfo.streamType = AudioStream;

            streamInfo.channels = pContext->channels;
            streamInfo.samplerate = pContext->sample_rate;
            streamInfo.sampleFormat = FFMpegSampleFormatToMediaSampleFormat(pContext->sample_fmt);
        }
        else if (mediaType == AVMEDIA_TYPE_SUBTITLE) {
            streamInfo.streamType = SubtitleStream;
        }
        else {
            streamInfo.streamType = UnknownStream;
        }
        
        ///< common set media value
        streamInfo.bitrate = pContext->bit_rate;
        if (pContext->codec_id != AV_CODEC_ID_NONE && pContext->codec_id != AV_CODEC_ID_PROBE) {
            AVCodec *pCodec       = avcodec_find_decoder(pContext->codec_id);
            if (pCodec != NULL) {
                streamInfo.codecName  = [NSString stringWithUTF8String:pCodec->name];
            }
        }
        else {
            streamInfo.streamType = UnknownStream;
        }
        
        ///< stream metadata
        if (avStream->metadata != NULL) {
            AVDictionaryEntry *t = NULL;
            t = av_dict_get(avStream->metadata, "", t, AV_DICT_IGNORE_SUFFIX);
            while (t != NULL)
            {
                if (t->key != NULL && t->value != NULL)
                {
                    NSString *keyString = [NSString stringWithUTF8String:t->key];
                    NSString *valueString = [NSString stringWithUTF8String:t->value];
                    [streamInfo addMetaDataToStreamInfo:keyString
                                                  value:valueString];
                }
                t = av_dict_get(avStream->metadata, "", t, AV_DICT_IGNORE_SUFFIX);
            }
        }
        
        ///< stream extra data
        if (pContext->extradata != NULL && pContext->extradata_size > 0) {
            streamInfo.extraData = [[NSData alloc] initWithBytes:pContext->extradata length:pContext->extradata_size];
        }
        
        streamInfo.codecID = FFMpegCodecIDToMeidaCodecID(pContext->codec_id);
        
        [self.movieInfo addStreamInfoToMovieInfo:streamInfo];
    }
}

- (BOOL)isValidFramerate:(int32_t) framerateNumerator
    framerateDenominator:(int32_t) framerateDenominator
{
    double framerateValue = 1.0 * framerateNumerator /framerateDenominator;
    if (framerateValue >= 121 || framerateValue < 1) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - get & set

- (MovieInfo *)movieInfo {
    if (_movieInfo == nil) {
        _movieInfo = [[MovieInfo alloc] init];
    }
    return _movieInfo;
}

@end

//////////////////////////////////////////////////////////////////////////
//ffmepg log call back
void ffmpeg_log(void* avcl, int level, const char *fmt, va_list vl)
{
    char buffer[256];
    if (level == AV_LOG_WARNING) {
        vsnprintf(buffer, 256, fmt, vl);
        DNSLog(@"ffmpeg demuxer warning:%s", buffer);
    }
    else if (level == AV_LOG_ERROR) {
        vsnprintf(buffer, 256, fmt, vl);
        DNSLog(@"ffmpeg demuxer error:%s", buffer);
    }
    else if (level == AV_LOG_FATAL) {
        vsnprintf(buffer, 256, fmt, vl);
        DNSLog(@"ffmpeg demuxer fatal:%s", buffer);
    }
    else if (level == AV_LOG_TRACE) {
//        vsnprintf(buffer, 256, fmt, vl);
//        NSLog(@"ffmpeg demuxer trace:%s", buffer);
    }
}

FFMpegDemuxer *createFFMpegDemuxer() {
    FFMpegDemuxer *demuxer = [[FFMpegDemuxerImp alloc] init];
    return demuxer;
}
