//
//  MGWUMinigameTemplate
//
//  Created by Zachary Barryte on 6/6/14.
//  Copyright 2014 Apportable. All rights reserved.
//

#import "MyMinigame.h"
#import "CCPhysics+ObjectiveChipmunk.h"

@implementation MyMinigame
{
    NSMutableArray* _enemiesArray;
    CCPhysicsNode* _physicsNode;
    CCLabelTTF* _scoreLabel;
    
    BOOL _gameOver;
    float _timeAlive;
}

#pragma mark -
#pragma mark Lifecycle

-(id)init {
    
    if ((self = [super init])) {
        // Initialize any arrays, dictionaries, etc in here
        self.instructions = @"Avoid the space enemies!";
        _enemiesArray = [NSMutableArray array];
        _timeAlive = 0.0f;
        _gameOver = NO;
    }
    return self;
}

- (void)didLoadFromCCB {

    //  Setting this allows us to use the touchBegan, touchMoved and touchEnded methods
    self.userInteractionEnabled = YES;
}


- (void)onEnter {
    
    [super onEnter];
    
    //  Tell our physics node that we want collision callbacks
    _physicsNode.collisionDelegate = self;
    
    //  These tell the Cocos2d scheduler to call our methods at regular intervals
    [self schedule:@selector(spawnEnemy) interval:0.35f];       // Spawn a new enemy every .35 seconds
    [self schedule:@selector(updateScoreLabel) interval:0.1f];  // Update the score label every 0.1 seconds
}

- (void)cleanup {
    
    //  cleanup is called before our minigame gets deallocated (which happens after we call endMinigameWithScore)
    //  So we need  to tell the Cocos2d scheduler that we don't need our spawnEnemy and updateScoreLabel methods called anymore
    [self unscheduleAllSelectors];
}


#pragma mark -
#pragma mark Game Methods

-(void)update:(CCTime)delta
{
    // Called each update cycle
    // n.b. Lag and other factors may cause it to be called more or less frequently on different devices or sessions
    // delta will tell you how much time has passed since the last cycle (in seconds)
    
    if (_gameOver) {
        
        // If game over, end the mini-game
        [self endMinigame];
        
    } else {
        
        // Add the time between the last frame and this frame (delta) to the total _timeAlive variable
        _timeAlive += delta;
        
        //  Now we will iterate through all the enemies that we're tracking in our _enemiesArray
        //  And remove any of those that are off the screen on the left side
        
        NSMutableArray* enemiesToRemove = [NSMutableArray array];
        
        //  We can't remove the enemy from the _enemiesArray while iterating through _enemiesArray - that would mess up the iteration
        //  So instead we'll add them to a enemiesToRemove array, then remove them after we're done iterating
        for (CCNode* enemy in _enemiesArray) {
            
            if (enemy.position.x < 0.0f) {
                [enemiesToRemove addObject:enemy];
                [enemy removeFromParent];  // This removes the enemy from the node hierarchy - it will no longer be displayed
            }
        }
        
        //  Done iterating, now we remove the enemies from the _enemiesArray
        for (CCNode* enemy in enemiesToRemove) {
            [_enemiesArray removeObject:enemy];
        }
    }
}

- (void)spawnEnemy {
    
    CCNode* enemy;
    
    // Generate a random number, to load one of two possible enemies

    int randomNumber = arc4random() % 2;  // randomNumber will be either 0 or 1
    
    switch (randomNumber)
    {
        case 0: enemy = [CCBReader load:@"Enemy"]; break;
        case 1: enemy = [CCBReader load:@"EnemyTwo"]; break;
    }
    
    // Spawn enemies on the right side of the screen, at a random height
    enemy.position = ccp(self.contentSizeInPoints.width, self.contentSizeInPoints.height * CCRANDOM_0_1());
    
    // Enemies have a random scale between 20% and 100%
    // Here clampf makes sure the random value is between 0.2f and 1.0f
    enemy.scale = clampf(CCRANDOM_0_1(), 0.2f, 1.0f);
    
    // Add the enemy to the physics node
    [_physicsNode addChild:enemy];
    
    //  Add the enemy to our enemies array so we can track them
    [_enemiesArray addObject:enemy];
    
    //  Make the enemy spin with a random angular impulse
    [enemy.physicsBody applyAngularImpulse:CCRANDOM_MINUS1_1() * 15000.0f];
}


- (void)endMinigame {
    
    // The player's score is based on how long they stayed alive
    // But it must be between 1 and 100, so we clamp the time alive value to between 1 and 100
    [self endMinigameWithScore: (int) clampf(_timeAlive, 1.0f, 100.0f)];
}

- (void)updateScoreLabel {
    
    // the .1f part means that there should only be 1 decimal place displayed
    _scoreLabel.string = [NSString stringWithFormat:@"%.1f", _timeAlive];
}

#pragma mark -
#pragma mark Touch Methods

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    

}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event {

    if (!_gameOver) {
        
        CGPoint touchLocation = [touch locationInNode:self];
        CGPoint touchLocationWorldSpace = [self convertToWorldSpace:touchLocation];
        CGPoint touchLocationInHeroNodeSpace = [self.hero.parent convertToNodeSpace:touchLocationWorldSpace];
        
        
        // For fun: spin the hero character based on how far it moved
        CGPoint oldPosition = self.hero.position;
        CGPoint difference = ccpSub(touchLocationInHeroNodeSpace, oldPosition);
        
        [self.hero.physicsBody applyAngularImpulse:difference.y * 10.0f + 0.05f];
        
        
        // Update the hero's position to the new position
        self.hero.position = ccp(self.hero.position.x, touchLocationInHeroNodeSpace.y);
    }
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    
}

#pragma mark -
#pragma mark CCPhysicsCollisionDelegate Callback

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair HeroCollision:(CCNode *)hero EnemyCollision:(CCNode *)enemy {
    
    //  self.hero has a collision category HeroCollision set up in SpriteBuilder
    //  the enemies have a collision category EnemyCollision set up in SpriteBuilder
    //  So this collision callback method will tell us whenever the hero hits an enemy
    
    //  If we hit an enemy, it's game over!
    _gameOver = YES;
}


// DO NOT DELETE!
-(MyCharacter *)hero {
    return (MyCharacter *)self.character;
}
// DO NOT DELETE!

@end
