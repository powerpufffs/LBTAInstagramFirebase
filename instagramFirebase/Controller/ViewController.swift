  //
//  ViewController.swift
//  instagramFirebase
//
//  Created by Z Tai on 10/9/18.
//  Copyright © 2018 Z Tai. All rights reserved.
//

import UIKit
import Firebase
  
  
class ViewController: UIViewController {
    //MARK: Private Properties
    private var plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "plus_photo").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleAddPhoto), for: .touchUpInside)
        return button
    }()
    
    private var emailTextfield: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(formEditingChange), for: .editingChanged)

        return tf
    }()
    
    private var userNameTextfield: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(formEditingChange), for: .editingChanged)
        
        return tf
    }()
    
    private var passwordTextfield: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true

            tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        
        tf.addTarget(self, action: #selector(formEditingChange), for: .editingChanged)

        return tf
    }()
    
    private var signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        button.isEnabled = false

        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(plusPhotoButton)
        
        //Setting Anchors
        plusPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        plusPhotoButton.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 40, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 140, height: 140)
        
        view.addSubview(emailTextfield)
        
        setUpViews()
    }
    
    //MARK: Listeners
    
    @objc private func handleAddPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func formEditingChange() {
        if emailTextfield.text?.count ?? 0 > 0 && userNameTextfield.text?.count ?? 0 > 0, passwordTextfield.text?.count ?? 0 > 0 {
            signUpButton.backgroundColor = UIColor.rgb(red: 17, green: 154, blue: 237)
            signUpButton.isEnabled = false;
        } else {
            signUpButton.isEnabled = true;
            signUpButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        }
    }
    
    @objc private func handleSignUp() {
        guard let username = userNameTextfield.text, let email = emailTextfield.text, let password = passwordTextfield.text, username.count > 0, email.count > 0, password.count > 0 else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, Error) in
            
            if let error = Error {
                print("Failed to create user:", error)
                return
            }
        
            print("Successfully created user:", user?.user.uid ?? "")
            
            //Save data into Firebase
            
            if let image = self.plusPhotoButton.imageView?.image, let upLoadData = image.jpegData(compressionQuality: 0.3) {
                let filename = NSUUID().uuidString
                
                let storageRef = Storage.storage().reference().child("profile_image").child(filename)
                storageRef.putData(upLoadData, metadata: nil, completion: { (metadata, error) in
                    
                    if let error = error {
                        print("Failed to upload profile image:", error)
                        return
                    }
                    
                    storageRef.downloadURL(completion: { (downloadURL, error) in
                        if let error = error {
                            print("Failed to fetch downloadURL:", error)
                            return
                        }
                        
                        guard let profileImageUrl = downloadURL?.absoluteString else { return }
                        guard let uid = user?.user.uid else { return }
                        
                        let dictionaryValues =  ["usernames": username, "profileImageUrl": profileImageUrl]
                        let values = [uid: dictionaryValues]
                        
                        Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (error, reference) in
                            
                            if let error = error {
                                print("Failed to save user info into db", error)
                                return
                            }
                            
                            print("Sucessfully saved user info to db")
                        })
                    })
                })
            }
        }
//
//            // Firebase 5 Update: Must now retrieve downloadURL
//            storageRef.downloadURL(completion: { (downloadURL, err) in
//                if let err = err {
//                    print("Failed to fetch downloadURL:", err)
//                    return
//                }
//
//                guard let profileImageUrl = downloadURL?.absoluteString else { return }
//
//                print("Successfully uploaded profile image:", profileImageUrl)
//
//                guard let uid = user?.user.uid else { return }
//
//                let dictionaryValues = ["username": username, "profileImageUrl": profileImageUrl]
//                let values = [uid: dictionaryValues]
//
//                Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
//
//                    if let err = err {
//                        print("Failed to save user info into db:", err)
//                        return
//                    }
//
//                    print("Successfully saved user info to db")
//
//                })
//            })
//        })
    }
    
    //MARK: Private Functions
    
    private func setUpViews() {
        let stackView = UIStackView(arrangedSubviews: [emailTextfield, userNameTextfield, passwordTextfield, signUpButton])
        
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
        
        stackView.anchor(top: plusPhotoButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, width: 0, height: 200)
    }
  }
  
  //MARK: Extensions
  
  extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: Protocol functions
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            plusPhotoButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage {
            plusPhotoButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        plusPhotoButton.layer.cornerRadius = plusPhotoButton.frame.width / 2
        plusPhotoButton.layer.masksToBounds = true
        plusPhotoButton.layer.borderColor = UIColor.black.cgColor
        plusPhotoButton.layer.borderWidth = 3
        
        dismiss(animated: true)
    }
  }
  
  extension UIView {
    func anchor(top: NSLayoutYAxisAnchor?, left: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?, paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat, height: CGFloat) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
    }
  }

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
