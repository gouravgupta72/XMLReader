//
//  XMLReader.m
//
//  Created by Gourav Gupta on 11/11/13.

#import "XMLReader.h"

@interface XMLReader (Internal)

- (id)initWithError:(NSError *__autoreleasing *)error;
- (NSDictionary *)objectWithData:(NSData *)data;

@end

@implementation NSDictionary (XMLReaderNavigation)

@end

@implementation XMLReader

#pragma mark - XMLReader

// Method to remove presiding blank
-(NSString *) RemoveExtraSpace:(NSString *)datastring
{
    if (([datastring rangeOfString:@"\n        "].length>0) )
    {
        datastring=[datastring stringByReplacingOccurrencesOfString:@"\n        " withString:@""];
    }else
        if (([datastring rangeOfString:@"\n        "].length>0) )
        {
            datastring=[datastring stringByReplacingOccurrencesOfString:@"\n        " withString:@""];
        }else
            if (([datastring rangeOfString:@"\n       "].length>0) )
            {
                datastring=[datastring stringByReplacingOccurrencesOfString:@"\n       " withString:@""];
            }else
                if (([datastring rangeOfString:@"\n      "].length>0) )
                {
                    datastring=[datastring stringByReplacingOccurrencesOfString:@"\n      " withString:@""];
                }else if (([datastring rangeOfString:@"\n      "].length>0) )
                {
                    datastring=[datastring stringByReplacingOccurrencesOfString:@"\n     " withString:@""];
                }else if (([datastring rangeOfString:@"\n    "].length>0) )
                {
                    datastring=[datastring stringByReplacingOccurrencesOfString:@"\n    " withString:@""];
                }else if (([datastring rangeOfString:@"\n   "].length>0) )
                {
                    datastring=[datastring stringByReplacingOccurrencesOfString:@"\n   " withString:@""];
                }else if (([datastring rangeOfString:@"\n  "].length>0) )
                {
                    datastring=[datastring stringByReplacingOccurrencesOfString:@"\n  " withString:@""];
                }else if (([datastring rangeOfString:@"\n "].length>0) )
                {
                    datastring=[datastring stringByReplacingOccurrencesOfString:@"\n " withString:@""];
                }else if (([datastring rangeOfString:@"\n"].length>0) )
                {
                    datastring=[datastring stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                } 
    
    return datastring;
}


// Method to parse xml from NSData .

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data  error:(NSError *__autoreleasing *)error
{
    XMLReader *reader = [[XMLReader alloc] initWithError:error];
    NSDictionary *rootDictionary = [reader objectWithData:data];
    return rootDictionary;
}


// Method to parse xml from NSSting .
+ (NSDictionary *)dictionaryForXMLString:(NSString *)string  error:(NSError *__autoreleasing *)error;
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [XMLReader dictionaryForXMLData:data error:error];
    
}


#pragma mark - Parsing

- (id)initWithError:(NSError *__autoreleasing *)error
{
    if ((self = [super init]))
    {
        errorPointer = error;
        dictionaryStack = [[NSMutableArray alloc]init];
    }
    
    return self;
}

- (NSDictionary *)objectWithData:(NSData *)data
{
    // Clear out any old data
    
    dictionaryStack = [[NSMutableArray alloc]init];
    textInProgress = [NSMutableString stringWithString:@""];
    
    // Initialize the stack with a fresh dictionary
    [dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    // Parse the XML
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = self;
    BOOL success = [parser parse];
    
    // Return the stack's root dictionary on success
    if (success)
    {
        NSDictionary *resultDict = [dictionaryStack objectAtIndex:0];
        return resultDict;
    }
    
    return nil;
}



#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = [dictionaryStack lastObject];
   
    // Create the child dictionary for the new element
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    
    // Initialize child dictionary with the attributes, prefixed with '@'
    for (NSString *key in attributeDict) {
        [childDict setValue:[attributeDict objectForKey:key]
                     forKey:[NSString stringWithFormat:@"%@", key]];
    }
    
	    // If there's already an item for this key, it means we need to create an array
    id existingValue = [parentDict objectForKey:elementName];
    
    if (existingValue)
    {
        NSMutableArray *array = nil;
        
        if ([existingValue isKindOfClass:[NSMutableArray class]])
        {
            // The array exists, so use it
            array = (NSMutableArray *) existingValue;
        }
        else
        {
            // Create an array if it doesn't exist
            array = [NSMutableArray array];
            [array addObject:existingValue];
            
            // Replace the child dictionary with an array of children dictionaries
            [parentDict setObject:array forKey:elementName];
            
        }
        
        // Add the new child dictionary to the array
        [array addObject:childDict];
       
    }
    else
    {
        // No existing value, so update the dictionary
        [parentDict setObject:childDict forKey:elementName];
       
    }
    // Update the stack
    [dictionaryStack addObject:childDict];
   
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // Update the parent dict with text info
    NSMutableDictionary *dictInProgress = [dictionaryStack lastObject];
    // Pop the current dict
    [dictionaryStack removeLastObject];
    // Set the text property
    if ([textInProgress length] > 0)
    {
        if ([dictInProgress count] > 0)
        {
            [dictInProgress setObject:textInProgress forKey:elementName];
            
        }
        else
        {
            // Given that there will only ever be a single value in this dictionary, let's replace the dictionary with a simple string.
            NSMutableDictionary *parentDict = [dictionaryStack lastObject];
            
            id parentObject = [parentDict objectForKey:elementName];
            
            // Parent is an Array
            if ([parentObject isKindOfClass:[NSArray class]])
            {
                [parentObject removeLastObject];
                [parentObject addObject:textInProgress];
                
            }
            
            // Parent is a Dictionary
            else
            {
                [parentDict removeObjectForKey:elementName];
                [parentDict setObject:textInProgress forKey:elementName];
                
            }
        }
        
        // Reset the text
        textInProgress = [NSMutableString stringWithString:@""];
    }
    
    // If there was no value for the tag, and no attribute, then remove it from the dictionary.
    else if ([dictInProgress count] == 0)
    {
        NSMutableDictionary *parentDict = [dictionaryStack lastObject];
        [parentDict removeObjectForKey:elementName];
        
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    
    [textInProgress appendString:[self RemoveExtraSpace:string]];

}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    // Set the error pointer to the parser's error object
    if (errorPointer)
        *errorPointer = parseError;
}



@end