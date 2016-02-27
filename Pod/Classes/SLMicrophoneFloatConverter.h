//
//  SLMicrophoneFloatConverter.h
//  microhoneTest
//
//  Created by wyudong on 2/21/16.
//  Copyright © 2016 Pheroant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

FOUNDATION_EXPORT UInt32 const EZAudioFloatConverterDefaultPacketSize;

@interface SLMicrophoneFloatConverter : NSObject

- (instancetype)initWithInputFormat:(AudioStreamBasicDescription)inputFormat;

- (void)convertDataFromAudioBufferList:(AudioBufferList *)audioBufferList
                    withNumberOfFrames:(UInt32)frames
                        toFloatBuffers:(float **)buffers;

@end
