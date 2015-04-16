//
//  IMBiPhotoParserConfiguration.m
//  iMedia
//
//  Created by Jörg Jacobsen on 10.03.15.
//
//

#import "IMBiPhotoParserConfiguration.h"
#import "NSImage+iMedia.h"
#import "IMBIconCache.h"

/**
 Attribute keys supported by iPhoto media source (as of OS X 10.10.3)
 */
NSString *kIMBiPhotoMediaGroupIdentifierEvents = @"AllProjectsItem";
NSString *kIMBiPhotoMediaGroupIdentifierPhotos = @"allPhotosAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierFaces = @"peopleAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierPlaces = @"allPlacedPhotosAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierLast12Months = @"lastNMonthsAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierLastImport = @"lastImportAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierFlagged = @"flaggedAlbum";
NSString *kIMBiPhotoMediaGroupIdentifierEventFilterBar = @"eventFilterBarAlbum";

/**
 Parser configuration factory for Apple iPhoto app.
 */
IMBMLParserConfigurationFactory IMBMLiPhotoParserConfigurationFactory =
^IMBAppleMediaLibraryParserConfiguration *(MLMediaType mediaType)
{
    NSSet *identifiersOfNonUserCreatedGroups = [NSSet setWithObjects:
                                                kIMBiPhotoMediaGroupIdentifierEvents,
                                                kIMBiPhotoMediaGroupIdentifierPhotos,
                                                kIMBiPhotoMediaGroupIdentifierFaces,
                                                kIMBiPhotoMediaGroupIdentifierPlaces,
                                                kIMBiPhotoMediaGroupIdentifierLast12Months,
                                                kIMBiPhotoMediaGroupIdentifierLastImport,
                                                kIMBiPhotoMediaGroupIdentifierFlagged,
                                                nil];
    
    return [[IMBiPhotoParserConfiguration alloc] initWithMediaSourceIdentifier:MLMediaSourceiPhotoIdentifier
                                                               AppleMediaLibraryMediaType:mediaType
                                                        identifiersOfNonUserCreatedGroups:identifiersOfNonUserCreatedGroups];
};

@implementation IMBiPhotoParserConfiguration

/**
 */
- (NSDictionary*) metadataForObject:(IMBObject*)inObject error:(NSError**)outError
{
    if (outError) *outError = nil;
    
    // Map metadata information from iPhoto library representation (MLMediaObject.attributes) to iMedia representation
    
    NSMutableDictionary* externalMetadata = [NSMutableDictionary dictionaryWithDictionary:inObject.preliminaryMetadata];
    
    [externalMetadata addEntriesFromDictionary:[NSImage imb_metadataFromImageAtURL:inObject.URL checkSpotlightComments:NO]];
    
    return [NSDictionary dictionaryWithDictionary:externalMetadata];
}

/**
 Hardcoded library name.
 */
- (NSString *)libraryName
{
    return @"iPhoto";
}

- (BOOL)shouldUseMediaGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *unqualifiedGroupIdentifiers = [NSSet setWithObjects:
                                          kIMBiPhotoMediaGroupIdentifierEventFilterBar,
                                          nil];
    return (![unqualifiedGroupIdentifiers containsObject:mediaGroup.identifier]);
}

- (BOOL)shouldReuseMediaObjectsOfParentGroupForGroup:(MLMediaGroup *)mediaGroup
{
    NSSet *qualifiedGroupIdentifiers = [NSSet setWithObjects:
//                                        kIMBiPhotoMediaGroupIdentifierEvents,
                                        kIMBiPhotoMediaGroupIdentifierPhotos,
                                        nil];
    
    return [qualifiedGroupIdentifiers containsObject:mediaGroup.identifier];
}

- (MLMediaObject *)keyMediaObjectForMediaGroup:(MLMediaGroup *)mediaGroup fromMediaSource:(MLMediaSource *)mediaSource
{
    NSString *keyPhotoKey = mediaGroup.attributes[@"KeyPhotoKey"];
    
    if (keyPhotoKey) {
        return [mediaSource mediaObjectForIdentifier:keyPhotoKey];
    }
    return nil;
}

- (NSImage *)groupIconForTypeIdentifier:(NSString *)typeIdentifier highlight:(BOOL)highlight
{
    // Note that for icon types lacking a name space prefix we havn't yet found a matching type identifier replacement
    
    static const IMBIconTypeMappingEntry kIconTypeMappingEntries[] =
    {
        // Icon Type                Application Icon Name            Fallback Icon Name
        
        {@"Book",					@"sl-icon-small_book",				@"folder",	nil,				nil},
        {@"Calendar",				@"sl-icon-small_calendar",			@"folder",	nil,				nil},
        {@"Card",					@"sl-icon-small_card",				@"folder",	nil,				nil},
        {@"com.apple.iPhoto.RollAlbum",					@"sl-icon-small_events",            @"folder",	nil,				nil},
        {@"com.apple.iPhoto.EventsFolder",              @"sl-icon-small_events",			@"folder",	nil,				nil},
        {@"com.apple.iPhoto.FacesAlbum",				@"sl-icon-small_people",			@"folder",	nil,				nil},
        {@"com.apple.iPhoto.PlacesAlbum",				@"sl-icon-small_places",			@"folder",	nil,				nil},
        {@"com.apple.iPhoto.FlaggedAlbum",				@"sl-icon-small_flag",				@"folder",	nil,				nil},
        {@"com.apple.iPhoto.FacebookProject",			@"sl-icon-small_facebook",			@"folder",	nil,				nil},
        {@"com.apple.iPhoto.FolderAlbum",				@"sl-icon-small_folder",			@"folder",	nil,				nil},
        {@"com.apple.iPhoto.PhotoStreamAlbum",			@"sl-icon-small_photostream",		@"folder",	nil,				nil},
        {@"Photocasts",				@"sl-icon-small_subscriptions",     @"folder",	nil,				nil},
        {@"com.apple.iPhoto.LibraryAlbum",				@"sl-icon-small_library",			@"folder",	nil,				nil},
        {@"com.apple.iPhoto.Album",                     @"sl-icon-small_album",             @"folder",	nil,				nil},
        {@"Roll",					@"sl-icon-small_roll",				@"folder",	nil,				nil},
        {@"Selected Event Album",	@"sl-icon-small_event",             @"folder",	nil,				nil},
        {@"Shelf",					@"sl-icon_flag",					@"folder",	nil,				nil},
        {@"com.apple.iPhoto.SlideShow",                 @"sl-icon-small_slideshow",         @"folder",	nil,				nil},
        {@"com.apple.iPhoto.SmartAlbum",				@"sl-icon-small_smartAlbum",		@"folder",	nil,				nil},
        {@"com.apple.iPhoto.MonthAlbum",                @"sl-icon-small_cal",				@"folder",	nil,				nil},
        {@"com.apple.iPhoto.SpecialAlbum",              @"sl-icon_lastImport",				@"folder",	nil,				nil},
        {@"Subscribed",				@"sl-icon-small_subscribedAlbum",	@"folder",	nil,				nil}
//        {@"Wildcard",				@"sl-icon-small_album",             @"folder",	nil,				nil}	// fallback image
    };
    
    static const IMBIconTypeMapping kIconTypeMapping =
    {
        sizeof(kIconTypeMappingEntries) / sizeof(kIconTypeMappingEntries[0]),
        kIconTypeMappingEntries,
        @"-sel"
    };
    
    return [[IMBIconCache sharedIconCache] iconForType:typeIdentifier
                                          fromBundleID:@"com.apple.iPhoto"
                                      withMappingTable:&kIconTypeMapping
                                             highlight:highlight
                          considerGenericFallbackImage:NO];
}

@end
