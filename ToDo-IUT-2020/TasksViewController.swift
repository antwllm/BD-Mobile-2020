//
//  ViewController.swift
//  ToDo-IUT-2020
//
//  Created by William Antwi on 07/04/2020.
//  Copyright © 2020 Appsolute SARL. All rights reserved.
//

import UIKit

class TasksViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let tasksManager = TasksManager.shared
        
    var tasks: [Task] {
        return tasksManager.tasks
    }
    
    lazy var dateFormatter : DateFormatter = {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "d MMM, HH'h'mm"
        
        return dateFormatter
    } ()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tasksManager.delegate = self
        
        searchController.searchResultsUpdater = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.placeholder = "Type a name"
        
        navigationItem.searchController = searchController
        
        definesPresentationContext = false
        
        self.navigationItem.leftBarButtonItem?.title = "Sorting : \(tasksManager.currentSorting.label)"
    }
        
    @IBAction func sortBy(_ sender: Any) {
        
        let alertController = UIAlertController(title: "ToDo", message: "Sort by", preferredStyle: .actionSheet)
        
        for sorting in tasksManager.availableSortings {
            
            let action = UIAlertAction(title: tasksManager.labelForSorting(sorting), style: .default) { (action) in
                                              
                self.tasksManager.currentSorting = sorting
                
                
                self.navigationItem.leftBarButtonItem?.title = "Sorting : \(sorting.label)"
            }
                          
            alertController.addAction(action)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancel)
               
        present(alertController, animated: true, completion: nil)
    
    }
    
    @IBAction func addTask(_ sender: Any) {
        
        let alertController = UIAlertController(title: "To Do", message: "Add task", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            
            textField.placeholder = "New task \(self.tasks.count + 1)"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
            
            if let textfield = alertController.textFields?[0],
                let taskName = textfield.text,
                taskName.count > 0 {
                
                self.tasksManager.createTask(name: taskName)
            }
        }
        
        alertController.addAction(saveAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
}

extension TasksViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        tasksManager.filterTasksWithText(searchController.searchBar.text ?? "")
    }
}

extension TasksViewController: TasksManagerDelegate {
    
    func didUpdateData() {
        tableView.reloadData()
    }
}

extension TasksViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tasks.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let task = tasks[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCellIdentifier")!
        
        cell.textLabel?.text = task.name
        cell.accessoryType = task.checked ? .checkmark : .none
        cell.detailTextLabel?.text = "C : \(dateFormatter.string(from: task.createdAt)) - U : \(dateFormatter.string(from: task.updatedAt))"
        cell.detailTextLabel?.textColor = .gray
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let task = tasks[indexPath.row]
        task.checked = !task.checked
        task.updatedAt = Date()
        
        tasksManager.syncTask(task)
                
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let task = self.tasks[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
                        
            self.tasksManager.deleteTask(task)
            
            completion(true)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { (action, view, completion) in
            
            let alertController = UIAlertController(title: "To Do", message: "Edit task", preferredStyle: .alert)
            
            alertController.addTextField { $0.text = task.name }
            
            let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
                
                if let textfield = alertController.textFields?[0],
                    let taskName = textfield.text,
                    taskName.count > 0  {
                    
                    task.name = taskName
                    task.updatedAt = Date()
                    
                    self.tasksManager.syncTask(task)
                    
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }
            
            alertController.addAction(saveAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alertController.addAction(cancelAction)
            
            
            self.present(alertController, animated: true, completion: nil)
            
            completion(true)
        }
        
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        
    }
}
