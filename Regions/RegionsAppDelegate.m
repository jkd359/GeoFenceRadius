

#import "RegionsAppDelegate.h"
#import "RegionsViewController.h"

@implementation RegionsAppDelegate

@synthesize window;

@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
    [self setupPersistentStore];
    context = [NSManagedObjectContext new];
    [context setPersistentStoreCoordinator:psc];
    
    // Override point for customization after application launch.
	[self.viewController setContext:context];
	self.window.rootViewController = self.viewController;
	[self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
	
	// Reset the icon badge number to zero.
	[UIApplication sharedApplication].applicationIconBadgeNumber = 0;
	
	if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
		// Stop normal location updates and start significant location change updates for battery efficiency.
		[viewController.locationManager stopUpdatingLocation];
		[viewController.locationManager startMonitoringSignificantLocationChanges];
	}
	else {
		NSLog(@"Significant location change monitoring is not available.");
	}
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	
	if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
		// Stop significant location updates and start normal location updates again since the app is in the forefront.
		[viewController.locationManager stopMonitoringSignificantLocationChanges];
		[viewController.locationManager startUpdatingLocation];
	}
	else {
		NSLog(@"Significant location change monitoring is not available.");
	}
	
	if (!viewController.updatesTableView.hidden) {
		// Reload the updates table view to reflect update events that were recorded in the background.
		[viewController.updatesTableView reloadData];
			
		// Reset the icon badge number to zero.
		[UIApplication sharedApplication].applicationIconBadgeNumber = 0;
	}
}


- (void)applicationWillResignActive:(UIApplication *)application {
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    NSError *error;
    if (context != nil)
    {
        if ([context hasChanges] && ![context save:&error])
        {
			// Handle error.
        }
    }
}

- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(void)setupPersistentStore;
{
    NSString *docDir = [self applicationDocumentsDirectory];
    NSString *pathToDb = [docDir stringByAppendingPathComponent:
                          @"FaveCities.sqlite"];
    NSURL *urlForPath = [NSURL fileURLWithPath:pathToDb];
    
	NSError *error;
    psc = [[NSPersistentStoreCoordinator alloc]
           initWithManagedObjectModel:[self model]];
    if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:urlForPath
                                 options:nil
                                   error:&error])
    {
        // Handle error
    }
}

- (void)application:(UIApplication *)application
didReceiveLocalNotification:(UILocalNotification *)notification
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Memory Detected!"
                                                        message:notification.alertBody
                                                       delegate:self cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    if (alertView) {
        [alertView release];
    }
}

- (void)dealloc {
	[window release];
	[viewController release];
    [super dealloc];
}

@end
