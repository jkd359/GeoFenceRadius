
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>

@class RegionsViewController;

@interface RegionsAppDelegate : NSObject <UIApplicationDelegate, CLLocationManagerDelegate> {
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
    NSPersistentStoreCoordinator *psc;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RegionsViewController *viewController;

@property (retain, nonatomic) NSManagedObjectContext * context;
@property (retain, nonatomic) NSPersistentStoreCoordinator * psc;
@property (retain, nonatomic) NSManagedObjectModel * model;


@end
