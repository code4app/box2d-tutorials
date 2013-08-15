//
//  HelloWorldLayer.mm
//  AngryBird
//
//  Created by curer on 8/8/13.
//  Copyright curer 2013. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#define FLOOR_HEIGHT    62.0f


enum {
	kTagParentNode = 1,
};


#pragma mark - HelloWorldLayer

@interface HelloWorldLayer()

@end

@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
		
		// enable events
		
		self.touchEnabled = YES;
		
		// init physics
		[self initPhysics];
		
		
		[self scheduleUpdate];
        
        //[self resetGame];
        [self performSelector:@selector(resetGame)
                   withObject:nil
                   afterDelay:0.5f];
	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
    
    [bullets release];
	
	[super dealloc];
}	


-(void) initPhysics
{
	
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);		
	
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;		
	
	// bottom
	
	groundBox.Set(b2Vec2(0, FLOOR_HEIGHT/PTM_RATIO), b2Vec2(s.width * 2 / PTM_RATIO, FLOOR_HEIGHT/PTM_RATIO));
	groundBody->CreateFixture(&groundBox,0);
	 
	// top
	groundBox.Set(b2Vec2(0, s.height / PTM_RATIO), b2Vec2(s.width * 2 / PTM_RATIO, s.height / PTM_RATIO));
	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0, s.height / PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(s.width * 2 / PTM_RATIO, s.height / PTM_RATIO), b2Vec2(s.width * 2 / PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
    
    CCSprite *sprite = [CCSprite spriteWithFile:@"bg.png"];
    sprite.anchorPoint = CGPointZero;
    [self addChild:sprite z:-1];
    
    sprite = [CCSprite spriteWithFile:@"catapult_base_2.png"];
    sprite.anchorPoint = CGPointZero;
    sprite.position = CGPointMake(181.0f, FLOOR_HEIGHT);
    [self addChild:sprite z:0];
    
    sprite = [CCSprite spriteWithFile:@"squirrel_1.png"];
    sprite.anchorPoint = CGPointZero;
    sprite.position = CGPointMake(11.0f, FLOOR_HEIGHT);
    [self addChild:sprite z:0];
    
    sprite = [CCSprite spriteWithFile:@"catapult_base_1.png"];
    sprite.anchorPoint = CGPointZero;
    sprite.position = CGPointMake(181.0f, FLOOR_HEIGHT);
    [self addChild:sprite z:9];
    
    sprite = [CCSprite spriteWithFile:@"squirrel_2.png"];
    sprite.anchorPoint = CGPointZero;
    sprite.position = CGPointMake(240.0f, FLOOR_HEIGHT);
    [self addChild:sprite z:9];
    
    sprite = [CCSprite spriteWithFile:@"fg.png"];
    sprite.anchorPoint = CGPointZero;
    [self addChild:sprite z:10];
    
    CCSprite *arm = [CCSprite spriteWithFile:@"catapult_arm.png"];
    [self addChild:arm z:1];
    
    b2BodyDef armBodyDef;
    armBodyDef.type = b2_dynamicBody;
    armBodyDef.linearDamping = 1;
    armBodyDef.angularDamping = 1;
    armBodyDef.position.Set(230.0f / PTM_RATIO, (FLOOR_HEIGHT + 91.0f) / PTM_RATIO);
    armBodyDef.userData = arm;
    armBody = world->CreateBody(&armBodyDef);
    
    b2PolygonShape armBox;
    b2FixtureDef armBoxDef;
    armBoxDef.shape = &armBox;
    armBoxDef.density = 0.3f;
    armBox.SetAsBox(11.0 / PTM_RATIO, 91.0 / PTM_RATIO);
    armFixture = armBody->CreateFixture(&armBoxDef);
    
    b2RevoluteJointDef armJointDef;
    armJointDef.Initialize(groundBody, armBody, b2Vec2(233.0 / PTM_RATIO, FLOOR_HEIGHT / PTM_RATIO));
    armJointDef.enableMotor = true;
    armJointDef.enableLimit = true;
    armJointDef.motorSpeed = - 10;
    armJointDef.lowerAngle = CC_DEGREES_TO_RADIANS(9);
    armJointDef.upperAngle = CC_DEGREES_TO_RADIANS(75);
    armJointDef.maxMotorTorque = 200;
    
    armJoint = (b2RevoluteJoint *)world->CreateJoint(&armJointDef);
}

- (void)createBullets:(int)count
{
    currentBullet = 0;
    CGFloat pos = 62.0f;
    
    if (count > 0)
    {
        // delta is the spacing between corns
        // 62 is the position o the screen where we want the corns to start appearing
        // 165 is the position on the screen where we want the corns to stop appearing
        // 30 is the size of the corn
        CGFloat delta = (count > 1)?((165.0f - 62.0f - 30.0f) / (count - 1)):0.0f;
        
        bullets = [[NSMutableArray alloc] initWithCapacity:count];
        for (int i=0; i<count; i++, pos+=delta)
        {
            // Create the bullet
            //
            CCSprite *sprite = [CCSprite spriteWithFile:@"acorn.png"];
            [self addChild:sprite z:1];
            
            b2BodyDef bulletBodyDef;
            bulletBodyDef.type = b2_dynamicBody;
            bulletBodyDef.bullet = true;
            bulletBodyDef.position.Set(pos/PTM_RATIO,(FLOOR_HEIGHT+15.0f)/PTM_RATIO);
            bulletBodyDef.userData = sprite;
            b2Body *bullet = world->CreateBody(&bulletBodyDef);
            bullet->SetActive(false);
            
            b2CircleShape circle;
            circle.m_radius = 15.0/PTM_RATIO;
            
            b2FixtureDef ballShapeDef;
            ballShapeDef.shape = &circle;
            ballShapeDef.density = 0.8f;
            ballShapeDef.restitution = 0.2f;
            ballShapeDef.friction = 0.99f;
            bullet->CreateFixture(&ballShapeDef);
            
            [bullets addObject:[NSValue valueWithPointer:bullet]];
        }
    }
}

- (BOOL)attachBullet
{
    if (currentBullet < [bullets count])
    {
        bulletBody = (b2Body*)[[bullets objectAtIndex:currentBullet++] pointerValue];
        bulletBody->SetTransform(b2Vec2(230.0f/PTM_RATIO, (155.0f+FLOOR_HEIGHT)/PTM_RATIO), 0.0f);
        bulletBody->SetActive(true);
        
        b2WeldJointDef weldJointDef;
        weldJointDef.Initialize(bulletBody, armBody, b2Vec2(230.0f/PTM_RATIO,(155.0f+FLOOR_HEIGHT)/PTM_RATIO));
        weldJointDef.collideConnected = false;
        
        bulletJoint = (b2WeldJoint*)world->CreateJoint(&weldJointDef);
        return YES;
    }
    
    return NO;
}

- (void)resetGame
{
    [self createBullets:4];
    [self attachBullet];
}

-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	world->DrawDebugData();	
	
	kmGLPopMatrix();
}

-(void) update: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
    
	
	//Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL) {
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			CCSprite *myActor = (CCSprite*)b->GetUserData();
			myActor.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
			myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
		}
	}
    
    if (releasingArm && bulletJoint)
    {
        // Check if the arm reached the end so we can return the limits
        if (armJoint->GetJointAngle() <= CC_DEGREES_TO_RADIANS(10))
        {
            releasingArm = NO;
            
            // Destroy joint so the bullet will be free
            world->DestroyJoint(bulletJoint);
            bulletJoint = nil;
            
        }
    }
    
    // Bullet is moving.
    if (bulletBody && bulletJoint == nil)
    {
        b2Vec2 position = bulletBody->GetPosition();
        CGPoint myPosition = self.position;
        CGSize screenSize = [CCDirector sharedDirector].winSize;
        
        // Move the camera.
        if (position.x > screenSize.width / 2.0f / PTM_RATIO)
        {
            myPosition.x = -MIN(screenSize.width * 2.0f - screenSize.width, position.x * PTM_RATIO - screenSize.width / 2.0f);
            self.position = myPosition;
        }
    }
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mouseJoint != nil) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    
    if (locationWorld.x < armBody->GetWorldCenter().x + 50.0/PTM_RATIO)
    {
        b2MouseJointDef md;
        md.bodyA = groundBody;
        md.bodyB = armBody;
        md.target = locationWorld;
        md.maxForce = 2000;
        
        mouseJoint = (b2MouseJoint *)world->CreateJoint(&md);
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mouseJoint == nil) return;
    
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    
    mouseJoint->SetTarget(locationWorld);
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mouseJoint != nil)
    {
        world->DestroyJoint(mouseJoint);
        mouseJoint = nil;
    }
    
    if (armJoint->GetJointAngle() >= CC_DEGREES_TO_RADIANS(20))
    {
        releasingArm = YES;
    }
}

@end
