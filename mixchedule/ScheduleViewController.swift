//
//  LoginViewController.swift
//  mixchedule
//
//  Created by Choi76 on 6/12/24.
//

import UIKit
import Firebase
import FSCalendar

class ScheduleViewController: UIViewController {

    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var collectionview: UICollectionView!
    @IBOutlet weak var addSchedule: UIButton!
    @IBOutlet weak var selectedDateLabel: UILabel!
    
    var events: [String: [String: [Event]]] = [:] // 년-월별로 이벤트 저장용
    var selectedDateEvents: [Event] = [] // 선택된 날짜의 이벤트 저장
    var selectedDate: Date? // 현재 선택된 날짜 저장
    
    let db = Database.database().reference() // Firebase 데이터베이스 참조
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        calendar.delegate = self
        calendar.dataSource = self
        
        // 컬렉션 뷰 설정
        collectionview.dataSource = self
        collectionview.delegate = self
        collectionview.register(UINib(nibName: "SechduleCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "SechduleCollectionViewCell")
        
        // FSCalendar 달력 커스텀 설정
        calendarInit()
        
        // 오늘 날짜의 일정 불러오기
        let today = Date()
        fetchEventsForMonth(date: today) { [weak self] in
            self?.calendar(self!.calendar, didSelect: today, at: .current)
        }
        
        // NotificationCenter 등록 => 스케쥴이 업데이트 되었을 때 동작
        NotificationCenter.default.addObserver(self, selector: #selector(scheduleDidChange(_:)), name: NSNotification.Name("ScheduleDidChange"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ScheduleDidChange"), object: nil)
    }
    
    @objc func scheduleDidChange(_ notification: Notification) {
        guard let date = selectedDate else { return }
        fetchEventsForMonth(date: date) { [weak self] in
            self?.calendar(self!.calendar, didSelect: date, at: .current)
        }
    }
    
    // 네비게이션 바 숨기기
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // 주어진 날짜의 년,월 일정들 불러와서 저장
    func fetchEventsForMonth(date: Date, completion: (() -> Void)? = nil) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        
        let currentMonth = dateFormatter.string(from: date)
        
        // 기존 이벤트 데이터 초기화
        self.events.removeAll()
        
        db.child("events").child(currentMonth).observeSingleEvent(of: .value) { snapshot  in
            guard let monthData = snapshot.value as? [String: [[String: String]]] else { return }
            
            var monthEvents: [String: [Event]] = [:]
            
            for (day, eventsArray) in monthData {
                var dailyEvents: [Event] = []
                for eventData in eventsArray {
                    if let title = eventData["title"], let time = eventData["time"], let username = eventData["user"] {
                        dailyEvents.append(Event(title: title, time: time, user: username))
                    }
                }
                monthEvents[day] = dailyEvents // 일정 정보 딕셔너리에 저장
            }
            self.events[currentMonth] = monthEvents
            self.calendar.reloadData()
            completion?()
        }
    }
    
    func calendarInit(){
        calendar.appearance.headerTitleColor = .black // 헤더 타이틀 색상
        calendar.appearance.weekdayTextColor = .black // 요일 텍스트 색상
        calendar.appearance.weekdayFont = .boldSystemFont(ofSize: 15.0)
    }
    
    // 일정 추가하기
    @IBAction func addScheduleTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "addSchedule", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addSchedule" {
            if let addScheduleVC = segue.destination as? AddScheduleViewController {
                addScheduleVC.selectedDate = self.selectedDate // 선택한 날짜 정보 전달
            }
        }
    }
}

extension ScheduleViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let month = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: date)
        
        return events[month]?[day]?.count ?? 0
    }

    // 사용자가 달력의 특정 요일 클릭시
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        self.selectedDate = date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let month = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: date)

        selectedDateEvents = events[month]?[day] ?? []
        self.collectionview.reloadData()
        
        // 선택한 날짜를 selectedDateLabel에 표시
        dateFormatter.dateFormat = "yyyy-MM-dd"
        selectedDateLabel.text = dateFormatter.string(from: date)
    }
    
    // 사용자가 달력의 다른 달로 이동할 때 이벤트를 새로 불러옴
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        let currentPage = calendar.currentPage
        fetchEventsForMonth(date: currentPage)
    }
    
    // 달력을 스크롤할 때 달력의 표시 범위가 변경되었는지 확인하고 변경되었으면 데이터 초기화 및 로드
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.view.layoutIfNeeded()
    }
}

extension ScheduleViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedDateEvents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SechduleCollectionViewCell", for: indexPath) as? SechduleCollectionViewCell else {
            return UICollectionViewCell()
        }
        let event = selectedDateEvents[indexPath.row]
        cell.scheduleNameLabel.text = event.title
        cell.scheduleTimeLabel.text = event.time
        cell.postedUsername.text = event.user
        return cell
    }
    
    // 스케쥴 셀이 가로로 보여지도록
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let framSize = self.collectionview.frame.size
        let height = framSize.height
        let width = framSize.width
        
        return CGSize(width: width - 20, height: height / 2 - 40)
    }
}
