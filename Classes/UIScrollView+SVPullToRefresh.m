//
// UIScrollView+SVPullToRefresh.m
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <QuartzCore/QuartzCore.h>
#import "UIScrollView+SVPullToRefresh.h"
#import "SVPullToRefreshLoadingView.h"

//fequal() and fequalzro() from http://stackoverflow.com/a/1614761/184130
#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static CGFloat const SVPullToRefreshViewHeight = 60;
static CGFloat const changeBeginValue = 50;
static CGFloat const resetScrollViewOffsetDelay = 0;


@interface SVPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

@property (nonatomic, readwrite) SVPullToRefreshState state;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic, readwrite) CGFloat originalBottomInset;
@property (nonatomic, assign) BOOL wasTriggeredByUser;
@property (nonatomic, assign) BOOL showsPullToRefresh;
@property (nonatomic, assign) BOOL isObserving;

- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForLoading;
- (void)setScrollViewContentInset:(UIEdgeInsets)insets;

@end

#pragma mark - UIScrollView (SVPullToRefresh)
#import <objc/runtime.h>

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (SVPullToRefresh)

@dynamic pullToRefreshView;
@dynamic showsPullToRefresh;

- (void)addPullToRefreshWithCustomView:(UIView<CustomRefreshViewProtocol> *)customView actionHandler:(void (^)(void))actionHandler{
    
    if(!self.pullToRefreshView) {
        CGFloat yOrigin = -SVPullToRefreshViewHeight;
        
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        
        SVPullToRefreshView *view = [[SVPullToRefreshView alloc] initWithSubView:customView Frame:CGRectMake(0, yOrigin, width, SVPullToRefreshViewHeight)];
        view.pullToRefreshActionHandler = actionHandler;
        view.scrollView = self;
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        view.originalBottomInset = self.contentInset.bottom;
        self.pullToRefreshView = view;
        self.showsPullToRefresh = YES;
    }
}

- (void)triggerPullToRefresh {
//    [self.pullToRefreshView.animView pullingAnimWithPercent:1 state:SVPullToRefreshStateTriggered];
    if ([self.pullToRefreshView.animView canPerformAction:@selector(pullingAnimateWithPercent:state:) withSender:nil]) {
        [self.pullToRefreshView.animView pullingAnimateWithPercent:1 state:SVPullToRefreshStateTriggered];
    }
    
    self.pullToRefreshView.state = SVPullToRefreshStateTriggered;
    [self.pullToRefreshView startAnimating];
}

- (void)setPullToRefreshView:(SVPullToRefreshView *)pullToRefreshView {
    [self willChangeValueForKey:@"SVPullToRefreshView"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView,
                             pullToRefreshView,
                             OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"SVPullToRefreshView"];
}

- (SVPullToRefreshView *)pullToRefreshView {
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowsPullToRefresh:(BOOL)showsPullToRefresh {
    
    self.pullToRefreshView.hidden = !showsPullToRefresh;
    
    if(showsPullToRefresh) {
        if (!self.pullToRefreshView.isObserving) {
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.pullToRefreshView.isObserving = YES;
            
            CGFloat yOrigin = -SVPullToRefreshViewHeight;
            self.pullToRefreshView.frame = CGRectMake(0, yOrigin, self.bounds.size.width, SVPullToRefreshViewHeight);
        }
    }
    else {
        if (self.pullToRefreshView.isObserving) {
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentSize"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
            [self.pullToRefreshView resetScrollViewContentInset];
            self.pullToRefreshView.isObserving = NO;
        }
    }
}

- (BOOL)showsPullToRefresh {
    return !self.pullToRefreshView.hidden;
}

@end

// ===================================================================================
#pragma mark - CLASS SVPullToRefreshView
// ===================================================================================

@implementation SVPullToRefreshView

- (id)initWithSubView:(UIView<CustomRefreshViewProtocol> *)subView Frame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = SVPullToRefreshStateStopped;
        self.wasTriggeredByUser = YES;
        
        self.animView = subView;
        self.animView.frame = CGRectMake(0, 0, 80, 40);
//        self.animView = [[SORefreshAnimateView alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        [self addSubview:self.animView];
    }
    
    return self;
}

//- (id)initWithFrame:(CGRect)frame {
//    
//    if(self = [super initWithFrame:frame]) {
//        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//        self.state = SVPullToRefreshStateStopped;
//        self.wasTriggeredByUser = YES;
//        
//        self.animView = [[SORefreshAnimateView alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
//        [self addSubview:self.animView];
//    }
//    
//    return self;
//}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGRect viewBounds = self.animView.frame;
    CGPoint origin = CGPointMake(roundf((self.bounds.size.width-viewBounds.size.width)/2), roundf((self.bounds.size.height-viewBounds.size.height)/2));
    CGRect afterFrame = CGRectMake(origin.x, origin.y, viewBounds.size.width, viewBounds.size.height);
    self.animView.frame = afterFrame;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsPullToRefresh) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "SVPullToRefreshView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"contentSize"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}


#pragma mark - Scroll View

- (void)resetScrollViewContentInset {
    if (_state == SVPullToRefreshStateLoading) return;
    
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = self.originalTopInset;
    
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0);
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    currentInsets.top = MIN(offset, self.originalTopInset + self.bounds.size.height);
    [self setScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"contentSize"]) {
        [self layoutSubviews];
        
        CGFloat yOrigin = -SVPullToRefreshViewHeight;
        self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, SVPullToRefreshViewHeight);
    }
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];

}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if(self.state != SVPullToRefreshStateLoading)
    {
        CGFloat scrollOffsetThreshold = self.frame.origin.y - self.originalTopInset;
        
        if(self.state == SVPullToRefreshStateTriggered)
        {
            if (!self.scrollView.isDragging)
            {
                self.state = SVPullToRefreshStateLoading;
            }
            else if(self.scrollView.isDragging && contentOffset.y >= scrollOffsetThreshold && contentOffset.y < 0)
            {
                self.state = SVPullToRefreshStateStopped;
//                CGFloat percent = (contentOffset.y + changeBeginValue)/(scrollOffsetThreshold + changeBeginValue);
                
//                [self.animView pullingAnimWithPercent:percent state:_state];
            }
        }
        
        else if(self.state == SVPullToRefreshStateStopped)
        {
            if (contentOffset.y <= scrollOffsetThreshold && self.scrollView.isDragging)
            {
                self.state = SVPullToRefreshStateTriggered;
//                if ([_animView canPerformAction:@selector(pullingAnimateWithPercent:state:) withSender:nil]) {
//                    [_animView pullingAnimateWithPercent:1 state:_state];
//                }
//                [self.animView pullingAnimWithPercent:1 state:_state];
            }
            else if(contentOffset.y > scrollOffsetThreshold && contentOffset.y < 0)
            {
//                CGFloat percent = contentOffset.y / scrollOffsetThreshold;
                CGFloat percent = (contentOffset.y + changeBeginValue)/(scrollOffsetThreshold + changeBeginValue);
//                NSLog(@"contentOffset.y -> %f   ###   scrollOffsetThreshold -> %f", contentOffset.y, scrollOffsetThreshold);
//                NSLog(@"percent -> %f", percent);
                if ([_animView canPerformAction:@selector(pullingAnimateWithPercent:state:) withSender:nil]) {
                    [_animView pullingAnimateWithPercent:percent state:_state];
//                    NSLog(@"percent -> %f,  state -> %d", percent, _state);
                }
//                [self.animView pullingAnimWithPercent:percent state:_state];
            }
        }
        
        else if(self.state != SVPullToRefreshStateStopped )
        {
            if (contentOffset.y >= scrollOffsetThreshold) {
                self.state = SVPullToRefreshStateStopped;
            }
        }
    }
    else
    {
        CGFloat offset = MAX(self.scrollView.contentOffset.y * -1, 0.0f);
        offset = MIN(offset, self.originalTopInset + self.bounds.size.height);
        UIEdgeInsets contentInset = self.scrollView.contentInset;
        self.scrollView.contentInset = UIEdgeInsetsMake(offset, contentInset.left, contentInset.bottom, contentInset.right);
    }
}

#pragma mark -

- (void)startAnimating{
    
    if(fequalzero(self.scrollView.contentOffset.y)) {
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.frame.size.height) animated:YES];
        self.wasTriggeredByUser = NO;
    }
    else
        self.wasTriggeredByUser = YES;
    
    self.state = SVPullToRefreshStateLoading;
}

- (void)stopAnimating {
    self.state = SVPullToRefreshStateStopped;
    
    if(!self.wasTriggeredByUser)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(resetScrollViewOffsetDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_state != SVPullToRefreshStateLoading) {
                [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, -self.originalTopInset) animated:YES];
            }
        });
}

- (void)setState:(SVPullToRefreshState)newState {
    
    if(_state == newState)
        return;
    
    SVPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case SVPullToRefreshStateAll:
        case SVPullToRefreshStateStopped:
        {
//            NSLog(@"Stoped");
            if (previousState == SVPullToRefreshStateLoading) {
                if ([_animView canPerformAction:@selector(finishAnimate) withSender:nil]) {
                    [_animView finishAnimate];
                }
//                [self.animView finishAnim];
            }
            __weak __typeof(&*self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(resetScrollViewOffsetDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf resetScrollViewContentInset];
            });
        }
            break;
            
        case SVPullToRefreshStateTriggered:
//            NSLog(@"Triggered");
            break;
            
        case SVPullToRefreshStateLoading:
//            NSLog(@"Loading");
            
            if ([_animView canPerformAction:@selector(loadingAnimate) withSender:nil]) {
                [_animView loadingAnimate];
            }
//            [self.animView loadingAnim];
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == SVPullToRefreshStateTriggered && _pullToRefreshActionHandler)
                _pullToRefreshActionHandler();
            
            break;
    }
}

@end

