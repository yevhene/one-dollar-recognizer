//
//  OneDollarRecognizerTest.m
//  one-dollar-recognizer
//

#import "OneDollarRecognizerTest.h"

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

@implementation OneDollarRecognizerTest

const NSUInteger kTemplatesNumber = 10;

const NSUInteger kPointsPerTemplateNumber = 5;

- (CGRect) region {
    return CGRectMake(0, 0, 250, 250);
}

- (NSArray *)points {
    NSMutableArray *points = [NSMutableArray array];
    for (NSUInteger j = 0; j < kPointsPerTemplateNumber; ++j) {
        [points addObject: [NSValue valueWithCGPoint: CGPointMake(j, j)]];
    }
    return points;
}

- (NSDictionary *)templates {
    NSMutableDictionary *templates = [[NSMutableDictionary alloc] init];
    for (NSUInteger i = 0; i < kTemplatesNumber; ++i) {
        [templates setObject: [self points]
                       forKey: [NSString stringWithFormat: @"%d", i]];
    }
    return templates;
}

- (void) setUp {
    recognizer = [[[OneDollarRecognizer alloc] init] retain];
    STAssertNotNil(recognizer, @"Could not create recognizer.");
}

- (void) tearDown {
    [recognizer release];
}

- (void) testInit {
    STAssertNotNil(recognizer.templates,
                   @"Should create templates dictionary.");
    STAssertTrue([recognizer.templates count] == 0,
                 @"Templates dictionary should be empty.");
}

- (void) testInitWithTemplates {
    [recognizer release];
    recognizer = [[OneDollarRecognizer alloc] initWithTemplates: [self templates]
                                                      andRegion: [self region]];
    STAssertTrue([recognizer.templates count] == kTemplatesNumber,
                 @"Templates dictionary should be %d.", kTemplatesNumber);
}

- (void) testRecognize {
    NSDictionary *recognizeResult = [recognizer recognize: [self points]];
    STAssertNotNil(recognizeResult,
                   @"Recognize result should be not nil.");
    // TODO
}

- (void) testResample {
    NSArray *points = [recognizer resample: [self points]];
    STAssertNotNil(points,
                   @"Should not be nil.");
    STAssertEquals([points count], kNumPoints,
                   @"Should resample to %d points.", kNumPoints);
}

- (void) testIndicativeAngle {
    CGFloat angle = [recognizer indicativeAngle: [self points]];
    STAssertEqualsWithAccuracy(angle, (CGFloat)(M_PI / 4), 0.001,
                               @"Should be equal to 45 degrees.");
}

- (void) testRotatePoints {
    NSArray *points = [recognizer rotatePoints: [self points]
                                       byAngle: -M_PI / 4];
    STAssertTrue([points count] == kPointsPerTemplateNumber,
                 @"Should return the same number of points as given.");
    for (int i = 0; i < [points count]; i++) {
        CGPoint point = [[points objectAtIndex: i] CGPointValue];
        STAssertEqualsWithAccuracy(point.y, (CGFloat)((kPointsPerTemplateNumber - 1) / 2.0), 0.001,
                                   @"All points should lie on X-axis.");
        if (i > 0) {
            CGPoint lastPoint = [[points objectAtIndex: i - 1] CGPointValue];
            STAssertTrue(point.x > lastPoint.x,
                         @"Points should have growing X coordinate");
        }
    }
}

- (void) testCentroid {
    CGPoint centroid = [recognizer centroid: [self points]];

    STAssertEqualsWithAccuracy(centroid.x, (CGFloat)((kPointsPerTemplateNumber - 1) / 2.0), 0.001,
                               @"Centroid x-coordinate should be in the middle of given points.");
    STAssertEqualsWithAccuracy(centroid.y, (CGFloat)((kPointsPerTemplateNumber - 1) / 2.0), 0.001,
                               @"Centroid y-coordinate should be in the middle of given points.");
}

- (void) testBoundingBox {
    CGRect boundingBox = [recognizer boundingBox: [self points]];

    STAssertEqualsWithAccuracy(boundingBox.origin.x, (CGFloat)0.0, 0.001,
                               @"Origin x-coordinate should be minimum of given points.");
    STAssertEqualsWithAccuracy(boundingBox.origin.y, (CGFloat)0.0, 0.001,
                               @"Origin y-coordinate should be minimum of given points.");
    STAssertEqualsWithAccuracy(CGRectGetMaxX(boundingBox), (CGFloat)(kPointsPerTemplateNumber - 1), 0.001,
                               @"Max x should be maximum of given points.");
    STAssertEqualsWithAccuracy(CGRectGetMaxY(boundingBox), (CGFloat)(kPointsPerTemplateNumber - 1), 0.001,
                               @"Max y should be maximum of given points.");
}

- (void) testDistanceBetweenPoints {
    CGFloat distance = [recognizer distanceBetween: CGPointMake(0.0, 0.0)
                                              and: CGPointMake(1.0, 1.0)];
    STAssertEqualsWithAccuracy(distance, (CGFloat)M_SQRT2, 0.001,
                               @"Distance should be correct.");
}

- (void) testPathLength {
    CGFloat pathLength = [recognizer pathLength: [self points]];
    STAssertEqualsWithAccuracy(pathLength, (CGFloat)((kPointsPerTemplateNumber - 1) * M_SQRT2), 0.001,
                               @"Path length should be sum of the distances between points.");
}

- (void) testPathDistanceBetweenPoints {
    CGFloat pathDistance = [recognizer pathDistanceBetween: [self points]
                                                      and: [self points]];
    STAssertEqualsWithAccuracy(pathDistance, (CGFloat)0.0, 0.001,
                               @"Distance between path and itself should be zero.");
}

@end
