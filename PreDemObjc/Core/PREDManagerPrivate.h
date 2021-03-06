//
//  PREDManagerPrivate.h
//  PreDemObjc
//
//  Created by Troy on 2017/6/27.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#ifndef PREDManagerPrivate_h
#define PREDManagerPrivate_h

#import "PREDManager.h"
#import "PREDConfigManager.h"
#import "PREDNetworkClient.h"

#define PREDAppIdLength     8

@interface PREDManager ()

+ (PREDManager *_Nonnull)sharedPREDManager;

@property (nonatomic, getter = isCrashManagerEnabled) BOOL enableCrashManager;

@property (nonatomic, getter = isHttpMonitorEnabled) BOOL enableHttpMonitor;

@property (nonatomic, getter = isLagMonitorEnabled) BOOL enableLagMonitor;

@property (readonly, nonatomic, nonnull) NSString* appKey;

@end

#endif /* PREDManagerPrivate_h */
