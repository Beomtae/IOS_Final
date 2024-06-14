//
//  AddScheduleViewController.swift
//  mixchedule
//
//  Created by Choi76 on 6/13/24.
//

import UIKit
import Firebase

class AddScheduleViewController: UIViewController {

    @IBOutlet weak var scheduleNameTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var selectedDateLabel: UILabel!
    
    var selectedDate: Date? // 전달받은 선택된 날짜
    
    let db = Database.database().reference() // Firebase 데이터베이스 참조
    var userName: String? // 현재 로그인한 사용자의 이름
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .pageSheet // 모달 스타일 설정
        
        // 선택된 날짜를 selectedDateLabel에 표시
        if let date = selectedDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            selectedDateLabel.text = dateFormatter.string(from: date)
        }
        
        // 현재 로그인한 사용자의 이름 가져오기
        fetchUserName()
    }
    
    func fetchUserName() {
        guard let user = Auth.auth().currentUser else {
            print("사용자가 로그인되지 않았습니다.")
            return
        }
        
        let uid = user.uid
        db.child("members").child(uid).observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any],
                  let name = userData["Name"] as? String else {
                print("사용자 데이터를 가져오지 못했습니다.")
                return
            }
            self.userName = name
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        // 모든 값을 채웠는지 검사
        guard let date = selectedDate,
              let title = scheduleNameTextField.text, !title.isEmpty,
              let time = timeTextField.text, !time.isEmpty,
              let name = userName else {
            // 값이 비어 있을 경우
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let month = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: date)
        
        let eventData: [String: String] = [
            "title": title,
            "time": time,
            "user": name
        ]
        
        // 파이어베이스에 일정 저장
        db.child("events").child(month).child(day).observeSingleEvent(of: .value) { snapshot in
            var eventsArray: [[String: String]] = snapshot.value as? [[String: String]] ?? []
            eventsArray.append(eventData)
            
            self.db.child("events").child(month).child(day).setValue(eventsArray) { error, _ in
                if let error = error {
                    print("일정 저장 실패: \(error.localizedDescription)")
                    return
                }
                print("일정 저장 성공")
                
                // 일정 저장 후 NotificationCenter를 통해 ScheduleViewController에 알림
                NotificationCenter.default.post(name: NSNotification.Name("ScheduleDidChange"), object: nil)
                
                // 일정 저장 이후 모달 창 종료
                self.dismiss(animated: true)
            }
        }
    }
}
