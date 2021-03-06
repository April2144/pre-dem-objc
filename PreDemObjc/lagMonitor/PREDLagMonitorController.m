//
//  PREDLagMonitorController.m
//  Pods
//
//  Created by WangSiyu on 06/07/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDLagMonitorController.h"
#import <CrashReporter/CrashReporter.h>
#import "PREDCrashReportTextFormatter.h"
#import "PREDHelper.h"
#import <Qiniu/QiniuSDK.h>
#import "PREDLogger.h"

@implementation PREDLagMonitorController {
    CFRunLoopObserverRef _observer;
    dispatch_semaphore_t _semaphore;
    CFRunLoopActivity _activity;
    NSInteger _countTime;
    PREPLCrashReporter *_reporter;
    PREDPersistence *_persistence;
    QNUploadManager *_uploadManager;
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    PREDLagMonitorController *instrance = (__bridge PREDLagMonitorController *)info;
    instrance->_activity = activity;
    // 发送信号
    dispatch_semaphore_t semaphore = instrance->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

- (instancetype)initWithPersistence:(PREDPersistence *)persistence {
    if (self = [super init]) {
        PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;
        PREPLCrashReporterConfig *config = [[PREPLCrashReporterConfig alloc] initWithSignalHandlerType: signalHandlerType
                                                                                 symbolicationStrategy: PLCrashReporterSymbolicationStrategyAll];
        _reporter = [[PREPLCrashReporter alloc] initWithConfiguration:config];
        _persistence = persistence;
        _uploadManager = [[QNUploadManager alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self endMonitor];
}

- (void)startMonitor {
    if (_observer) {
        return;
    }
    [self registerObserver];
}

- (void)endMonitor {
    if (!_observer) {
        return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

- (void)registerObserver {
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &runLoopObserverCallBack,
                                        &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    // 创建信号
    _semaphore = dispatch_semaphore_create(0);
    
    // 在子线程监控时长
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (YES) {
            // 假定连续5次超时50ms认为卡顿(当然也包含了单次超时250ms)
            long st = dispatch_semaphore_wait(_semaphore, dispatch_time(DISPATCH_TIME_NOW, 50*NSEC_PER_MSEC));
            if (st != 0) {
                if (_activity==kCFRunLoopBeforeSources || _activity==kCFRunLoopAfterWaiting) {
                    if (++_countTime < 5)
                        continue;
                    [self sendLagStack];
                }
            }
            _countTime = 0;
        }
    });
}

- (void)sendLagStack {
    NSError *error;
    NSData *data = [_reporter generateLiveReportAndReturnError:&error];
    if (error) {
        PREDLogError(@"generate lag report error: %@", error);
        return;
    }
    PREDLagMeta *meta = [[PREDLagMeta alloc] initWithData:data error:&error];
    if (error) {
        PREDLogError(@"parse lag report error: %@", error);
        return;
    }
    [_persistence persistLagMeta:meta];
}

@end
