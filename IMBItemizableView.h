//
//  IMBItemizableView.h
//  iMedia
//
//  Created by Jörg Jacobsen on 10.05.15.
//
//

#ifndef iMedia_IMBItemizableView_h
#define iMedia_IMBItemizableView_h

@protocol IMBItemizableView <NSObject>

/**
 */
- (void)scrollIndexToVisible:(NSInteger)index;

/**
 */
- (NSInteger)firstVisibleItemIndex;

@end

#endif
