//
//  IMBApertureParserConfiguration.m
//  iMedia
//
//  Created by Jörg Jacobsen on 11.03.15.
//
//

#import "IMBApertureParserConfiguration.h"
#import "NSImage+iMedia.h"
#import "IMBIconCache.h"

/**
 Reverse-engineered keys of the Photos app media source's attributes.
 
 Apple doesn't seem to yet publicly define these constants anywhere.
 */
/* Top Level Groups*/
NSString *kIMBApertureMediaGroupIdentifierAllProjects = @"AllProjectsItem";
NSString *kIMBApertureMediaGroupIdentifierLastViewedEvent = @"eventFilterBarAlbum";

/**
 Parser configuration factory for Apple iPhoto app.
 */
IMBMLParserConfigurationFactory IMBMLApertureParserConfigurationFactory =
^IMBAppleMediaLibraryParserConfiguration *(MLMediaType mediaType)
{
    NSSet *identifiersOfNonUserCreatedGroups = [NSSet setWithObjects:
                                                nil];
    
    return [[IMBApertureParserConfiguration alloc] initWithMediaSourceIdentifier:MLMediaSourceApertureIdentifier
                                                    AppleMediaLibraryMediaType:mediaType
                                             identifiersOfNonUserCreatedGroups:identifiersOfNonUserCreatedGroups];
};

@implementation IMBApertureParserConfiguration

/**
 */
- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError
{
    if (outError) *outError = nil;
    
    // Map metadata information from Aperture library representation (MLMediaObject.attributes) to iMedia representation
    
    NSMutableDictionary* externalMetadata = [NSMutableDictionary dictionaryWithDictionary:inObject.preliminaryMetadata];
    
    [externalMetadata addEntriesFromDictionary:[NSImage imb_metadataFromImageAtURL:inObject.URL checkSpotlightComments:NO]];
    
    // Add Aperture-specific entries to external dictionary here
    
    return [NSDictionary dictionaryWithDictionary:externalMetadata];
}

/**
 Hardcoded library name.
 */
- (NSString *)libraryName
{
    return @"Aperture";
}

- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *unqualifiedGroupIdentifiers = [NSSet setWithObjects:
                                          kIMBApertureMediaGroupIdentifierAllProjects,
                                          kIMBApertureMediaGroupIdentifierLastViewedEvent,
                                          nil];
    return (![unqualifiedGroupIdentifiers containsObject:mediaGroup.identifier]);
}

- (BOOL)shouldReuseMediaObjectsOfParentGroupForGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *qualifiedGroupIdentifiers = [NSSet setWithObjects:
                                        nil];
    
    return [qualifiedGroupIdentifiers containsObject:mediaGroup.identifier];
}

//- (NSImage *)groupIconForTypeIdentifier:(NSString *)typeIdentifier highlight:(BOOL)highlight
//{
//    return nil;
//}

- (NSImage *)groupIconForTypeIdentifier:(NSString *)typeIdentifier highlight:(BOOL)highlight
{
    // Note that for icon types starting with "v3-" we havn't yet found a matching type identifier replacement
    
    static const IMBIconTypeMappingEntry kIconTypeMappingEntries[] =
    {
        // Icon Type                        Application Icon Name            Fallback Icon Name
        {@"com.apple.Aperture.PhotoStreamAlbum",        @"SL-stream",                   @"folder",	nil,	nil},   // photo stream
        {@"com.apple.Aperture.FacesAlbum",              @"SL-faces",                    @"folder",	nil,	nil},   // faces
        {@"com.apple.Aperture.PlacesAlbum",             @"SL-places",                   @"folder",	nil,	nil},   // faces
        {@"com.apple.Aperture.MonthAlbum",              @"SL-customLast",               @"folder",	nil,	nil},   // faces
        {@"com.apple.Aperture.UserAlbum",               @"SL-album",					@"folder",	nil,	nil},	// album
        {@"com.apple.Aperture.LibraryAlbums",           @"SL-smartAlbum",				@"folder",	nil,	nil},	// smart album
        {@"com.apple.Aperture.UserSmartAlbum",          @"SL-smartAlbum",				@"folder",	nil,	nil},	// library **** ... 200X
        {@"com.apple.Aperture.ProjectAlbum",            @"SL-project",					@"folder",	nil,	nil},	// project
        {@"com.apple.Aperture.LastViewedEvent",         @"SL-project",					@"folder",	nil,	nil},	// project
        {@"com.apple.Aperture.AllProjects",             @"SL-allProjects",				@"folder",	nil,	nil},	// library (top level)
        {@"com.apple.Aperture.FolderAlbum",             @"SL-folder",					@"folder",	nil,	nil},	// folder
        {@"v3-7",	@"SL-folder",					@"folder",	nil,	nil},	// sub-folder of project
        {@"v3-8",	@"SL-book",                     @"folder",	nil,	nil},	// book
        {@"v3-9",	@"SL-webpage",					@"folder",	nil,	nil},	// web gallery
        {@"v3-9",	@"Project_I_WebGallery",		@"folder",	nil,	nil},	// web gallery (alternate image)
        {@"v3-10",	@"SL-webJournal",				@"folder",	nil,	nil},	// web journal
        {@"v3-11",	@"SL-lightTable",				@"folder",	nil,	nil},	// light table
        {@"v3-13",	@"sl-icon-small_webGallery",	@"folder",	nil,	nil},	// smart web gallery
        {@"v3-19",	@"SL-slideshow",				@"folder",	nil,	nil},	// slideshow
        {@"com.apple.Aperture.AllPhotos",               @"SL-photos",					@"folder",	nil,	nil},	// photos
        {@"com.apple.Aperture.Flagged",                 @"SL-flag",						@"folder",	nil,	nil},	// flagged
        {@"v3-96",	@"SL-smartLibrary",             @"folder",	nil,	nil},	// library albums
        {@"v3-97",	@"SL-allProjects",				@"folder",	nil,	nil},	// library
        {@"v3-98",	@"AppIcon.icns",				@"folder",	nil,	nil},	// library
        {@"v3-99",	@"List_Icons_Library",			@"folder",	nil,	nil},	// library (knot holding all images)
        {@"com.apple.Aperture.LastImportAlbum",         @"SL-LastImport",               @"folder",	nil,	nil},	// last import
    };
    static const IMBIconTypeMapping kIconTypeMapping =
    {
        sizeof(kIconTypeMappingEntries) / sizeof(kIconTypeMappingEntries[0]),
        kIconTypeMappingEntries,
        @"_S"
    };
    
//    // Since icons are different for different versions of Aperture, we are adding the prefix v2- or v3-
//    // to the album type so that we can store different icons (for each version) in the icon cache...
//    
//    NSString* type = [@"v3-" stringByAppendingString:typeIdentifier];
    return [[IMBIconCache sharedIconCache] iconForType:typeIdentifier
                                          fromBundleID:@"com.apple.Aperture"
                                      withMappingTable:&kIconTypeMapping
                                             highlight:highlight
                          considerGenericFallbackImage:NO];
}

@end
