#import <UIKit/UIKit.h>
#import <CydiaSubstrate/CydiaSubstrate.h>
#import <YouTubeHeader/YTAssetLoader.h>
#import "AppIconOptionsController.h"

@interface AppIconOptionsController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *appIcons;
@property (nonatomic, assign) NSInteger selectedIconIndex;

@end

@implementation AppIconOptionsController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Change App Icon";

    self.selectedIconIndex = -1;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    self.appIcons = [self loadAppIcons];
    
    if (![UIApplication sharedApplication].supportsAlternateIcons) {
        NSLog(@"Alternate icons are not supported on this device.");
    }
}

- (NSArray *)loadAppIcons {
    // Assuming you have your custom icons in a bundle named "AppIcons" inside your tweak
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"AppIcons" ofType:@"bundle"]];
    if (bundle) {
        return [bundle pathsForResourcesOfType:@"png" inDirectory:nil];
    } else {
        NSLog(@"Error loading app icons bundle");
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.appIcons.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedIconIndex = indexPath.row;
    [self.tableView reloadData];
}

- (void)saveIcon {
    if (![UIApplication sharedApplication].supportsAlternateIcons) {
        NSLog(@"Alternate icons are not supported on this device.");
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *selectedIcon = self.selectedIconIndex >= 0 ? self.appIcons[self.selectedIconIndex] : nil;
        if (selectedIcon) {
            NSString *iconName = [selectedIcon.lastPathComponent stringByDeletingPathExtension];
            
            LSApplicationWorkspace *workspace = [LSApplicationWorkspace defaultWorkspace];
            [workspace setAlternateIconName:iconName forApplicationWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier] completionHandler:^(NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        NSLog(@"Error setting alternate icon: %@", error.localizedDescription);
                    } else {
                        NSLog(@"Alternate icon set successfully");
                    }
                });
            }];
        } else {
            NSLog(@"Selected icon path is nil");
        }
    });
}

- (void)resetIcon {
    if (![UIApplication sharedApplication].supportsAlternateIcons) {
        NSLog(@"Alternate icons are not supported on this device.");
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        LSApplicationWorkspace *workspace = [LSApplicationWorkspace defaultWorkspace];
        [workspace setAlternateIconName:nil forApplicationWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier] completionHandler:^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    NSLog(@"Error resetting icon: %@", error.localizedDescription);
                } else {
                    NSLog(@"Icon reset successfully");
                }
            });
        }];
    });
}

@end
