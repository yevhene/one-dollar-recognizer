//
//  OneDollarRecognizer.h
//  one-dollar-recognizer
//

#include <UIKit/UIKit.h>


static const NSUInteger kNumPoints = 64;

static const double kAngleRange = 45.0 / 180 * M_PI;

static const double kAnglePrecision = 2.0 / 180 * M_PI;

static const double kPhi = 0.61803399; // Golden Ratio


@interface OneDollarRecognizer : NSObject {
@private
    //<NSString *name, NSArray *points>
    NSMutableDictionary *_templates;

    CGRect _region;
}

@property(readonly) NSDictionary *templates;

@property(assign) CGRect region;

- (id) initWithTemplates: (NSDictionary *)templates
               andRegion: (CGRect) region;

+ (OneDollarRecognizer *)recognizerWithTemplates: (NSDictionary *)templates
                                       andRegion: (CGRect) region;

- (NSDictionary *)recognize: (NSArray *)points;

- (void)addTemplateWithName: (NSString *)name
                  andPoints: (NSArray *)points;

- (void)removeTemplateWithName: (NSString *)name;

@end
