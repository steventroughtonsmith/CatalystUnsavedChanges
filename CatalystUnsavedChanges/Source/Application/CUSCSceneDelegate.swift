//
//  CUSCSceneDelegate.swift
//  CatalystUnsavedChanges
//
//  Created by Steven Troughton-Smith on 08/02/2023.
//  
//

import UIKit

class CUSCSceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else {
			fatalError("Expected scene of type UIWindowScene but got an unexpected type")
		}
		window = UIWindow(windowScene: windowScene)
		
		CUSCWindowManager.shared.editorWindowIdentifier = session.persistentIdentifier
		
		if let window = window {
			window.rootViewController = CUSCMainViewController()
			
			CUSCWindowManager.shared.alertPresentationParent = window.rootViewController
			
#if targetEnvironment(macCatalyst)
			
			let toolbar = NSToolbar(identifier: NSToolbar.Identifier("CUSCSceneDelegate.Toolbar"))
			toolbar.delegate = self
			toolbar.displayMode = .iconOnly
			toolbar.allowsUserCustomization = false
			
			windowScene.titlebar?.toolbar = toolbar
			windowScene.titlebar?.toolbarStyle = .unified
			
#endif
			
			window.makeKeyAndVisible()
		}
	}
}
