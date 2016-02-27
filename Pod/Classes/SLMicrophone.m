//
//  SLMicrophone.m
//  microhoneTest
//
//  Created by wyudong on 2/21/16.
//  Copyright © 2016 Pheroant. All rights reserved.
//

#import "SLMicrophone.h"
#import "SLMicrophoneUtilities.h"
#import "SLMicrophoneFloatConverter.h"

typedef struct SLMicrophoneInfo
{
    AudioUnit                     audioUnit;
    AudioBufferList              *audioBufferList;
    float                       **floatData;
    AudioStreamBasicDescription   inputFormat;
    AudioStreamBasicDescription   streamFormat;
} SLMicrophoneInfo;

static OSStatus SLAudioMicrophoneCallback(void                       *inRefCon,
                                          AudioUnitRenderActionFlags *ioActionFlags,
                                          const AudioTimeStamp       *inTimeStamp,
                                          UInt32                      inBusNumber,
                                          UInt32                      inNumberFrames,
                                          AudioBufferList            *ioData);

@interface SLMicrophone ()
@property (nonatomic, strong) SLMicrophoneFloatConverter *floatConverter;
@property (nonatomic, assign) SLMicrophoneInfo      *info;
@end

@implementation SLMicrophone

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [SLMicrophoneUtilities checkResult:AudioUnitUninitialize(self.info->audioUnit)
                        operation:"Failed to unintialize audio unit for microphone"];
    [SLMicrophoneUtilities freeBufferList:self.info->audioBufferList];
    [SLMicrophoneUtilities freeFloatBuffers:self.info->floatData
                      numberOfChannels:self.info->streamFormat.mChannelsPerFrame];
    free(self.info);
}

- (id)init
{
    self = [super init];
    if(self)
    {
        self.info = (SLMicrophoneInfo *)malloc(sizeof(SLMicrophoneInfo));
        memset(self.info, 0, sizeof(SLMicrophoneInfo));
        [self setup];
    }
    return self;
}

//------------------------------------------------------------------------------

- (SLMicrophone *)initWithMicrophoneDelegate:(id<SLMicrophoneDelegate>)delegate
{
    self = [super init];
    if(self)
    {
        self.info = (SLMicrophoneInfo *)malloc(sizeof(SLMicrophoneInfo));
        memset(self.info, 0, sizeof(SLMicrophoneInfo));
        _delegate = delegate;
        [self setup];
    }
    return self;
}

- (void)setup
{
    // Create an input component description for mic input
    AudioComponentDescription inputComponentDescription;
    inputComponentDescription.componentType = kAudioUnitType_Output;
    inputComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    inputComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO;

    // The following must be set to zero unless a specific value is requested.
    inputComponentDescription.componentFlags = 0;
    inputComponentDescription.componentFlagsMask = 0;
    
    // get the first matching component
    AudioComponent inputComponent = AudioComponentFindNext( NULL , &inputComponentDescription);
    NSAssert(inputComponent, @"Couldn't get input component unit!");
    
    // create new instance of component
    [SLMicrophoneUtilities checkResult:AudioComponentInstanceNew(inputComponent, &self.info->audioUnit)
                        operation:"Failed to get audio component instance"];
    
    // must enable input scope for remote IO unit
    UInt32 flag = 1;
    [SLMicrophoneUtilities checkResult:AudioUnitSetProperty(self.info->audioUnit,
                                                       kAudioOutputUnitProperty_EnableIO,
                                                       kAudioUnitScope_Input,
                                                       1,
                                                       &flag,
                                                       sizeof(flag))
                        operation:"Couldn't enable input on remote IO unit."];
    
    //[self setDevice:[EZAudioDevice currentInputDevice]];
    
    UInt32 propSize = sizeof(self.info->inputFormat);
    [SLMicrophoneUtilities checkResult:AudioUnitGetProperty(self.info->audioUnit,
                                                       kAudioUnitProperty_StreamFormat,
                                                       kAudioUnitScope_Input,
                                                       1,
                                                       &self.info->inputFormat,
                                                       &propSize)
                        operation:"Failed to get stream format of microphone input scope"];

    self.info->inputFormat.mSampleRate = [[AVAudioSession sharedInstance] sampleRate];
    NSAssert(self.info->inputFormat.mSampleRate, @"Expected AVAudioSession sample rate to be greater than 0.0. Did you setup the audio session?");

    [self setAudioStreamBasicDescription:[self defaultStreamFormat]];
    
    // render callback
    AURenderCallbackStruct renderCallbackStruct;
    renderCallbackStruct.inputProc = SLAudioMicrophoneCallback;
    renderCallbackStruct.inputProcRefCon = (__bridge void *)(self);
    [SLMicrophoneUtilities checkResult:AudioUnitSetProperty(self.info->audioUnit,
                                                       kAudioOutputUnitProperty_SetInputCallback,
                                                       kAudioUnitScope_Global,
                                                       1,
                                                       &renderCallbackStruct,
                                                       sizeof(renderCallbackStruct))
                        operation:"Failed to set render callback"];
    
    [SLMicrophoneUtilities checkResult:AudioUnitInitialize(self.info->audioUnit)
                        operation:"Failed to initialize input unit"];
}

- (void)setAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd
{
    if (self.floatConverter)
    {
        [SLMicrophoneUtilities freeBufferList:self.info->audioBufferList];
        [SLMicrophoneUtilities freeFloatBuffers:self.info->floatData
                          numberOfChannels:self.info->streamFormat.mChannelsPerFrame];
    }
    
    //
    // Set new stream format
    //
    self.info->streamFormat = asbd;
    [SLMicrophoneUtilities checkResult:AudioUnitSetProperty(self.info->audioUnit,
                                                       kAudioUnitProperty_StreamFormat,
                                                       kAudioUnitScope_Input,
                                                       0,
                                                       &asbd,
                                                       sizeof(asbd))
                        operation:"Failed to set stream format on input scope"];
    [SLMicrophoneUtilities checkResult:AudioUnitSetProperty(self.info->audioUnit,
                                                       kAudioUnitProperty_StreamFormat,
                                                       kAudioUnitScope_Output,
                                                       1,
                                                       &asbd,
                                                       sizeof(asbd))
                        operation:"Failed to set stream format on output scope"];
    
    //
    // Allocate scratch buffers
    //
    UInt32 maximumBufferSize = [self maximumBufferSize];
    BOOL isInterleaved = [SLMicrophoneUtilities isInterleaved:asbd];
    UInt32 channels = asbd.mChannelsPerFrame;
    self.floatConverter = [[SLMicrophoneFloatConverter alloc] initWithInputFormat:asbd];
    self.info->floatData = [SLMicrophoneUtilities floatBuffersWithNumberOfFrames:maximumBufferSize
                                                           numberOfChannels:channels];
    self.info->audioBufferList = [SLMicrophoneUtilities audioBufferListWithNumberOfFrames:maximumBufferSize
                                                                    numberOfChannels:channels
                                                                         interleaved:isInterleaved];
}

- (AudioStreamBasicDescription)defaultStreamFormat
{
    return [SLMicrophoneUtilities floatFormatWithNumberOfChannels:1
                                                  sampleRate:self.info->inputFormat.mSampleRate];
}

- (UInt32)maximumBufferSize
{
    UInt32 maximumBufferSize;
    UInt32 propSize = sizeof(maximumBufferSize);
    [SLMicrophoneUtilities checkResult:AudioUnitGetProperty(self.info->audioUnit,
                                                       kAudioUnitProperty_MaximumFramesPerSlice,
                                                       kAudioUnitScope_Global,
                                                       0,
                                                       &maximumBufferSize,
                                                       &propSize)
                        operation:"Failed to get maximum number of frames per slice"];
    return maximumBufferSize;
}

-(void)startFetchingAudio
{
    [SLMicrophoneUtilities checkResult:AudioOutputUnitStart(self.info->audioUnit)
                        operation:"Failed to start microphone audio unit"];
}

-(void)stopFetchingAudio
{
    [SLMicrophoneUtilities checkResult:AudioOutputUnitStop(self.info->audioUnit)
                        operation:"Failed to stop microphone audio unit"];
}

static OSStatus SLAudioMicrophoneCallback(void                       *inRefCon,
                                          AudioUnitRenderActionFlags *ioActionFlags,
                                          const AudioTimeStamp       *inTimeStamp,
                                          UInt32                      inBusNumber,
                                          UInt32                      inNumberFrames,
                                          AudioBufferList            *ioData)
{
    SLMicrophone *microphone = (__bridge SLMicrophone *)inRefCon;
    SLMicrophoneInfo *info = (SLMicrophoneInfo *)microphone.info;
    
    //
    // Make sure the size of each buffer in the stored buffer array
    // is properly set using the actual number of frames coming in!
    //
    for (int i = 0; i < info->audioBufferList->mNumberBuffers; i++) {
        info->audioBufferList->mBuffers[i].mDataByteSize = inNumberFrames * info->streamFormat.mBytesPerFrame;
    }
    
    //
    // Render audio into buffer
    //
    OSStatus result = AudioUnitRender(info->audioUnit,
                                      ioActionFlags,
                                      inTimeStamp,
                                      inBusNumber,
                                      inNumberFrames,
                                      info->audioBufferList);
    
    //
    // Notify delegate of new float data processed
    //
    if ([microphone.delegate respondsToSelector:@selector(microphone:hasAudioReceived:withBufferSize:withNumberOfChannels:)])
    {
        //
        // Convert to float
        //
        [microphone.floatConverter convertDataFromAudioBufferList:info->audioBufferList
                                               withNumberOfFrames:inNumberFrames
                                                   toFloatBuffers:info->floatData];
        [microphone.delegate microphone:microphone
                       hasAudioReceived:info->floatData
                         withBufferSize:inNumberFrames
                   withNumberOfChannels:info->streamFormat.mChannelsPerFrame];
    }
    
    return result;
}



@end
