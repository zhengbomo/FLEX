//
//  FLEXSystemMonitorView.m
//  FLEX
//
//  Created by bomo on 2020/9/11.
//

#import "FLEXSystemMonitorView.h"
#import "FLEXResources.h"
#include <mach/mach_types.h>
#include <mach/mach_init.h>
#include <mach/task.h>
#include <mach/vm_map.h>
#include <mach/thread_act.h>

@interface FLEXSystemMonitorItemView: UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;
- (void)updateContent:(NSString *)content;
- (void)updateTitle:(NSString *)title content:(NSString *)content;

@end

@interface FLEXSystemMonitorView ()

@property (nonatomic, strong) CADisplayLink *dLink;

@property (nonatomic, copy) NSArray<FLEXSystemMonitorItemView *> *toolbarItems;

@property (nonatomic, strong) FLEXSystemMonitorItemView *fpsItem;
@property (nonatomic, strong) FLEXSystemMonitorItemView *cpuItem;
@property (nonatomic, strong) FLEXSystemMonitorItemView *memoryItem;

@end

@implementation FLEXSystemMonitorView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.cpuItem = [[FLEXSystemMonitorItemView alloc] init];
        self.memoryItem = [[FLEXSystemMonitorItemView alloc] init];
        self.fpsItem = [[FLEXSystemMonitorItemView alloc] init];
        
        
        [self.cpuItem updateTitle:@"CPU" content:@""];
        [self.memoryItem updateTitle:@"MEM" content:@""];
        [self.fpsItem updateTitle:@"FPS" content:@""];
        
        self.toolbarItems = @[
            self.cpuItem, self.memoryItem, self.fpsItem
        ];
        
        for (FLEXSystemMonitorItemView *toolbarItem in self.toolbarItems) {
            [self addSubview:toolbarItem];
        }
        
        [self start];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width / self.toolbarItems.count;
    CGFloat originX = 0;
    for (FLEXSystemMonitorItemView *toolbarItem in self.toolbarItems) {
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
    uint64_t memoryMB = memoryByte / 1024 / 1024;
    NSString *memoryMsg = [NSString stringWithFormat:@"%@MB", @(memoryMB)];
    [self.memoryItem updateContent:memoryMsg];
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

@end

@implementation FLEXSystemMonitorItemView

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.textColor = UIColor.blackColor;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:self.titleLabel];
        
        self.valueLabel = [[UILabel alloc] init];
        self.valueLabel.textColor = UIColor.blackColor;
        self.valueLabel.textAlignment = NSTextAlignmentCenter;
        self.valueLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:self.valueLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.bounds.size;
    
    self.valueLabel.frame = CGRectMake(0, 0, size.width, size.height * 0.5);
    self.titleLabel.frame = CGRectMake(0, size.height * 0.5, size.width, size.height * 0.5);
}

- (void)updateTitle:(NSString *)title content:(NSString *)content {
    self.titleLabel .text = title;
    self.valueLabel.text = content;
}

- (void)updateContent:(NSString *)content {
    self.valueLabel.text = content;
}




@end
