#lang racket

(provide tool@)

(require drracket/tool
         framework
         racket/gui/base

         sauron/project/manager
         sauron/project/current-project
         sauron/project/panel)

(define tool@
  (unit
    (import drracket:tool^)
    (export drracket:tool-exports^)

    (define (phase1) (void))
    (define (phase2) (void))

    (define drracket-frame-mixin
      (mixin (drracket:unit:frame<%> (class->interface drracket:unit:frame%)) ()
        (define project-files-show? #f)

        (super-new)

        (define/override (get-definitions/interactions-panel-parent)
          (define panel (new panel:horizontal-dragable% [parent (super get-definitions/interactions-panel-parent)]))
          (define real-area (new panel:vertical-dragable% [parent panel]))

          (new project-files-pane% [parent real-area]
               [editor-panel this])
          (send real-area set-percentages '(1/20 19/20))

          (define (close-real-area)
            (set! project-files-show? #f)
            (send panel change-children
                  (λ (x)
                    (filter
                     (λ (x) (not (eq? real-area x))) x))))
          (define (show-real-area)
            (set! project-files-show? #t)
            (send panel change-children
                  (λ (x) (cons real-area x)))
            (send panel set-percentages '(2/11 9/11)))
          (new menu-item% [parent (send this get-show-menu)]
               [label (if project-files-show? "Hide the Project Viewer" "Show the Project Viewer")]
               [callback
                (λ (c e)
                  (define (get-manager)
                    (new project-manager%
                         [label "select a project"]
                         [on-select
                          (λ (path)
                            (send current-project set path)
                            (show-real-area)
                            (send c set-label "Hide the Project Viewer"))]))
                  (if (send current-project get)
                      (if project-files-show?
                          (let ()
                            (close-real-area)
                            (send c set-label "Show the Project Viewer"))
                          (let ()
                            (show-real-area)
                            (send c set-label "Hide the Project Viewer")))
                      (send (get-manager) run)))]
               ;;; c+y   open project viewer (on Linux, MacOS)
               ;;; c+s+y open project viewer (on Windows)
               [shortcut #\y]
               [shortcut-prefix (case (system-type)
                                  [(windows) '(ctl shift)]
                                  [else (get-default-shortcut-prefix)])])

          (let ([edit-menu (send this get-edit-menu)])
            (for ([item (send edit-menu get-items)])
              (when (and (is-a? item labelled-menu-item<%>) (equal? "Find" (send item get-label)))
                (send item delete)))
            (new menu-item% [parent edit-menu]
                 [label "Find"]
                 [callback (λ (c e)
                             (if (send this search-hidden?)
                                 (send this unhide-search-and-toggle-focus
                                       #:new-search-string-from-selection? #t)
                                 (send this hide-search)))]
                 ;;; c+f search text
                 [shortcut #\f]
                 [shortcut-prefix (get-default-shortcut-prefix)]))

          (unless project-files-show?
            (send panel change-children
                  (λ (x)
                    (filter
                     (λ (x) (not (eq? real-area x))) x))))
          (make-object vertical-panel% panel))))

    (drracket:get/extend:extend-unit-frame drracket-frame-mixin)))
