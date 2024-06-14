//
//  MyPageViewController.swift
//  mixchedule
//
//  Created by Choi76 on 6/13/24.
//

import UIKit
import Firebase

class MyPageViewController: UIViewController {

    @IBOutlet weak var emailLabel: UILabel! // 이메일
    @IBOutlet weak var nameLabel: UILabel! // 이름
    @IBOutlet weak var positionLabel: UILabel! // 직책
    @IBOutlet weak var deptLabel: UILabel! // 단과대
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 현재 로그인한 사용자의 정보 가져오기
        fetchUserInfo()
    }
    
    func fetchUserInfo() {
        guard let user = Auth.auth().currentUser else {
            print("사용자가 로그인되지 않았습니다.")
            return
        }
        
        let uid = user.uid
        let db = Database.database().reference()
        
        db.child("members").child(uid).observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any] else {
                print("사용자 데이터를 가져오지 못했습니다.")
                return
            }
            
            // Firebase에서 사용자 정보 가져와서 레이블에 설정
            self.emailLabel.text = userData["ID"] as? String
            self.nameLabel.text = userData["Name"] as? String
            self.positionLabel.text = userData["Pos"] as? String
            self.deptLabel.text = userData["Dept"] as? String
        }
    }
}

