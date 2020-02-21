//
//  YuneecPreviewView.m
//  YuneecPreviewView
//
//  Created by tbago on 17/1/26.
//  Copyright © 2017年 yuneec. All rights reserved.
//

#import "YuneecPreviewView.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#include <sys/time.h>

enum AttribEnum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE,
    ATTRIB_COLOR,
};

enum TextureType
{
    TEXY = 0,
    TEXU,
    TEXV,
    TEXC
};

@interface YuneecPreviewView()
{
    EAGLContext             *_glContext;///<OpenGL绘图上下文
    GLuint                  _framebuffer;///<帧缓冲区
    GLuint                  _renderBuffer;///<渲染缓冲区
    GLuint                  _program;///<着色器句柄
    GLuint                  _textureYUV[3];///<YUV纹理数组
    GLuint                  _videoW;///<视频宽度
    GLuint                  _videoH;///<视频高度
    GLsizei                 _viewScale;
    //void                    *_pYuvData;
#ifdef DEBUG
    struct timeval      _time;
    NSInteger           _frameRate;
#endif
}

//#define PRINT_CALL 1

/**
 初始化YUV纹理
 */
- (void)setupYUVTexture:(YuneecPreviewPixelFmtType)fmtType;

/**
 创建缓冲区
 @return 成功返回TRUE 失败返回FALSE
 */
- (BOOL)createFrameAndRenderBuffer;

/**
 销毁缓冲区
 */
- (void)destoryFrameAndRenderBuffer;

//加载着色器
/**
 初始化YUV纹理
 */
- (void)loadShader:(YuneecPreviewPixelFmtType)type;

/**
 编译着色代码
 @param shaderCode    代码
 @param shaderType    类型
 @return 成功返回着色器 失败返回－1
 */
- (GLuint)compileShader:(NSString*)shaderCode withType:(GLenum)shaderType;

/**
 渲染
 */
- (void)renderWithVideoWidth:(NSInteger)width height:(NSInteger)height;

@property (nonatomic, readwrite) CGRect renderingRect;

@end

@implementation YuneecPreviewView

const YuneecPreviewPixelFmtType defaultPixelFmtType = YuneecPreviewPixelFmtTypeI420;

@synthesize renderingRect = _renderingRect;

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        if (![self doInit:defaultPixelFmtType]) {
            self = nil;
        }
    }
    _bOpenGlInited = YES;
    _pixelFmtType = defaultPixelFmtType;
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if (![self doInit:defaultPixelFmtType]) {
            self = nil;
        }
    }
    return self;
}

#pragma mark - Public Method

- (void)displayYUV420pData:(void *)data width:(NSInteger)w height:(NSInteger)h pixelFmt:(YuneecPreviewPixelFmtType)fmtType
{
    //_pYuvData = data;
    //    if (_offScreen || !self.window)
    //    {
    //        return;
    //    }
    @synchronized(self)
    {
        if (w != _videoW || h != _videoH)
        {
            [self setVideoSize:(GLuint)w height:(GLuint)h pixelFmt:fmtType];
        }
        [EAGLContext setCurrentContext:_glContext];
        
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
        
        //glTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid* pixels);
        
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLsizei)w, (GLsizei)h, GL_RED_EXT, GL_UNSIGNED_BYTE, data);
        
        //[self debugGlError];
        if(YuneecPreviewPixelFmtTypeI420 == fmtType) {
            glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLsizei)w/2, (GLsizei)h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, data + w * h);
            glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLsizei)w/2, (GLsizei)h/2, GL_RED_EXT, GL_UNSIGNED_BYTE, data + w * h * 5 / 4);
        }
        else {
            glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (GLsizei)w/2, (GLsizei)h/2, GL_RG_EXT, GL_UNSIGNED_BYTE, data + w * h);
        }
        //[self debugGlError];
        
        [self renderWithVideoWidth:w height:h];
    }
    
#ifdef DEBUG
    
    GLenum err = glGetError();
    if (err != GL_NO_ERROR)
    {
        printf("GL_ERROR=======>%d\n", err);
    }
    struct timeval nowtime;
    gettimeofday(&nowtime, NULL);
    if (nowtime.tv_sec != _time.tv_sec)
    {
//        printf("视频 %d 帧率:   %d\n", self.tag, _frameRate);
        memcpy(&_time, &nowtime, sizeof(struct timeval));
        _frameRate = 1;
    }
    else
    {
        _frameRate++;
    }
#endif
}

- (void)setVideoSize:(GLuint)width height:(GLuint)height pixelFmt:(YuneecPreviewPixelFmtType)fmtType
{
    _videoW = width;
    _videoH = height;
    [self clearFrame];
    [self destoryFrameAndRenderBuffer];
    [self createFrameAndRenderBuffer];
    
    void *blackData = malloc(width * height * 1.5);
    if(blackData)
        //bzero(blackData, width * height * 1.5);
        memset(blackData, 0x0, width * height * 1.5);
    
    [EAGLContext setCurrentContext:_glContext];
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RG_EXT, width/2, height/2, 0, GL_RG_EXT, GL_UNSIGNED_BYTE, blackData + width * height);

    if(fmtType == YuneecPreviewPixelFmtTypeI420) {
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height);
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width/2, height/2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, blackData + width * height * 5 / 4);
    }
    else {
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RG_EXT, width/2, height/2, 0, GL_RG_EXT, GL_UNSIGNED_BYTE, blackData + width * height);
    }
    free(blackData);
}


- (void)clearFrame
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self window])
        {
            [EAGLContext setCurrentContext:_glContext];
            glClearColor(0.0, 0.0, 0.0, 1.0);
            glClear(GL_COLOR_BUFFER_BIT);
            glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
            [_glContext presentRenderbuffer:GL_RENDERBUFFER];
        }
    });
}
#pragma mark - View inherit

- (void)layoutSubviews
{
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized(self)
        {
            [EAGLContext setCurrentContext:_glContext];
            [self destoryFrameAndRenderBuffer];
            [self createFrameAndRenderBuffer];
        }
        
        glViewport(0, 0, self.bounds.size.width*_viewScale, self.bounds.size.height*_viewScale);
    });
}


/**
 设置OpenGL
 */
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


#pragma mark - OpenGL Initialization

- (BOOL)doInit:(YuneecPreviewPixelFmtType)fmtType
{
    self.scaleMode = YuneecPreviewViewScaleModeAspectFit;
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    //eaglLayer.opaque = YES;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat,
                                    //[NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking,
                                    nil];
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    _viewScale = [UIScreen mainScreen].scale;
    
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //[self debugGlError];
    
    if(!_glContext || ![EAGLContext setCurrentContext:_glContext])
    {
        return NO;
    }
    
    [self setupYUVTexture:fmtType];
    [self loadShader:fmtType];
    glUseProgram(_program);

    if(YuneecPreviewPixelFmtTypeI420 == fmtType) {
        GLuint textureUniformY = glGetUniformLocation(_program, "SamplerY");
        GLuint textureUniformU = glGetUniformLocation(_program, "SamplerU");
        GLuint textureUniformV = glGetUniformLocation(_program, "SamplerV");
        glUniform1i(textureUniformY, 0);
        glUniform1i(textureUniformU, 1);
        glUniform1i(textureUniformV, 2);
    }
    else {
        GLuint textureUniformY = glGetUniformLocation(_program, "SamplerY");
        GLuint textureUniformUV = glGetUniformLocation(_program, "SamplerUV");
        glUniform1i(textureUniformY, 0);
        glUniform1i(textureUniformUV, 1);
    }
    return YES;
}

- (void)setupYUVTexture:(YuneecPreviewPixelFmtType)fmtType
{
    if (_textureYUV[TEXY])
    {
        glDeleteTextures(3, _textureYUV);
    }
    glGenTextures(3, _textureYUV);
    if (!_textureYUV[TEXY] || !_textureYUV[TEXU] || !_textureYUV[TEXV])
    {
        NSLog(@"<<<<<<<<<<<<纹理创建失败!>>>>>>>>>>>>");
        return;
    }
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXY]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXU]);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    if(YuneecPreviewPixelFmtTypeI420 == fmtType) {
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, _textureYUV[TEXV]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}

#define FSH @"varying lowp vec2 TexCoordOut;\
\
uniform sampler2D SamplerY;\
uniform sampler2D SamplerU;\
uniform sampler2D SamplerV;\
\
void main(void)\
{\
mediump vec3 yuv;\
lowp vec3 rgb;\
\
yuv.x = texture2D(SamplerY, TexCoordOut).r;\
yuv.y = texture2D(SamplerU, TexCoordOut).r - 0.5;\
yuv.z = texture2D(SamplerV, TexCoordOut).r - 0.5;\
\
rgb = mat3( 1,       1,         1,\
0,       -0.39465,  2.03211,\
1.13983, -0.58060,  0) * yuv;\
\
gl_FragColor = vec4(rgb, 1);\
\
}"

#define FSH_NV12 @"varying lowp vec2 TexCoordOut;\
\
uniform sampler2D SamplerY;\
uniform sampler2D SamplerUV;\
\
void main(void)\
{\
mediump vec3 yuv;\
lowp vec3 rgb;\
\
yuv.x = texture2D(SamplerY, TexCoordOut).r;\
yuv.yz = texture2D(SamplerUV, TexCoordOut).rg - vec2(0.5, 0.5);\
\
rgb = mat3(1, 1, 1, \
0, -.21482, 2.12798, \
1.28033, -.38059, 0) * yuv;   \
\
gl_FragColor = vec4(rgb, 1);\
\
}"


#define VSH @"attribute vec4 position;\
attribute vec2 TexCoordIn;\
varying vec2 TexCoordOut;\
\
void main(void)\
{\
gl_Position = position;\
TexCoordOut = TexCoordIn;\
}"

/**
 加载着色器
 */
- (void)loadShader:(YuneecPreviewPixelFmtType)fmtType
{
    /**
     1
     */
    GLuint fragmentShader = 0;
    GLuint vertexShader = [self compileShader:VSH withType:GL_VERTEX_SHADER];
    if(YuneecPreviewPixelFmtTypeI420 == fmtType) {
        fragmentShader = [self compileShader:FSH withType:GL_FRAGMENT_SHADER];
    }
    else {
        fragmentShader = [self compileShader:FSH_NV12 withType:GL_FRAGMENT_SHADER];
    }
    
    /**
     2
     */
    _program = glCreateProgram();
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    
    /**
     绑定需要在link之前
     */
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXTURE, "TexCoordIn");
    
    glLinkProgram(_program);
    
    /**
     3
     */
    GLint linkSuccess;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"<<<<着色器连接失败 %@>>>", messageString);
        //exit(1);
    }
    
    if (vertexShader)
        glDeleteShader(vertexShader);
    if (fragmentShader)
        glDeleteShader(fragmentShader);
}

- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType
{
    
   	/**
     1
     */
    NSError *error = nil;
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    else
    {
        //NSLog(@"shader code-->%@", shaderString);
    }
    
    /**
     2
     */
    GLuint shaderHandle = glCreateShader(shaderType);
    
    /**
     3
     */
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    /**
     4
     */
    glCompileShader(shaderHandle);
    
    /**
     5
     */
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

- (BOOL)createFrameAndRenderBuffer
{
    glGenFramebuffers(1, &_framebuffer);
    glGenRenderbuffers(1, &_renderBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    
    if (![_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer])
    {
        NSLog(@"attach渲染缓冲区失败");
    }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"创建缓冲区错误 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    return YES;
}

- (void)destoryFrameAndRenderBuffer
{
    if (_framebuffer)
    {
        glDeleteFramebuffers(1, &_framebuffer);
    }
    
    if (_renderBuffer)
    {
        glDeleteRenderbuffers(1, &_renderBuffer);
    }
    
    _framebuffer = 0;
    _renderBuffer = 0;
    _bOpenGlInited = NO;
}

#pragma mark - Private Method

- (void)renderWithVideoWidth:(NSInteger)width height:(NSInteger)height
{
    [EAGLContext setCurrentContext:_glContext];
    CGSize size = self.bounds.size;
    
    double viewAspectRatio = size.width / size.height;
    double streamAspectRatio = (CGFloat)width/(CGFloat)height;
    
    GLint renderXOffset     = 0;
    GLint renderYOffset     = 0;
    GLsizei renderWidth     = size.width;
    GLsizei renderHeight    = size.height;
    
    if (self.scaleMode == YuneecPreviewViewScaleModeAspectFit)
    {
    /// <0 y补偿; =0; >0 x补偿
        double supplimentRet = viewAspectRatio - streamAspectRatio;
        
        if (supplimentRet > 0) {
            renderWidth = streamAspectRatio * size.height;
            renderHeight = size.height;
            
            renderXOffset = (size.width - renderWidth) / 2;
            renderYOffset = 0;
        }
        else {
            renderWidth = size.width;
            renderHeight = size.width / streamAspectRatio;
            
            renderXOffset = 0;
            renderYOffset = (size.height - renderHeight) / 2;
        }
    }
    else if (self.scaleMode == YuneecPreviewViewScaleModeAspectFill) {
        double supplimentRet = viewAspectRatio - streamAspectRatio;
        
        if (supplimentRet > 0) {
            renderWidth = size.width;
            renderHeight = size.width / streamAspectRatio;
            
            renderXOffset = 0;
            renderYOffset = (size.height - renderHeight) / 2;
        }
        else {
            renderWidth  = size.height * streamAspectRatio;
            renderHeight = size.height;
            
            renderXOffset = (size.width - renderWidth) / 2;
            renderYOffset = 0;
        }
    }
    
    glViewport(renderXOffset * _viewScale, renderYOffset * _viewScale, renderWidth * _viewScale, renderHeight * _viewScale);
    
    self.renderingRect = CGRectMake(renderXOffset, renderYOffset, renderWidth, renderHeight);

    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    
    static const GLfloat coordVertices[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    
    // Update attribute values
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    glVertexAttribPointer(ATTRIB_TEXTURE, 2, GL_FLOAT, 0, 0, coordVertices);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    
    // Draw
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [_glContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}

//- (void)debugGlError
//{
//    GLenum r = glGetError();
//    if (r != 0)
//    {
//        printf("%d   \n", r);
//    }
//}

@end
