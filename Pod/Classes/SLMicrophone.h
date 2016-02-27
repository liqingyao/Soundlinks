//
//  SLMicrophone.h
//  microhoneTest
//
//  Created by wyudong on 2/21/16.
//  Copyright © 2016 Pheroant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@class SLMicrophone;

@protocol SLMicrophoneDelegate <NSObject>

@optional

- (void)    microphone:(SLMicrophone *)microphone
      hasAudioReceived:(float **)buffer
        withBufferSize:(UInt32)bufferSize
  withNumberOfChannels:(UInt32)numberOfChannels;

@end

@interface SLMicrophone : NSObject

@property (nonatomic, weak) id<SLMicrophoneDelegate> delegate;

- (SLMicrophone *)initWithMicrophoneDelegate:(id<SLMicrophoneDelegate>)delegate;

- (void)startFetchingAudio;

- (void)stopFetchingAudio;

@end
