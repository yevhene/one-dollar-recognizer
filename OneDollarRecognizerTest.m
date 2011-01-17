//
//  OneDollarRecognizerTest.m
//  one-dollar-recognizer
//

#import "OneDollarRecognizerTest.h"


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
    STAssertNotNil(recognizer.templates, @"Should create templates dictionary.");
    STAssertTrue([recognizer.templates count] == 0,  @"Templates dictionary should be empty.");
}

- (void) testInitWithTemplates {
    [recognizer release];
    recognizer = [[OneDollarRecognizer alloc] initWithTemplates: [self templates]
                                                      andRegion: [self region]];
    STAssertTrue([recognizer.templates count] == kTemplatesNumber, @"Templates dictionary should be %d.", kTemplatesNumber);
}

- (void) testRecognize {
    NSDictionary *recognizeResult = [recognizer recognize: [self points]];
    STAssertNotNil(recognizeResult, @"Recognize result should be not nil.");
}

@end
