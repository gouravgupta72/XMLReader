//
//  XMLReader.h
//
//  Created by Gourav Gupta on 11/11/13.

#import <Foundation/Foundation.h>


@interface XMLReader : NSObject<NSXMLParserDelegate>
{
    NSMutableArray *dictionaryStack;
    NSMutableString *textInProgress;
     NSError *__autoreleasing *errorPointer;
   
}
//+(void) parseXMLFileAtURL;
+ (NSDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError *__autoreleasing *)error;
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string error:(NSError *__autoreleasing *)error;

@end
