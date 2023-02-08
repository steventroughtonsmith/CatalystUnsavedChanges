//
//  CUSCWindowManager.swift
//  CatalystUnsavedChanges
//
//  Created by Steven Troughton-Smith on 08/02/2023.
//

import UIKit

// MARK: - Swizzles

extension NSObject {
	@objc func hostWindowForSceneIdentifier(_ identifier:String) -> NSObject? {
		return nil
	}
	
	@objc func CUSC_windowShouldClose(_ window:NSObject) -> Bool {
		
		if window == CUSCWindowManager.shared.nsEditorWindow {
			if CUSCWindowManager.shared.blockWindowCloseBecauseDocumentHasUnsavedChanges == true {
				
				CUSCWindowManager.shared.promptToSaveChanges() {
					let closeSelector = NSSelectorFromString("performClose:")
					
					if window.responds(to: closeSelector) {
						window.perform(closeSelector)
					}
				}
				return false
			}
		}
		
		return CUSC_windowShouldClose(window)
	}
	
	@objc func CUSC_terminate(_ sender:AnyObject?) {
		
		if CUSCWindowManager.shared.blockWindowCloseBecauseDocumentHasUnsavedChanges == true {
			
			CUSCWindowManager.shared.promptToSaveChanges() { [weak self] in
				self?.CUSC_terminate(sender)
			}
			return
		}
		
		return CUSC_terminate(sender)
	}
}

// MARK: - Window Manager

class CUSCWindowManager: NSObject {
	static let shared = CUSCWindowManager()
	
	var editorWindowIdentifier:String = ""
	
	var alertPresentationParent:UIViewController?
	var nsEditorWindow:NSObject? = nil
			
	var blockWindowCloseBecauseDocumentHasUnsavedChanges = false {
		didSet {
			nsEditorWindow?.setValue(blockWindowCloseBecauseDocumentHasUnsavedChanges, forKeyPath: "documentEdited")
		}
	}
	
	override init() {
		super.init()
		
		/*
		 Hook the UIKit NSWindow delegate close event
		 */
		do {
			let m1 = class_getInstanceMethod(NSClassFromString("UINSSceneWindowController"), NSSelectorFromString("windowShouldClose:"))
			let m2 = class_getInstanceMethod(NSClassFromString("UINSSceneWindowController"), NSSelectorFromString("CUSC_windowShouldClose:"))
			if let m1 = m1, let m2 = m2 {
				method_exchangeImplementations(m1, m2)
			}
		}
		
		/*
		 Hook the NSApplication close event
		 */
		do {
			let m1 = class_getInstanceMethod(NSClassFromString("NSApplication"), NSSelectorFromString("terminate:"))
			let m2 = class_getInstanceMethod(NSClassFromString("NSApplication"), NSSelectorFromString("CUSC_terminate:"))
			if let m1 = m1, let m2 = m2 {
				method_exchangeImplementations(m1, m2)
			}
		}
		
		/*
		 Uses the Catalyst NSWindow creation entrypoint notification (Private)
		 */
		NotificationCenter.default.addObserver(forName: NSNotification.Name("UISBHSDidCreateWindowForSceneNotification"), object: nil, queue: .main) { [weak self] notification in
			
			if let userInfo = notification.userInfo, let sceneIdentifier = userInfo["SceneIdentifier"] as? String {
				self?.prepareScene(for: sceneIdentifier)
			}
		}
	}
	
	func prepareScene(for identifier:String) {
		if identifier.hasSuffix(editorWindowIdentifier) {
			guard let nsApp = NSClassFromString("NSApplication") else { return }
			guard let appDelegate = nsApp.value(forKeyPath: "sharedApplication.delegate") as? NSObject else { return }
			
			if appDelegate.responds(to: #selector(hostWindowForSceneIdentifier(_:))) {
				guard let hostWindowProxy = appDelegate.hostWindowForSceneIdentifier(identifier) else { return }
				guard let nsWindow = hostWindowProxy.value(forKeyPath: "attachedWindow") as? NSObject else { return }
				
				nsEditorWindow = nsWindow
			}
		}
	}
	
	// MARK: - Prompt to Save
	
	func promptToSaveChanges(completion: @escaping () -> Void) {
		let alert = UIAlertController(title: "Unsaved Changes", message: "Are you sure you want to lose these changes?", preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "Lose Changes", style: .destructive, handler: { [weak self] _ in
			self?.blockWindowCloseBecauseDocumentHasUnsavedChanges = false
			completion()
		}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		
		alertPresentationParent?.present(alert, animated: true)
	}
}
