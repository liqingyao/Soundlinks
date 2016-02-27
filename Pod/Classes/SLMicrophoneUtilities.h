//
//  SLMicrophoneUtilities.h
//  microhoneTest
//
//  Created by wyudong on 2/21/16.
//  Copyright © 2016 Pheroant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface SLMicrophoneUtilities : NSObject

+ (AudioBufferList *)audioBufferListWithNumberOfFrames:(UInt32)frames
                                      numberOfChannels:(UInt32)channels
                                           interleaved:(BOOL)interleaved;

+ (float **)floatBuffersWithNumberOfFrames:(UInt32)frames
                          numberOfChannels:(UInt32)channels;

+ (AudioStreamBasicDescription)floatFormatWithNumberOfChannels:(UInt32)channels
                                                    sampleRate:(float)sampleRate;

+ (BOOL)isInterleaved:(AudioStreamBasicDescription)asbd;

+ (void)freeBufferList:(AudioBufferList *)bufferList;

+ (void)freeFloatBuffers:(float **)buffers numberOfChannels:(UInt32)channels;

+ (void)checkResult:(OSStatus)result operation:(const char *)operation;

@end
