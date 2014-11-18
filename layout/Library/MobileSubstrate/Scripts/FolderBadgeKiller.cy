var orig = { };

/*
%hook SBFolderIcon
- (void)setBadge:(id)badge { }
%end
*/

MS.hookMessage(SBFolderIcon, @selector(setBadge:), function() { NSLog("Killed badge"); }, orig);