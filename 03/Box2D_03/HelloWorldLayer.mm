//
//  HelloWorldLayer.mm
//  Box2D_03
//
//  Created by curer on 7/20/13.
//  Copyright curer 2013. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"


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
		self.accelerometerEnabled = YES;
		
		// init physics
		[self initPhysics];
        [self initMap];
        [self initBike];
		
		[self scheduleUpdate];
	}
    
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
	
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
			flags += b2Draw::e_jointBit;
			//flags += b2Draw::e_aabbBit;
			//flags += b2Draw::e_pairBit;
			//flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);		
	
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;		
	
	// bottom
	
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// top
	//groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
	//groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
}

- (void)initBike
{
    CGPoint pt = ccp(0, 280);
    
    ballA = [self addNewSpriteAtPosition:ccp(pt.x, pt.y)];
    b2Body *ballB = [self addNewSpriteAtPosition:ccp(pt.x + 90, pt.y + 90)];
    
    b2DistanceJointDef jointDef;
    jointDef.Initialize(ballA, ballB, ballA->GetPosition(), ballB->GetPosition());
    
    b2DistanceJoint *join = (b2DistanceJoint *)world->CreateJoint(&jointDef);
    CGFloat distance = 30.0 / PTM_RATIO;
    join->SetLength(distance);
}

- (void)initMap
{
    [self b2BodyStaticWithPosition:ccp(0, 100)
                          andAngle:M_PI_4 / 4
                           andSize:CGSizeMake(100, 5)];
    
    
    [self b2BodyStaticWithPosition:ccp(230, 180)
                          andAngle:M_PI_4 / 2
                           andSize:CGSizeMake(150, 5)];
}

- (b2Body *)b2BodyStaticWithPosition:(CGPoint)pt andAngle:(CGFloat)angle andSize:(CGSize)size
{
    b2BodyDef bodyDef;
    
    bodyDef.type = b2_staticBody; //no need this is default value
    bodyDef.angle = angle;
    bodyDef.position.Set(pt.x / PTM_RATIO, pt.y / PTM_RATIO);
    
    b2Body *body = world->CreateBody(&bodyDef);
    
    b2PolygonShape shape;
    shape.SetAsBox(size.width / PTM_RATIO, size.height / PTM_RATIO);
    
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = 0;
    fixtureDef.friction = 1.0f;
    
    body->CreateFixture(&fixtureDef);
    
    return body;
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

-(b2Body *) addNewSpriteAtPosition:(CGPoint)p
{
	CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
	// Define the dynamic body.
	//Set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
    
	b2Body *body = world->CreateBody(&bodyDef);
    b2CircleShape shape;
    shape.m_radius = 10.0 / PTM_RATIO;
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &shape;	
	fixtureDef.density = 100.0f;
	fixtureDef.friction = 1.0f;
    fixtureDef.restitution = 0.2f;
	body->CreateFixture(&fixtureDef);
    
    return body;
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
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//ballA->ApplyAngularImpulse(-9999);
    //ballA->ApplyTorque(-1000000);
    ballA->ApplyLinearImpulse(b2Vec2(99,0), ballA->GetPosition());
}

@end
