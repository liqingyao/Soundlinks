//
//  SLAlgorithm.h
//  microhoneTest
//
//  Created by LiQingyao on 16/2/22.
//  Copyright © 2016年 Pheroant. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SLAlgorithm : NSObject

+ (void)initAlgorithmWithBufferSize:(UInt32)bufferSize;

+ (int)detectedDataWithBuffer:(float *)inBuffer andBufferSize:(UInt32)bufferSize;

@end
