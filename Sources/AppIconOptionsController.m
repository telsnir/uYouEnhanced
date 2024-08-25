// AppIconOptionsController.m
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SpringBoard/SpringBoard.h>
#import <objc/runtime.h>
#import <sys/utsname.h>

#define kAppIconOptionsControllerKey @"AppIconOptionsController"

@interface AppIconOptionsController : UIViewController

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray<NSString *> *appIcons;
@property (assign, nonatomic) NSInteger selectedIconIndex;

@end

@implementation AppIconOptionsController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Change App Icon";
    self.view.backgroundColor = [UIColor whiteColor];
    self.selectedIconIndex = -1;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    self.appIcons = [self getAppIcons];
    if (![UIApplication sharedApplication].supportsAlternateIcons) {
        NSLog(@"Alternate icons are not supported on this device.");
        return;
    }
}
- (NSArray<NSString *> *)getAppIcons {
    NSMutableArray *icons = [NSMutableArray array];
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray *iconFiles = [bundle pathsForResourcesOfType:@"png" inDirectory:@"AppIcons"];
    
    for (NSString *iconFile in iconFiles) {
        [icons addObject:iconFile];
    }
    
    return [icons copy];
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.appIcons.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AppIconCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AppIconCell"];
    }
    NSString *iconPath = self.appIcons[indexPath.row];
    cell.textLabel.text = [iconPath.lastPathComponent stringByDeletingPathExtension];
    UIImage *iconImage = [UIImage imageWithContentsOfFile:iconPath];
    cell.imageView.image = iconImage;
    cell.imageView.layer.cornerRadius = 10.0;
    cell.imageView.clipsToBounds = YES;
    cell.imageView.frame = CGRectMake(10, 10, 40, 40);
    cell.textLabel.frame = CGRectMake(60, 10, self.view.frame.size.width - 70, 40);
    if (indexPath.row == self.selectedIconIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }    
    return cell;
}
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedIconIndex = indexPath.row;
    [self.tableView reloadData];
}
#pragma mark - Icon Change Methods
- (void)saveIcon {
    if (self.selectedIconIndex < 0 || self.selectedIconIndex >= self.appIcons.count) {
        NSLog(@"No icon selected.");
        return;
    }
    NSString *selectedIconPath = self.appIcons[self.selectedIconIndex];
    NSString *iconName = [selectedIconPath.lastPathComponent stringByDeletingPathExtension];
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    [infoDict setObject:iconName forKey:@"ALTAppIcon"];
    [infoDict writeToFile:plistPath atomically:YES];
    [[UIApplication sharedApplication] setAlternateIconName:iconName completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error setting alternate icon: %@", error.localizedDescription);
        } else {
            NSLog(@"Alternate icon set successfully.");
        }
    }];
}
- (void)resetIcon {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    [infoDict removeObjectForKey:@"ALTAppIcon"];
    [infoDict writeToFile:plistPath atomically:YES];
    [[UIApplication sharedApplication] setAlternateIconName:nil completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error resetting icon: %@", error.localizedDescription);
        } else {
            NSLog(@"Icon reset successfully.");
        }
    }];
}
+ (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}
+ (SBApplication *)getSpringBoard {
    Class springBoardClass = NSClassFromString(@"SBApplication");
    return (SBApplication *)[springBoardClass performSelector:NSSelectorFromString(@"sharedApplication")];
}
+ (SBIconController *)getIconController {
    SBApplication *springBoard = [self getSpringBoard];
    if (springBoard) {
        return (SBIconController *)[springBoard performSelector:NSSelectorFromString(@"_iconController")];
    }
    return nil;
}
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self addAppIconOptionsButtonToSpringBoard];
    });
}
+ (void)addAppIconOptionsButtonToSpringBoard {
    dispatch_async(dispatch_get_main_queue(), ^{
        SBApplication *springBoard = [self getSpringBoard];
        SBIconController *iconController = [self getIconController];
        UIButton *appIconOptionsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [appIconOptionsButton setTitle:@"App Icons" forState:UIControlStateNormal];
        [appIconOptionsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [appIconOptionsButton addTarget:self action:@selector(presentAppIconOptionsViewController) forControlEvents:UIControlEventTouchUpInside];
        appIconOptionsButton.frame = CGRectMake(100, 100, 100, 50);
        [springBoard.view addSubview:appIconOptionsButton];
    });
}
+ (void)presentAppIconOptionsViewController {
    SBApplication *springBoard = [self getSpringBoard];
    AppIconOptionsController *appIconOptionsController = [[AppIconOptionsController alloc] init];
    UIViewController *rootViewController = springBoard.rootViewController;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:appIconOptionsController];
    [rootViewController presentViewController:navigationController animated:YES completion:nil];
}
@end
