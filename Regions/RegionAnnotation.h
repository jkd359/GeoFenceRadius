

#import <MapKit/MapKit.h>

@interface RegionAnnotation : NSObject <MKAnnotation> {

}

@property (nonatomic, retain) CLRegion *region;
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite) CLLocationDistance radius;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;

- (id)initWithCLRegion:(CLRegion *)newRegion andTitle:(NSString *)newTitle ;
- (void) updateTitle;
- (void) updateRegion:newRegion;
@end
