//
//  OneDollarRecognizer.m
//  one-dollar-recognizer
//

#import "OneDollarRecognizer.h"


const NSUInteger kNumPoints = 64;

const double kAngleRange = 45.0 / 180 * M_PI;

const double kAnglePrecision = 2.0 / 180 * M_PI;

const double kPhi = 1.61803399; // Golden Ratio


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
    double angle = [self indicativeAngle: processedPoints];
    processedPoints = [self rotatePoints: processedPoints
                                 byAngle: -angle];
    processedPoints = [self scale: processedPoints];
    processedPoints = [self translate: processedPoints];

    double halfDiagonal = sqrt(_region.size.width*_region.size.width  + _region.size.height*_region.size.height) / 2;
    
    for (NSString *templateName in _templates) {
        double distance = [self distanceAtBestAngleFromPoints: points 
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
    // TODO
    return nil;
}

- (double)indicativeAngle: (NSArray *)points {
    // TODO
    return 0;
}

- (NSArray *)rotatePoints: (NSArray *)points
                  byAngle: (double)angle {
    // TODO
    return nil;
}

- (NSArray *)scale: (NSArray *)points {
    // TODO
    return nil;
}

- (NSArray *)translate: (NSArray *)points {
    // TODO
    return nil;
}

- (double)distanceAtBestAngleFromPoints: (NSArray *)points
                               toPoints: (NSArray *)points {
    // TODO
    return 0;
}

- (double) distanceFromPoints: (NSArray *)points
                     toPoints: (NSArray *)points
                    withAngle: angle {
    // TODO
    return 0;
}

- (CGPoint) centroid: (NSArray *)points {
    // TODO
    return CGPointZero;
}

- (CGRect) boundingBox: (NSArray *)points {
    // TODO
    return CGRectZero;
}

- (double) pathDistanceBetween: (NSArray *)points1
                           and: (NSArray *)points2 {
    // TODO
    return 0;
}

- (double) pathLength: (NSArray *)points {
    // TODO
    return 0;
}

- (double) distanceBetween: point1 
                       and: point2 {
    // TODO
    return 0;
}

@end
