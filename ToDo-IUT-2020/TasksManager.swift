//
//  TasksManager.swift
//  ToDo-IUT-2020
//
//  Created by William Antwi on 03/05/2020.
//  Copyright © 2020 Appsolute SARL. All rights reserved.
//

import Foundation

import Firebase

extension String {
    
    func clean() -> String {
        return self.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}

protocol TasksManagerDelegate: AnyObject {
    
    func didUpdateData()
}

class TasksManager {
    
    static let shared = TasksManager()
    
    weak var delegate: TasksManagerDelegate?
    
    let tasksRef = Database.database().reference()
    
    var tasks = [Task]()
    
    private var baseTasks = [Task]() {
        
        didSet {
            filterTasksWithText(currentSearchText)
        }
    }
    
    private var currentSearchText = ""
    
    class Sorting {
        
        enum Field {
            case name, checked, updatedAt, createdAt
            
            var label: String {
                
                var label = ""
                
                switch self {
                case .checked:
                    label = "Checked"
                case .updatedAt:
                    label = "Updated At"
                case .createdAt:
                    label = "Created At"
                default:
                    label = "Name"
                }
                
                return label
            }
        }
        
        var field: Field = .name
        var ascending: Bool = true
        
        var label: String {
            return ascending ? ascendingLabel : descendingLabel
        }
        
        var ascendingLabel: String {
            return field.label + " ↑"
        }
        
        var descendingLabel: String {
            return field.label + " ↓"
        }
        
        init (_ field: Field, ascending: Bool = true) {
            
            self.field = field
            self.ascending = ascending
        }
    }
    
    var _currentSorting : Sorting
    
    var currentSorting : Sorting {
        
        get { return _currentSorting }
        
        set(value) {
            
            if _currentSorting.field == value.field {
                
                value.ascending = !value.ascending
                
            } else {
                
                _currentSorting.ascending = true
            }
            
            _currentSorting = value
            
            sortTasks()
            
            delegate?.didUpdateData()
        }
    }
    
    let availableSortings = [Sorting(.name), Sorting(.checked), Sorting(.updatedAt), Sorting(.createdAt)]
    
    init() {
        
        _currentSorting = Sorting(.name)
        setupObservers()
    }
    
    
    //MARK: Task Helper
    
    func createTask(name: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        
        let task = Task(name, createdAt: createdAt, updatedAt: updatedAt)
        
        let taskRef = tasksRef.childByAutoId()
        
        task.firebaseId = taskRef.key
        
        let taskDict = task.postDict()
        
        taskRef.setValue(taskDict)
        
        baseTasks.append(task)
        sortTasks()
        
    }
    
    func removeTask(withId id: String) {
        
        baseTasks.removeAll {
            return $0.firebaseId == id
        }
        
    }
    
    func getTask(withId id: String) -> Task? {
        
        return baseTasks.first {
            return $0.firebaseId == id
        }
    }
    
    func syncTask(_ task: Task) {
        
        if let id = task.firebaseId {
            
            let taskRef = tasksRef.child(id)
            
            taskRef.updateChildValues(task.postDict())
        }
        
    }
    
    func deleteTask(_ task: Task) {
        
        baseTasks.removeAll {
            return ($0 === task)
        }
        
        if let id = task.firebaseId {
            
            let taskRef = tasksRef.child(id)
            
            taskRef.removeValue()
        }
    }
    
    //MARK: Sorting & search
    
    func labelForSorting(_ sorting: Sorting) -> String {
        
        if sorting.field == currentSorting.field {
            return currentSorting.ascending ? currentSorting.descendingLabel : currentSorting.ascendingLabel
        } else {
            return sorting.label
        }
    }
    
    func sortTasks() {
        
        let sorting = currentSorting
        
        switch sorting.field {
        case .name:
            sorting.ascending ?
                
                baseTasks.sort { $0.name.clean() < $1.name.clean() } :
                baseTasks.sort { $0.name.clean() > $1.name.clean() }
        case .updatedAt:
            sorting.ascending ? baseTasks.sort { $0.updatedAt < $1.updatedAt } : baseTasks.sort { $0.updatedAt > $1.updatedAt }
        case .checked:
            sorting.ascending ? baseTasks.sort { $1.checked && !$0.checked } : baseTasks.sort { $0.checked && !$1.checked }
        default:
            sorting.ascending ? baseTasks.sort { $0.createdAt < $1.createdAt } : baseTasks.sort { $0.createdAt > $1.createdAt }
        }
        
        self.delegate?.didUpdateData()
    }
    
    func filterTasksWithText(_ text: String) {
        
        currentSearchText = text
        
        if !currentSearchText.isEmpty {
            
            tasks = baseTasks.filter { $0.name.range(of: currentSearchText, options: [.diacriticInsensitive, .caseInsensitive]) != nil}
            
        } else {
            tasks = baseTasks
        }
        
        delegate?.didUpdateData()
    }
    
    
    //MARK: Firebase
    
    private func handleTask(withSnapshot snapshot: DataSnapshot) {
        
        if let taskDict = snapshot.value as? [String : Any] {
            
            if let task = self.getTask(withId: snapshot.key) {
                
                task.update(withDicytionary: taskDict)
                
            } else {
                
                let task = Task(taskDict)
                
                task.firebaseId = snapshot.key
                
                self.baseTasks.append(task)
                
            }
        }
        
        sortTasks()
    }
    
    func setupObservers() {
        
        tasksRef.observe(.childAdded) { (snapshot) in
            
            self.handleTask(withSnapshot: snapshot)
            
            self.delegate?.didUpdateData()
        }
        
        tasksRef.observe(.childChanged) { (snapshot) in
            
            self.handleTask(withSnapshot: snapshot)
            
            self.delegate?.didUpdateData()
            
        }
        
        tasksRef.observe(.childRemoved) { (snapshot) in
            
            self.removeTask(withId: snapshot.key)
            
            self.delegate?.didUpdateData()
        }
        
    }
}
