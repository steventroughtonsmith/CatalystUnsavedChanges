//
//  CUSCMainViewController.swift
//  CatalystUnsavedChanges
//
//  Created by Steven Troughton-Smith on 08/02/2023.
//  
//

import UIKit

final class CUSCMainViewController: UIViewController {

	let textView = UITextView()
	
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "CatalystUnsavedChanges"
		textView.delegate = self
		view.addSubview(textView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	// MARK: -
	
	override func viewDidLoad() {
		textView.becomeFirstResponder()
	}
	
	override func viewDidLayoutSubviews() {
		textView.contentInset = view.safeAreaInsets
		textView.frame = view.bounds
	}
}

extension CUSCMainViewController : UITextViewDelegate {
	func textViewDidChange(_ textView: UITextView) {
		CUSCWindowManager.shared.blockWindowCloseBecauseDocumentHasUnsavedChanges = true
	}
}
