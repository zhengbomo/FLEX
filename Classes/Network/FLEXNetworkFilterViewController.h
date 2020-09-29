//
//  FLEXNetworkFilterViewController.h
//  FLEX
//
//  Created by 郑贤凯 on 2020/9/29.
//

#import "FLEXTableViewController.h"

typedef void(^FLEXNetworkFilterCallback)(NSArray<NSString *> * _Nullable method, NSArray<NSString *> * _Nullable domain);

@interface FLEXNetworkFilterViewController : FLEXTableViewController

@property (nonatomic, copy, nonnull) NSArray<NSString *> * methods;
@property (nonatomic, copy, nonnull) NSArray<NSString *> *domains;

/// required
@property (nonatomic, copy, nonnull) FLEXNetworkFilterCallback callback;

- (void)updateSelectedMethods:(NSArray *)methods domains:(NSArray *)domains;

@end
