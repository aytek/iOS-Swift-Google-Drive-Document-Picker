//
//  ViewController.swift
//  GoogleDriveSample
//
//  Created by aytekin meral on 27/10/2015.
//  Copyright © 2015 huiqin.testing. All rights reserved.
//

import UIKit

class ViewController: UIViewController, GoogleDriveViewControllerDelegate {

    var imageView:UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func browseFiles(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("googleDrive") as! GoogleDriveViewController
        self.presentViewController(vc, animated: true, completion: { () -> Void in
            vc.delegate = self
        })
    }
    
    
    
    //Google Drive Delegate
    func getFile(data: NSData, mimeType:String) {
        
        if mimeType == "image/png" || mimeType == "image/jpg" || mimeType == "image/jpeg" {
            
            self.imageView?.removeFromSuperview()
            
            self.imageView = UIImageView(frame: CGRectMake(0, 200, self.view.bounds.width, self.view.bounds.height-250))
            self.view.addSubview(self.imageView!)
            self.imageView?.contentMode = .ScaleAspectFit
            self.imageView?.image = UIImage(data: data)
        }
        else if mimeType == "video/mp4"{
            //play video file
            //http://stackoverflow.com/questions/30717302/how-to-play-movie-file-from-the-web-with-nsdata
        }
        else{
            print(mimeType)
        }
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
