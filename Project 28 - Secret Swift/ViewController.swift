//
//  ViewController.swift
//  Project 28 - Secret Swift
//
//  Created by Vitali Vyucheiski on 5/28/22.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    @IBOutlet weak var secret: UITextView!
    var passwordWasSet = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let passwordWasSetPassFromKeyChain = KeychainWrapper.standard.bool(forKey: "PasswordWasSet") {
            print("Recovered bool")
            passwordWasSet = passwordWasSetPassFromKeyChain
        }
        
        title = "Nothing to see here"
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @IBAction func authenticateTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        
        if passwordWasSet == false {
            let ac = UIAlertController(title: "Set Password", message: "Provide secure password for your SUPER secret notes", preferredStyle: .alert)
            ac.addTextField()
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak ac] _ in
                guard let password = ac?.textFields?[0].text else { return }
                self.passwordWasSet = true
                KeychainWrapper.standard.set(password, forKey: "Password")
                KeychainWrapper.standard.set(self.passwordWasSet, forKey: "PasswordWasSet")
            })
            self.present(ac, animated: true)
            
        }   else if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Identify yourself!"

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                    [weak self] success, authenticationError in

                    DispatchQueue.main.async {
                        if success {
                            self?.unlockSecretMessage()
                        } else {
                            let ac = UIAlertController(title: "Password", message: "", preferredStyle: .alert)
                            ac.addTextField()
                            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                            ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak ac] _ in
                                guard let password = ac?.textFields?[0].text else { return }
                                if password == KeychainWrapper.standard.string(forKey: "Password") {
                                    self?.unlockSecretMessage()
                                } else {
                                    let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                                    self?.present(ac, animated: true)
                                }
                            })
                            self?.present(ac, animated: true)
                        }
                    }
                }
            } else {
                let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        secret.scrollIndicatorInsets = secret.contentInset

        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage() {
        secret.isHidden = false
        title = "Secret stuff!"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveSecretMessage))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Change Password", style: .done, target: self, action: #selector(changePassword))

        secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage") ?? ""
    }
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItem = nil

        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        secret.resignFirstResponder()
        secret.isHidden = true
        title = "Nothing to see here"
    }
    
    @objc func changePassword() {
        let ac = UIAlertController(title: "Change Password", message: "Provide your previous password", preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak ac] _ in
            guard let password = ac?.textFields?[0].text else { return }
            if password == KeychainWrapper.standard.string(forKey: "Password") {
                let ac = UIAlertController(title: "Set NewPassword", message: "Provide new password", preferredStyle: .alert)
                ac.addTextField()
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak ac] _ in
                    guard let newPassword = ac?.textFields?[0].text else { return }
                    KeychainWrapper.standard.set(newPassword, forKey: "Password")
                })
                self.present(ac, animated: true)
            } else {
                let ac = UIAlertController(title: "You've entered incorrect password", message: "", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Try Again", style: .default, handler: {_ in self.changePassword(); return }))
                ac.addAction(UIAlertAction(title: "Ok", style: .cancel))
                self.present(ac, animated: true)
            }
        })
        self.present(ac, animated: true)
        
        
    }
    
}

