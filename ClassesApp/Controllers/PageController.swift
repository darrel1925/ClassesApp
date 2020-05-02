//
//  PageController.swift
//  ClassesApp
//
//  Created by Darrel Muonekwu on 4/18/20.
//  Copyright © 2020 Darrel Muonekwu. All rights reserved.
//

import UIKit

class PageController: UIPageViewController {
    
    lazy var orderedViewControllers : [UIViewController] = {
        return [createVC(identifier: "WelcomeScreen1"),
                createVC(identifier: "WelcomeScreen2"),
                createVC(identifier: "WelcomeScreen3.5"),
                createVC(identifier: "WelcomeScreen4")]
    }()
    
    var pageControl = UIPageControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.dataSource = self
        if  let firstViewController = orderedViewControllers.first{
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
            setUpPageControl()
            self.delegate = self
        }
        setUpGestures()
    }
    
    func setUpGestures() {

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeRight))
        let swipeLeft  = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeLeft))
        
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        swipeLeft.direction  = UISwipeGestureRecognizer.Direction.left
        
        self.view.addGestureRecognizer(swipeRight)
        self.view.addGestureRecognizer(swipeLeft)
    }
    
    @objc func respondToSwipeRight() {
        print("right")
        self.setViewControllers([orderedViewControllers[0]], direction: .forward, animated: true, completion: nil)
    }
    
    @objc func respondToSwipeLeft() {
        print("left")
        self.setViewControllers([orderedViewControllers[1]], direction: .reverse, animated: true, completion: nil)
    }
    
    func setUpPageControl(){
        
        pageControl = UIPageControl(frame: CGRect(x:0 , y :UIScreen.main.bounds.maxY - 50,  width: UIScreen.main.bounds.width, height:50))
        pageControl.numberOfPages = orderedViewControllers.count
        pageControl.currentPage = 0
        pageControl.tintColor = UIColor.black
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.black
        self.view.addSubview(pageControl)
    }
    
    func createVC(identifier: String) -> UIViewController{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
}

extension PageController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of:  viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of:  viewController) else{
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        
        // if you reach the end?
        guard orderedViewControllers.count != nextIndex else{
            
            return nil
        }
        
        guard orderedViewControllers.count  > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.pageControl.currentPage = orderedViewControllers.firstIndex(of : pageContentViewController)!
    }
    
}
