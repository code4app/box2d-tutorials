//
//  HelloWorldLayer.mm
//  Box2D_02
//
//  Created by curer on 7/19/13.
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

@property (nonatomic, assign) b2Body *testWall;

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
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;		
	
	// bottom
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// top
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
	groundBody->CreateFixture(&groundBox,0);
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,0);
	
	// right
	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,0);
    
    [self initWalls];
}

- (void)initWalls
{
    [self b2BodyStaticWithPosition:ccp(100, 200)
                          andAngle: -1 * M_PI_4
                           andSize:CGSizeMake(50, 5)];
    
    
    [self b2BodyStaticWithPosition:ccp(200, 30)
                          andAngle:0
                           andSize:CGSizeMake(100, 5)];
    
    /** not working， Static can't move
     *
     b2Vec2 force = b2Vec2(-30, 30);
     self.testWall = [self b2BodyStaticWithPosition:ccp(300, 30) andAngle:0 andSize:CGSizeMake(5, 50)];
     self.testWall->ApplyLinearImpulse(force, self.testWall->GetPosition());
     */
    
    /** not working Static can't move
    self.testWall = [self b2BodyStaticWithPosition:ccp(300, 30)
                                          andAngle:0
                                           andSize:CGSizeMake(5, 50)];
    self.testWall->SetLinearVelocity(b2Vec2(2, 0));*/
    
    self.testWall = [self b2BodykinematicWithPosition:ccp(380, 30)
                                             andAngle:0
                                              andSize:CGSizeMake(5, 50)];
    self.testWall->SetLinearVelocity(b2Vec2(-2, 0));
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
    
    body->CreateFixture(&fixtureDef);
    
    return body;
}

- (b2Body *)b2BodykinematicWithPosition:(CGPoint)pt andAngle:(CGFloat)angle andSize:(CGSize)size
{
    b2BodyDef bodyDef;
    
    bodyDef.type = b2_kinematicBody; //no need this is default value
    bodyDef.angle = angle;
    bodyDef.position.Set(pt.x / PTM_RATIO, pt.y / PTM_RATIO);
    
    b2Body *body = world->CreateBody(&bodyDef);
    
    b2PolygonShape shape;
    shape.SetAsBox(size.width / PTM_RATIO, size.height / PTM_RATIO);
    
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = 0;
    
    body->CreateFixture(&fixtureDef);
    
    return body;
}

- (b2Body *)b2BodydynamicWithPosition:(CGPoint)pt andAngle:(CGFloat)angle andSize:(CGSize)size
{
    b2BodyDef bodyDef;
    
    bodyDef.type = b2_dynamicBody; //no need this is default value
    bodyDef.angle = angle;
    bodyDef.position.Set(pt.x / PTM_RATIO, pt.y / PTM_RATIO);
    
    b2Body *body = world->CreateBody(&bodyDef);
    
    b2PolygonShape shape;
    shape.SetAsBox(size.width / PTM_RATIO, size.height / PTM_RATIO);
    
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = 0;
    
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

-(void) addNewSpriteAtPosition:(CGPoint)p
{
	CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
	// Define the dynamic body.
	//Set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	b2PolygonShape dynamicBox;
	dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicBox;	
	fixtureDef.density = 1.0f;
	fixtureDef.friction = 0.3f;
	body->CreateFixture(&fixtureDef);
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
	//Add a new body/atlas sprite at the touched location
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		
		location = [[CCDirector sharedDirector] convertToGL: location];
		
		[self addNewSpriteAtPosition: location];
	}
}

@end
