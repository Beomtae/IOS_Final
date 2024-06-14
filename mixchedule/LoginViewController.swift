//
//  LoginViewController.swift
//  mixchedule
//
//  Created by Choi76 on 6/12/24.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var idTextFiled: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginUIButton: UIButton!
    @IBOutlet weak var signInUIButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        // 바탕화면 클릭시 키보드 내리기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    
    // 로그인
    @IBAction func login(_ sender: UIButton) {
        guard let email = idTextFiled.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            print("아이디와 비밀번호를 입력하세요.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("로그인 실패: \(error.localizedDescription)")
                return
            }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarVC = storyboard
                .instantiateViewController(identifier: "TabBarViewController") as TabBarViewController
            tabBarVC.modalPresentationStyle = .fullScreen //전체 화면으로 변경
            self.navigationController?.pushViewController(tabBarVC, animated: true)
            print("로그인 성공!")
        }
    }
    
    // 회원가입
    @IBAction func signIn(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signUpViewController = storyboard
            .instantiateViewController(identifier: "SignUpViewController") as SignUpViewController
        signUpViewController.modalPresentationStyle = .fullScreen //전체 화면으로 변경
        navigationController?.pushViewController(signUpViewController, animated: true)
    }
    
    
    // 바탕화면 클릭시 키보드 내리기
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // 키보드 올라갈 때 전체 화면 위로 올리기
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= (keyboardSize.height) // 키보드 높이만큼 이동
            }
        }
    }
   
    // 키보드 내려갈때 전체 화면 원상복귀
    @objc private func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }

}
