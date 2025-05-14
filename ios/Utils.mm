#import "Utils.h"
#import <UIKit/UIKit.h>

@implementation Utils

static const float PAPER_WIDTH = 384.0f;

+ (CGContextRef)createBitmapContextWithWidth:(int)width height:(int)height {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0); // Fundo branco
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    return context;
}

+ (UIFont *)getFontWithBold:(BOOL)bold size:(float)size {
    return [UIFont systemFontOfSize:size weight:bold ? UIFontWeightBold : UIFontWeightRegular];
}

+ (NSTextAlignment)getTextAlignment:(NSString *)align {
    if ([align isEqualToString:@"CENTER"]) return NSTextAlignmentCenter;
    if ([align isEqualToString:@"RIGHT"]) return NSTextAlignmentRight;
    return NSTextAlignmentLeft;
}

+ (NSData *)createTextBitmapWithText:(NSString *)text align:(NSString *)align bold:(BOOL)bold fontSize:(float)fontSize {
    UIFont *font = [self getFontWithBold:bold size:fontSize];
    NSArray *wrappedLines = [self wrapTextToLines:text font:font maxWidth:PAPER_WIDTH];
    
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGFloat lineHeight = [@"A" sizeWithAttributes:attributes].height;
    int totalHeight = (int)(lineHeight * wrappedLines.count);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(PAPER_WIDTH, totalHeight), YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setFill];
    CGContextFillRect(context, CGRectMake(0, 0, PAPER_WIDTH, totalHeight));
    
    for (NSUInteger i = 0; i < wrappedLines.count; i++) {
        NSString *line = wrappedLines[i];
        CGSize textSize = [line sizeWithAttributes:attributes];
        CGFloat xPos = 10.0;
        if ([align isEqualToString:@"CENTER"]) {
            xPos = (PAPER_WIDTH - textSize.width) / 2.0;
        } else if ([align isEqualToString:@"RIGHT"]) {
            xPos = PAPER_WIDTH - textSize.width - 10.0;
        }
        
        CGPoint point = CGPointMake(xPos, i * lineHeight);
        [line drawAtPoint:point withAttributes:@{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: [UIColor blackColor]
        }];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef cgImage = image.CGImage;
    NSData *data = [self convertBitmapToPrinterArray:cgImage width:(int)PAPER_WIDTH height:totalHeight];
    
    return data;
}

+ (NSData *)createColumnTextBitmapWithTexts:(NSArray *)texts widths:(NSArray *)widths alignments:(NSArray *)alignments bold:(BOOL)bold size:(float)size {
    UIFont *font = [self getFontWithBold:bold size:size];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    
    CGFloat lineHeight = [@"A" sizeWithAttributes:attributes].height;
    int bitmapHeight = (int)lineHeight;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(PAPER_WIDTH, bitmapHeight), YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setFill];
    CGContextFillRect(context, CGRectMake(0, 0, PAPER_WIDTH, bitmapHeight));
    
    CGFloat xOffset = 0.0;
    for (NSUInteger i = 0; i < texts.count; i++) {
        NSString *text = texts[i];
        CGFloat width = [widths[i] floatValue];
        NSString *alignment = alignments[i];
        
        CGSize textSize = [text sizeWithAttributes:attributes];
        CGFloat xPos = xOffset + 10.0;
        
        if ([alignment isEqualToString:@"CENTER"]) {
            xPos = xOffset + (width - textSize.width) / 2.0;
        } else if ([alignment isEqualToString:@"RIGHT"]) {
            xPos = xOffset + width - textSize.width - 10.0;
        }
        
        [text drawAtPoint:CGPointMake(xPos, 0) withAttributes:@{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: [UIColor blackColor]
        }];
        
        xOffset += width;
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef cgImage = image.CGImage;
    NSData *data = [self convertBitmapToPrinterArray:cgImage width:(int)PAPER_WIDTH height:bitmapHeight];
    
    return data;
}

+ (NSData *)createStyledStrokeBitmapWithHeight:(int)height width:(float)width dash:(NSArray *)dash {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(PAPER_WIDTH, height), YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setFill];
    CGContextFillRect(context, CGRectMake(0, 0, PAPER_WIDTH, height));
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, width);
    
    if (dash.count > 0) {
        CGFloat *dashPattern = (CGFloat *)malloc(dash.count * sizeof(CGFloat));
        for (NSUInteger i = 0; i < dash.count; i++) {
            dashPattern[i] = [dash[i] floatValue];
        }
        CGContextSetLineDash(context, 0.0, dashPattern, dash.count);
        free(dashPattern);
    }

    CGContextMoveToPoint(context, 0.0, height / 2.0);
    CGContextAddLineToPoint(context, PAPER_WIDTH, height / 2.0);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef cgImage = image.CGImage;
    NSData *data = [self convertBitmapToPrinterArray:cgImage width:(int)PAPER_WIDTH height:height];
    
    return data;
}

+ (NSData *)twoColumnsBitmapWithLeftText:(NSString *)leftText rightText:(NSString *)rightText bold:(BOOL)bold size:(float)size {
    UIFont *font = [self getFontWithBold:bold size:size];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    
    CGSize leftSize = [leftText sizeWithAttributes:attributes];
    CGSize rightSize = [rightText sizeWithAttributes:attributes];
    
    if (leftSize.width + rightSize.width > PAPER_WIDTH) {
        [NSException raise:@"InvalidSize" format:@"Text too wide for paper"];
    }
    
    CGFloat lineHeight = [@"A" sizeWithAttributes:attributes].height;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(PAPER_WIDTH, lineHeight), YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setFill];
    CGContextFillRect(context, CGRectMake(0, 0, PAPER_WIDTH, lineHeight));
    
    [leftText drawAtPoint:CGPointMake(10.0, 0) withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor blackColor]
    }];
    
    [rightText drawAtPoint:CGPointMake(PAPER_WIDTH - rightSize.width - 10.0, 0) withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor blackColor]
    }];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef cgImage = image.CGImage;
    NSData *data = [self convertBitmapToPrinterArray:cgImage width:(int)PAPER_WIDTH height:(int)lineHeight];
    
    return data;
}

+ (NSData *)convertBitmapToPrinterArray:(CGImageRef)image width:(int)width height:(int)height {
    CGDataProviderRef provider = CGImageGetDataProvider(image);
    CFDataRef data = CGDataProviderCopyData(provider);
    const UInt8 *pixels = CFDataGetBytePtr(data);
    
    int bytesPerRow = (width + 7) / 8;
    NSMutableData *result = [NSMutableData dataWithLength:bytesPerRow * height];
    UInt8 *bytes = (UInt8 *)result.mutableBytes;
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int pixelIndex = (y * width + x) * 4; // RGBA
            UInt8 alpha = pixels[pixelIndex + 3];
            UInt8 r = pixels[pixelIndex];
            UInt8 g = pixels[pixelIndex + 1];
            UInt8 b = pixels[pixelIndex + 2];
            
            // Considerar pixel como preto se for escuro o suficiente
            BOOL isBlack = (r + g + b) / 3 < 128 && alpha > 128;
            
            if (isBlack) {
                int byteIndex = y * bytesPerRow + x / 8;
                int bitIndex = 7 - (x % 8);
                bytes[byteIndex] |= (1 << bitIndex);
            }
        }
    }
    
    // Adicionar comando de impressora
    NSMutableData *finalData = [NSMutableData data];
    const uint8_t header[] = {0x1D, 0x76, 0x30, 0x00};
    [finalData appendBytes:header length:4];
    uint8_t widthBytes[] = {(uint8_t)(width / 8), 0x00};
    [finalData appendBytes:widthBytes length:2];
    uint8_t heightBytes[] = {(uint8_t)(height), 0x00};
    [finalData appendBytes:heightBytes length:2];
    [finalData appendData:result];
    
    CFRelease(data);
    return finalData;
}

+ (NSArray *)wrapTextToLines:(NSString *)text font:(UIFont *)font maxWidth:(float)maxWidth {
    NSMutableArray *lines = [NSMutableArray array];
    NSArray *words = [text componentsSeparatedByString:@" "];
    NSMutableString *currentLine = [NSMutableString string];
    
    for (NSString *word in words) {
        NSString *testLine = [currentLine length] == 0 ? word : [NSString stringWithFormat:@"%@ %@", currentLine, word];
        CGSize size = [testLine sizeWithAttributes:@{NSFontAttributeName: font}];
        
        if (size.width <= maxWidth) {
            [currentLine setString:testLine];
        } else {
            if ([currentLine length] > 0) {
                [lines addObject:[currentLine copy]];
            }
            [currentLine setString:word];
        }
    }
    
    if ([currentLine length] > 0) {
        [lines addObject:[currentLine copy]];
    }
    
    return lines;
}

@end
