@import com.saurik.substrate.MS;

/* FROM http://iphonedevwiki.net/index.php/Cycript_Tricks */

NSLog_ = dlsym(RTLD_DEFAULT, "NSLog")
NSLog = function() { var types = 'v', args = [], count = arguments.length; for (var i = 0; i != count; ++i) { types += '@'; args.push(arguments[i]); } new Functor(NSLog_, types).apply(null, args); }

function include(fn) {
  var t = [new NSTask init]; [t setLaunchPath:@"/usr/bin/cycript"]; [t setArguments:["-c", fn]];
  var p = [NSPipe pipe]; [t setStandardOutput:p]; [t launch]; [t waitUntilExit]; 
  var s = [new NSString initWithData:[[p fileHandleForReading] readDataToEndOfFile] encoding:4];
  return this.eval(s.toString());
}

function loadFramework(fw) {
  var h="/System/Library/",t="Frameworks/"+fw+".framework";
  [[NSBundle bundleWithPath:h+t]||[NSBundle bundleWithPath:h+"Private"+t] load];
}