

#import "RegionAnnotationView.h"
#import "RegionAnnotation.h"
#import "MyCircle.h"

@implementation RegionAnnotationView

@synthesize map, theAnnotation;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation {
	self = [super initWithAnnotation:annotation reuseIdentifier:[annotation title]];	
	
	if (self) {		
		self.canShowCallout	= YES;		
		self.multipleTouchEnabled = NO;
		self.draggable = YES;
		self.animatesDrop = YES;
		self.map = nil;
		self.theAnnotation = (RegionAnnotation *)annotation;
		self.pinColor = MKPinAnnotationColorPurple;
		radiusOverlay = [MKCircle circleWithCenterCoordinate:theAnnotation.coordinate radius:theAnnotation.radius];
		
		[map addOverlay:radiusOverlay];
	}
	
	return self;
}


- (void)removeRadiusOverlay {
    
	// Find the overlay for this annotation view and remove it if it has the same coordinates.
	for (id overlay in [map overlays]) {
		if ([overlay isKindOfClass:[MKCircle class]]) {						
			MKCircle *circleOverlay = (MKCircle *)overlay;			
			CLLocationCoordinate2D coord = circleOverlay.coordinate;
            
			if (coord.latitude == self.theAnnotation.coordinate.latitude &&
                coord.longitude == self.theAnnotation.coordinate.longitude) {
				[map removeOverlay:overlay];
			}			
		}
	}
	
	isRadiusUpdated = NO;
}


- (void)updateRadiusOverlay:(bool) isSelected {
	if (!isRadiusUpdated) {
		isRadiusUpdated = YES;
		
		[self removeRadiusOverlay];	
		
		self.canShowCallout = NO;
        [self setPinColor:(isSelected ? MKPinAnnotationColorRed : MKPinAnnotationColorPurple)];
        MyCircle *circle = (MyCircle *)[MyCircle circleWithCenterCoordinate:theAnnotation.coordinate radius:theAnnotation.radius];
        circle.selected = isSelected;
        [map addOverlay:circle];
        
		self.canShowCallout = YES;		
	}
}



- (void)dealloc {
	[radiusOverlay release];
    [theAnnotation release];
	[super dealloc];
}


@end
