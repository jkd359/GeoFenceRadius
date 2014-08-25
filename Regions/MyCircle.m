//
//  MyCircle.m
//  Regions
//
//  Created by Erik Kerber on 8/16/12.
//  Copyright (c) 2012 Apple Inc. All rights reserved.
//

#import "MyCircle.h"

@implementation MyCircle

+ (MyCircle *)circleWithCenterCoordinate2:(CLLocationCoordinate2D)coord radius:(CLLocationDistance)radius
{
    return (MyCircle *)[super circleWithCenterCoordinate:coord radius:radius];
}

@end
