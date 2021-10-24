//
//  ActionViewController.swift
//  ActionExtension
//
//  Created by Abhik Ahuja on 10/23/21.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    @IBOutlet weak var MainView: UIView!
    @IBOutlet weak var NavigationBar: UINavigationBar!
    
    @IBOutlet weak var shortenedLink: UILabel!
    
    var url: URL?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBar.topItem?.title = "Uni"
        // Get the item[s] we're handling from the extension context.
        
        // For example, look for an image and place it into an image view.
        // Replace this with something appropriate for the type[s] your extension supports.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var urlFound = false
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil, completionHandler: { (url, error) in
                            OperationQueue.main.addOperation {
                                if error == nil {
                                    if let strongUrl = url as? URL {
                                        self.url = strongUrl
                                        urlFound = true
                                        self.shortenedLink.text = URLShortener.shortenURL(string: self.url!.absoluteString)
                                        return
                                    }
                                }
                            }
                    })
                    if (urlFound) {
                        break
                    }
                }
            }
        }
        return
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }
    
    @IBAction func share() {
        guard let shortenedLinkStr = shortenedLink.text else {
            return
        }
        let url = URL(string: shortenedLinkStr)
        let av = UIActivityViewController(activityItems: [url!],
            applicationActivities: nil)
        
        present(av, animated: true, completion: nil)
}

}
