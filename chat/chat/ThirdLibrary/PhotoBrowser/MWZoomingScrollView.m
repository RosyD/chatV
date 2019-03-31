//
//  ZoomingScrollView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "MWZoomingScrollView.h"
#import "MWPhotoBrowser.h"
#import "MWPhoto.h"
#import "UIView+Additions.h"

// Declare private methods of browser
@interface MWPhotoBrowser ()
- (UIImage *)imageForPhoto:(id<MWPhoto>)photo;
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
@end

// Private methods and properties
@interface MWZoomingScrollView ()
@property (nonatomic, assign) MWPhotoBrowser *photoBrowser;
- (void)handleSingleTap:(CGPoint)touchPoint;
- (void)handleDoubleTap:(CGPoint)touchPoint;
@end

@implementation MWZoomingScrollView

@synthesize photoBrowser = _photoBrowser, photo = _photo, captionView = _captionView;

- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser {
    
    if ((self = [super init])) {
        
        // Delegate
        self.photoBrowser = browser;
        
		// Tap view for background
		_tapView = [[MWTapDetectingView alloc] initWithFrame:self.bounds];
		_tapView.tapDelegate = self;
		_tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_tapView.backgroundColor = [UIColor blackColor];
		[self addSubview:_tapView];
		
		// Image view
		_photoImageView = [[MWTapDetectingImageView alloc] initWithFrame:CGRectZero];
		_photoImageView.tapDelegate = self;
		_photoImageView.contentMode = UIViewContentModeCenter;
		_photoImageView.backgroundColor = [UIColor blackColor];
		[self addSubview:_photoImageView];
//        _photoImageView.center = CGPointMake(_photoImageView.center.x, self.size.height/2);
//		ITLog(([NSString stringWithFormat:@"contentSize::%f %f size::%f %f",self.contentSize.width,self.contentSize.height,self.size.width,self.size.height]));
		// Spinner
		_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		_spinner.hidesWhenStopped = YES;
		_spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:_spinner];
        
        //进度条
        if (self)
        {
            _progressHud = [[MBProgressHUD alloc] initWithView:self];
        }
        
        if (_progressHud)
        {
            [self addSubview:_progressHud];
            _progressHud.center = CGPointMake(self.size.width/2, self.size.height/2);
            _progressHud.labelText = @"        0%";
//            ITLog(([NSString stringWithFormat:@"%@",NSStringFromCGRect(_progressHud.frame)]));

        }
        
		// Setup
		self.backgroundColor = [UIColor blackColor];
		self.delegate = self;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
    }
    return self;
}

- (void)dealloc {
    
    if (_progressView) {
        [_progressView removeObserver:self forKeyPath:@"progress" context:nil];
    }
    _progressView = nil;
	[_tapView release];
	[_photoImageView release];
	[_spinner release];
    [_photo release];
    _photo = nil;
    [_progressHud release];
	[super dealloc];
}

- (void)setPhoto:(id<MWPhoto>)photo {
    
    _photoImageView.image = nil; // Release image
    if (_photo != photo) {
        [_photo release];
        _photo = [photo retain];
    }
    [self displayImage];
}

- (void)prepareForReuse {
    
    self.photo = nil;
    [_captionView removeFromSuperview];
    self.captionView = nil;
	_photoImageView.image = nil;
}

#pragma mark - Image

- (void)_displayImageWith:(UIImage *)img{
    
    // Hide spinner
    [_spinner stopAnimating];
    
    // Set image
    _photoImageView.alpha = 0;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    _photoImageView.image = img;
    _photoImageView.alpha = 1;
    [UIView commitAnimations];
    _photoImageView.hidden = NO;
    
    // Setup photo frame
    CGRect photoImageViewFrame;
    photoImageViewFrame.origin = CGPointZero;
    photoImageViewFrame.size = img.size;
    _photoImageView.frame = photoImageViewFrame;
//    _photoImageView.center = CGPointMake(_photoImageView.center.x, self.size.height/2);
    //            ITLog(([NSString stringWithFormat:@"contentSize::%f %f size::%f %f",self.contentSize.width,self.contentSize.height,self.size.width,self.size.height]));
    self.contentSize = photoImageViewFrame.size;
    
    //            if ([_progressView superview]!=nil)
    //            {
    //                [_progressView removeFromSuperview];
    //                _progressView = nil;
    //            }
    if (_progressView) {
        [_progressView removeObserver:self forKeyPath:@"progress" context:nil];
        [_progressHud hide:NO];
        _progressView = nil;
    }
    _progressView = [self.photoBrowser processbarForPhoto:_photo];
    //            ITLog(([NSString stringWithFormat:@"_progressView---->%p %@",_progressView,_photo]));
    if (![_progressView isKindOfClass:[NSNull class]]&&_progressView != nil) {
        //                [self addSubview:_progressView];
        _progressHud.labelText = [NSString stringWithFormat:@"  %.0f%%",[_progressView progress]*100];
        
        [_progressView addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        //                _progressView.frame = CGRectMake(10, self.bounds.size.height - 65, 300, 100);
        [_progressHud show:NO];
    }

    // Set zoom to minimum zoom
    [self setMaxMinZoomScalesForCurrentBounds];
}

// Get and display image
- (void)displayImage {
    
    self.scrollEnabled = NO; //https://github.com/mwaterfall/MWPhotoBrowser/issues/309
    
	if (_photo && _photoImageView.image == nil) {
		
		// Reset
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
		self.zoomScale = 1;
		self.contentSize = CGSizeMake(0, 0);
		
		// Get image from browser as it handles ordering of fetching
		UIImage *img = [self.photoBrowser imageForPhoto:_photo];
		if (img) {
            [self _displayImageWith:img];
		} else {
			// Hide image view
			_photoImageView.hidden = YES;
			[_spinner startAnimating];
		}
		[self setNeedsLayout];
	}
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"progress"]) {
        [self performSelectorOnMainThread:@selector(show:) withObject:[change objectForKey:NSKeyValueChangeNewKey] waitUntilDone:YES];
//        ITLog(([NSString stringWithFormat:@"%@",[change objectForKey:NSKeyValueChangeNewKey]]));
        if ([[change objectForKey:NSKeyValueChangeNewKey] floatValue] == 1.0) {
            [_progressHud hide:NO];
        }
    }
}

-(void)show:(NSNumber *)number
{
//    if (_progressHud == nil) {
//        _progressHud = [[MBProgressHUD alloc] initWithView:self.photoImageView];
//        [self.photoImageView addSubview:_progressHud];
//        _progressHud.center = CGPointMake(self.photoImageView.size.width/2, self.photoImageView.size.height/2);
//    }
    _progressHud.labelText = [NSString stringWithFormat:@"%.0f%%",[number floatValue]*100];
    [_progressHud show:NO];
}

// Image failed so just show black!
- (void)displayImageFailure {
    
	[_spinner stopAnimating];
    //出错后显示一个占位符
    [self _displayImageWith:[UIImage imageNamed:@"image_placeHolder.png"]]; //TXB
    [self setNeedsLayout]; //TXB
}

#pragma mark - Setup

/*
- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (_photoImageView ) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}
*/

- (void)setMaxMinZoomScalesForCurrentBounds {
    
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    // Bail if no image
    if (_photoImageView.image == nil) return;
    
    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // Image is smaller than screen so no zooming!
    if (xScale >= 1 && yScale >= 1) {
        minScale = 1.0;
    }
    
    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // Initial zoom
    /*
    self.zoomScale = [self initialZoomScaleWithMinScale];
    
    // If we're zooming to fill then centralise
    if (self.zoomScale != minScale) {
        // Centralise
        self.contentOffset = CGPointMake((imageSize.width * self.zoomScale - boundsSize.width) / 2.0,
                                         (imageSize.height * self.zoomScale - boundsSize.height) / 2.0);
        // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
        self.scrollEnabled = NO;
    }*/
    
    self.zoomScale = minScale;
    
    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    _photoImageView.center = CGPointMake(_photoImageView.center.x, self.size.height/2);

    
    // Layout
    [self setNeedsLayout];
    
}


/*
- (void)setMaxMinZoomScalesForCurrentBounds {
	
	// Reset
	self.maximumZoomScale = 1;
	self.minimumZoomScale = 1;
	self.zoomScale = 1;
	
	// Bail
	if (_photoImageView.image == nil) return;
	
	// Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    
    // Calculate Min
    CGFloat xScale = (boundsSize.width-5) / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = (boundsSize.height-5) / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
	
	// If image is smaller than the screen then ensure we show it at
	// min scale of 1
	if (xScale > 1 && yScale > 1) {
		minScale = 1.0;
	}
    
	// Calculate Max
	CGFloat maxScale = 3.0; // Allow double scale
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
	if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
		maxScale = maxScale / [[UIScreen mainScreen] scale];
	}
	
	// Set
	self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    self.zoomScale = minScale;
	
	// Reset position
	_photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    _photoImageView.center = CGPointMake(_photoImageView.center.x, self.size.height/2);
    
//    NSLog(@"_photoImageView %@ %f,%f,%f",NSStringFromCGRect(_photoImageView.frame),self.maximumZoomScale,self.minimumZoomScale,self.zoomScale);

    
//    NSLog((([NSString stringWithFormat:@"contentSize::%f %f size::%f %f",self.contentSize.width,self.contentSize.height,self.size.width,self.size.height]));
	[self setNeedsLayout];

}*/

#pragma mark - Layout

- (void)layoutSubviews {
	
	// Update tap view frame
	_tapView.frame = self.bounds;


	// Spinner
	if (!_spinner.hidden) _spinner.center = CGPointMake(floorf(self.bounds.size.width/2.0),
													  floorf(self.bounds.size.height/2.0));
    // Super
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
        _photoImageView.frame = frameToCenter;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
	return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    // https://github.com/mwaterfall/MWPhotoBrowser/issues/309
    // 修改，在某个特殊状态下，出现不能滑动翻页的情况
    if (self.zoomScale > 1.0f) { // check if it is zoomed in
        self.scrollEnabled = NO;
    }
    else {
        self.scrollEnabled = YES; // reset
    }
//    self.scrollEnabled = YES; // reset
	[_photoBrowser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
	[_photoBrowser hideControlsAfterDelay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
    
	[_photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
}


- (void)handleDoubleTap:(CGPoint)touchPoint {
	
	// Cancel any single tap handling
	[NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
	
	// Zoom
    if (self.zoomScale != self.minimumZoomScale){// && self.zoomScale != [self initialZoomScaleWithMinScale]) {
		
		// Zoom out
		[self setZoomScale:self.minimumZoomScale animated:YES];
		
	} else {
		
		// Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];

	}
	
	// Delay controls
	[_photoBrowser hideControlsAfterDelay];
	
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch {
    
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    
    [self handleDoubleTap:[touch locationInView:imageView]];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleSingleTap:CGPointMake(touchX, touchY)];
}
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleDoubleTap:CGPointMake(touchX, touchY)];
}

@end
