//
//  FLEXNetworkFilterViewController.m
//  FLEX
//
//  Created by 郑贤凯 on 2020/9/29.
//

#import "FLEXNetworkFilterViewController.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkObserver.h"
#import "NSUserDefaults+FLEX.h"
#import "FLEXColor.h"
#import "FLEXAlert.h"
#import "FLEXMacros.h"

@interface FLEXNetworkFilterViewController ()

@property (nonatomic, strong) NSMutableArray<NSString *> *selectedDomains;
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedMethods;

@end

@implementation FLEXNetworkFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self disableToolbar];
    
    self.navigationItem.title = @"Network Filter";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"OK" style:UIBarButtonItemStylePlain target:self action:@selector(ok)];
}

- (void)ok {
    if (self.callback) {
        self.callback(self.selectedMethods, self.selectedDomains);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateSelectedMethods:(NSArray *)methods domains:(NSArray *)domains {
    self.selectedMethods = [methods mutableCopy];
    self.selectedDomains = [domains mutableCopy];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.domains.count > 0) {
        if (self.methods.count > 0) {
            return 2;
        } else {
            return 1;
        }
    } else if (self.methods.count > 0) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return self.methods.count;
        case 1: return self.domains.count;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"METHOD";
        case 1: return @"DOMAIN";
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = [self.tableView
        dequeueReusableCellWithIdentifier:kFLEXDefaultCell forIndexPath:indexPath
    ];
    
    switch (indexPath.section) {
        // method
        case 0: {
            NSString *method = self.methods[indexPath.row];
            if ([self.selectedMethods containsObject:method]) {
                cell.textLabel.textColor = cell.tintColor;
            } else {
                cell.textLabel.textColor = FLEXColor.primaryTextColor;
            }
            cell.textLabel.text = self.methods[indexPath.row];
            break;
        }
        // Domains
        case 1: {
            NSString *domain = self.domains[indexPath.row];
            if ([self.selectedDomains containsObject:domain]) {
                cell.textLabel.textColor = cell.tintColor;
            } else {
                cell.textLabel.textColor = FLEXColor.primaryTextColor;
            }
            cell.textLabel.text = self.domains[indexPath.row];
            break;
        }
        default:
            @throw NSInternalInconsistencyException;
            break;
    }

    return cell;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0: {
            NSString *method = self.methods[indexPath.row];
            if ([self.selectedMethods containsObject:method]) {
                [self.selectedMethods removeObject:method];
            } else {
                [self.selectedMethods addObject:method];
            }
            break;
        }
        case 1: {
            NSString *domain = self.domains[indexPath.row];
            if ([self.selectedDomains containsObject:domain]) {
                [self.selectedDomains removeObject:domain];
            } else {
                [self.selectedDomains addObject:domain];
            }
            break;
        }
        default:
            break;
    }
    
    NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:indexPath.section];
    [tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
}

- (NSMutableArray<NSString *> *)selectedDomains {
    if (_selectedDomains == nil) {
        _selectedDomains = [NSMutableArray array];
    }
    return _selectedDomains;
}

- (NSMutableArray<NSString *> *)selectedMethods {
    if (_selectedMethods == nil) {
        _selectedMethods = [NSMutableArray array];
    }
    return _selectedMethods;
}

@end

