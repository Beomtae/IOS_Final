//
//  SignUpViewController.swift
//  mixchedule
//
//  Created by Choi76 on 6/13/24.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var pwTextField: UITextField!
    @IBOutlet weak var posTextField: UITextField! // 교수,학생,교직원,등
    @IBOutlet weak var deptPickerView: UIPickerView!
    
    // 사용자가 선택 가능한 단과대학 목록
    let departments = ["디자인대학", "창의융합대학", "IT공과대학", "인문예술대학", "사회과학대학"]
       
    override func viewDidLoad() {
        super.viewDidLoad()

        // pickerview 설정
        deptPickerView.dataSource = self
        deptPickerView.delegate = self
        
        let index = departments.count / 2
        deptPickerView.selectRow(index, inComponent: 0, animated: false)
    }

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard let email = idTextField.text, !email.isEmpty,
              let password = pwTextField.text, !password.isEmpty,
              let name = nameTextField.text, !name.isEmpty,
              let position = posTextField.text, !position.isEmpty else {
            // 모든 값을 채우지 않았을 경우
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("회원가입 실패: \(error.localizedDescription)")
                return
            }
            
            guard let uid = authResult?.user.uid else { return }
            
            
            let deptIndex = self.deptPickerView.selectedRow(inComponent: 0)
            let dept = self.departments[deptIndex]
            
            let memberData: [String: Any] = [
                "ID": email,
                "Name": name,
                "Pos": position,
                "Dept": dept
            ]
            
            Database.database().reference().child("members").child(uid).setValue(memberData) { error, _ in
                if let error = error {
                    print("회원 정보 저장 실패: \(error.localizedDescription)")
                    return
                }
                print("회원가입 성공")
                
                // 회원가입 성공 이후 로그인 페이지로 되돌아가기
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

}
extension SignUpViewController : UIPickerViewDelegate,UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return departments.count
    }


    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return departments[row]
    }
}

