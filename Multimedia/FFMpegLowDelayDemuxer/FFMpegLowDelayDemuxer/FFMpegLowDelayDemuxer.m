//
//  FFMpegLowDelayDemuxer.m
//  FFMpegLowDelayDemuxer
//
//  Created by tbago on 20/11/2017.
//  Copyright © 2017 yuneec. All rights reserved.
//

#import "FFMpegLowDelayDemuxer.h"

@implementation FFMpegLowDelayDemuxer

- (BOOL)openFileByPath:(NSString *) filePath {
    return NO;
}

- (void)closeInputFile {

}

- (uint32_t)getMovieCount {
    return 0;
}

- (MovieInfo *)getMovieInfoByIndex:(uint32_t) index {
    return NULL;
}

- (CompassedFrame *)readFrame {
    return NULL;
}

- (BOOL)seekToPosition:(int64_t) position
          realPosition:(int64_t *) realPosition {
    return NO;
}

- (int64_t)getCurrentTime {
    return -1;
}

- (int64_t)getCurrentPosition {
    return -1;
}

- (BOOL)eof {
    return YES;
}

- (void)stopReading {
    return;
}

@end
