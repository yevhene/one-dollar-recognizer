//
//  OneDollarRecognizer.m
//  one-dollar-recognizer
//

#import "OneDollarRecognizer.h"


@interface OneDollarRecognizer (private)

- (NSArray *)resample: (NSArray *)points;

- (CGFloat)indicativeAngle: (NSArray *)points;

- (NSArray *)rotatePoints: (NSArray *)points
                  byAngle: (CGFloat)angle;

- (NSArray *)scale: (NSArray *)points;

- (NSArray *)translate: (NSArray *)points;

- (CGFloat)distanceAtBestAngleFromPoints: (NSArray *)points
                                toPoints: (NSArray *)points;

- (CGFloat) distanceFromPoints: (NSArray *)points
                      toPoints: (NSArray *)points
                     withAngle: angle;

- (CGPoint) centroid: (NSArray *)points;

- (CGRect) boundingBox: (NSArray *)points;

- (CGFloat) pathDistanceBetween: (NSArray *)points1
                           and: (NSArray *)points2;

- (CGFloat) pathLength: (NSArray *)points;

- (CGFloat) distanceBetween: (CGPoint) point1
                        and: (CGPoint) point2;

@end


@implementation OneDollarRecognizer

@synthesize templates = _templates, region = _region;

- (id) init {
    if ((self = [super init])) {
        _templates = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id) initWithTemplates: (NSDictionary *)templates
               andRegion: (CGRect) region {
    if ((self = [self init])) {
        // TODO: Resample templates
        [_templates addEntriesFromDictionary: templates];
        _region = region;
    }
    return self;
}

- (void) dealloc {
    [_templates release];

    [super dealloc];
}

+ (OneDollarRecognizer *)recognizerWithTemplates: (NSDictionary *)templates
                                       andRegion: (CGRect) region {
    return [[[OneDollarRecognizer alloc] initWithTemplates: templates
                                                 andRegion: region] autorelease];
}

- (NSDictionary *)recognize: (NSArray *)points {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    NSArray *processedPoints = [self resample: points];
    CGFloat angle = [self indicativeAngle: processedPoints];
    processedPoints = [self rotatePoints: processedPoints
                                 byAngle: -angle];
    processedPoints = [self scale: processedPoints];
    processedPoints = [self translate: processedPoints];

    CGFloat halfDiagonal = sqrt(_region.size.width*_region.size.width  + _region.size.height*_region.size.height) / 2;

    for (NSString *templateName in _templates) {
        CGFloat distance = [self distanceAtBestAngleFromPoints: points
                                                      toPoints: [_templates objectForKey: templateName]];
        double score = 1.0 - (distance / halfDiagonal);

        [result setObject: [NSNumber numberWithDouble: score]
                   forKey: templateName];
    }

    return result;
}

- (void)addTemplateWithName: (NSString *)name
                  andPoints: (NSArray *)points {
    [_templates setObject: points
                   forKey: name];
}

- (void)removeTemplateWithName: (NSString *)name {
    [_templates removeObjectForKey: name];
}

#pragma mark private

- (NSArray *)resample: (NSArray *)points {
    NSMutableArray *workingPoints = [NSMutableArray arrayWithArray: points];
    NSMutableArray *result = [NSMutableArray array];
    double intervalLength = [self pathLength: points] / (kNumPoints - 1);

    // Put first point
    [result addObject: [workingPoints objectAtIndex: 0]];

    double distanceInInterval = 0.0;

    for (NSUInteger i = 1; i < [workingPoints count]; ++i) {
        CGPoint lastPoint = [[workingPoints objectAtIndex: i - 1] CGPointValue];
        CGPoint currentPoint = [[workingPoints objectAtIndex: i] CGPointValue];
        double currentDistance = [self distanceBetween: lastPoint
                                                   and: currentPoint];

        if (distanceInInterval + currentDistance >= intervalLength) {
            double qx = lastPoint.x +
                        ((intervalLength - distanceInInterval) / currentDistance) *
                        (currentPoint.x - lastPoint.x);
            double qy = lastPoint.y +
                        ((intervalLength - distanceInInterval) / currentDistance) *
                        (currentPoint.y - lastPoint.y);
            CGPoint newPoint = CGPointMake(qx, qy);

            [result addObject: [NSValue valueWithCGPoint: newPoint]];

            [workingPoints insertObject: [NSValue valueWithCGPoint: newPoint]
                                atIndex: i];

            distanceInInterval = 0.0;
        } else {
            distanceInInterval += currentDistance;
        }
    }

    // Somtimes we fall a rounding-error short of adding the last point, so add it if so
    if ([result count] == kNumPoints - 1) {
        [result addObject: [workingPoints lastObject]];
    }
    return result;
}

- (CGFloat)indicativeAngle: (NSArray *)points {
    CGPoint centroid = [self centroid: points];
    CGPoint firstPoint = [[points objectAtIndex: 0] CGPointValue];
    CGFloat angle = atan2(centroid.y - firstPoint.y, centroid.x - firstPoint.x);
    return angle;
}

- (NSArray *)rotatePoints: (NSArray *)points
                  byAngle: (CGFloat)angle {
    NSMutableArray *result = [NSMutableArray array];
    CGPoint centroid = [self centroid: points];
    double angleSin = sin(angle);
    double angleCos = cos(angle);

    for (NSValue *value in points) {
        CGPoint point = [value CGPointValue];
        double qx = (point.x - centroid.x) * angleCos - (point.y - centroid.y) * angleSin + centroid.x;
        double qy = (point.x - centroid.x) * angleSin + (point.y - centroid.y) * angleCos + centroid.y;
        [result addObject: [NSValue valueWithCGPoint: CGPointMake(qx, qy)]];
    }

    return result;
}

- (NSArray *)scale: (NSArray *)points {
    // TODO
    return nil;
}

- (NSArray *)translate: (NSArray *)points {
    // TODO
    return nil;
}

- (CGFloat)distanceAtBestAngleFromPoints: (NSArray *)points
                               toPoints: (NSArray *)points {
    // TODO
    return 0;
}

- (CGFloat) distanceFromPoints: (NSArray *)points
                     toPoints: (NSArray *)points
                    withAngle: angle {
    // TODO
    return 0;
}

- (CGPoint) centroid: (NSArray *)points {
    CGFloat sumx = 0.0;
    CGFloat sumy = 0.0;
    for (NSValue *value in points) {
        CGPoint point = [value CGPointValue];
        sumx += point.x;
        sumy += point.y;
    }
    CGPoint centroid = CGPointMake(sumx / [points count], sumy / [points count]);
    return centroid;
}

- (CGRect) boundingBox: (NSArray *)points {
    CGFloat minX = CGFLOAT_MAX;
    CGFloat minY = CGFLOAT_MAX;
    CGFloat maxX = CGFLOAT_MIN;
    CGFloat maxY = CGFLOAT_MIN;
    for (NSValue *value in points) {
        CGPoint point = [value CGPointValue];
        if (point.x < minX)
            minX = point.y;
        if (point.x > maxX)
            maxX = point.y;
        if (point.y < minY)
            minY = point.y;
        if (point.y > maxY)
            maxY = point.y;
    }
    CGRect boundingBox = CGRectMake(minX, minY, maxX - minX, maxY - minY);
    return boundingBox;
}

- (CGFloat) pathDistanceBetween: (NSArray *)points1
                            and: (NSArray *)points2 {
    CGFloat pathDistance = 0.0;
    for (NSInteger i = 0; i < [points1 count]; ++i) {
        CGPoint point1 = [[points1 objectAtIndex: i] CGPointValue];
        CGPoint point2 = [[points2 objectAtIndex: i] CGPointValue];
        pathDistance += [self distanceBetween: point1
                                          and: point2];
    }
    return pathDistance;
}

- (CGFloat) pathLength: (NSArray *)points {
    CGFloat pathLength = 0.0;
    for (NSInteger i = 1; i < [points count]; ++i) {
        CGPoint point1 = [[points objectAtIndex: i - 1] CGPointValue];
        CGPoint point2 = [[points objectAtIndex: i] CGPointValue];
        pathLength += [self distanceBetween: point1
                                        and: point2];
    }
    return pathLength;
}

- (CGFloat) distanceBetween: (CGPoint) point1
                        and: (CGPoint) point2 {
    CGFloat dx = point2.x - point1.x;
    CGFloat dy = point2.y - point1.y;
    return sqrt(dx*dx + dy*dy);
}

@end
