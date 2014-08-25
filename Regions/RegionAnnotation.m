

#import "RegionAnnotation.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreData/CoreData.h>
#import "StoredLocation.h"

@implementation RegionAnnotation

@synthesize region, coordinate, radius, title, subtitle;

- (id)init {
	self = [super init];
	if (self != nil) {
		self.title = @"Unknown";
	}
	
	return self;	
}

- (id)initWithCLRegion:(CLRegion *)newRegion andTitle:(NSString *)newTitle {
	self = [self init];
	
    
    // Grab the address of the new region with Geocoder.
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *loc = [[CLLocation alloc] initWithLatitude: newRegion.center.latitude longitude: newRegion.center.longitude];
    
    
    if(newTitle == nil || [newTitle isEqualToString:@"Unknown"])
    {
    [geocoder reverseGeocodeLocation: loc completionHandler:
        ^(NSArray *placemarks, NSError *error) {
            //Get nearby address
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
     
     
            //String to hold address
            NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
     
            //Set the label text to current location
            self.title = locatedAt;
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"TitleUpdated"
             object:self];
     }];
    }
    else{
        self.title = newTitle;
    }
	if (self != nil) {
		self.region = newRegion;
		self.coordinate = region.center;
		self.radius = region.radius;
	}		
    [NSThread sleepForTimeInterval:.5];
    [loc release];
    [geocoder release];
    
	return self;		
}

-(void) updateRegion:(CLRegion *)newRegion
{
    self.region = newRegion;
}

- (void) updateTitle
{
    // Only update the title if we are using a default geocoded title.
    //if([[region identifier] rangeOfString:@"Geocode"].location == NSNotFound)
    //    return;
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *loc = [[CLLocation alloc] initWithLatitude: region.center.latitude longitude: region.center.longitude];
    
    [geocoder reverseGeocodeLocation: loc completionHandler:
     ^(NSArray *placemarks, NSError *error) {
         //Get nearby address
         CLPlacemark *placemark = [placemarks objectAtIndex:0];
         
         
         //String to hold address
         NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
         
         //Set the label text to current location
         self.title = locatedAt;
         
         [[NSNotificationCenter defaultCenter]
          postNotificationName:@"TitleUpdated"
          object:self];
     }];

}

/*
 This method provides a custom setter so that the model is notified when the subtitle value has changed.
 */
- (void)setRadius:(CLLocationDistance)newRadius {
	[self willChangeValueForKey:@"subtitle"];
	if(newRadius < 5)
        newRadius = 5;
	radius = newRadius;
	
	[self didChangeValueForKey:@"subtitle"];
}


- (NSString *)subtitle {
	return [NSString stringWithFormat: @"Lat: %.4F, Lon: %.4F, Rad: %.1fm", coordinate.latitude, coordinate.longitude, radius];	
}


- (void)dealloc {
	[region release];
	[title release];
	[subtitle release];
	[super dealloc];
}


@end
