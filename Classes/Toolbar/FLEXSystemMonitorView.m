//
//  FLEXSystemMonitorView.m
//  FLEX
//
//  Created by bomo on 2020/9/11.
//

#import "FLEXSystemMonitorView.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXResources.h"
#import "FLEXNavigationController.h"
#import "FLEXExplorerViewController.h"
#import "FLEXSystemLogViewController.h"
#import "FLEXManager+Private.h"
#import "FLEXColor.h"
#include <mach/mach_types.h>
#include <mach/mach_init.h>
#include <mach/task.h>
#include <mach/vm_map.h>
#include <mach/thread_act.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <net/if_var.h>
#include <sys/socket.h>


@interface FLEXSystemMonitorItemView: UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;
- (void)updateContent:(NSString *)content;
- (void)updateTitle:(NSString *)title content:(NSString *)content;

@end

@interface FLEXSystemMonitorView ()

@property (nonatomic, strong) CADisplayLink *dLink;

@property (nonatomic, copy) NSArray<UIView *> *toolbarItems;

@property (nonatomic, strong) FLEXSystemMonitorItemView *fpsItem;
@property (nonatomic, strong) FLEXSystemMonitorItemView *cpuItem;
@property (nonatomic, strong) FLEXSystemMonitorItemView *memoryItem;
@property (nonatomic, strong) FLEXSystemMonitorItemView *networkItem;
@property (nonatomic, strong) FLEXExplorerToolbarItem *logItem;
@property (nonatomic, strong) FLEXExplorerToolbarItem *netMonitorItem;



@end

@implementation FLEXSystemMonitorView

+ (void)load {
    // first time
    uint64_t a, b;
    [FLEXSystemMonitorView networkInBytes:&a outBytes:&b];
}

+ (CGFloat)viewHeight {
    return 44 * 2;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.cpuItem = [[FLEXSystemMonitorItemView alloc] init];
        self.memoryItem = [[FLEXSystemMonitorItemView alloc] init];
        self.fpsItem = [[FLEXSystemMonitorItemView alloc] init];
        self.networkItem = [[FLEXSystemMonitorItemView alloc] init];
        self.networkItem.valueLabel.font = [UIFont systemFontOfSize:10];
        
        self.logItem = [FLEXExplorerToolbarItem itemWithTitle:@"Log" image:FLEXResources.globalsIcon];
        self.netMonitorItem = [FLEXExplorerToolbarItem itemWithTitle:@"Net" image:FLEXResources.globalsIcon];
        
        [self.logItem addTarget:self action:@selector(showLog) forControlEvents:UIControlEventTouchUpInside];
        [self.netMonitorItem addTarget:self action:@selector(showNetMonitor) forControlEvents:UIControlEventTouchUpInside];
        
        [self.cpuItem updateTitle:@"CPU" content:@""];
        [self.memoryItem updateTitle:@"Memory" content:@""];
        [self.fpsItem updateTitle:@"FPS" content:@""];
        [self.networkItem updateTitle:@"Network" content:@""];
        [self.networkItem updateTitle:@"Network" content:@""];
        
        
        self.toolbarItems = @[
            self.cpuItem, self.memoryItem, self.fpsItem, self.networkItem, self.logItem, self.netMonitorItem
        ];
        
        for (UIView *toolbarItem in self.toolbarItems) {
            [self addSubview:toolbarItem];
        }
        
        [self start];
    }
    return self;
}

- (void)showLog {
    FLEXSystemLogViewController *vc = [[FLEXSystemLogViewController alloc] init];
    FLEXNavigationController *navVC = [FLEXNavigationController withRootViewController:vc];
    [FLEXManager.sharedManager.explorerViewController presentViewController:navVC animated:YES completion:nil];
}

- (void)showNetMonitor {
    UIViewController *vc = [[FLEXNetworkMITMViewController alloc] init];
    FLEXNavigationController *navVC = [FLEXNavigationController withRootViewController:vc];
    [FLEXManager.sharedManager.explorerViewController presentViewController:navVC animated:YES completion:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat height = 44;
    CGFloat width = self.bounds.size.width / self.toolbarItems.count;
    CGFloat originX = 0;
    for (UIView *toolbarItem in self.toolbarItems) {
        CGRect frame = CGRectMake(originX, 0, width, height);
        toolbarItem.frame = frame;
        originX = CGRectGetMaxX(frame);
    }
}

- (void)start {
    self.dLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fpsCount:)];
    [self.dLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stop {
    [self.dLink invalidate];
}

- (NSInteger)fps {
    return _fps;
}

static NSInteger _fps = 0;

- (void)fpsCount:(CADisplayLink *)displayLink {
    static int total = 0;
    static NSTimeInterval lastTimeStamp;
    
    if (lastTimeStamp == 0) {
        lastTimeStamp = self.dLink.timestamp;
    } else {
        total++;
        // 开始渲染时间与上次渲染时间差值
        NSTimeInterval useTime = self.dLink.timestamp - lastTimeStamp;
        if (useTime < 1) return;
        lastTimeStamp = self.dLink.timestamp;
        // fps 计算
        _fps = total / useTime;
        total = 0;
    }
    NSString *fpsMsg = [NSString stringWithFormat:@"%@", @(_fps)];
    [self.fpsItem updateContent:fpsMsg];
    
    NSString *cpuMsg = [NSString stringWithFormat:@"%@%%", @(FLEXSystemMonitorView.cpuUsage)];
    [self.cpuItem updateContent:cpuMsg];
    
    uint64_t memoryByte = FLEXSystemMonitorView.memoryUsage;
    NSString *memoryMsg = [self descForBytes:memoryByte];
    [self.memoryItem updateContent:memoryMsg];
    
    // 网络流量
    uint64_t netInBytes = 0;
    uint64_t netOutBytes = 0;
    [FLEXSystemMonitorView networkInBytes:&netInBytes outBytes:&netOutBytes];
    NSString *netMsg = [NSString stringWithFormat:@"↓%@\n↑%@", [self descForBytes:netInBytes], [self descForBytes:netOutBytes]];
    [self.networkItem updateContent:netMsg];
}

- (NSString *)descForBytes:(uint64_t)bytes {
    if (bytes < 1024) {
        return [NSString stringWithFormat:@"%.2fB", bytes * 1.0];
    } else if (bytes < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.2fKB", bytes / 1024.0];
    } else if (bytes < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.2fMB", bytes / 1024.0 / 1024];
    } else {
        return [NSString stringWithFormat:@"%.2fGB", bytes / 1024.0 / 1024 / 1024];
    }
}

/// 内存占用
+ (uint64_t)memoryUsage {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if (result != KERN_SUCCESS)
        return 0;
    return vmInfo.phys_footprint;
}

/// CPU占用
+ (integer_t)cpuUsage {
    thread_act_array_t threads; //int 组成的数组比如 thread[1] = 5635
    mach_msg_type_number_t threadCount = 0; //mach_msg_type_number_t 是 int 类型
    const task_t thisTask = mach_task_self();
    //根据当前 task 获取所有线程
    kern_return_t kr = task_threads(thisTask, &threads, &threadCount);
    
    if (kr != KERN_SUCCESS) {
        return 0;
    }
    
    integer_t cpuUsage = 0;
    // 遍历所有线程
    for (int i = 0; i < threadCount; i++) {
        
        thread_info_data_t threadInfo;
        thread_basic_info_t threadBaseInfo;
        mach_msg_type_number_t threadInfoCount = THREAD_INFO_MAX;
        
        if (thread_info((thread_act_t)threads[i], THREAD_BASIC_INFO, (thread_info_t)threadInfo, &threadInfoCount) == KERN_SUCCESS) {
            // 获取 CPU 使用率
            threadBaseInfo = (thread_basic_info_t)threadInfo;
            if (!(threadBaseInfo->flags & TH_FLAGS_IDLE)) {
                cpuUsage += threadBaseInfo->cpu_usage;
            }
        }
    }
    assert(vm_deallocate(mach_task_self(), (vm_address_t)threads, threadCount * sizeof(thread_t)) == KERN_SUCCESS);
    return cpuUsage;
}

static uint64_t originInByte = 0;
static uint64_t originOutByte = 0;

/// 网络流量
+ (void)networkInBytes:(uint64_t *)inBytes outBytes:(uint64_t *)outBytes {
    struct ifaddrs *ifa_list = 0, *ifa;
    if (getifaddrs(&ifa_list) == -1) {
        return;
    }
   
    uint64_t iBytes = 0;
    uint64_t oBytes = 0;
   
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            continue;
        if (ifa->ifa_data == 0)
            continue;
       
        
        NSString *name = @(ifa->ifa_name);
        if ([name hasPrefix:@"en"]) {
            // WIFI
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            iBytes += if_data->ifi_ibytes;
            oBytes += if_data->ifi_obytes;
        } else if ([name hasPrefix:@"pdp_ip"]) {
            // WWAN
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            iBytes += if_data->ifi_ibytes;
            oBytes += if_data->ifi_obytes;
        }
    }
    
    if (originInByte == 0) {
        originInByte = iBytes;
        originOutByte = oBytes;
    }
    
    freeifaddrs(ifa_list);
    
    *inBytes = iBytes - originInByte;
    *outBytes = oBytes - originOutByte;
}


@end

@implementation FLEXSystemMonitorItemView

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        self.userInteractionEnabled = NO;
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.textColor = FLEXColor.primaryTextColor;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:self.titleLabel];
        
        self.valueLabel = [[UILabel alloc] init];
        self.valueLabel.numberOfLines = 0;
        self.valueLabel.adjustsFontSizeToFitWidth = YES;
        self.valueLabel.textColor = FLEXColor.primaryTextColor;
        self.valueLabel.textAlignment = NSTextAlignmentCenter;
        self.valueLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:self.valueLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.bounds.size;
    
    CGFloat valuePercent = 0.7;
    self.valueLabel.frame = CGRectMake(0, 0, size.width, size.height * valuePercent);
    self.titleLabel.frame = CGRectMake(0, size.height * valuePercent, size.width, size.height * (1 - valuePercent));
}

- (void)updateTitle:(NSString *)title content:(NSString *)content {
    self.titleLabel .text = title;
    self.valueLabel.text = content;
}

- (void)updateContent:(NSString *)content {
    self.valueLabel.text = content;
}




@end
