//
//  ViewController.swift
//  GoogleDriveSample
//
//  Created by Ng Hui Qin on 4/9/15.
//  Copyright (c) 2015 huiqin.testing. All rights reserved.
//

import UIKit
import MobileCoreServices
import SDWebImage

protocol GoogleDriveViewControllerDelegate: NSObjectProtocol{
    func getFile(data: NSData, mimeType:String)
}

extension UIBarButtonItem {
    func addTargetForAction(target: AnyObject, action: Selector) {
        self.target = target
        self.action = action
    }
}

class GoogleDriveViewController: UIViewController , UINavigationControllerDelegate ,UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate  {
    
    var delegate:GoogleDriveViewControllerDelegate?
    func setDelegate(tdelegate:GoogleDriveViewControllerDelegate){
        self.delegate = tdelegate
    }
    
    var window: UIWindow?
    let driveService : GTLServiceDrive =  GTLServiceDrive()
    
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var navItem: UINavigationItem!
    
    @IBOutlet weak var tableView: UITableView!
    let scopes = "https://www.googleapis.com/auth/drive.file"
    let kKeychainItemName : NSString = "Google Drive Document Picker"
    let kClientID = "Your client id"
    let kClientSecret = "your client secret"
    var fileList:[AnyObject]!
    var history:[String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.backButton.addTargetForAction(self, action: Selector("backHandler"))
        self.dismissButton.addTargetForAction(self, action: Selector("closeHandler"))
        
        self.driveService.authorizer  = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(kKeychainItemName as String,
            clientID: kClientID,
            clientSecret: kClientSecret)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if (!self.isAuthorized()){
            self.presentViewController(self.createAuthController(), animated: true, completion: nil)
        }
        else{
            
            executeQuery("(mimeType = 'application/vnd.google-apps.folder' or mimeType = 'image/jpeg' or mimeType = 'image/png' or mimeType = 'video/mp4') and 'root' in parents and trashed=false", folderId: "root", isBack: false)
            
        }
    }
    
    
    func executeQuery(queryString:String, folderId:String, isBack:Bool){
        
        let query:GTLQueryDrive = GTLQueryDrive.queryForFilesList() as! GTLQueryDrive
        query.maxResults = 1000
        query.q = queryString
        
        self.driveService.executeQuery(query, completionHandler: { (ticket, files, error) -> Void in
            
            if let fList:GTLDriveFileList = files as? GTLDriveFileList{
                
                self.fileList = fList.items()
                self.tableView.reloadData()
                
                if isBack == false {
                    self.history.append(folderId)
                }
                
                if let _ = fList.items() {
                    //scroll top
                    let indexPath = NSIndexPath(forItem: 0, inSection: 0)
                    self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
                }
                
            }
        })
    }
    
    
    func closeHandler(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func backHandler(){

        if(self.history.count>1){
            
            self.history.removeLast()
            let previousFolderId = self.history.last!
            
            //here we query for folders, images (jpg, png) and videos (mp4)
            //you can change your query according to your needs.
            executeQuery("(mimeType = 'application/vnd.google-apps.folder' or mimeType = 'image/jpeg' or mimeType = 'image/png') and '\(previousFolderId)' in parents and trashed=false", folderId: previousFolderId, isBack: true)
        }
    }
    
    
    //Table view delegates
    func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int
    {
        let len = (self.fileList != nil) ? self.fileList.count : 0
        return len
    }

    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "driveCell")
        cell.textLabel!.text = self.fileList[indexPath.row].title
        
        if let imageView = cell.imageView{
            
            //if file type is folder, create folder cell
            if self.fileList[indexPath.row].mimeType == "application/vnd.google-apps.folder" {
                
                imageView.image = UIImage(named: "folder_icon")
                
            } else {
                
                if(imageView.image == nil){
                    //TO DO: add a paleceholder image here. UIImage(named: "folder") -> UIImage(named: "placeholder")
                    imageView.sd_setImageWithURL(NSURL(string: self.fileList[indexPath.row].thumbnailLink)!, placeholderImage: UIImage(named: "folder_icon"))
                }
                
            }
        }
        
        return cell
    }
    
   
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // if selected file is folder, then open that folder with a new query
        if(self.fileList[indexPath.row].mimeType == "application/vnd.google-apps.folder"){
            
            
            let selectedDriveFile = self.fileList[indexPath.row] as! GTLDriveFile
            
            //here we query for folders, images (jpg, png) and videos (mp4)
            //you can change your query according to your needs.
            executeQuery("(mimeType = 'application/vnd.google-apps.folder' or mimeType = 'image/jpeg' or mimeType = 'image/png') and '\(selectedDriveFile.identifier)' in parents and trashed=false", folderId: selectedDriveFile.identifier, isBack: false)
            
            
        }else{
            
            //download selected file
            let fetcher:GTMHTTPFetcher = self.driveService.fetcherService.fetcherWithURLString(self.fileList[indexPath.row].downloadUrl)
            fetcher.beginFetchWithCompletionHandler { (data, error) -> Void in
                
                self.delegate?.getFile(data, mimeType: self.fileList[indexPath.row].mimeType)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    //
    
    
    // Helper to check if user is authorized
    func isAuthorized() -> Bool {
        return (self.driveService.authorizer as! GTMOAuth2Authentication).canAuthorize
    }
    
    // Creates the auth controller for authorizing access to Google Drive.
    func createAuthController() -> GTMOAuth2ViewControllerTouch {
        return GTMOAuth2ViewControllerTouch(scope: kGTLAuthScopeDrive,
            clientID: kClientID,
            clientSecret: kClientSecret,
            keychainItemName: kKeychainItemName as String,
            delegate: self,
            finishedSelector: Selector("viewController:finishedWithAuth:error:"))
        
    }

    
    // Handle completion of the authorization process, and updates the Drive service
    // with the new credentials.
    func viewController(viewController: GTMOAuth2ViewControllerTouch , finishedWithAuth authResult: GTMOAuth2Authentication , error:NSError? ) {
        if let _ = error{
            //show a fail message here.
            print("Authentication failed")
            self.driveService.authorizer = nil
        } else {
            print("Authentication success")
            self.driveService.authorizer = authResult
            viewController.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    
}


