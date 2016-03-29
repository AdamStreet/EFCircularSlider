//
//  EFCircularSlider.m
//  Awake
//
//  Created by Eliot Fowler on 12/3/13.
//  Copyright (c) 2013 Eliot Fowler. All rights reserved.
//

#import "EFCircularSlider.h"
#import <QuartzCore/QuartzCore.h>
#import "EFCircularTrig.h"


@interface EFCircularSlider ()

@property (nonatomic) CGFloat radius;
@property (nonatomic) int     angleFromNorth;
@property (nonatomic, strong) NSMutableDictionary *labelsWithPercents;

@property (nonatomic, readonly) CGFloat handleWidth;
@property (nonatomic, readonly) CGFloat innerLabelRadialDistanceFromCircumference;
@property (nonatomic, readonly) CGPoint centerPoint;

@property (nonatomic, readonly) CGFloat radiusForDoubleCircleOuterCircle;
@property (nonatomic, readonly) CGFloat lineWidthForDoubleCircleOuterCircle;
@property (nonatomic, readonly) CGFloat radiusForDoubleCircleInnerCircle;
@property (nonatomic, readonly) CGFloat lineWidthForDoubleCircleInnerCircle;

@property (nonatomic) BOOL snapToLabels;	// Remove if necessary

@end

static const CGFloat kFitFrameRadius = -1.0;
static int NormalizeValues(int *startPoint, int *endPoint, int *oldAngle, int *newAngle);

@implementation EFCircularSlider

@synthesize radius = _radius;

#pragma mark - Initialisation

- (id)init
{
    return [self initWithRadius:kFitFrameRadius];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initDefaultValuesWithRadius:kFitFrameRadius];
    }
    return self;
}

- (id)initWithRadius:(CGFloat)radius
{
    self = [super init];
    if (self)
    {
        [self initDefaultValuesWithRadius:radius];
    }
    return self;
}

-(void) initDefaultValuesWithRadius:(CGFloat)radius
{
    _radius        = radius;
    _maximumValue  = 100.0f;
    _minimumValue  = 0.0f;
    _lineWidth     = 5;
    _unfilledColor = [UIColor blackColor];
    _filledColor   = [UIColor redColor];
    _labelFont     = [UIFont systemFontOfSize:10.0f];
    _snapToLabels  = NO;
    _handleType    = CircularSliderHandleTypeSemiTransparentWhiteCircle;
    _labelColor    = [UIColor redColor];
    _labelDisplacement = 0;
	
	_startPoint = 0;
	_endPoint = 360;
    _angleFromNorth = _startPoint;
    
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - Public setter overrides
-(void) setLineWidth:(int)lineWidth
{
    _lineWidth = lineWidth;
    [self setNeedsUpdateConstraints]; // This could affect intrinsic content size
    [self invalidateIntrinsicContentSize]; // Need to update intrinsice content size
    [self setNeedsDisplay];           // Need to redraw with new line width
}

-(void) setHandleType:(CircularSliderHandleType)handleType
{
    _handleType = handleType;
    [self setNeedsUpdateConstraints]; // This could affect intrinsic content size
    [self setNeedsDisplay];           // Need to redraw with new handle type
}

-(void) setFilledColor:(UIColor*)filledColor
{
    _filledColor = filledColor;
    [self setNeedsDisplay]; // Need to redraw with new filled color
}

-(void) setUnfilledColor:(UIColor*)unfilledColor
{
    _unfilledColor = unfilledColor;
    [self setNeedsDisplay]; // Need to redraw with new unfilled color
}

-(void) setHandlerColor:(UIColor *)handleColor
{
    _handleColor = handleColor;
    [self setNeedsDisplay]; // Need to redraw with new handle color
}

-(void) setLabelFont:(UIFont*)labelFont
{
    _labelFont = labelFont;
    [self setNeedsDisplay]; // Need to redraw with new label font
}

-(void) setLabelColor:(UIColor*)labelColor
{
    _labelColor = labelColor;
    [self setNeedsDisplay]; // Need to redraw with new label color
}

-(void)setInnerMarkingLabels:(NSArray*)innerMarkingLabels
{
    _innerMarkingLabels = innerMarkingLabels;
    [self setNeedsUpdateConstraints]; // This could affect intrinsic content size
    [self setNeedsDisplay]; // Need to redraw with new label texts
}

- (void)setExternMarkingLabels:(NSArray *)externMarkingLabels
{
	_externMarkingLabels = externMarkingLabels;
	
	[self setNeedsUpdateConstraints]; // This could affect intrinsic content size
	[self setNeedsDisplay]; // Need to redraw with new label texts
}

-(void)setMinimumValue:(float)minimumValue
{
    _minimumValue = minimumValue;
    [self setNeedsDisplay]; // Need to redraw with updated value range
}

-(void)setMaximumValue:(float)maximumValue
{
    _maximumValue = maximumValue;
    [self setNeedsDisplay]; // Need to redraw with updated value range
}

- (void)setStartPoint:(int)startPoint
{
	startPoint = (startPoint % 360);
	
	_startPoint = startPoint;
	
	_angleFromNorth = startPoint;
	
	[self setNeedsDisplay];
}

- (void)setEndPoint:(int)endPoint
{
	endPoint = (endPoint % 360);
	
	_endPoint = endPoint;
	
	[self setNeedsDisplay];
}

/**
 *  There is no local variable currentValue - it is always calculated based on angleFromNorth
 *
 *  @param currentValue Value used to update angleFromNorth between minimumValue & maximumValue
 */
-(void) setCurrentValue:(float)currentValue
{
    NSAssert(currentValue <= self.maximumValue && currentValue >= self.minimumValue,
             @"currentValue (%.2f) must be between self.minimuValue (%.2f) and self.maximumValue (%.2f)",
              currentValue, self.minimumValue, self.maximumValue);
	
	// Update the angleFromNorth to match this newly set value
	int startPoint = self.startPoint;
	int endPoint = self.endPoint;
	int actualAngle = self.angleFromNorth;
	NormalizeValues(&startPoint, &endPoint, NULL, &actualAngle);
	
	int normalizedAngle = (((currentValue - self.minimumValue) / (self.maximumValue - self.minimumValue)) * endPoint);
	self.angleFromNorth = ((self.startPoint + normalizedAngle) % 360);
	
    [self sendActionsForControlEvents:UIControlEventValueChanged];
	
	[self setNeedsDisplay];
}

-(void)setAngleFromNorth:(int)angleFromNorth
{
    _angleFromNorth = angleFromNorth;
    NSAssert(_angleFromNorth >= 0, @"_angleFromNorth %d must be greater than 0", angleFromNorth);
}

-(void) setRadius:(CGFloat)radius
{
    _radius = radius;
    [self invalidateIntrinsicContentSize]; // Need to update intrinsice content size
    [self setNeedsDisplay]; // Need to redraw with new radius
}

#pragma mark - Public getter overrides

/**
 *  There is no local variable currentValue - it is always calculated based on angleFromNorth
 *
 *  @return currentValue Value between minimumValue & maximumValue derived from angleFromNorth
 */
-(float) currentValue
{
	int normalizedStartPoint = self.startPoint;
	int normalizedEndPoint = self.endPoint;
	int normalizedAngle = self.angleFromNorth;
	
	NormalizeValues(&normalizedStartPoint, &normalizedEndPoint, NULL, &normalizedAngle);
	
    return (self.minimumValue + (((CGFloat)normalizedAngle / (CGFloat)normalizedEndPoint) * (self.maximumValue - self.minimumValue)));
}

-(CGFloat) radius
{
    if (_radius == kFitFrameRadius)
    {
        // Slider is being used in frames - calculate the max radius based on the frame
        //  (constrained by smallest dimension so it fits within view)
        CGFloat minimumDimension = MIN(self.bounds.size.height, self.bounds.size.width);
        int halfLineWidth = ceilf(self.lineWidth / 2.0);
        int halfHandleWidth = ceilf(self.handleWidth / 2.0);
        return minimumDimension * 0.5 - MAX(halfHandleWidth, halfLineWidth);
    }
    return _radius;
}

-(UIColor*)handleColor
{
    UIColor *newHandleColor = _handleColor;
    switch (self.handleType) {
        case CircularSliderHandleTypeSemiTransparentWhiteCircle:
        {
            newHandleColor = [UIColor colorWithWhite:1.0 alpha:0.7];
            break;
        }
        case CircularSliderHandleTypeSemiTransparentBlackCircle:
        {
            newHandleColor = [UIColor colorWithWhite:0.0 alpha:0.7];
            break;
        }
        case CircularSliderHandleTypeDoubleCircleWithClosedCenter:
        case CircularSliderHandleTypeDoubleCircleWithOpenCenter:
        case CircularSliderHandleTypeBigCircle:
        {
            if (!newHandleColor)
            {
                // handleColor public property hasn't been set - use filledColor
                newHandleColor = self.filledColor;
            }
            break;
        }
    }
    
    return newHandleColor;
}

#pragma mark - Private getter overrides

-(CGFloat) handleWidth
{
    switch (self.handleType) {
        case CircularSliderHandleTypeSemiTransparentWhiteCircle:
        case CircularSliderHandleTypeSemiTransparentBlackCircle:
        {
            return self.lineWidth;
        }
        case CircularSliderHandleTypeBigCircle:
        {
            return self.lineWidth + 5; // 5 points bigger than standard handles
        }
        case CircularSliderHandleTypeDoubleCircleWithClosedCenter:
        case CircularSliderHandleTypeDoubleCircleWithOpenCenter:
        {
            return 2 * [EFCircularTrig outerRadiuOfUnfilledArcWithRadius:self.radiusForDoubleCircleOuterCircle
                                                               lineWidth:self.lineWidthForDoubleCircleOuterCircle];
        }
    }
}

-(CGFloat)radiusForDoubleCircleOuterCircle
{
    return 0.5 * self.lineWidth + 5;
}
-(CGFloat)lineWidthForDoubleCircleOuterCircle
{
    return 4.0;
}

-(CGFloat)radiusForDoubleCircleInnerCircle
{
    return 0.5 * self.lineWidth;
}
-(CGFloat)lineWidthForDoubleCircleInnerCircle
{
    return 2.0;
}

-(CGFloat)innerLabelRadialDistanceFromCircumference
{
    // Labels should be moved far enough to clear the line itself plus a fixed offset (relative to radius).
    int distanceToMoveInwards  = 0.1 * -(self.radius) - 0.5 * self.lineWidth;
        distanceToMoveInwards -= 0.5 * self.labelFont.pointSize; // Also account for variable font size.
    return distanceToMoveInwards;
}

-(CGPoint)centerPoint
{
    return CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
}

#pragma mark - Method overrides
-(CGSize)intrinsicContentSize
{
    // Total width is: diameter + (2 * MAX(halfLineWidth, halfHandleWidth))
    int diameter = self.radius * 2;
    int halfLineWidth = ceilf(self.lineWidth / 2.0);
    int halfHandleWidth = ceilf(self.handleWidth / 2.0);
    
    int widthWithHandle = diameter + (2 *  MAX(halfHandleWidth, halfLineWidth));
    
    return CGSizeMake(widthWithHandle, widthWithHandle);
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // Draw the circular lines that slider handle moves along
    [self drawLine:ctx];
    
    // Draw the draggable 'handle'
    [self drawHandle:ctx];
    
    // Add the labels
    [self drawInnerLabels:ctx];
	[self drawOuterLabels:ctx];
}


- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self pointInsideHandle:point withEvent:event])
    {
        return YES; // Point is indeed within handle bounds
    }
    else
    {
        return [self pointInsideCircle:point withEvent:event]; // Return YES if point is inside slider's circle
    }
}

- (BOOL)pointInsideCircle:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint p1 = [self centerPoint];
    CGPoint p2 = point;
    CGFloat xDist = (p2.x - p1.x);
    CGFloat yDist = (p2.y - p1.y);
    double distance = sqrt((xDist * xDist) + (yDist * yDist));
    return distance < self.radius + self.lineWidth * 0.5;
}

- (BOOL)pointInsideHandle:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint handleCenter = [self pointOnCircleAtAngleFromNorth:self.angleFromNorth];
    CGFloat handleRadius = MAX(self.handleWidth, 44.0) * 0.5;
    // Adhere to apple's design guidelines - avoid making touch targets smaller than 44 points
    
    // Treat handle as a box around it's center
    BOOL pointInsideHorzontalHandleBounds = (point.x >= handleCenter.x - handleRadius
                                             && point.x <= handleCenter.x + handleRadius);
    BOOL pointInsideVerticalHandleBounds  = (point.y >= handleCenter.y - handleRadius
                                             && point.y <= handleCenter.y + handleRadius);
    return pointInsideHorzontalHandleBounds && pointInsideVerticalHandleBounds;
}

#pragma mark - Drawing methods

-(void) drawLine:(CGContextRef)ctx
{
    // Draw an unfilled circle (this shows what can be filled)
    [self.unfilledColor set];
    [EFCircularTrig drawUnfilledArcInContext:ctx
									  center:self.centerPoint
									  radius:self.radius
								   lineWidth:self.lineWidth
						  fromAngleFromNorth:self.startPoint
							toAngleFromNorth:self.endPoint];

    // Draw an unfilled arc up to the currently filled point
    [self.filledColor set];
    
    [EFCircularTrig drawUnfilledArcInContext:ctx
                                      center:self.centerPoint
                                      radius:self.radius
                                   lineWidth:self.lineWidth
                          fromAngleFromNorth:self.startPoint
                            toAngleFromNorth:self.angleFromNorth];
}

-(void) drawHandle:(CGContextRef)ctx{
    CGContextSaveGState(ctx);
    CGPoint handleCenter = [self pointOnCircleAtAngleFromNorth:self.angleFromNorth];
    
    // Ensure that handle is drawn in the correct color
    [self.handleColor set];
    
    switch (self.handleType) {
        case CircularSliderHandleTypeSemiTransparentWhiteCircle:
        case CircularSliderHandleTypeSemiTransparentBlackCircle:
        case CircularSliderHandleTypeBigCircle:
        {
            [EFCircularTrig drawFilledCircleInContext:ctx
                                     center:handleCenter
                                     radius:0.5 * self.handleWidth];
            break;
        }
        case CircularSliderHandleTypeDoubleCircleWithClosedCenter:
        case CircularSliderHandleTypeDoubleCircleWithOpenCenter:
        {
            [self drawUnfilledLineBehindDoubleCircleHandle:ctx];
            
            // Draw unfilled outer circle
            [EFCircularTrig drawUnfilledCircleInContext:ctx
                                       center:CGPointMake(handleCenter.x,
                                                          handleCenter.y)
                                       radius:self.radiusForDoubleCircleOuterCircle
                                    lineWidth:self.lineWidthForDoubleCircleOuterCircle];
            
            if (self.handleType == CircularSliderHandleTypeDoubleCircleWithClosedCenter)
            {
                // Draw filled inner circle
                [EFCircularTrig drawFilledCircleInContext:ctx
                                                   center:handleCenter
                                                   radius:[EFCircularTrig outerRadiuOfUnfilledArcWithRadius:self.radiusForDoubleCircleInnerCircle
                                                                                                  lineWidth:self.lineWidthForDoubleCircleInnerCircle]];
            }
            else if (self.handleType == CircularSliderHandleTypeDoubleCircleWithOpenCenter)
            {
                // Draw unfilled inner circle
                [EFCircularTrig drawUnfilledCircleInContext:ctx
                                                     center:CGPointMake(handleCenter.x,
                                                                        handleCenter.y)
                                                     radius:self.radiusForDoubleCircleInnerCircle
                                                  lineWidth:self.lineWidthForDoubleCircleInnerCircle];
            }
            
            break;
        }
    }
    
    CGContextRestoreGState(ctx);
}

/**
 *  Draw unfilled line from left edge of handle to right edge of handle
 *  This is to ensure that the filled portion of the line doesn't show inside the double circle
 *  @param ctx Graphics Context within which to draw unfilled line behind handle
 */
-(void) drawUnfilledLineBehindDoubleCircleHandle:(CGContextRef)ctx
{
    CGFloat degreesToHandleCenter   = self.angleFromNorth;
    // To determine where handle intersects the filledCircle, make approximation that arcLength ~ radius of handle outer circle.
    // This is a fine approximation whenever self.radius is sufficiently large (which it must be for this control to be usable)
    CGFloat degreesDifference = [EFCircularTrig degreesForArcLength:self.radiusForDoubleCircleOuterCircle
                                                 onCircleWithRadius:self.radius];
    CGFloat degreesToHandleLeftEdge  = degreesToHandleCenter - degreesDifference;
    CGFloat degreesToHandleRightEdge = degreesToHandleCenter + degreesDifference;
    
    CGContextSaveGState(ctx);
    [self.unfilledColor set];
    [EFCircularTrig drawUnfilledArcInContext:ctx
                                      center:self.centerPoint
                                      radius:self.radius
                                   lineWidth:self.lineWidth
                          fromAngleFromNorth:degreesToHandleLeftEdge
                            toAngleFromNorth:degreesToHandleRightEdge];
    CGContextRestoreGState(ctx);
}

- (void)drawLabels:(NSArray *)labels intoContext:(CGContextRef)ctx withinCircle:(BOOL)inside
{
	// Only draw labels if they have been set
	const NSInteger labelsCount = labels.count;
	if (0 < labelsCount) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
		NSDictionary *attributes = @{ NSFontAttributeName: self.labelFont,
									  NSForegroundColorAttributeName: self.labelColor};
#endif
		int normalizedStartPoint = self.startPoint;
		int normalizedEndPoint = self.endPoint;
		
		NormalizeValues(&normalizedStartPoint, &normalizedEndPoint, NULL, NULL);
		
		const int totalCircleWayLenght = normalizedEndPoint;
		
		for (int i = 0; i < labelsCount; i++) {
			// Enumerate through labels clockwise
			NSString* label = labels[i];
			
			// Determine how many degrees around the full circle this label should go
			const CGFloat percentage = ((CGFloat)i / ((CGFloat)labelsCount - 1));
			const int degressFromNorth = (int)(floorf(percentage * totalCircleWayLenght));
			const int degressFromStartPoint = ((self.startPoint + degressFromNorth) % 360);
			CGRect labelFrame = [self contextCoordinatesForLabelAtDegreesFromNorth:degressFromStartPoint
																			 label:label
																	  withinCircle:inside];
			
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
			[label drawInRect:labelFrame withAttributes:attributes];
#else
			[self.labelColor setFill];
			[label drawInRect:labelFrame withFont:self.labelFont];
#endif
		}
	}
}


-(void) drawInnerLabels:(CGContextRef)ctx
{
	[self drawLabels:self.innerMarkingLabels intoContext:ctx withinCircle:YES];
}

- (void)drawOuterLabels:(CGContextRef)ctx
{
	[self drawLabels:self.externMarkingLabels intoContext:ctx withinCircle:NO];
}

-(CGRect)contextCoordinatesForLabelAtDegreesFromNorth:(int)degreesFromNorthForLabel
												label:(NSString *)label
										 withinCircle:(BOOL)withinCircle
{
    // Determine how many degrees around the full circle this label should go
    const CGPoint pointOnCircle = [self pointOnCircleAtAngleFromNorth:degreesFromNorthForLabel];
    
    const CGSize  labelSize        = [self sizeOfString:label withFont:self.labelFont];
    const CGPoint offsetFromCircle = [self offsetFromCircleForLabelAtDegreesFromNorth:degreesFromNorthForLabel
																			 withSize:labelSize
																		 withinCircle:withinCircle];

    return CGRectMake(pointOnCircle.x + offsetFromCircle.x, pointOnCircle.y + offsetFromCircle.y, labelSize.width, labelSize.height);
}

-(CGPoint) offsetFromCircleForLabelAtDegreesFromNorth:(int)degreesFromNorthForLabel
											 withSize:(CGSize)labelSize
										 withinCircle:(BOOL)withinCircle
{
    // TODO replace innerLabelRadialDistanceFromCircumference
    const CGFloat radialDistance = self.innerLabelRadialDistanceFromCircumference + self.labelDisplacement;
    CGPoint offset   = [EFCircularTrig pointOnRadius:radialDistance
									atAngleFromNorth:degreesFromNorthForLabel];
	
	if (!withinCircle) {
		offset.x *= -1.0;
	}
	
    return CGPointMake(-labelSize.width * 0.5 + offset.x, -labelSize.height * 0.5 + offset.y);
}

#pragma mark - UIControl functions

-(BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super continueTrackingWithTouch:touch withEvent:event];
    
    CGPoint lastPoint = [touch locationInView:self];
    [self moveHandle:lastPoint];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    return YES;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    if(self.snapToLabels && self.innerMarkingLabels != nil)
    {
        CGPoint bestGuessPoint = CGPointZero;
        float minDist = 360;
        NSUInteger labelsCount = self.innerMarkingLabels.count;
        
        for (NSUInteger i = 0; i < labelsCount; i++)
        {
            CGFloat percentageAlongCircle = i/(float)labelsCount;
            CGFloat degreesForLabel       = percentageAlongCircle * 360;
            if(fabs(self.angleFromNorth - degreesForLabel) < minDist)
            {
                minDist = fabs(self.angleFromNorth - degreesForLabel);
                bestGuessPoint = [self pointOnCircleAtAngleFromNorth:degreesForLabel];
            }
        }
        self.angleFromNorth = floor([EFCircularTrig angleRelativeToNorthFromPoint:self.centerPoint
                                                                             toPoint:bestGuessPoint]);
        [self setNeedsDisplay];
    }
}

-(void)moveHandle:(CGPoint)point
{
	int newAngleFromNorth = floor([EFCircularTrig angleRelativeToNorthFromPoint:self.centerPoint
															   toPoint:point]);
	
	if (0 < self.startPoint ||
		self.endPoint < 360) {
		// endpoint or startpoint is set
		// Normalize values to have startPoint = 0
		
		int normalizedEndPoint = self.endPoint;
		int normalizedStartPoint = self.startPoint;
		int normalizedNewAngle = newAngleFromNorth;
		int normalizedOldAngle = self.angleFromNorth;
		
		NormalizeValues(&normalizedStartPoint, &normalizedEndPoint, &normalizedOldAngle, &normalizedNewAngle);
		
		if (normalizedNewAngle < normalizedStartPoint) {
			newAngleFromNorth = self.startPoint;
		}
		
		if (normalizedEndPoint < normalizedNewAngle) {
			newAngleFromNorth = self.endPoint;
		}
		
		// Avoid to jump from the beginning to the end or vica vesa
		
		const BOOL isJumping = (abs(normalizedStartPoint - normalizedEndPoint)/2) < abs(normalizedOldAngle - normalizedNewAngle);
		if (isJumping)
			return;
	}
	
	self.angleFromNorth = newAngleFromNorth;
	
	[self setNeedsDisplay];
}

#pragma mark - Helper functions
- (BOOL) isDoubleCircleHandle
{
    return self.handleType == CircularSliderHandleTypeDoubleCircleWithClosedCenter || self.handleType == CircularSliderHandleTypeDoubleCircleWithOpenCenter;
}

- (CGSize) sizeOfString:(NSString *)string withFont:(UIFont*)font
{
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[NSAttributedString alloc] initWithString:string attributes:attributes].size;
}

-(CGPoint)pointOnCircleAtAngleFromNorth:(int)angleFromNorth
{
    CGPoint offset = [EFCircularTrig  pointOnRadius:self.radius atAngleFromNorth:angleFromNorth];
    return CGPointMake(self.centerPoint.x + offset.x, self.centerPoint.y + offset.y);
}

@end

static inline int NormalizeValues(int *startPoint, int *endPoint, int *oldAngle, int *newAngle)
{
	NSCParameterAssert(startPoint);
	NSCParameterAssert(endPoint);
	
	if (*startPoint <= *endPoint)
		return 0;
	
	const int diff = (360 - *startPoint);
	
	*startPoint = ((*startPoint + diff) % 360);
	*endPoint = ((*endPoint + diff) % 360);
	
	if (newAngle) {
		*newAngle = ((*newAngle + diff) % 360);
	}
	
	if (oldAngle) {
		*oldAngle = ((*oldAngle + diff) % 360);
	}
	
	NSCAssert(*startPoint == 0, @"Review calculations");
	
	return diff;
}
