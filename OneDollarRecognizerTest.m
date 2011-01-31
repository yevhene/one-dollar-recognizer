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

- (CGFloat)distanceAtBestAngleFromPoints: (NSArray *)points1
                                toPoints: (NSArray *)points2;

- (CGFloat) distanceFromPoints: (NSArray *)points1
              toTemplatePoints: (NSArray *)points2
                     withAngle: (CGFloat) angle;

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

const CGFloat kEps = 0.001;

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
                 @"Should have empty templates dictionary.");
}

- (void) assertResampled: (NSArray *) points {
    STAssertEquals(kNumPoints, [points count],
                   @"Should resample to %d points.", kNumPoints);
}

- (void) assertScaled: (NSArray *) scaledPoints {
    CGRect boundingBox = [recognizer boundingBox: scaledPoints];

    if (boundingBox.size.width > boundingBox.size.height) {
        STAssertEqualsWithAccuracy(boundingBox.size.width, [self region].size.width, kEps,
                                   @"Bounding box of new points should be scaled to whole region");
    } else {
        STAssertEqualsWithAccuracy(boundingBox.size.height, [self region].size.height, kEps,
                                   @"Bounding box of new points should be scaled to whole region");
    }
}

- (void) assertTranslated: (NSArray *) translatedPoints {
    CGPoint center = [recognizer centroid: translatedPoints];

    STAssertEqualsWithAccuracy(center.x, CGRectGetMidX([self region]), kEps,
                               @"Centroid of new points should be translated to center of region");
    STAssertEqualsWithAccuracy(center.y, CGRectGetMidY([self region]), kEps,
                               @"Centroid of new points should be translated to center of region");
}

- (void) assertRotated: (NSArray *) points {
    for (int i = 0; i < [points count]; i++) {
        CGPoint point = [[points objectAtIndex: i] CGPointValue];

        if (i > 0) {
            CGPoint lastPoint = [[points objectAtIndex: i - 1] CGPointValue];
            STAssertEqualsWithAccuracy(point.y, lastPoint.y, kEps,
                                       @"Should be parallel to X-axis.");
            STAssertTrue(point.x > lastPoint.x,
                         @"Should have each next point (%@) with bigger X-coordinate than previous (%@)",
                         NSStringFromCGPoint(point), NSStringFromCGPoint(lastPoint));
        }
    }
}

- (void) assertTransformedTemplate: (NSArray *) points {
    [self assertResampled: points];
    [self assertRotated: points];
    [self assertScaled: points];
    [self assertTranslated: points];
}

- (void) testInitWithTemplates {
    [recognizer release];
    recognizer = [[OneDollarRecognizer alloc] initWithTemplates: [self templates]
                                                      andRegion: [self region]];
    STAssertEquals(kTemplatesNumber, [recognizer.templates count],
                 @"Should have templates dictionary of expected size");

    for (NSArray *template in [recognizer.templates allValues]) {
    	[self assertTransformedTemplate: template];
    }
}

- (void) testAddSingleTemplate {
    recognizer.region = [self region];
    [recognizer addTemplateWithName: @"testTemplate" andPoints: [self points]];

    STAssertEquals(1u, [recognizer.templates count],
                   @"Should add one template");
    STAssertEquals(@"testTemplate", [[recognizer.templates allKeys] objectAtIndex: 0],
                   @"Should add template with given name");
    [self assertTransformedTemplate: [[recognizer.templates allValues] objectAtIndex: 0]];
}

- (void) testAddMultipleTemplates {
    recognizer.region = [self region];

    NSDictionary *templates = [self templates];

    for (NSString *templateName in [templates allKeys]) {
    	[recognizer addTemplateWithName: templateName
                              andPoints: [templates objectForKey: templateName]];
    }

    STAssertEquals([templates count], [recognizer.templates count],
                   @"Should add the same number of templates as given");

    for (NSString *templateName in [recognizer.templates allKeys]) {
	NSArray *template = [recognizer.templates objectForKey: templateName];
    	STAssertNotNil(template,
                       @"Should have template '%@' in templates dictionary", templateName);
    	[self assertTransformedTemplate: template];
    }
}

- (void) testRecognize {
    [self testInitWithTemplates];

    NSDictionary *recognizeResult = [recognizer recognize: [self points]];
    STAssertNotNil(recognizeResult,
                   @"Should return not nil recognition result.");
    STAssertEquals(kTemplatesNumber, [recognizer.templates count],
                   @"Should return the same number of results as number of templates");

    for (NSString *templateName in [recognizeResult allKeys]) {
    	CGFloat score = [[recognizeResult objectForKey: templateName] doubleValue];
        STAssertTrue(score >= 0.0,
                     @"Should have score (%f) not less than zero", score);
        STAssertTrue(score <= 1.0,
                     @"Should have score (%f) not bigger than 1.0", score);

        // Note, tolerance is high because of low precision of best rotation angle
        STAssertEqualsWithAccuracy((CGFloat) 1.0, score, 0.1,
                                   @"Should have near 1.0 score as is the same path");
    }
}

- (void) testResample {
    NSArray *points = [recognizer resample: [self points]];
    STAssertNotNil(points,
                   @"Should not be nil.");
    [self assertResampled: points];
}

- (void) testIndicativeAngle {
    CGFloat angle = [recognizer indicativeAngle: [self points]];
    STAssertEqualsWithAccuracy(angle, (CGFloat)(M_PI / 4), kEps,
                               @"Should be equal to 45 degrees.");
}

- (void) testRotatePoints {
    NSArray *points = [recognizer rotatePoints: [self points]
                                       byAngle: -M_PI / 4];

    STAssertTrue([points count] == kPointsPerTemplateNumber,

                 @"Should return the same number of points as given.");
    [self assertRotated: points];
}

- (void) testCentroid {
    CGPoint centroid = [recognizer centroid: [self points]];

    STAssertEqualsWithAccuracy(centroid.x, (CGFloat)((kPointsPerTemplateNumber - 1) / 2.0), kEps,
                               @"Centroid x-coordinate should be in the middle of given points.");
    STAssertEqualsWithAccuracy(centroid.y, (CGFloat)((kPointsPerTemplateNumber - 1) / 2.0), kEps,
                               @"Centroid y-coordinate should be in the middle of given points.");
}

- (void) testBoundingBoxSinglePoint {
    CGPoint point = CGPointMake(1.0, 2.0);
    CGRect boundingBox = [recognizer boundingBox:
                          [NSArray arrayWithObject:
                           [NSValue valueWithCGPoint: point]]];

    STAssertEqualsWithAccuracy(boundingBox.origin.x, point.x, kEps,
                               @"Should have origin x-coordinate be same as given point.");
    STAssertEqualsWithAccuracy(boundingBox.origin.y, point.y, kEps,
                               @"Should have origin y-coordinate be same as given point");
    STAssertEqualsWithAccuracy(boundingBox.size.width, (CGFloat) 1.0, kEps,
                               @"Should have width of one point.");
    STAssertEqualsWithAccuracy(boundingBox.size.height, (CGFloat) 1.0, kEps,
                               @"Should have height of one point.");
}

- (void) testBoundingBoxMultiplePoints {
    CGRect boundingBox = [recognizer boundingBox: [self points]];

    STAssertEqualsWithAccuracy(boundingBox.origin.x, (CGFloat)0.0, kEps,
                               @"Should have origin x-coordinate be minimum of given points.");
    STAssertEqualsWithAccuracy(boundingBox.origin.y, (CGFloat)0.0, kEps,
                               @"Should have origin y-coordinate be minimum of given points.");
    STAssertEqualsWithAccuracy(CGRectGetMaxX(boundingBox), (CGFloat)(kPointsPerTemplateNumber - 1), kEps,
                               @"Should have max x be maximum of given points.");
    STAssertEqualsWithAccuracy(CGRectGetMaxY(boundingBox), (CGFloat)(kPointsPerTemplateNumber - 1), kEps,
                               @"Should have max y  be maximum of given points.");
}

- (void) testDistanceBetweenPoints {
    CGFloat distance = [recognizer distanceBetween: CGPointMake(0.0, 0.0)
                                              and: CGPointMake(1.0, 1.0)];
    STAssertEqualsWithAccuracy(distance, (CGFloat)M_SQRT2, kEps,
                               @"Distance should be correct.");
}

- (void) testPathLength {
    CGFloat pathLength = [recognizer pathLength: [self points]];
    STAssertEqualsWithAccuracy(pathLength, (CGFloat)((kPointsPerTemplateNumber - 1) * M_SQRT2), kEps,
                               @"Path length should be sum of the distances between points.");
}

- (void) testPathDistanceBetweenPoints {
    CGFloat pathDistance = [recognizer pathDistanceBetween: [self points]
                                                      and: [self points]];
    STAssertEqualsWithAccuracy(pathDistance, (CGFloat)0.0, kEps,
                               @"Distance between path and itself should be zero.");
}

- (void) testScaleTo {
    recognizer.region = [self region];

    NSArray *scaledPoints = [recognizer scale: [self points]];

    STAssertEquals([scaledPoints count], kPointsPerTemplateNumber,
                   @"Should return the same number of points as given.");

    [self assertScaled: scaledPoints];
}

- (void) testTranslateTo {
    recognizer.region = [self region];

    NSArray *translatedPoints = [recognizer translate: [self points]];

    STAssertEquals([translatedPoints count], kPointsPerTemplateNumber,
                   @"Should return the same number of points as given.");

    [self assertTranslated: translatedPoints];
}

- (void) testDistanceAtBestAngleSamePoints {
    CGFloat distance = [recognizer distanceAtBestAngleFromPoints: [self points]
                                                        toPoints: [self points]];
    // Note that smaller epsilon used here, because of high kAnglePrecision value
    STAssertEqualsWithAccuracy(distance, (CGFloat) 0.0, 0.05,
                               @"Distance between path and itself should be zero.");
}

- (void) testDistanceAtBestAngleSamePointsTranslated {
    NSMutableArray *translatedPoints = [[self points] mutableCopy];
    for (int i = 0; i < [translatedPoints count]; i++) {
        NSValue *value = [translatedPoints objectAtIndex: i];
        CGPoint point = [value CGPointValue];
        [translatedPoints replaceObjectAtIndex: i
                                    withObject:
         [NSValue valueWithCGPoint:
          CGPointMake(point.x - M_SQRT1_2, point.y - M_SQRT1_2)]];
    }

    CGFloat distance = [recognizer distanceAtBestAngleFromPoints: [self points]
                                                        toPoints: translatedPoints];
    STAssertEqualsWithAccuracy(distance, (CGFloat) 1.0 * kPointsPerTemplateNumber, kEps,
                               @"Distance between path and translated one should be 1.0 multiplied by number of points");
}

- (void) testDistanceWithAngleSamePoints {
    CGFloat distance = [recognizer distanceFromPoints: [self points]
                                     toTemplatePoints: [self points]
                                            withAngle: 0.0];
    STAssertEqualsWithAccuracy(distance, (CGFloat) 0.0, kEps,
                               @"Distance between path and itself should be zero.");
}

- (void) testDistanceWithAngleSamePointsNonZeroAngle {
    CGFloat distance = [recognizer distanceFromPoints: [self points]
                                     toTemplatePoints: [self points]
                                            withAngle: M_PI / 2];
    // Following assumes sin(PI/4) = sqrt(1/2), i.e. the same as distance between two test points
    CGFloat expectedDistance = (kPointsPerTemplateNumber / 2 * (kPointsPerTemplateNumber / 2 + 1)) * 2;
    STAssertEqualsWithAccuracy(expectedDistance, distance, kEps,
                               @"Distance between path and itself at given angle should be as calculated");
}


@end
