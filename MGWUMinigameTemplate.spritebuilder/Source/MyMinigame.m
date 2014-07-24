//
//  MGWUMinigameTemplate
//
//  Created by Zachary Barryte on 6/6/14.
//  Copyright 2014 Apportable. All rights reserved.
//

#import "MyMinigame.h"
#import "Enemy.h"
#import "CCPhysics+ObjectiveChipmunk.h"

@implementation MyMinigame
{
    NSMutableArray* enemies;
    CCPhysicsNode* physicsNode;
    CCLabelTTF* scoreLabel;
    
    BOOL gameOver;
    float timeAlive;
}

-(id)init {
    if ((self = [super init]))
    {
        // Initialize any arrays, dictionaries, etc in here
        self.instructions = @"Avoid the screws! :D";
        enemies = [NSMutableArray array];
        timeAlive = 0.0f;
        gameOver = NO;
    }
    return self;
}

-(void)didLoadFromCCB
{
    // Set up anything connected to Sprite Builder here
    
    // We're calling a public method of the character that tells it to jump!
    self.userInteractionEnabled = YES;
}

- (void)cleanup
{
    [self unscheduleAllSelectors];
}

-(void)onEnter
{
    [super onEnter];
    // Create anything you'd like to draw here
    
    physicsNode.collisionDelegate = self;
    
    self.hero.anchorPoint = ccp(0.0f, 0.5f);
    
    [self schedule:@selector(spawnEnemy) interval:0.35f];
    [self schedule:@selector(updateScoreLabel) interval:0.1f];
}

-(void)update:(CCTime)delta
{
    // Called each update cycle
    // n.b. Lag and other factors may cause it to be called more or less frequently on different devices or sessions
    // delta will tell you how much time has passed since the last cycle (in seconds)
    
    timeAlive += delta;
    
    NSMutableArray* enemiesToRemove = [NSMutableArray array];
    for (CCNode* enemy in enemies)
    {
        if (enemy.position.x < -0.2f)
        {
            [enemiesToRemove addObject:enemy];
            [enemy removeFromParent];
        }
    }
    
    for (CCNode* enemy in enemiesToRemove)
    {
        [enemies removeObject:enemy];
    }
}

- (void)spawnEnemy
{
    Enemy* enemy;
    
    int randomNumber = arc4random() % 2;
    
    switch (randomNumber)
    {
        case 0: enemy = (Enemy*) [CCBReader load:@"Enemy"]; break;
        case 1: enemy = (Enemy*) [CCBReader load:@"EnemyTwo"]; break;
    }
    
    enemy.positionType = CCPositionTypeNormalized;
    enemy.position = ccp(1.0f, CCRANDOM_0_1());
    
    enemy.scale = clampf(CCRANDOM_0_1(), 0.2f, 1.0f);
    
    [physicsNode addChild:enemy];
    [enemies addObject:enemy];
    
    
    [enemy.physicsBody applyAngularImpulse:CCRANDOM_MINUS1_1() * 15000.0f];
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!gameOver)
    {
        CGPoint touchLocation = [touch locationInNode:self];
        
        CGPoint touchNormalized = [self.hero convertPositionFromPoints:touchLocation type:CCPositionTypeMake(CCPositionUnitNormalized, CCPositionUnitNormalized, CCPositionReferenceCornerBottomLeft)];
        
        self.hero.position = ccp(self.hero.position.x, touchNormalized.y);
    }
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!gameOver)
    {
        CGPoint touchLocation = [touch locationInNode:self];
        
        CGPoint touchNormalized = [self.hero convertPositionFromPoints:touchLocation type:CCPositionTypeMake(CCPositionUnitNormalized, CCPositionUnitNormalized, CCPositionReferenceCornerBottomLeft)];
        
        CGPoint oldPosition = self.hero.position;
        CGPoint difference = ccpSub(touchNormalized, oldPosition);
        CGPoint differenceInPoints = [self.hero convertPositionToPoints:difference type:CCPositionTypeMake(CCPositionUnitNormalized, CCPositionUnitNormalized, CCPositionReferenceCornerBottomLeft)];
        
        [self.hero.physicsBody applyAngularImpulse:differenceInPoints.y * 10.0f + 0.05f];
        
        self.hero.position = ccp(self.hero.position.x, touchNormalized.y);
    }
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    
}

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair Hero:(CCNode *)nodeA Enemy:(CCNode *)nodeB
{
    if (!gameOver)
    {
        [[physicsNode space] addPostStepBlock:^
        {
            [self endMinigame];
            [self.hero removeFromParent];
        } key:self.hero];
    }
}


-(void)endMinigame
{
    if (!gameOver)
    {
        gameOver = YES;
        [self endMinigameWithScore:(int) clampf(timeAlive, 1.0f, 100.0f)];
    }
}

- (void)updateScoreLabel
{
    scoreLabel.string = [NSString stringWithFormat:@"%3.1f", timeAlive];
}

// DO NOT DELETE!
-(MyCharacter *)hero
{
    return (MyCharacter *)self.character;
}
// DO NOT DELETE!

@end
