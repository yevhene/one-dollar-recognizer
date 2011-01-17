//
//  OneDollarRecognizerTest.m
//  one-dollar-recognizer
//

#import "OneDollarRecognizerTest.h"

@interface OneDollarRecognizer (private)

- (NSArray *)resample: (NSArray *)points;

- (double)indicativeAngle: (NSArray *)points;

- (NSArray *)rotatePoints: (NSArray *)points
                  byAngle: (double)angle;

- (NSArray *)scale: (NSArray *)points;

- (NSArray *)translate: (NSArray *)points;

- (double)distanceAtBestAngleFromPoints: (NSArray *)points
                               toPoints: (NSArray *)points;

- (double) distanceFromPoints: (NSArray *)points
                     toPoints: (NSArray *)points
                    withAngle: angle;

- (CGPoint) centroid: (NSArray *)points;

- (CGRect) boundingBox: (NSArray *)points;

- (double) pathDistanceBetween: (NSArray *)points1
                           and: (NSArray *)points2;

- (double) pathLength: (NSArray *)points;

- (double) distanceBetween: point1 
                       and: point2;

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
}

- (void) testResample {
    NSArray *points = [recognizer resample: [self points]];
    STAssertTrue([points count] == kNumPoints,
                 @"Should resample to %d points.", kNumPoints);
}

- (void) testIndicativeAngle {
    double angle = [recognizer indicativeAngle: [self points]];
    STAssertEqualsWithAccuracy(angle, M_PI / 4, 0.001,
                               @"Should be equal to 45 degrees.");
}

- (void) testRotatePoints {
    NSArray *points = [recognizer rotatePoints: [self points]
                                       byAngle: M_PI / 4];
    STAssertTrue([points count] == kPointsPerTemplateNumber,
                 @"Should return the same number of points as given.");
    for (int i = 0; i < [points count]; i++) {
        CGPoint point = [[points objectAtIndex: i] CGPointValue];
        STAssertEqualsWithAccuracy(point.y, 0.0, 0.001,
                                   @"All points should lie on X-axis.");
        STAssertTrue(point.x >= 0,
                     @"All points should have positive X coordinate");
        if (i > 0) {
            CGPoint lastPoint = [[points objectAtIndex: i - 1] CGPointValue];
            STAssertTrue(point.x > lastPoint.x,
                         @"Points should have growing X coordinate");
        }
    }
}

@end
