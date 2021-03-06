//
//  FSCalendarCell.m
//  Pods
//
//  Created by Wenchao Ding on 12/3/15.
//
//

#import "FSCalendarCell.h"
#import "FSCalendar.h"
#import "UIView+FSExtension.h"
#import "NSDate+FSExtension.h"
#import "FSCalendarDynamicHeader.h"

#define kAnimationDuration 0.15

@implementation FSCalendarCell

static CGFloat FSEventLayerVerticalCenterDelta = -8.0f;
static CGFloat FSBackgroundLayerMinimumInteritemSpacing = 7.0f;

#pragma mark - Init and life cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont systemFontOfSize:15];
        titleLabel.textColor = [UIColor darkTextColor];
        [self.contentView addSubview:titleLabel];
        self.titleLabel = titleLabel;
        
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        subtitleLabel.font = [UIFont systemFontOfSize:10];
        subtitleLabel.textColor = [UIColor lightGrayColor];
        [self.contentView addSubview:subtitleLabel];
        self.subtitleLabel = subtitleLabel;
        
        CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
        backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
        backgroundLayer.hidden = YES;
        [self.contentView.layer insertSublayer:backgroundLayer atIndex:0];
        self.backgroundLayer = backgroundLayer;
        
        CAShapeLayer *eventLayer = [CAShapeLayer layer];
        eventLayer.backgroundColor = [UIColor clearColor].CGColor;
        eventLayer.fillColor = [UIColor cyanColor].CGColor;
        eventLayer.path = [UIBezierPath bezierPathWithOvalInRect:eventLayer.bounds].CGPath;
        eventLayer.hidden = YES;
        [self.contentView.layer addSublayer:eventLayer];
        self.eventLayer = eventLayer;
        
        CALayer *imageLayer = [CALayer layer];
        imageLayer.backgroundColor = [UIColor clearColor].CGColor;
        [self.contentView.layer addSublayer:imageLayer];
        self.imageLayer = imageLayer;
    }
    return self;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    CGFloat titleHeight = self.bounds.size.height*5.0/6.0;
    CGFloat diameter = MIN(self.bounds.size.height, self.bounds.size.width) - FSBackgroundLayerMinimumInteritemSpacing;
    _backgroundLayer.frame = CGRectMake((self.bounds.size.width-diameter)/2,
                                        (titleHeight-diameter)/2,
                                        diameter,
                                        diameter);
    
    CGFloat eventSize = _backgroundLayer.frame.size.height/8.0f;
    _eventLayer.frame = CGRectMake((_backgroundLayer.frame.size.width-eventSize) / 2 + _backgroundLayer.frame.origin.x,
                                   titleHeight + FSEventLayerVerticalCenterDelta,
                                   eventSize,
                                   eventSize);
    
    _eventLayer.path = [UIBezierPath bezierPathWithOvalInRect:_eventLayer.bounds].CGPath;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self configureCell];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [CATransaction setDisableActions:YES];
}

- (BOOL)isSelected
{
    return [super isSelected] || ([self.calendar.selectedDate fs_isEqualToDateForDay:_date] && !_deselecting);
}

#pragma mark - BackgroundLayer States management

- (void)updateBackgroundLayerState {
    UIColor *currentStateColor = [self colorForCurrentStateInDictionary:_appearance.backgroundColors];
    _backgroundLayer.strokeColor = currentStateColor.CGColor;
    _backgroundLayer.fillColor = [self isToday] ? currentStateColor.CGColor : [UIColor clearColor].CGColor;
    _backgroundLayer.lineWidth = 2.0f;
}

#pragma mark - Public

- (void)performSelecting
{
    _backgroundLayer.hidden = NO;
    _backgroundLayer.path = [UIBezierPath bezierPathWithOvalInRect:_backgroundLayer.bounds].CGPath;
    [self updateBackgroundLayerState];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    CABasicAnimation *zoomOut = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomOut.fromValue = @0.3;
    zoomOut.toValue = @1.2;
    zoomOut.duration = kAnimationDuration/4*3;
    CABasicAnimation *zoomIn = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomIn.fromValue = @1.2;
    zoomIn.toValue = @1.0;
    zoomIn.beginTime = kAnimationDuration/4*3;
    zoomIn.duration = kAnimationDuration/4;
    group.duration = kAnimationDuration;
    group.animations = @[zoomOut, zoomIn];
    [_backgroundLayer addAnimation:group forKey:@"bounce"];
    [self configureCell];
}

- (void)performDeselecting
{
    _deselecting = YES;
    [self configureCell];
    _deselecting = NO;
}

#pragma mark - Private

- (void)configureCell
{
    _titleLabel.font = _appearance.titleFont ? _appearance.titleFont : [UIFont systemFontOfSize:_appearance.titleTextSize];
    _titleLabel.text = [NSString stringWithFormat:@"%@",@(_date.fs_day)];
    _subtitleLabel.font = _appearance.subtitleFont ? _appearance.subtitleFont : [UIFont systemFontOfSize:_appearance.subtitleTextSize];
    _subtitleLabel.text = _subtitle;
    _titleLabel.textColor = [self colorForCurrentStateInDictionary:_appearance.titleColors];
    _subtitleLabel.textColor = [self colorForCurrentStateInDictionary:_appearance.subtitleColors];
    [self updateBackgroundLayerState];
    
    CGFloat titleHeight = [_titleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.titleLabel.font}].height;
    if (_subtitleLabel.text) {
        _subtitleLabel.hidden = NO;
        CGFloat subtitleHeight = [_subtitleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.subtitleLabel.font}].height;
        CGFloat height = titleHeight + subtitleHeight;
        _titleLabel.frame = CGRectMake(0,
                                       (self.contentView.fs_height*5.0/6.0-height)*0.5,
                                       self.fs_width,
                                       titleHeight);
        
        _subtitleLabel.frame = CGRectMake(0,
                                          _titleLabel.fs_bottom - (_titleLabel.fs_height-_titleLabel.font.pointSize),
                                          self.fs_width,
                                          subtitleHeight);
    } else {
        _titleLabel.frame = CGRectMake(0, 0, self.fs_width, floor(self.contentView.fs_height*5.0/6.0));
        _subtitleLabel.hidden = YES;
    }
    
    BOOL isToday = [self isToday];
    _backgroundLayer.hidden = !self.selected && !isToday;
    _backgroundLayer.path = _appearance.cellStyle == FSCalendarCellStyleCircle ?
    [UIBezierPath bezierPathWithOvalInRect:_backgroundLayer.bounds].CGPath :
    [UIBezierPath bezierPathWithRect:_backgroundLayer.bounds].CGPath;
    _eventLayer.hidden = !_hasEvent;
    _eventLayer.fillColor = !isToday ? _appearance.eventColor.CGColor : _appearance.eventHighlightedColor.CGColor;
    
    if (_image) {
        _imageLayer.hidden = NO;
        _imageLayer.frame = CGRectMake((self.fs_width-_image.size.width)*0.5, self.fs_height-_image.size.height, _image.size.width, _image.size.height);
        _imageLayer.contents = (id)_image.CGImage;
    } else {
        _imageLayer.hidden = YES;
        _imageLayer.contents = nil;
    }
}

- (BOOL)isPlaceholder
{
    return ![_date fs_isEqualToDateForMonth:_month];
}

- (BOOL)isToday
{
    return [_date fs_isEqualToDateForDay:self.calendar.today];
}

- (BOOL)isWeekend
{
    return self.date.fs_weekday == 1 || self.date.fs_weekday == 7;
}

- (UIColor *)colorForCurrentStateInDictionary:(NSDictionary *)dictionary
{
    if (self.isSelected) {
        if (self.isToday) {
            return dictionary[@(FSCalendarCellStateSelected|FSCalendarCellStateToday)] ?: dictionary[@(FSCalendarCellStateSelected)];
        }
        return dictionary[@(FSCalendarCellStateSelected)];
    }
    if (self.isToday) {
        return dictionary[@(FSCalendarCellStateToday)];
    }
    if (self.isPlaceholder) {
        return dictionary[@(FSCalendarCellStatePlaceholder)];
    }
    if (self.isWeekend && [[dictionary allKeys] containsObject:@(FSCalendarCellStateWeekend)]) {
        return dictionary[@(FSCalendarCellStateWeekend)];
    }
    return dictionary[@(FSCalendarCellStateNormal)];
}

- (FSCalendar *)calendar
{
    UIView *superview = self.superview;
    while (superview && ![superview isKindOfClass:[FSCalendar class]]) {
        superview = superview.superview;
    }
    return (FSCalendar *)superview;
}

@end



