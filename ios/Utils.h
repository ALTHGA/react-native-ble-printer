#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface Utils : NSObject

+ (NSData *)createTextBitmapWithText:(NSString *)text align:(NSString *)align bold:(BOOL)bold fontSize:(float)fontSize;
+ (NSData *)createColumnTextBitmapWithTexts:(NSArray *)texts widths:(NSArray *)widths alignments:(NSArray *)alignments bold:(BOOL)bold size:(float)size;
+ (NSData *)createStyledStrokeBitmapWithHeight:(int)height width:(float)width dash:(NSArray *)dash;
+ (NSData *)twoColumnsBitmapWithLeftText:(NSString *)leftText rightText:(NSString *)rightText bold:(BOOL)bold size:(float)size;
+ (NSData *)convertBitmapToPrinterArray:(CGImageRef)image width:(int)width height:(int)height;
+ (NSArray *)wrapTextToLines:(NSString *)text font:(UIFont *)font maxWidth:(float)maxWidth;

@end