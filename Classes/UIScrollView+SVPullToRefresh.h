//
// UIScrollView+SVPullToRefresh.h
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVPullToRefresh
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

@class SVPullToRefreshView;
@class SVPullToRefreshLoadingView;
@class SORefreshAnimateView;

typedef NS_ENUM(NSUInteger, SVPullToRefreshState) {
    SVPullToRefreshStateStopped = 0,
    SVPullToRefreshStateTriggered,
    SVPullToRefreshStateLoading,
    SVPullToRefreshStateAll = 10
};

@protocol CustomRefreshViewProtocol <NSObject>
@optional
- (void)pullingAnimateWithPercent:(CGFloat)percent state:(SVPullToRefreshState)state;
- (void)loadingAnimate;
- (void)finishAnimate;
@end


@interface UIScrollView (SVPullToRefresh)

//- (void)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler;
- (void)addPullToRefreshWithCustomView:(UIView<CustomRefreshViewProtocol> *)customView
                         actionHandler:(void (^)(void))actionHandler;
- (void)triggerPullToRefresh;

@property (nonatomic, strong, readonly) SVPullToRefreshView *pullToRefreshView;
@property (nonatomic, assign) BOOL showsPullToRefresh;

@end


// ===================================================================================
#pragma mark - CLASS SVPullToRefreshView
// ===================================================================================




@interface SVPullToRefreshView : UIView

//@property (nonatomic, strong) SVPullToRefreshLoadingView *loadingView;
@property (nonatomic, strong) UIView<CustomRefreshViewProtocol> *animView;/**<  */

@property (nonatomic, readonly) SVPullToRefreshState state;

- (id)initWithSubView:(UIView<CustomRefreshViewProtocol> *)subView Frame:(CGRect)frame;

- (void)startAnimating;
- (void)stopAnimating;

@end
