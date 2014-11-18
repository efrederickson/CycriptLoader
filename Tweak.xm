#import <cycript.h>
#include <objc/runtime.h>

extern "C" void CydgetSetupContext(JSGlobalContextRef);
extern CFBundleRef CFBundleGetBundleWithIdentifier ( CFStringRef bundleID );
extern "C" char ***_NSGetArgv(void);

#include <JavaScriptCore/JSContextRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include <JavaScriptCore/JSStringRefCF.h>
#include <JavaScriptCore/JSValueRef.h>

#define CLLog(fmt, ...) NSLog((@"[CycriptLoader] " fmt), ##__VA_ARGS__)
#define SCRIPT_PATH @"/Library/MobileSubstrate/Scripts/"

static __attribute__((constructor)) void __cycript_loader_init()
{
	NSArray *rawFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:SCRIPT_PATH error:nil];
	NSMutableArray *scripts = [[rawFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.cy' OR self ENDSWITH '.js'"]] mutableCopy];
	[scripts removeObject:@"__core.cy"];
	[scripts insertObject:@"__core.cy" atIndex:0];

	JSGlobalContextRef context = JSGlobalContextCreate(NULL);
	CydgetSetupContext(context);

	for (NSString *fileName in scripts) 
	{
		CLLog(@"Loading %@", fileName);
		NSError *error;
		NSString *cycript = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",SCRIPT_PATH,fileName] encoding:NSUTF8StringEncoding error:&error];
		if (error) 
		{
			CLLog(@"Error (could not read script %@): %@", fileName, error);
			continue;
		}

		NSString *plistName_ = [[fileName lastPathComponent] stringByDeletingPathExtension];
		NSString *plistName = [NSString stringWithFormat:@"%@.plist", plistName_];
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",SCRIPT_PATH,plistName]];

		BOOL shouldLoad = dict == nil;
		if (dict)
		{
			//CLLog(@"%@ has filter list", fileName);
			NSDictionary *filters = dict[@"Filter"];
			if (filters)
			{
				NSArray *bundles = filters[@"Bundles"];
				if (bundles)
				{
					for (NSString *bundle in bundles)
					{
						if (CFBundleGetBundleWithIdentifier((__bridge CFStringRef)bundle) != NULL)
						{
							shouldLoad = YES;
							break;
						}
					}
				}

				NSArray *executables = filters[@"Executables"];
				if (executables && [executables count] > 0)
				{
					char *args(**_NSGetArgv());
					char *name(strrchr(args, '/'));
					name = name == NULL ? args : name + 1;
					NSString *currentExecutableName = (__bridge NSString*)(CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, name, kCFStringEncodingUTF8, kCFAllocatorNull));

					for (NSString *validName in executables)
					{
						if ([currentExecutableName isEqual:validName])
						{
							shouldLoad = YES; 
							break;
						}
					}
				}

				NSArray *classes = filters[@"Classes"];
				if (classes)
				{
					for (NSString *class_ in classes)
					{
						if (objc_getClass(class_.UTF8String))
						{
							shouldLoad = YES;
							break;
						}
					}
				}

				if ([dict[@"Enabled"] boolValue] == NO)
				{
					shouldLoad = NO;
				}
			}
		}
		if (!shouldLoad)
		{
			CLLog(@"Not Loading %@ into %@", fileName, NSBundle.mainBundle.bundleIdentifier);
			continue;
		}

		size_t length = cycript.length;
	    unichar *buffer = (unichar*)malloc(length * sizeof(unichar));
	    [cycript getCharacters:buffer range:NSMakeRange(0, length)];
	    const uint16_t *characters = buffer;
	    CydgetMemoryParse(&characters, &length);
	    JSStringRef expression = JSStringCreateWithCharacters(characters, length);

	    JSValueRef exception = NULL;
	    //JSValueRef result = 
	    JSEvaluateScript(context, expression, NULL, NULL, 0, &exception);
	    free(buffer);
	    JSStringRelease(expression);

	    if (exception) {
	        JSObjectRef exceptionObject = JSValueToObject(context, exception, NULL);

	        NSInteger line = (NSInteger)JSValueToNumber(context, JSObjectGetProperty(context, exceptionObject, JSStringCreateWithUTF8CString("line"), NULL), NULL);

	        JSStringRef string = JSValueToStringCopy(context, JSObjectGetProperty(context, exceptionObject, JSStringCreateWithUTF8CString("name"), NULL), NULL);
	        NSString *name = (__bridge_transfer NSString *)JSStringCopyCFString(kCFAllocatorDefault, string);
	        JSStringRelease(string);

	        string = JSValueToStringCopy(context, JSObjectGetProperty(context, exceptionObject, JSStringCreateWithUTF8CString("message"), NULL), NULL);
	        NSString *message = (__bridge_transfer NSString *)JSStringCopyCFString(kCFAllocatorDefault, string);
	        JSStringRelease(string);

	        string = JSValueToStringCopy(context, exception, NULL);
	        NSString *description = (__bridge_transfer NSString *)JSStringCopyCFString(kCFAllocatorDefault, string);
	        JSStringRelease(string);

	        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	        [userInfo setValue:@(line) forKey:@"Line"];
	        [userInfo setValue:name forKey:@"ErrorName"];
	        [userInfo setValue:message forKey:@"ErrorMessage"];
	        [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
	        CLLog(@"Error loading script %@: %@", fileName, userInfo);
	    }
	    //else
	    //	CLLog(@"Loaded %@ successfully!", fileName);
	}
}