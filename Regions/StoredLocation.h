//
//  StoredLocation.h
//  GeoMem
//
//  Created by Erik Kerber on 8/20/12.
//  Copyright (c) 2012 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>

@interface StoredLocation : NSManagedObject

@property (nonatomic, retain) CLRegion * location;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) bool selected;

@end
