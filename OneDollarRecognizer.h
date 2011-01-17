//
//  OneDollarRecognizer.h
//  one-dollar-recognizer
//

#include <UIKit/UIKit.h>

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
