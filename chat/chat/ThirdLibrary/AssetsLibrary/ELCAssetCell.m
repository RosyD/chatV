//
//  AssetCell.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAssetTablePicker.h"

#define ELCOverlayImageView UIImageView

#define photoWidth (kScreen_Width - 4 * 5)/4

@interface ELCAssetCell ()

@property (nonatomic, strong) NSArray *rowAssets;
@property (nonatomic, strong) NSMutableArray *imageViewArray;
@property (nonatomic, strong) NSMutableArray *overlayViewArray;

@end

@implementation ELCAssetCell

//Using auto synthesizers

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self) {
        
//        if(!_notAllowTap)
        {
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
            [self addGestureRecognizer:tapRecognizer];
        }
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.imageViewArray = mutableArray;
        
        NSMutableArray *overlayArray = [[NSMutableArray alloc] initWithCapacity:4];
        self.overlayViewArray = overlayArray;
        
        self.alignmentLeft = YES;
	}
	return self;
}

-(UIImage*)overlayImage:(ELCAsset *)asset{
    return asset.selected?_superAssetTablePicker.cellOverlayImageForSelected:_superAssetTablePicker.cellOverlayImageForUnSelect;
}

//#ifdef ACUtility_Need_Log
//-(void)dealloc{
//    ITLog(@"");
//}
//#endif

- (void)setAssets:(NSArray *)assets
{
    self.rowAssets = assets;
	for (UIImageView *view in _imageViewArray) {
        [view removeFromSuperview];
	}
    for (ELCOverlayImageView *view in _overlayViewArray) {
        [view removeFromSuperview];
	}
    //set up a pointer here so we don't keep calling [UIImage imageNamed:] if creating overlays
//    UIImage *overlayImage = nil;
    for (int i = 0; i < [_rowAssets count]; ++i) {

        ELCAsset *asset = [_rowAssets objectAtIndex:i];
        UIImageView *imageView = nil;
        
        if (i < [_imageViewArray count]) {
            imageView = [_imageViewArray objectAtIndex:i];
            
        } else {
            imageView = [[UIImageView alloc] init];
            [_imageViewArray addObject:imageView];
        }
        
        imageView.image = nil;
        [asset loadThumbWithBlock:^(UIImage *img) {
            imageView.image = img;
        }];
        
        if (i < [_overlayViewArray count]) {
            ELCOverlayImageView *overlayView = [_overlayViewArray objectAtIndex:i];
            overlayView.image   =   [self overlayImage:asset];
//            overlayView.hidden = asset.selected ? NO : YES;
//            overlayView.labIndex.text = [NSString stringWithFormat:@"%d", asset.index + 1];
        } else {
            ELCOverlayImageView *overlayView = [[ELCOverlayImageView alloc] initWithImage:[self overlayImage:asset]];
            [_overlayViewArray addObject:overlayView];
//            overlayView.hidden = asset.selected ? NO : YES;
//            overlayView.labIndex.text = [NSString stringWithFormat:@"%d", asset.index + 1];
        }
    }
}

#define ELCOverlayImageView_Button_WH   44

- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:self];
    int c = (int32_t)self.rowAssets.count;
    //
    CGFloat totalWidth = c * photoWidth + (c - 1) * 4;
    CGFloat startX;
    
    if (self.alignmentLeft) {
        startX = 4;
    }else {
        startX = (self.bounds.size.width - totalWidth) / 2;
    }
    
    //
	CGRect frame = CGRectMake(startX, 2, photoWidth, photoWidth);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
        if (CGRectContainsPoint(frame, point)) {
            
            //取得点击在ELCOverlayImageView中的位置
            point.x -=  frame.origin.x;
            point.y -=  frame.origin.y;
            
            ELCAsset *asset = [_rowAssets objectAtIndex:i];
            if(CGRectContainsPoint(CGRectMake(photoWidth-2-ELCOverlayImageView_Button_WH, 2, ELCOverlayImageView_Button_WH, ELCOverlayImageView_Button_WH), point)){
                //在按钮上
//                NSLog(@"%@",NSStringFromCGPoint(point));
                asset.selected = !asset.selected;
                ELCOverlayImageView *overlayView = [_overlayViewArray objectAtIndex:i];
                overlayView.image = [self overlayImage:asset];
            }
            else{
                [_superAssetTablePicker previewWithELCAsset:asset];
            }
            
            
//            overlayView.hidden = !asset.selected;
//TXB
            /*
            if (asset.selected) {
                asset.index = [[ELCConsole mainConsole] numOfSelectedElements];
                [overlayView setIndex:asset.index+1];
               [[ELCConsole mainConsole] addIndex:asset.index];
            }
            else
            {
                int lastElement = [[ELCConsole mainConsole] numOfSelectedElements] - 1;
                [[ELCConsole mainConsole] removeIndex:lastElement];
            }*/
            break;
        }
        frame.origin.x = frame.origin.x + frame.size.width + 4;
    }
}

- (void)layoutSubviews
{
    int c = (int32_t)self.rowAssets.count;
    CGFloat totalWidth = c * photoWidth + (c - 1) * 4;
    CGFloat startX;
    
    if (self.alignmentLeft) {
        startX = 4;
    }else {
        startX = (self.bounds.size.width - totalWidth) / 2;
    }
    
	CGRect frame = CGRectMake(startX, 2, photoWidth, photoWidth);
	
	for (int i = 0; i < [_rowAssets count]; ++i) {
		UIImageView *imageView = [_imageViewArray objectAtIndex:i];
		[imageView setFrame:frame];
		[self addSubview:imageView];
        
        ELCOverlayImageView *overlayView = [_overlayViewArray objectAtIndex:i];
        [overlayView setFrame:frame];
        [self addSubview:overlayView];
		
		frame.origin.x = frame.origin.x + frame.size.width + 4;
	}
}


@end
