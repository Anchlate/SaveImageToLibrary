//
//  ViewController.m
//  保存图片到相册
//
//  Created by Qianrun on 16/8/30.
//  Copyright © 2016年 qianrun. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>


@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) NSInteger saveType;
@property (nonatomic, strong) UIImage *targetImage;
@property (nonatomic, retain) NSURL *targetImageURL;
@property (nonatomic, retain) NSURL *targetVideoURL;

- (IBAction)defineImageLibrary:(id)sender;
- (IBAction)imageLibrary:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

#pragma mark -Event
- (IBAction)defineImageLibrary:(id)sender {
    
    NSLog(@"......保存相片到自定义相册");
    
    [self save];
}

- (IBAction)imageLibrary:(id)sender {
    NSLog(@"......保存相片到相册");
    
    [self saveImageFromImage:self.imageView.image];
    
}




#pragma mark -Private

// 保存相片到相册的三种方法

// 1.
- (void)saveImageFromImage:(UIImage *)image{
    _saveType = 0;
    _targetImage = image;
    [self saveIntoAlbum];
}

// 2.
- (void)saveImageFromFileURL:(NSURL *)url{
    
    _saveType = 1;
    _targetImageURL = url;
    [self saveIntoAlbum];
}

// 3.
- (void)saveVideoFromFileURL:(NSURL *)url{
    _saveType = 2;
    _targetVideoURL = url;
    [self saveIntoAlbum];
}

- (void)saveIntoAlbum{
    
    // 1、判断相册访问权限
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (![self achiveAuthorizationStatus]) {
            // 没权限
            return ;
        }
        
        NSError *error = nil;
        // 2、有权限，保存相片到相机胶卷
        __block PHObjectPlaceholder *targetObject = nil;
//        __weak typeof (self) weakself = self;
        
        switch (_saveType) {
            case 0:{
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    targetObject = [PHAssetCreationRequest creationRequestForAssetFromImage:_targetImage].placeholderForCreatedAsset;
                } error:&error];
                break;
            }
            case 1:{
                
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    targetObject = [PHAssetCreationRequest creationRequestForAssetFromImageAtFileURL:_targetImageURL].placeholderForCreatedAsset;
                } error:&error];
                break;
            }
            case 2:{
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    targetObject = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:_targetVideoURL].placeholderForCreatedAsset;
                } error:&error];
                break;
            }
                
            default:
                break;
        }
        
        if (error) {
            NSLog(@"保存失败：%@", error);
            return;
        }
        
        
        NSLog(@"......保存成功");
        
        // TODO: 将保存到系统的图片或视频引用保存到自定义相册
    }];
}

// 判断是否有权限
- (BOOL)achiveAuthorizationStatus{
    
    // 1、判断相册访问权限
    /*
     * PHAuthorizationStatusNotDetermined = 0, 用户未对这个应用程序的权限做出选择
     * PHAuthorizationStatusRestricted, 此应用程序没有被授权访问的照片数据。可能是家长控制权限。
     * PHAuthorizationStatusDenied, 用户已经明确拒绝了此应用程序访问照片数据.
     * PHAuthorizationStatusAuthorized, 用户已授权此应用访问照片数据.
     */
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        // 没权限
        UIAlertController *authorizationAlert = [UIAlertController alertControllerWithTitle:@"提示" message:@"没有照片的访问权限，请在设置中开启" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:NULL];
        [authorizationAlert addAction:cancel];
        [self presentViewController:authorizationAlert animated:YES completion:nil];
        return NO;
    } else {
        return YES;
    }
}

/***************************************************************************************************/

// 获取应用名作为自定义相册名
#define albumName [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey]
- (PHAssetCollection *)createdCollection {
    
    // 获得所有的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:albumName]) {
            return collection;
        }
    }
    
    // 代码执行到这里，说明还没有自定义相册
    __block NSString *createdCollectionId = nil;
    
    // 创建一个新的相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName].placeholderForCreatedAssetCollection.localIdentifier;
    } error:nil];
    
    if (createdCollectionId == nil) return nil;
    
    // 创建完毕后再取出相册
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionId] options:nil].firstObject;
}

/**将图片保存到自定义相册中*/

/*
- (void)saveImageToCustomAlbum{
    
    NSError *error = nil;
    
    // 3、拿到自定义的相册对象
    PHAssetCollection *collection = [self createdCollection];
    if (collection == nil) return;
    
    // 4、保存
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection] insertAssets:@[] atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    
    if (error) {
        NSLog(@"保存失败：%@", error);
    } else {
        NSLog(@"保存成功");
    }
}
*/

-(void)save
{
    //(1) 获取当前的授权状态
    PHAuthorizationStatus lastStatus = [PHPhotoLibrary authorizationStatus];
    
    //(2) 请求授权
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        //回到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(status == PHAuthorizationStatusDenied) //用户拒绝（可能是之前拒绝的，有可能是刚才在系统弹框中选择的拒绝）
            {
                if (lastStatus == PHAuthorizationStatusNotDetermined) {
                    //说明，用户之前没有做决定，在弹出授权框中，选择了拒绝
                    NSLog(@"失败！请在系统设置中开启访问相册权限");
                    return;
                }
                // 说明，之前用户选择拒绝过，现在又点击保存按钮，说明想要使用该功能，需要提示用户打开授权
                NSLog(@"失败！请在系统设置中开启访问相册权限");
                
            }
            else if(status == PHAuthorizationStatusAuthorized) //用户允许
            {
                //保存图片---调用上面封装的方法
                [self saveImageToCustomAblum];
            }
            else if (status == PHAuthorizationStatusRestricted)
            {
                NSLog(@"系统原因，无法访问相册");
            }
        });
    }];
}

/**将图片保存到自定义相册中*/
-(void)saveImageToCustomAblum
{
     //1 将图片保存到系统的【相机胶卷】中---调用刚才的方法
     PHFetchResult<PHAsset *> *assets = [self syncSaveImageWithPhotos];
     if (assets == nil)
     {
         
         return;
     }
     
     //2 拥有自定义相册（与 APP 同名，如果没有则创建）--调用刚才的方法
     PHAssetCollection *assetCollection = [self getAssetCollectionWithAppNameAndCreateIfNo];
     if (assetCollection == nil) {
         NSLog(@"相册创建失败");
         return;
     }
     
     
     //3 将刚才保存到相机胶卷的图片添加到自定义相册中 --- 保存带自定义相册--属于增的操作，需要在PHPhotoLibrary的block中进行
     NSError *error = nil;
     [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
         //--告诉系统，要操作哪个相册
         PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
         //--添加图片到自定义相册--追加--就不能成为封面了
         //--[collectionChangeRequest addAssets:assets];
         //--插入图片到自定义相册--插入--可以成为封面
         [collectionChangeRequest insertAssets:assets atIndexes:[NSIndexSet indexSetWithIndex:0]];
     } error:&error];
     
     
     if (error) {
         NSLog(@"保存失败");
         return;
     }
     NSLog(@"保存成功");
 }
 
/**拥有与 APP 同名的自定义相册--如果没有则创建*/
-(PHAssetCollection *)getAssetCollectionWithAppNameAndCreateIfNo
{
    //1 获取以 APP 的名称
    NSString *title = [NSBundle mainBundle].infoDictionary[(__bridge NSString *)kCFBundleNameKey];
    //2 获取与 APP 同名的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        //遍历
        if ([collection.localizedTitle isEqualToString:title]) {
            //找到了同名的自定义相册--返回
            return collection;
        }
    }
    
    //说明没有找到，需要创建
    NSError *error = nil;
    __block NSString *createID = nil; //用来获取创建好的相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        //发起了创建新相册的请求，并拿到ID，当前并没有创建成功，待创建成功后，通过 ID 来获取创建好的自定义相册
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
        createID = request.placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    if (error) {
        NSLog(@"创建失败");
        return nil;
    }else{
        NSLog(@"创建成功");
        //通过 ID 获取创建完成的相册 -- 是一个数组
        return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createID] options:nil].firstObject;
    }
}

/**同步方式保存图片到系统的相机胶卷中---返回的是当前保存成功后相册图片对象集合*/
-(PHFetchResult<PHAsset *> *)syncSaveImageWithPhotos
{
    //--1 创建 ID 这个参数可以获取到图片保存后的 asset对象
    __block NSString *createdAssetID = nil;
    
    //--2 保存图片
    NSError *error = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        //----block 执行的时候还没有保存成功--获取占位图片的 id，通过 id 获取图片---同步
        createdAssetID = [PHAssetChangeRequest creationRequestForAssetFromImage:self.imageView.image].placeholderForCreatedAsset.localIdentifier;
    } error:&error];
    
    //--3 如果失败，则返回空
    if (error) {
        return nil;
    }
    
    //--4 成功后，返回对象
    //获取保存到系统相册成功后的 asset 对象集合，并返回
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetID] options:nil];
    return assets;
}

@end