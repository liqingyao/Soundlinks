//
//  SLMicrophoneUtilities.m
//  microhoneTest
//
//  Created by wyudong on 2/21/16.
//  Copyright © 2016 Pheroant. All rights reserved.
//

#import "SLMicrophoneUtilities.h"

@implementation SLMicrophoneUtilities

+ (AudioBufferList *)audioBufferListWithNumberOfFrames:(UInt32)frames
                                      numberOfChannels:(UInt32)channels
                                           interleaved:(BOOL)interleaved
{
    unsigned nBuffers;
    unsigned bufferSize;
    unsigned channelsPerBuffer;
    if (interleaved)
    {
        nBuffers = 1;
        bufferSize = sizeof(float) * frames * channels;
        channelsPerBuffer = channels;
    }
    else
    {
        nBuffers = channels;
        bufferSize = sizeof(float) * frames;
        channelsPerBuffer = 1;
    }
    
    AudioBufferList *audioBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer) * (channels-1));
    audioBufferList->mNumberBuffers = nBuffers;
    for(unsigned i = 0; i < nBuffers; i++)
    {
        audioBufferList->mBuffers[i].mNumberChannels = channelsPerBuffer;
        audioBufferList->mBuffers[i].mDataByteSize = bufferSize;
        audioBufferList->mBuffers[i].mData = calloc(bufferSize, 1);
    }
    return audioBufferList;
}

+ (float **)floatBuffersWithNumberOfFrames:(UInt32)frames
                          numberOfChannels:(UInt32)channels
{
    size_t size = sizeof(float *) * channels;
    float **buffers = (float **)malloc(size);
    for (int i = 0; i < channels; i++)
    {
        size = sizeof(float) * frames;
        buffers[i] = (float *)malloc(size);
    }
    return buffers;
}

+ (void)freeBufferList:(AudioBufferList *)bufferList
{
    if (bufferList)
    {
        if (bufferList->mNumberBuffers)
        {
            for( int i = 0; i < bufferList->mNumberBuffers; i++)
            {
                if (bufferList->mBuffers[i].mData)
                {
                    free(bufferList->mBuffers[i].mData);
                }
            }
        }
        free(bufferList);
    }
    bufferList = NULL;
}

+ (void)freeFloatBuffers:(float **)buffers numberOfChannels:(UInt32)channels
{
    if (!buffers || !*buffers)
    {
        return;
    }
    
    for (int i = 0; i < channels; i++)
    {
        free(buffers[i]);
    }
    free(buffers);
}

+ (AudioStreamBasicDescription)floatFormatWithNumberOfChannels:(UInt32)channels
                                                    sampleRate:(float)sampleRate
{
    AudioStreamBasicDescription asbd;
    UInt32 floatByteSize   = sizeof(float);
    asbd.mBitsPerChannel   = 8 * floatByteSize;
    asbd.mBytesPerFrame    = floatByteSize;
    asbd.mBytesPerPacket   = floatByteSize;
    asbd.mChannelsPerFrame = channels;
    asbd.mFormatFlags      = kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFramesPerPacket  = 1;
    asbd.mSampleRate       = sampleRate;
    return asbd;
}

+ (BOOL)isInterleaved:(AudioStreamBasicDescription)asbd
{
    return !(asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved);
}

+ (void)checkResult:(OSStatus)result operation:(const char *)operation
{
    if (result == noErr) return;
    char errorString[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(result);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4]))
    {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(errorString, "%d", (int)result);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
}

@end
