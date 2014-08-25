

#import "RegionsViewController.h"
#import "RegionAnnotationView.h"
#import "RegionAnnotation.h"
#import "MyCircle.h"
#include "../LocationController.h"

@implementation RegionsViewController

@synthesize regionsMapView, updatesTableView, updateEvents, locationManager, context, tabBar;

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
	[updateEvents release];
	self.locationManager.delegate = nil;
	[locationManager release];
	[regionsMapView release];
	[updatesTableView release];
    [tabBar release];
    [super dealloc];
}

#pragma mark - View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"TitleUpdated" object:nil queue:nil usingBlock:^(NSNotification * a){
        [self updateStoredRegion:a.object];
        [self updateRegionsInRange];
    }];
    
    
    
    [tabBar setSelectedItem:[tabBar.items objectAtIndex:0]];
	
	// Create empty array to add region events to.
	updateEvents = [[NSMutableArray alloc] initWithCapacity:0];
	
	// Create location manager with filters set for battery efficiency.
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
	locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	
	// Start updating location changes.
	[locationManager startUpdatingLocation];
    
    // Satellite View
    regionsMapView.mapType = MKMapTypeSatellite;
    
    // Setup a long press gesture recognizer on the map
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = .5; //user needs to press for 2 seconds
    [self.regionsMapView addGestureRecognizer:lpgr];
    [lpgr release];
    
    [self setupModel];
}


- (void)viewDidAppear:(BOOL)animated {

    
	// Iterate through the regions and add annotations to the map for each of them.
	for (int i = 0; i < [self.locations count]; i++) {
        StoredLocation *loc = (StoredLocation *)[self.locations objectAtIndex:i];
		CLRegion *region = loc.location;
		RegionAnnotation *annotation = [[RegionAnnotation alloc] initWithCLRegion:region andTitle:loc.name];
		[regionsMapView addAnnotation:annotation];
        
		//[annotation release];
	}
    

    // TODO - check all the tracked regions, and make sure there are no zombies.
    // Get all regions being monitored for this application.
	//NSArray *regions = [[locationManager monitoredRegions] allObjects];
}


- (void)viewDidUnload {
    [self setTabBar:nil];
	self.updateEvents = nil;
	self.locationManager.delegate = nil;
	self.locationManager = nil;
	self.regionsMapView = nil;
	self.updatesTableView = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - CoreData

-(void)setupModel;
{
    NSError *error;
    NSFetchRequest *req = [NSFetchRequest new];
    NSEntityDescription *descr = [NSEntityDescription entityForName:@"StoredLocation"
                                             inManagedObjectContext:context];
    [req setEntity:descr];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                         ascending:YES];
    [req setSortDescriptors:[NSArray arrayWithObject:sort]];
    [sort release];
    
    [self setLocations:[[context executeFetchRequest:req error:&error]
                     mutableCopy]];
    
    if([[self locations] count] == 0)
    {
        // set up default data
        StoredLocation *location;
        
        // Starkey
        location = [NSEntityDescription
                 insertNewObjectForEntityForName:@"StoredLocation"
                 inManagedObjectContext:context];
        [location setName:@"Starkey Laboratories"];
        [location setLocation:[[CLRegion alloc] initCircularRegionWithCenter:CLLocationCoordinate2DMake(44.88344968, -93.40300705) radius:100 identifier:@"Starkey"]];
        
        [locationManager startMonitoringForRegion:location.location desiredAccuracy:kCLLocationAccuracyBest];
        
        // Braemar
        location = [NSEntityDescription
                    insertNewObjectForEntityForName:@"StoredLocation"
                    inManagedObjectContext:context];
        [location setName:@"Braemar Golf Club"];
        [location setLocation:[[CLRegion alloc] initCircularRegionWithCenter:CLLocationCoordinate2DMake(44.8680,-93.3858) radius:635 identifier:@"Braemar"]];

        [locationManager startMonitoringForRegion:location.location desiredAccuracy:kCLLocationAccuracyBest];
        
        [context save:&error];
        
        [self setLocations:[[context executeFetchRequest:req error:&error]
                         mutableCopy]];
    }
}


#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0)  // 0 == the cancel button
    {
        //  Since we don't have a pointer to the textfield, we're
        //  going to need to traverse the subviews to find our
        //  UITextField in the hierarchy
        for (UIView* view in alertView.subviews)
        {
            if ([view isKindOfClass:[UITextField class]])
            {
                UITextField* textField = (UITextField*)view;
                
                RegionAnnotation * regionAnnotation = (RegionAnnotation *)selectedRegion.annotation;
                [regionAnnotation setTitle:textField.text];
                
                [locationManager stopMonitoringForRegion:regionAnnotation.region];
                
                CLRegion *newRegion = [[CLRegion alloc] initCircularRegionWithCenter:regionAnnotation.region.center radius:regionAnnotation.region.radius identifier:regionAnnotation.region.identifier];
                regionAnnotation.region = newRegion;
                
                [self updateStoredRegion:regionAnnotation];
                [self updateRegionsInRange];
                // TODO [newRegion release];
                
                [locationManager startMonitoringForRegion:regionAnnotation.region desiredAccuracy:kCLLocationAccuracyBest];

                break;
            }
        }
    }
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.locations count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    StoredLocation * loc = (StoredLocation *)[self.locations objectAtIndex:indexPath.row];
    
    CLLocationCoordinate2D curLoc = regionsMapView.userLocation.coordinate;
    
    
    if([loc.location containsCoordinate:curLoc])
    {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.userInteractionEnabled = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else
    {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.font = [UIFont italicSystemFontOfSize:18.0];
        cell.userInteractionEnabled = NO;
    }
    
    if([loc selected])
    {
        [tableView selectRowAtIndexPath:indexPath animated:false scrollPosition:UITableViewScrollPositionNone];
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FullStar"]];
    }
    else{
        cell.selected = NO;
        cell.accessoryView = nil;
    }
    
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 0;
    
	cell.textLabel.text = loc.name;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    StoredLocation * loc = (StoredLocation *)[self.locations objectAtIndex:indexPath.row];
    loc.selected = YES;
    
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FullStar"]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    StoredLocation * loc = (StoredLocation *)[self.locations objectAtIndex:indexPath.row];
    loc.selected = NO;
    
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryView = nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 60.0;
}


#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKAnnotationView* annotationView = [mapView viewForAnnotation:userLocation];
    annotationView.canShowCallout = NO;
    
    [self updateRegionsInRange];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {	
	if([annotation isKindOfClass:[RegionAnnotation class]]) {
		RegionAnnotation *currentAnnotation = (RegionAnnotation *)annotation;
		NSString *annotationIdentifier = [currentAnnotation title];
		RegionAnnotationView *regionView = (RegionAnnotationView *)[regionsMapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];	
		
		if (!regionView) {
			regionView = [[[RegionAnnotationView alloc] initWithAnnotation:annotation] autorelease];
			regionView.map = regionsMapView;
			
			// Create a button for the left callout accessory view of each annotation to remove the annotation and region being monitored.
			UIButton *removeRegionButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[removeRegionButton setFrame:CGRectMake(0., 0., 25., 25.)];
			[removeRegionButton setImage:[UIImage imageNamed:@"RemoveRegion"] forState:UIControlStateNormal];
            [removeRegionButton setTag:1];
            
            UIButton *editNameButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[editNameButton setFrame:CGRectMake(0., 0., 25., 25.)];
			[editNameButton setImage:[UIImage imageNamed:@"ID"] forState:UIControlStateNormal];
            [editNameButton setTag:2];
			
			regionView.leftCalloutAccessoryView = removeRegionButton;
            regionView.rightCalloutAccessoryView = editNameButton;
		} else {		
			regionView.annotation = annotation;
			regionView.theAnnotation = annotation;
		}
		
		// Update or add the overlay displaying the radius of the region around the annotation.
		[regionView updateRadiusOverlay:NO];
		
		return regionView;		
	}	
	
	return nil;	
}


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	if([overlay isKindOfClass:[MyCircle class]]) {
        MyCircle *c = (MyCircle *)overlay;
		// Create the view for the radius overlay.
		MKCircleView *circleView = [[[MKCircleView alloc] initWithOverlay:overlay] autorelease];
        
        if(c.selected){
            circleView.strokeColor = [UIColor redColor];
            circleView.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.4];
        }else{
            circleView.strokeColor = [UIColor purpleColor];
            circleView.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:0.4];
        }
		
		return circleView;		
	}
	
	return nil;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	if([annotationView isKindOfClass:[RegionAnnotationView class]]) {
		RegionAnnotationView *regionView = (RegionAnnotationView *)annotationView;
		RegionAnnotation *regionAnnotation = (RegionAnnotation *)regionView.annotation;
		
		// If the annotation view is starting to be dragged, remove the overlay and stop monitoring the region.
		if (newState == MKAnnotationViewDragStateStarting) {		
			[regionView removeRadiusOverlay];
			
			[locationManager stopMonitoringForRegion:regionAnnotation.region];
		}
		
		// Once the annotation view has been dragged and placed in a new location, update and add the overlay and begin monitoring the new region.
		if (oldState == MKAnnotationViewDragStateDragging && newState == MKAnnotationViewDragStateEnding) {
			[regionView updateRadiusOverlay:YES];
            
            [(RegionAnnotation *)annotationView.annotation updateTitle];
			
			CLRegion *newRegion = [[[CLRegion alloc] initCircularRegionWithCenter:regionAnnotation.coordinate radius:regionAnnotation.region.radius identifier:regionAnnotation.region.identifier] autorelease];
			regionAnnotation.region = newRegion;
			
			[locationManager startMonitoringForRegion:regionAnnotation.region desiredAccuracy:kCLLocationAccuracyBest];
            
            
            [regionAnnotation updateRegion:newRegion];

            [self updateStoredRegion:regionAnnotation];
            
            [self updateRegionsInRange];
            
		}		
	}	
}

-(void) addAndSaveNewRegion:(RegionAnnotation *)regionToUpdate
{
    StoredLocation *location = [NSEntityDescription
                                insertNewObjectForEntityForName:@"StoredLocation"
                                inManagedObjectContext:context];
    [location setName:regionToUpdate.title];
    [location setLocation:regionToUpdate.region];
    
    
    NSError *error;
    NSFetchRequest *req = [NSFetchRequest new];
    NSEntityDescription *descr = [NSEntityDescription entityForName:@"StoredLocation"
                                             inManagedObjectContext:context];
    [req setEntity:descr];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                         ascending:YES];
    [req setSortDescriptors:[NSArray arrayWithObject:sort]];
    [sort release];
    
    [context save:&error];
    
    [self setLocations:[[context executeFetchRequest:req error:&error]
                        mutableCopy]];

}

-(void) updateStoredRegion:(RegionAnnotation *)regionToUpdate
{
    StoredLocation *storedLoc = [self getStoredObjectForAnnotation:regionToUpdate.region];
    
    [context deleteObject:storedLoc];
    [[self locations] removeObject:storedLoc];
    
    [self addAndSaveNewRegion:regionToUpdate];
 }


-(StoredLocation *) getStoredObjectForAnnotation:(CLRegion *)region
{
    for (StoredLocation *i in [self locations])
    {
        if([i.location.identifier isEqualToString:region.identifier])
            return i;
        
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    
    RegionAnnotationView *regionView = (RegionAnnotationView *)view;
    RegionAnnotation *regionAnnotation = (RegionAnnotation *)regionView.annotation;
    
    if([control tag] == 1)
    {
        // Delete
        
        // Stop monitoring the region, remove the radius overlay, and finally remove the annotation from the map.
        [locationManager stopMonitoringForRegion:regionAnnotation.region];
        
        StoredLocation *storedLoc = [self getStoredObjectForAnnotation:regionAnnotation.region];
        
        [context deleteObject:storedLoc];
        [[self locations] removeObject:storedLoc];
        
        
        NSError *error;
        NSFetchRequest *req = [NSFetchRequest new];
        NSEntityDescription *descr = [NSEntityDescription entityForName:@"StoredLocation"
                                                 inManagedObjectContext:context];
        [req setEntity:descr];
        
        NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"name"
                                                             ascending:YES] autorelease];
        [req setSortDescriptors:[NSArray arrayWithObject:sort]];
        
        [context save:&error];

        [self setLocations:[[context executeFetchRequest:req error:&error]
                            mutableCopy]];
        
        [regionsMapView removeAnnotation:regionAnnotation];
        [regionView removeRadiusOverlay];
        
        
    }
    else if([control tag] == 2)
    {
        UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:@"Title"  message:@"Edit Name" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok",nil] autorelease];
        [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alertView show];
        
    }

    
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    
    RegionAnnotationView *regionView = (RegionAnnotationView *)view;

    
    if([view isKindOfClass:[RegionAnnotationView class]])
    {
        [mapView resignFirstResponder];
        
        lastScale = 1;
        selectedRegion = regionView;
        
        pinch = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scale:)] autorelease];
        [pinch setDelegate:self];
        [pinch setDelaysTouchesBegan:YES];
        [self.regionsMapView addGestureRecognizer:pinch];
        
        
        regionView.pinColor = MKPinAnnotationColorRed;
        [regionView updateRadiusOverlay:YES];
    }
    else{
        // If the user clicks the blue dot, don't show anything... it's annoying.
        view.canShowCallout = NO;
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    if([view isKindOfClass:[RegionAnnotationView class]])
    {
        [mapView removeGestureRecognizer:pinch];
        [mapView becomeFirstResponder];
        RegionAnnotationView *regionView = (RegionAnnotationView *)view;
        [regionView updateRadiusOverlay:NO];
    }
    
}
 
#pragma mark - Gesture stuff
-(void)scale:(UIPinchGestureRecognizer *)sender {
    
    if([sender state] == UIGestureRecognizerStateBegan)
    {
        regionsMapView.zoomEnabled = false;
        regionsMapView.scrollEnabled = false;
    }
    
    RegionAnnotation *annotation = selectedRegion.annotation;
    
    NSLog(@"%f, %f, %f, %f, %f", annotation.radius, sender.scale, lastScale, (sender.scale - lastScale), annotation.radius + (annotation.radius * (sender.scale - lastScale)));
    
    [annotation setRadius:annotation.radius + (annotation.radius * (sender.scale - lastScale))];
    lastScale = sender.scale;
    [selectedRegion updateRadiusOverlay:YES];
    
    // Refresh the region to be tracked if we're done.
	if([sender state] == UIGestureRecognizerStateEnded )
    {
        regionsMapView.zoomEnabled = true;
        regionsMapView.scrollEnabled = true;
        
        [locationManager stopMonitoringForRegion:annotation.region];
        
        CLRegion *newRegion = [[CLRegion alloc] initCircularRegionWithCenter:annotation.region.center radius:annotation.radius identifier:annotation.region.identifier];
        
        [annotation updateRegion:newRegion];
        
        [locationManager startMonitoringForRegion:newRegion desiredAccuracy:kCLLocationAccuracyBest];
        
        [self updateStoredRegion:selectedRegion.annotation];
        
        [self updateRegionsInRange];
    }
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.regionsMapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.regionsMapView convertPoint:touchPoint toCoordinateFromView:self.regionsMapView];
    
    
    [self addRegion:touchMapCoordinate];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer

{
    return  YES;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer

{
    return  YES;
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"didFailWithError: %@", error);
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	NSLog(@"didUpdateToLocation %@ from %@", newLocation, oldLocation);
	
	// Work around a bug in MapKit where user location is not initially zoomed to.
	if (oldLocation == nil) {
		// Zoom to the current user location.
		MKCoordinateRegion userLocation = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 1500.0, 1500.0);
		[regionsMapView setRegion:userLocation animated:YES];
	}
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region  {
    
    StoredLocation *loc = [self getStoredObjectForAnnotation:region];
    NSString * name = [loc.name isEqualToString:@"Unknown"] ? loc.location.identifier : loc.name;
    [updateEvents insertObject:name atIndex:0];
    
    if([updateEvents count] == 1){
        [self addNotification:[[NSString alloc] initWithFormat:@"Selected new memory region %@", loc.name]];
        loc.selected = YES;
    }
    else{
        [self addNotification:[[NSString alloc] initWithFormat:@"Entered region %@", loc.name]];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
	
	StoredLocation *loc = [self getStoredObjectForAnnotation:region];
    NSString * name = [loc.name isEqualToString:@"Unknown"] ? loc.location.identifier : loc.name;
    [updateEvents insertObject:name atIndex:0];
    
    if(loc.selected)
    {
        loc.selected = NO;
        [self addNotification:[[NSString alloc] initWithFormat:@"Left and de-activated memory region %@", loc.name]];
    }
    else{
        [self addNotification:[[NSString alloc] initWithFormat:@"Left memory region %@", loc.name]];
    }
}


- (void)addNotification:(NSString * ) description {
    UILocalNotification *localNotification = [[[UILocalNotification alloc] init] autorelease];
    
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = description;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = 1;
    
    //NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Object 1", @"Key 1", @"Object 2", @"Key 2", nil];
    //localNotification.userInfo = infoDict;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

-(void) updateRegionsInRange
{
    // This method screams proto-duction.
    // This method is bad
    // This method is that picture of a ferris wheel built on top of the eiffel tower.
    
    
    int numBefore = [updateEvents count];
    [updateEvents removeAllObjects];
    
    CLLocationCoordinate2D curLoc = regionsMapView.userLocation.coordinate;
    BOOL anyAlreadySelected = NO;
    for(StoredLocation * loc in [self locations])
    {
        if([loc.location containsCoordinate:curLoc])
        {
            [updateEvents addObject:loc];
            if(loc.selected)
                anyAlreadySelected = true;
        }else{
            loc.selected = NO;
        }
    }
    
    if([updateEvents count] == 1 ||
       ([updateEvents count] > 1 && !anyAlreadySelected))
    {
        ((StoredLocation *)[updateEvents objectAtIndex:0]).selected = YES;
    }
     
    [self.locations sortUsingComparator:^NSComparisonResult(id a, id b){
        StoredLocation * first = (StoredLocation *)a;
        StoredLocation * second = (StoredLocation *)b;
        
        int firstInRange = [updateEvents containsObject:first];
        int secondInRange = [updateEvents containsObject:second];
        
        if (firstInRange > secondInRange) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        if (firstInRange < secondInRange) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
           
    } ];

    
    
    [self.updatesTableView reloadData];
    if([updateEvents count] > 1 && numBefore <= 1 && tabBar.selectedItem.tag != 1)
    {
        [tabBar setSelectedItem:[tabBar.items objectAtIndex:0]];
        [self show:@"Multiple memories found!"];
    }
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"monitoringDidFailForRegion %@: %@", region.identifier, error);
    
}


#pragma mark - RegionsViewController


/*
 This method creates a new region based on the center coordinate of the map view.
 A new annotation is created to represent the region and then the application starts monitoring the new region.
 */
- (IBAction)addRegion:(CLLocationCoordinate2D) curLoc {
	if ([CLLocationManager regionMonitoringAvailable]) {
		// Create a new region based on the center of the map view.
        
        
        //CLLocation *curLoc = regionsMapView.userLocation.location;
        
		CLRegion *newRegion = [[CLRegion alloc] initCircularRegionWithCenter:curLoc
																	  radius:50.0
																  identifier:[NSString stringWithFormat:@"Geocoded - %f %f", curLoc.latitude, curLoc.longitude]];
		
        
		// Create an annotation to show where the region is located on the map.
		RegionAnnotation *myRegionAnnotation = [[RegionAnnotation alloc] initWithCLRegion:newRegion andTitle:nil];
        
        
        
		myRegionAnnotation.coordinate = newRegion.center;
		myRegionAnnotation.radius = newRegion.radius;
		
		[regionsMapView addAnnotation:myRegionAnnotation];
        [regionsMapView selectAnnotation:myRegionAnnotation animated:true];
		
		// TODO [myRegionAnnotation release];
        
        [self addAndSaveNewRegion:myRegionAnnotation];
		
		// Start monitoring the newly created region.
		[locationManager startMonitoringForRegion:newRegion desiredAccuracy:kCLLocationAccuracyBest];
		
        [self updateRegionsInRange];
        
		[newRegion release];
	}
	else {
		NSLog(@"Region monitoring is not available.");
	}
}

- (void)show:(NSString *) text
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: @""
                          message: text
                          delegate: nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#pragma mark UITabBarDelegate
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if(item.tag == 0)
    {
        self.regionsMapView.hidden = false;
        self.updatesTableView.hidden = true;
    }
    else{
        self.regionsMapView.hidden = true;
        self.updatesTableView.hidden = false;
    }
    
	// Reload the table data and update the icon badge number when the table view is shown.
	if (!updatesTableView.hidden) {
        [updatesTableView reloadData];
    }
		
}
/*
 This method adds the region event to the events array and updates the icon badge number.
 */
//- (void)updateWithEvent:(NSString *)event {
    
    
	// Add region event to the updates array.
//	[updateEvents insertObject:event atIndex:0];
	
	// Update the icon badge number.
//	[UIApplication sharedApplication].applicationIconBadgeNumber++;
	
//	if (!updatesTableView.hidden) {
//		[updatesTableView reloadData];
//	}
//}



@end
